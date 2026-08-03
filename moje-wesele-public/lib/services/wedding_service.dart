import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/wedding_summary.dart';
import '../utils/warsaw_time.dart';
import 'membership_service.dart';
import 'user_service.dart';

/// Wynik próby dołączenia do wesela jako gość.
enum JoinOutcome {
  /// Dołączono (utworzono członkostwo gościa).
  success,

  /// Użytkownik już należał do tego wesela (bez zmian).
  alreadyMember,

  /// Dane (kod/data/nazwisko) nie zgadzają się z żadnym weselem.
  invalid,

  /// Błąd techniczny (np. brak sieci).
  error,
}

/// Rezultat dołączania: wynik + ID wesela (gdy powodzenie) + rola.
class JoinResult {
  const JoinResult(this.outcome, {this.weddingId, this.role});
  final JoinOutcome outcome;
  final String? weddingId;
  final String? role;
}

/// Wynik dodawania osoby po e-mailu (panel „Osoby i dostęp").
enum AddPersonOutcome {
  /// Dodano członkostwo dla znalezionego konta.
  success,

  /// Nikt z tym adresem nie ma jeszcze konta w aplikacji.
  noAccount,

  /// Osoba już ma dostęp do tego wesela.
  alreadyMember,

  /// Błąd techniczny.
  error,
}

/// Wynik odbierania zaproszenia kodem (współorganizator/planer).
enum ClaimOutcome { success, alreadyMember, invalid, error }

class ClaimResult {
  const ClaimResult(this.outcome, {this.weddingId, this.role});
  final ClaimOutcome outcome;
  final String? weddingId;
  final String? role;
}

/// Zarządzanie weselami (kolekcja `weddings`) i ich powiązaniem z użytkownikiem.
///
/// Odpowiada za:
///   • utworzenie nowego wesela (auto-ID + domyślna konfiguracja + kod
///     dołączenia + członkostwo `owner` dla twórcy),
///   • listę wesel dostępnych użytkownikowi (przez jego członkostwa),
///   • dołączanie gościa po potrójnej weryfikacji (kod + data + nazwisko).
class WeddingService {
  WeddingService({
    FirebaseFirestore? db,
    MembershipService? memberships,
    UserService? users,
  })  : _db = db ?? FirebaseFirestore.instance,
        _memberships = memberships ?? MembershipService(db: db),
        _users = users ?? UserService(db: db);

  final FirebaseFirestore _db;
  final MembershipService _memberships;
  final UserService _users;

  static const String collectionName = 'weddings';

  /// Publiczny indeks kodu dołączenia gościa: `weddingCodes/{KOD}` →
  /// `{ weddingId, weddingDate, displayNames, eventName }`. Pozwala zweryfikować
  /// dane bez czytania całego (chronionego) dokumentu wesela.
  static const String weddingCodesCollection = 'weddingCodes';

  /// Indeks zaproszeń ról: `roleInvites/{KOD}` → `{ weddingId, role, expiresAt,
  /// expiresAtTs }`. Odczyt dla zalogowanych; tworzy owner.
  static const String roleInvitesCollection = 'roleInvites';

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(collectionName);

  /// Tworzy nowe wesele i nadaje twórcy rolę `owner`.
  ///
  /// Zwraca wygenerowane `weddingId`. `date` w formacie "YYYY-MM-DD" lub `null`
  /// (można uzupełnić później w Ustawieniach).
  Future<String> createWedding({
    required String userId,
    required String name,
    required String persons,
    String? date,
  }) async {
    final ref = _col.doc(); // auto-generowane, unikalne weddingId
    final weddingId = ref.id;
    final joinCode = await _uniqueJoinCode();

    await ref.set(_defaultWeddingData(
      ownerId: userId,
      name: name,
      persons: persons,
      date: date,
      joinCode: joinCode,
    ));

    await _memberships.create(
      userId: userId,
      weddingId: weddingId,
      role: 'owner',
    );

    // Publiczny indeks kodu (do weryfikacji dołączania gościa).
    await _upsertWeddingCode(
      code: joinCode,
      weddingId: weddingId,
      weddingDate: (date != null && date.isNotEmpty) ? date : null,
      displayNames: persons.trim(),
      eventName: name.trim().isEmpty ? 'Nasze Wesele' : name.trim(),
    );

    return weddingId;
  }

