import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/guest_visibility.dart';
import '../models/wedding_summary.dart';
import '../utils/warsaw_time.dart';
import 'membership_service.dart';
import 'user_service.dart';

/// Wynik przygotowania strefy gości dla jednego wesela (D1, etap 2).
class GuestViewSyncResult {
  const GuestViewSyncResult({
    required this.weddingId,
    required this.name,
    required this.ok,
    this.error,
  });

  final String weddingId;

  /// Czytelna nazwa do raportu.
  final String name;

  /// Czy `guestView/main` istnieje na serwerze i wskazuje właściwy token.
  final bool ok;

  /// Powód niepowodzenia (null, gdy [ok]).
  final String? error;
}

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

  /// Mapowanie token gościa → weddingId. Klient NIE czyta (token nie ujawnia
  /// weddingId); reguły używają go wewnętrznie przez `get()`.
  static const String guestTokensCollection = 'guestTokens';

  /// Publiczna „przestrzeń gościa" (mirror tylko z danymi dla gości), kluczem
  /// jest TOKEN: `guestSpaces/{token}` → { eventName, displayNames, data,
  /// guestVisibility, scheduleEvents }. NIE zawiera budżetu/listy gości itp.
  static const String guestSpacesCollection = 'guestSpaces';

  /// Podkolekcja z danymi dla ZALOGOWANEGO gościa (D1):
  /// `weddings/{id}/guestView/main` → `{ guestToken, eventName, displayNames,
  /// weddingDate }`. Odczyt dla każdego aktywnego członka, zapis dla
  /// organizatora. Docelowo zastępuje gościowi odczyt całego dokumentu wesela.
  static const String guestViewCollection = 'guestView';
  static const String guestViewDoc = 'main';

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
    final guestToken = _generateGuestToken();

    await ref.set(_defaultWeddingData(
      ownerId: userId,
      name: name,
      persons: persons,
      date: date,
      joinCode: joinCode,
      guestToken: guestToken,
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

    // Token + publiczny mirror dla gości (best-effort — wymaga reguł strefy
    // publicznej; przy ich braku nie blokuje zakładania wesela).
    await _syncGuestSpaceSafe(weddingId);

    return weddingId;
  }

  /// Zwraca token gościa; jeśli go nie ma (starsze wesele) — generuje, zapisuje
  /// przy weddings/{id} i synchronizuje mapowanie oraz publiczny mirror.
  Future<String> ensureGuestToken(String weddingId) async {
    final ref = _col.doc(weddingId);
    final snap = await ref.get();
    final data = snap.data() ?? const <String, dynamic>{};
    var token = (data['guestToken'] as String?)?.trim();
    if (token == null || token.isEmpty) {
      token = _generateGuestToken();
      await ref.set({'guestToken': token}, SetOptions(merge: true));
    }
    await _syncGuestSpace(weddingId, token, data);
    return token;
  }

  /// Synchronizuje publiczny mirror gościa (best-effort; łapie błędy uprawnień,
  /// gdy reguły strefy publicznej nie są jeszcze wdrożone).
  Future<void> _syncGuestSpaceSafe(String weddingId) async {
    try {
      final snap = await _col.doc(weddingId).get();
      final data = snap.data();
      final token = (data?['guestToken'] as String?)?.trim();
      if (data == null || token == null || token.isEmpty) return;
      await _syncGuestSpace(weddingId, token, data);
    } catch (_) {
      // Reguły strefy publicznej jeszcze niewdrożone — pominąć bez błędu.
    }
  }

  /// Zapisuje mapowanie token→weddingId oraz publiczny mirror (tylko dane dla
  /// gości). Wołane przy tworzeniu wesela, zapisie konfiguracji i widoczności.
  Future<void> _syncGuestSpace(
      String weddingId, String token, Map<String, dynamic> data) async {
    // Mapowanie (potrzebne regułom do autoryzacji zapisu mirrora/moderacji).
    await _db
        .collection(guestTokensCollection)
        .doc(token)
        .set({'weddingId': weddingId}, SetOptions(merge: true));
    // Publiczny mirror — WYŁĄCZNIE dane dla gości (bez budżetu/gości/dostawców).
    await _db
        .collection(guestSpacesCollection)
        .doc(token)
        .set(_guestMirror(data), SetOptions(merge: true));

    // D1 etap 1 — dokument dla ZALOGOWANEGO gościa. Na tym etapie NIKT go
    // jeszcze nie czyta; powstaje po to, żeby przy zacieśnianiu reguły odczytu
    // wesela (etap 5) istniał już dla każdego wesela.
    //
    // Własny try/catch, a zapis JAKO OSTATNI: dopóki reguła dla tej podkolekcji
    // nie jest wdrożona, ten zapis dostanie permission-denied — i nie może
    // przewrócić działającej synchronizacji `guestSpaces` powyżej. Dzięki temu
    // kolejność wdrożenia (kod przed regułami czy odwrotnie) jest bez znaczenia.
    try {
      await _db
          .collection(collectionName)
          .doc(weddingId)
          .collection(guestViewCollection)
          .doc(guestViewDoc)
          .set(_guestViewDoc(token, data), SetOptions(merge: true));
    } catch (_) {
      // Reguła jeszcze niewdrożona — pomijamy bez błędu.
    }
  }

  /// Minimalny zestaw danych dla ZALOGOWANEGO gościa (D1).
  ///
  /// Zawiera wyłącznie wskaźnik na publiczny mirror (`guestToken`) oraz tyle,
  /// ile trzeba, by pokazać wesele na liście „Twoje wesela" BEZ czytania
  /// dokumentu wesela. Całą treść (harmonogram, gry, widoczność) gość i tak
  /// pobierze z `guestSpaces/{token}` — nie ma powodu jej tu duplikować.
  ///
  /// ⚠️ Nie wolno tu wstawiać niczego wrażliwego: ten dokument czyta KAŻDY
  /// aktywny członek wesela, łącznie z rolą `guest`.
  Map<String, dynamic> _guestViewDoc(String token, Map<String, dynamic> data) {
    final cfg = data['appConfig'] is Map
        ? Map<String, dynamic>.from(data['appConfig'] as Map)
        : const <String, dynamic>{};
    return {
      'guestToken': token,
      'eventName': (cfg['eventName'] as String?) ?? '',
      'displayNames': (cfg['displayNames'] as String?) ?? '',
      'weddingDate': data['weddingDate'],
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Przygotowuje strefę gości we WSZYSTKICH weselach użytkownika [userId],
  /// w których ma pełny dostęp (owner / planer / współorganizator).
  ///
  /// Dla każdego wesela: dogenerowuje brakujący `guestToken`, zapisuje mapowanie
  /// tokenu, publiczny mirror i `guestView/main`, a następnie **odczytuje
  /// `guestView/main` z SERWERA i potwierdza**, że dokument istnieje i wskazuje
  /// na ten sam token.
  ///
  /// Weryfikacja zwrotna nie jest ozdobnikiem: zapis `guestView` w
  /// [_syncGuestSpace] celowo połyka błąd uprawnień (żeby nie przewrócić
  /// synchronizacji mirrora), a Firestore stosuje zapisy najpierw lokalnie —
  /// więc bez odczytu z serwera „udany" zapis mógłby w rzeczywistości zostać
  /// odrzucony przez reguły i nikt by się o tym nie dowiedział.
  ///
  /// Operacja jest idempotentna — można ją uruchamiać wielokrotnie.
  ///
  /// ⚠️ Obejmuje wyłącznie wesela TEGO użytkownika. Wesela, w których jest
  /// tylko gościem (albo cudze), musi przygotować ich własny organizator.
  Future<List<GuestViewSyncResult>> ensureGuestViewForUser(String userId) async {
    final memberships = await _memberships.forUser(userId);
    final today = warsawToday();
    final results = <GuestViewSyncResult>[];

    for (final m in memberships) {
      // Pomijamy zablokowanych/wygasłych oraz role bez prawa zapisu.
      if (!m.isEffectiveOn(today)) continue;
      if (!const ['owner', 'planner', 'collaborator'].contains(m.role)) continue;

      final snap = await _col.doc(m.weddingId).get();
      final data = snap.data();
      if (data == null) {
        results.add(GuestViewSyncResult(
          weddingId: m.weddingId,
          name: 'Wesele ${m.weddingId}',
          ok: false,
          error: 'Dokument wesela nie istnieje',
        ));
        continue;
      }

      final label = _weddingLabel(data, m.weddingId);
      try {
        // Dogenerowuje token (gdy brak) i synchronizuje mapowanie + mirror
        // + guestView.
        final token = await ensureGuestToken(m.weddingId);

        // Odczyt Z SERWERA — pomija lokalny bufor, więc widzimy stan faktyczny.
        final check = await _col
            .doc(m.weddingId)
            .collection(guestViewCollection)
            .doc(guestViewDoc)
            .get(const GetOptions(source: Source.server));
        final gv = check.data();

        if (gv == null) {
          results.add(GuestViewSyncResult(
            weddingId: m.weddingId,
            name: label,
            ok: false,
            error: 'guestView/main nie powstał — sprawdź reguły',
          ));
        } else if ((gv['guestToken'] as String?)?.trim() != token) {
          results.add(GuestViewSyncResult(
            weddingId: m.weddingId,
            name: label,
            ok: false,
            error: 'Token w guestView nie zgadza się z weselem',
          ));
        } else {
          results.add(GuestViewSyncResult(
              weddingId: m.weddingId, name: label, ok: true));
        }
      } catch (e) {
        results.add(GuestViewSyncResult(
          weddingId: m.weddingId,
          name: label,
          ok: false,
          error: '$e',
        ));
      }
    }
    return results;
  }

  /// Czytelna nazwa wesela do raportu (nazwa → osoby → identyfikator).
  String _weddingLabel(Map<String, dynamic> data, String weddingId) {
    final cfg = data['appConfig'];
    final name = (cfg is Map ? cfg['eventName'] as String? : null)?.trim() ?? '';
    if (name.isNotEmpty) return name;
    final persons =
        (cfg is Map ? cfg['displayNames'] as String? : null)?.trim() ?? '';
    if (persons.isNotEmpty) return persons;
    return 'Wesele $weddingId';
  }

  /// Odświeża publiczny mirror gościa dla [weddingId] (best-effort — nie rzuca).
  ///
  /// Wołane przez [FirestoreService.setAndSync] po każdej zmianie treści, która
  /// trafia na stronę gości (harmonogram, pytania gier), żeby gość nie oglądał
  /// wersji z ostatniego zapisu konfiguracji.
  Future<void> syncGuestMirrorSafe(String weddingId) =>
      _syncGuestSpaceSafe(weddingId);

  /// Buduje bezpieczny dla gości „mirror" z dokumentu wesela.
  ///
  /// ZASADA: trafia tu WYŁĄCZNIE to, co gość ma prawo zobaczyć. Nie ma budżetu,
  /// listy gości, dostawców, planu sali ani zadań. Treści gier dokładane są
  /// tylko dla sekcji WŁĄCZONYCH w widoczności — wyłączona gra nie leży w
  /// publicznym dokumencie „na wszelki wypadek".
  ///
  /// ⚠️ ŚWIADOMY KOMPROMIS: pytania quizu, „prawda/fałsz" i „zgadnij zdjęcie"
  /// jadą razem z poprawnymi odpowiedziami (`correctIndex`, `isTrue`), bo wynik
  /// liczy się na urządzeniu gościa. Kto otworzy narzędzia deweloperskie, może
  /// je podejrzeć. To zabawa weselna, nie egzamin — usunięcie tego wymagałoby
  /// liczenia punktów w Cloud Function.
  Map<String, dynamic> _guestMirror(Map<String, dynamic> data) {
    final cfg = data['appConfig'] is Map
        ? Map<String, dynamic>.from(data['appConfig'] as Map)
        : const <String, dynamic>{};
    final vis = GuestVisibility.fromRaw(data);
    // Treść sekcji jedzie do mirrora tylko, gdy sekcja jest włączona. Daty
    // OD/DO celowo NIE są tu sprawdzane — mirror odświeża się przy zapisie, a
    // nie codziennie o północy; gdyby zależał od dat, sekcja włączająca się
    // „jutro" nie miałaby treści do czasu kolejnego zapisu. Zakres dat i tak
    // egzekwuje strona gościa.
    List<dynamic> ifOn(String key, dynamic value) =>
        vis.sectionFor(key).enabled && value is List ? value : const <dynamic>[];

    return {
      'eventName': (cfg['eventName'] as String?) ?? '',
      'displayNames': (cfg['displayNames'] as String?) ?? '',
      'ceremonyPlace': (cfg['ceremonyPlace'] as String?) ?? '',
      'receptionPlace': (cfg['receptionPlace'] as String?) ?? '',
      'weddingDate': data['weddingDate'],
      'weddingTime': (data['weddingTime'] as String?) ?? '16:00',
      'guestVisibility': data['guestVisibility'] ?? const <String, dynamic>{},
      'scheduleEvents': ifOn('schedule', data['scheduleEvents']),
      // ── Treści gier (5b-part-2) ──
      'quizActive': data['quizActive'] == true,
      'quizQuestions': ifOn('quiz', data['quizQuestions']),
      'tfActive': data['tfActive'] == true,
      'tfStatements': ifOn('trueFalse', data['tfStatements']),
      'photoGuessActive': data['photoGuessActive'] == true,
      'photoQuestions': ifOn('photoGuess', data['photoQuestions']),
      'photoChallengesActive': data['photoChallengesActive'] == true,
      'photoChallengeTasks': ifOn('photoChallenge', data['photoChallengeTasks']),
      'bingoFields': ifOn('bingo', data['bingoFields']),
      'bingoCenterMode': (data['bingoCenterMode'] as String?) ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    };
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
    required String guestToken,
    String? date,
  }) {
    final coupleNames = _splitPersons(persons);
    return {
      'ownerId': ownerId,
      'joinCode': joinCode,
      'guestToken': guestToken,
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

  /// Alfabet URL-safe dla długiego tokenu gościa.
  static const String _tokenAlphabet =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

  /// Generuje długi (32-znakowy), kryptograficznie losowy token gościa.
  /// Oddzielony od weddingId — nie ujawnia wewnętrznego ID.
  String _generateGuestToken() {
    final rnd = Random.secure();
    return List.generate(
      32,
      (_) => _tokenAlphabet[rnd.nextInt(_tokenAlphabet.length)],
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
