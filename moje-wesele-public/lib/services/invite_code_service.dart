import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/invite_package.dart';
import '../models/join_code.dart';
import 'firestore_service.dart';

/// Stan kodu jednej paczki — złożony z prywatnego indeksu przy weselu
/// i tego, co realnie leży w publicznym `inviteCodes`.
class PackageCode {
  const PackageCode({
    required this.packageId,
    required this.code,
    required this.revoked,
    required this.roster,
  });

  final int packageId;
  final String code;

  /// Kod unieważniony — gość z takim zaproszeniem zostanie odprawiony
  /// (obsługa po stronie gościa dochodzi w etapie 3).
  final bool revoked;

  /// Odcisk składu paczki z chwili ostatniej synchronizacji.
  final String roster;

  factory PackageCode.fromMap(int packageId, Map<String, dynamic> m) =>
      PackageCode(
        packageId: packageId,
        code: (m['code'] as String?)?.trim() ?? '',
        revoked: m['revoked'] == true,
        roster: (m['roster'] as String?) ?? '',
      );

  Map<String, dynamic> toMap() => {
        'code': code,
        'revoked': revoked,
        'roster': roster,
      };
}

/// Wynik synchronizacji rosterów.
class SyncCodesResult {
  const SyncCodesResult({required this.updated, required this.failed});

  /// Ile paczek doczekało się odświeżonego składu w `inviteCodes`.
  final int updated;

  /// Ile nie udało się zaktualizować (np. brak uprawnień, brak sieci).
  final int failed;

  bool get anythingDone => updated > 0 || failed > 0;
}

/// Kody zaproszeń per paczka (etap 2).
///
/// DWA MIEJSCA, ŚWIADOMIE:
///
///  • `weddings/{id}.invitePackages` — PRYWATNY indeks organizatora
///    `{ "<packageId>": { code, revoked, roster } }`. Leży w chronionym
///    dokumencie wesela, bo tylko organizator ma prawo wiedzieć, który kod
///    należy do której paczki (do przedruku i unieważnienia).
///
///  • `inviteCodes/{KOD}` — PUBLICZNY dokument czytany przez gościa bez
///    logowania. Zawiera wyłącznie to, co gość musi zobaczyć: wesele, token
///    strefy gości i IMIONA z paczki.
///
/// Dlaczego nie jedno miejsce: gdyby kod dało się znaleźć zapytaniem po
/// `inviteCodes`, trzeba by otworzyć `list` — a wtedy ktokolwiek pobrałby
/// wszystkie kody wszystkich wesel. Reguła zostaje `list: false`, więc
/// odwrotne wyszukiwanie (paczka → kod) musi mieszkać po stronie organizatora.
class InviteCodeService {
  InviteCodeService({FirestoreService? firestore, FirebaseFirestore? db})
      : _firestore = firestore ?? FirestoreService(),
        _db = db ?? FirebaseFirestore.instance;

  final FirestoreService _firestore;
  final FirebaseFirestore _db;

  /// Publiczny indeks kodów paczek.
  static const String collectionName = 'inviteCodes';

  /// Klucz mapy kodów w dokumencie wesela.
  static const String indexField = 'invitePackages';

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(collectionName);

  /// Odczytuje prywatny indeks kodów z surowego dokumentu wesela.
  static Map<int, PackageCode> indexOf(Map<String, dynamic> raw) {
    final m = raw[indexField];
    if (m is! Map) return const {};
    final out = <int, PackageCode>{};
    for (final e in m.entries) {
      final id = int.tryParse(e.key.toString());
      if (id == null || e.value is! Map) continue;
      final pc = PackageCode.fromMap(
          id, Map<String, dynamic>.from(e.value as Map));
      if (pc.code.isNotEmpty) out[id] = pc;
    }
    return out;
  }

  /// Świeży odczyt prywatnego indeksu z dokumentu wesela.
  Future<Map<int, PackageCode>> readIndex() async =>
      indexOf(await _firestore.readData() ?? const <String, dynamic>{});

  /// Paczki, których opublikowany skład rozjechał się z listą gości.
  ///
  /// To jest ten „widoczny znacznik": zaproszenie mogło zostać wydrukowane
  /// z innym składem, więc organizator ma o tym wiedzieć, zanim gość zobaczy
  /// nieaktualną listę imion.
  static List<InvitePackage> staleOf(
    List<InvitePackage> packages,
    Map<int, PackageCode> index,
  ) =>
      [
        for (final p in packages)
          if (index[p.id] != null && index[p.id]!.roster != p.rosterFingerprint)
            p,
      ];

  /// Nadaje kod paczkom, które jeszcze go nie mają.
  ///
  /// Istniejących kodów NIE rusza — zaproszenia bywają już wydrukowane.
  /// [onProgress] pozwala pokazać pasek przy kilkudziesięciu paczkach.
  Future<int> generateMissing(
    List<InvitePackage> packages,
    Map<String, dynamic> raw, {
    void Function(int done, int total)? onProgress,
  }) async {
    final index = indexOf(raw);
    final missing = [for (final p in packages) if (!index.containsKey(p.id)) p];
    if (missing.isEmpty) return 0;

    var done = 0;
    for (final p in missing) {
      await _publish(p, await _uniqueCode());
      done++;
      onProgress?.call(done, missing.length);
    }
    return done;
  }