  /// Zwraca kod dołączenia wesela; jeśli go nie ma (starsze wesele) — generuje
  /// nowy, unikalny i zapisuje. Dodatkowo SYNCHRONIZUJE publiczny indeks
  /// `weddingCodes` z bieżącą datą/nazwiskiem (wywoływane m.in. po zapisie
  /// konfiguracji, by weryfikacja gościa działała po zmianie danych).
  Future<String> ensureJoinCode(String weddingId) async {
    final ref = _col.doc(weddingId);
    final snap = await ref.get();
    final data = snap.data() ?? const <String, dynamic>{};
    var code = (data['joinCode'] as String?)?.trim();
    if (code == null || code.isEmpty) {
      code = await _uniqueJoinCode();
      await ref.set({'joinCode': code}, SetOptions(merge: true));
    }
    final cfg = data['appConfig'];
    await _upsertWeddingCode(
      code: code,
      weddingId: weddingId,
      weddingDate: (data['weddingDate'] as String?)?.trim(),
      displayNames:
          (cfg is Map ? cfg['displayNames'] as String? : null)?.trim() ?? '',
      eventName:
          (cfg is Map ? cfg['eventName'] as String? : null)?.trim() ?? '',
    );
    return code;
  }

  /// Zapisuje/aktualizuje publiczny indeks kodu dołączenia.
  Future<void> _upsertWeddingCode({
    required String code,
    required String weddingId,
    required String? weddingDate,
    required String displayNames,
    required String eventName,
  }) =>
      _db.collection(weddingCodesCollection).doc(code).set({
        'weddingId': weddingId,
        'weddingDate': weddingDate,
        'displayNames': displayNames,
        'eventName': eventName,
      }, SetOptions(merge: true));

  /// Dołącza użytkownika jako GOŚĆ po potrójnej weryfikacji: kod + data ślubu
  /// + nazwisko/nazwa Państwa Młodych. Wszystkie trzy muszą się zgadzać.
  ///
  /// [date] w formacie "YYYY-MM-DD". [surname] porównywane z `displayNames`
  /// (a zapasowo z `eventName`) po normalizacji (bez wielkości liter/znaków
  /// diakrytycznych).
  Future<JoinResult> joinAsGuest({
    required String userId,
    required String code,
    required String date,
    required String surname,
  }) async {
    try {
      final normCode = code.trim().toUpperCase();
      if (normCode.isEmpty || date.trim().isEmpty || surname.trim().isEmpty) {
        return const JoinResult(JoinOutcome.invalid);
      }

      // Weryfikacja przez PUBLICZNY indeks (bez czytania chronionego wesela).
      final idxSnap =
          await _db.collection(weddingCodesCollection).doc(normCode).get();
      final idx = idxSnap.data();
      if (idx == null) return const JoinResult(JoinOutcome.invalid);

      final weddingId = (idx['weddingId'] as String?) ?? '';
      if (weddingId.isEmpty) return const JoinResult(JoinOutcome.invalid);

      // 1) Data ślubu musi się zgadzać (i musi być ustawiona).
      final wDate = (idx['weddingDate'] as String?)?.trim() ?? '';
      if (wDate.isEmpty || wDate != date.trim()) {
        return const JoinResult(JoinOutcome.invalid);
      }

      // 2) Nazwisko/nazwa Państwa Młodych.
      final display = (idx['displayNames'] as String?) ?? '';
      final event = (idx['eventName'] as String?) ?? '';
      if (!_surnameMatches(surname, display, event)) {
        return const JoinResult(JoinOutcome.invalid);
      }

      // Weryfikacja OK → dodaj gościa (jeśli jeszcze nie należy).
      final existing = await _memberships.findFor(userId, weddingId);
      if (existing != null) {
        return JoinResult(JoinOutcome.alreadyMember,
            weddingId: weddingId, role: existing.role);
      }
      // `claimCode` = kod dołączenia — reguła weryfikuje go względem weddingCodes.
      await _memberships.create(
        userId: userId,
        weddingId: weddingId,
        role: 'guest',
        claimCode: normCode,
      );
      return JoinResult(JoinOutcome.success, weddingId: weddingId, role: 'guest');
    } catch (_) {
      return const JoinResult(JoinOutcome.error);
    }
  }

  // ── Zarządzanie osobami (tylko owner — egzekwowane w UI) ─────────────────

  /// Dodaje osobę po e-mailu (osoba MUSI mieć już konto). `role` = 'planner'
  /// lub 'collaborator'; `expiresAt` ("YYYY-MM-DD") tylko dla planera.
  Future<AddPersonOutcome> addPersonByEmail({
    required String weddingId,
    required String email,
    required String role,
    String? expiresAt,
  }) async {
    try {
      final found = await _users.findByEmail(email);
      if (found == null) return AddPersonOutcome.noAccount;

      final existing = await _memberships.findFor(found.uid, weddingId);
      if (existing != null) return AddPersonOutcome.alreadyMember;

      await _memberships.create(
        userId: found.uid,
        weddingId: weddingId,
        role: role,
        status: 'active',
        expiresAt: role == 'planner' ? expiresAt : null,
        email: email.trim().toLowerCase(),
      );
      return AddPersonOutcome.success;
    } catch (_) {
      return AddPersonOutcome.error;
    }
  }

  /// Tworzy zaproszenie z KODEM (dla współorganizatora/planera). Zwraca kod do
  /// przekazania osobie. Powstaje dokument w indeksie `roleInvites/{KOD}`.
  Future<String> createRoleInvite({
    required String weddingId,
    required String role,
    String? expiresAt,
  }) async {
    final code = await _uniqueInviteCode();
    final exp = role == 'planner' ? expiresAt : null;
    await _db.collection(roleInvitesCollection).doc(code).set({
      'weddingId': weddingId,
      'role': role,
      'expiresAt': exp,
      'expiresAtTs': expiresAtTimestamp(exp),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return code;
  }

  /// Odbiera zaproszenie kodem — tworzy członkostwo dla bieżącego użytkownika
  /// na podstawie `roleInvites/{KOD}`. Membership zawiera `claimCode` (regułą
  /// weryfikowany względem istniejącego zaproszenia).
  Future<ClaimResult> claimRoleInvite({
    required String userId,
    required String email,
    required String displayName,
    required String code,
  }) async {
    try {
      final normCode = code.trim().toUpperCase();
      if (normCode.isEmpty) return const ClaimResult(ClaimOutcome.invalid);

      final inviteSnap =
          await _db.collection(roleInvitesCollection).doc(normCode).get();
      final invite = inviteSnap.data();
      if (invite == null) return const ClaimResult(ClaimOutcome.invalid);

      final weddingId = (invite['weddingId'] as String?) ?? '';
      final role = (invite['role'] as String?) ?? '';
      if (weddingId.isEmpty || role.isEmpty) {
        return const ClaimResult(ClaimOutcome.invalid);
      }

      final existing = await _memberships.findFor(userId, weddingId);
      if (existing != null) {
        return ClaimResult(ClaimOutcome.alreadyMember,
            weddingId: weddingId, role: existing.role);
      }

      await _memberships.create(
        userId: userId,
        weddingId: weddingId,
        role: role,
        status: 'active',
        expiresAt: (invite['expiresAt'] as String?),
        email: email.trim().toLowerCase(),
        displayName: displayName,
        claimCode: normCode,
      );
      return ClaimResult(ClaimOutcome.success, weddingId: weddingId, role: role);
    } catch (_) {
      return const ClaimResult(ClaimOutcome.error);
    }
  }

  /// Lista wesel dostępnych użytkownikowi (z jego członkostw). Wesela usunięte
  /// (brak dokumentu) są pomijane. Sortowanie: najbliższa data pierwsza,
  /// wesela bez daty na końcu.
  Future<List<WeddingSummary>> listForUser(String userId) async {
    final memberships = await _memberships.forUser(userId);
    final today = warsawToday();
    final result = <WeddingSummary>[];
    for (final m in memberships) {
      // Pomijamy zablokowane oraz wygasłe (planer po dacie ważności) —
      // taka osoba nie widzi wesela, dopóki owner nie przywróci/przedłuży.
      if (!m.isEffectiveOn(today)) continue;
      final snap = await _col.doc(m.weddingId).get();
      final data = snap.data();
      if (data == null) continue; // wesele nie istnieje / zostało usunięte
      result.add(WeddingSummary.fromWeddingDoc(m.weddingId, data, m.role));
    }
    result.sort((a, b) {
      if (a.date == null && b.date == null) return a.name.compareTo(b.name);
      if (a.date == null) return 1;
      if (b.date == null) return -1;
      return a.date!.compareTo(b.date!);
    });
    return result;
  }

  /// Domyślna, „pusta" konfiguracja nowego wesela. Struktura zgodna z modelem
  /// [WeddingData] i serwisami sekcji — puste listy są bezpieczne (modele mają
  /// wbudowane wartości domyślne, np. kategorie wydatków i opcje menu).
  Map<String, dynamic> _defaultWeddingData({
    required String ownerId,
    required String name,
    required String persons,
    required String joinCode,
    String? date,
  }) {
    final coupleNames = _splitPersons(persons);
    return {
      'ownerId': ownerId,
      'joinCode': joinCode,
      'appConfig': {
        'eventName': name.trim().isEmpty ? 'Nasze Wesele' : name.trim(),
        'displayNames': persons.trim(),
        'ceremonyPlace': '',
        'receptionPlace': '',
        'menuOptions': <String>[],
        'expenseCategories': <String>[],
        'witnessCount': 2,
      },
      'weddingDate': (date != null && date.isNotEmpty) ? date : null,
      'weddingTime': '16:00',
      'budgetData': {
        'coupleNames': coupleNames,
        'total': 0,
      },
      'guests': <dynamic>[],
      'tables': <dynamic>[],
      'tasks': <dynamic>[],
      'vendors': <dynamic>[],
      'scheduleEvents': <dynamic>[],
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Rozdziela „Imię1 i Imię2" na dwie osoby budżetu. Bez separatora — druga
  /// osoba pozostaje pusta (uzupełni się w Ustawieniach).
  List<String> _splitPersons(String persons) {
    final p = persons.trim();
    if (p.isEmpty) return ['Osoba 1', 'Osoba 2'];
    final parts = p.split(RegExp(r'\s+i\s+', caseSensitive: false));
    final a = parts.isNotEmpty ? parts[0].trim() : '';
    final b = parts.length > 1 ? parts[1].trim() : '';
    return [
      a.isEmpty ? 'Osoba 1' : a,
      b.isEmpty ? 'Osoba 2' : b,
    ];
  }

  // ── Kod dołączenia ───────────────────────────────────────────────────────

  /// Alfabet kodu — bez znaków mylących (0/O, 1/I/L), same wielkie litery/cyfry.
  static const String _codeAlphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  /// Generuje 6-znakowy kod dołączenia.
  String _generateCode() {
    final rnd = Random.secure();
    return List.generate(
      6,
      (_) => _codeAlphabet[rnd.nextInt(_codeAlphabet.length)],
    ).join();
  }

  /// Generuje kod dołączenia i sprawdza unikalność przez publiczny indeks
  /// `weddingCodes` (odczyt dozwolony bez członkostwa).
  Future<String> _uniqueJoinCode() async {
    for (var i = 0; i < 6; i++) {
      final code = _generateCode();
      final taken =
          await _db.collection(weddingCodesCollection).doc(code).get();
      if (!taken.exists) return code;
    }
    // Skrajnie mało prawdopodobne — dokładamy przyrostek z czasu.
    return '${_generateCode()}${DateTime.now().millisecondsSinceEpoch % 100}';
  }

  /// Generuje unikalny kod zaproszenia roli (sprawdza indeks `roleInvites`).
  Future<String> _uniqueInviteCode() async {
    for (var i = 0; i < 6; i++) {
      final code = _generateCode();
      final taken =
          await _db.collection(roleInvitesCollection).doc(code).get();
      if (!taken.exists) return code;
    }
    return '${_generateCode()}${DateTime.now().millisecondsSinceEpoch % 100}';
  }

  /// Czy podane nazwisko/nazwa pasuje do danych Państwa Młodych (po normalizacji
  /// pojawia się w `displayNames` lub `eventName`).
  bool _surnameMatches(String input, String displayNames, String eventName) {
    final needle = _normalize(input);
    if (needle.length < 2) return false;
    final hay = '${_normalize(displayNames)} ${_normalize(eventName)}';
    return hay.contains(needle);
  }

  /// Normalizacja: małe litery, bez polskich znaków diakrytycznych, pojedyncze
  /// spacje. Pozwala na tolerancyjne porównanie nazwiska.
  String _normalize(String s) {
    var t = s.toLowerCase().trim();
    const map = {
      'ą': 'a', 'ć': 'c', 'ę': 'e', 'ł': 'l', 'ń': 'n',
      'ó': 'o', 'ś': 's', 'ż': 'z', 'ź': 'z',
    };
    map.forEach((k, v) => t = t.replaceAll(k, v));
    return t.replaceAll(RegExp(r'\s+'), ' ');
  }
}