  /// Wystawia paczce NOWY kod i kasuje stary.
  ///
  /// ⚠️ Poprzedni kod przestaje działać — wydrukowane zaproszenia z tym QR-em
  /// stają się bezużyteczne. Wołający musi to potwierdzić u organizatora.
  Future<String> regenerate(InvitePackage p, Map<String, dynamic> raw) async {
    final old = indexOf(raw)[p.id];
    final code = await _uniqueCode();
    await _publish(p, code);
    if (old != null && old.code.isNotEmpty && old.code != code) {
      // Kasujemy dopiero PO zapisaniu nowego — gdyby zapis padł, paczka
      // zostaje ze starym, działającym kodem zamiast z żadnym.
      await _col.doc(old.code).delete().catchError((_) {});
    }
    return code;
  }

  /// Unieważnia kod paczki, zostawiając go w bazie ze znacznikiem.
  ///
  /// Nie kasujemy dokumentu, żeby gość skanujący stare zaproszenie dostał
  /// zrozumiały komunikat zamiast „nieprawidłowy kod".
  Future<void> setRevoked(InvitePackage p, Map<String, dynamic> raw,
      {required bool revoked}) async {
    final current = indexOf(raw)[p.id];
    if (current == null) return;
    await _col.doc(current.code).set(
      {'revoked': revoked, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
    await _saveIndex(p.id, PackageCode(
      packageId: p.id,
      code: current.code,
      revoked: revoked,
      roster: current.roster,
    ));
  }

  /// Odświeża skład paczek, których roster rozjechał się z listą gości.
  ///
  /// Wołane przy otwarciu ekranu zaproszeń — zapisuje TYLKO to, co się
  /// zmieniło, więc otwarcie ekranu bez zmian nie kosztuje ani jednego zapisu.
  Future<SyncCodesResult> syncRosters(
    List<InvitePackage> packages,
    Map<String, dynamic> raw,
  ) async {
    final index = indexOf(raw);
    final stale = staleOf(packages, index);
    if (stale.isEmpty) return const SyncCodesResult(updated: 0, failed: 0);

    var updated = 0;
    var failed = 0;
    for (final p in stale) {
      try {
        await _publish(p, index[p.id]!.code, revoked: index[p.id]!.revoked);
        updated++;
      } catch (_) {
        failed++;
      }
    }
    return SyncCodesResult(updated: updated, failed: failed);
  }

  /// Zapisuje paczkę w obu miejscach: publicznym dokumencie i prywatnym
  /// indeksie przy weselu.
  Future<void> _publish(InvitePackage p, String code,
      {bool revoked = false}) async {
    final token = await _guestToken();
    await _col.doc(code).set({
      'weddingId': _firestore.weddingId,
      'guestToken': token,
      'packageId': p.id,
      // ⚠️ WYŁĄCZNIE imiona — patrz InvitePackage.members. Nazwiska tylko przy
      // powtórzonym imieniu w tej samej paczce; żadnych telefonów, diet,
      // kategorii ani przypisania do stołu.
      'members': [
        for (final m in p.members)
          {
            'guestId': m.guestId,
            'name': m.name,
            'kind': m.isMain ? 'main' : 'companion',
            'namePending': m.namePending,
          },
      ],
      // Płaska lista identyfikatorów — reguła etapu 3 sprawdzi nią, czy
      // wybrana tożsamość należy do tej paczki (reguły nie umieją zaglądać
      // do map wewnątrz tablicy).
      'memberIds': [for (final m in p.members) m.guestId],
      'revoked': revoked,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _saveIndex(
      p.id,
      PackageCode(
        packageId: p.id,
        code: code,
        revoked: revoked,
        roster: p.rosterFingerprint,
      ),
    );
  }

  Future<void> _saveIndex(int packageId, PackageCode value) =>
      _firestore.mainDoc.set({
        indexField: {'$packageId': value.toMap()},
      }, SetOptions(merge: true));

  /// Token strefy gości — kod paczki prowadzi do TEJ SAMEJ strefy co wspólny
  /// link. Indywidualny kod jest bramką tożsamości, nie osobnym miejscem.
  Future<String> _guestToken() async {
    final data = await _firestore.readData() ?? const <String, dynamic>{};
    return (data['guestToken'] as String?)?.trim() ?? '';
  }

  /// Losuje kod i sprawdza, czy nie jest zajęty.
  Future<String> _uniqueCode() async {
    for (var i = 0; i < 6; i++) {
      final code = _generate();
      final taken = await _col.doc(code).get();
      if (!taken.exists) return code;
    }
    return _generate(JoinCode.length + JoinCode.groupSize);
  }

  String _generate([int length = JoinCode.length]) {
    final rnd = Random.secure();
    return List.generate(
      length,
      (_) => JoinCode.alphabet[rnd.nextInt(JoinCode.alphabet.length)],
    ).join();
  }
}
