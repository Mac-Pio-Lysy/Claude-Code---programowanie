import 'package:cloud_firestore/cloud_firestore.dart';

/// Dostęp do PUBLICZNEJ przestrzeni gościa (`guestSpaces/{token}`) — używany
/// w trybie web gościa (bez logowania). Kluczem jest TOKEN z linku/QR; serwis
/// NIGDY nie posługuje się weddingId (token go nie ujawnia).
///
/// Odczyt: mirror z danymi dla gości (event, data, widoczność, harmonogram).
/// Zapis: interakcje gości (księga gości, RSVP, propozycje muzyki, wyniki gier,
/// zdjęcia) do podkolekcji `guestSpaces/{token}/{coll}` — reguły dopuszczają
/// tworzenie bez logowania, ale wyłącznie pod tym tokenem (= tym weselem).
class GuestSpaceService {
  GuestSpaceService({required this.token, FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final String token;
  final FirebaseFirestore _db;

  /// Nazwa kolekcji publicznych stref gości.
  static const String collectionName = 'guestSpaces';

  DocumentReference<Map<String, dynamic>> get _space =>
      _db.collection(collectionName).doc(token);

  /// Strumień mirrora (dane dla gości). `null`, gdy token nieprawidłowy.
  Stream<Map<String, dynamic>?> watchSpace() =>
      _space.snapshots().map((s) => s.data());

  /// Jednorazowy odczyt mirrora.
  Future<Map<String, dynamic>?> readSpace() async => (await _space.get()).data();

  CollectionReference<Map<String, dynamic>> _coll(String name) =>
      _space.collection(name);

  /// Uniwersalny strumień wpisów kolekcji (najnowsze pierwsze).
  Stream<List<Map<String, dynamic>>> _watch(String coll) => _coll(coll)
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  int get _now => DateTime.now().millisecondsSinceEpoch;

  // ── Interakcje gości (kształt payloadu ZGODNY z walidacją w regułach) ──────

  /// Wpis do księgi gości (imię + treść). PUBLICZNY odczyt.
  ///
  /// [authorUid] (etap 4, opcjonalny): uid anonimowej sesji gościa
  /// (`GuestIdentity.uid`) — do powiązania wpisu z tożsamością z paczki,
  /// wyłącznie do wglądu organizatora. Gdy pominięty, wpis zachowuje się
  /// jak dotychczas (bez stempla).
  Future<void> addGuestbookEntry({
    required String name,
    required String message,
    String? authorUid,
  }) =>
      _coll('guestbook').add({
        'name': _cap(name, 80),
        'message': _cap(message, 1000),
        'timestamp': _now,
        'authorUid': ?authorUid,
      });

  Stream<List<Map<String, dynamic>>> watchGuestbook() => _watch('guestbook');

  /// Rada dla Pary Młodej. PUBLICZNY odczyt.
  ///
  /// [authorUid] — patrz komentarz przy [addGuestbookEntry].
  Future<void> addAdvice({
    required String name,
    required String message,
    String? authorUid,
  }) =>
      _coll('advice').add({
        'name': _cap(name, 80),
        'message': _cap(message, 1000),
        'timestamp': _now,
        'authorUid': ?authorUid,
      });

  Stream<List<Map<String, dynamic>>> watchAdvice() => _watch('advice');

  /// Wpis na mapę gości (miasto) — JEDEN NA GOŚCIA. PUBLICZNY odczyt.
  ///
  /// Identyfikatorem dokumentu jest [uid] gościa, więc ponowne wysłanie
  /// nadpisuje własny wpis zamiast tworzyć kolejny.
  Future<void> saveGuestMapEntry({
    required String uid,
    required String name,
    required String city,
    String greeting = '',
  }) =>
      _coll('guestMap').doc(uid).set({
        'name': _cap(name, 80),
        'city': _cap(city, 80),
        'greeting': _cap(greeting, 300),
        'timestamp': _now,
      });

  Stream<List<Map<String, dynamic>>> watchGuestMap() => _watch('guestMap');

  /// Wiadomość do kapsuły czasu (dla Pary Młodej). Odczyt TYLKO organizator.
  Future<void> addTimeCapsule(
          {required String name, required String message}) =>
      _coll('timeCapsule').add({
        'name': _cap(name, 80),
        'message': _cap(message, 2000),
        'timestamp': _now,
      });

  /// Potwierdzenie obecności (RSVP) — JEDEN NA GOŚCIA.
  /// Odczyt TYLKO organizator oraz sam autor (od etapu C reguł).
  ///
  /// Identyfikatorem dokumentu jest [uid] gościa: pierwszy zapis tworzy wpis,
  /// każdy kolejny go nadpisuje. Dzięki temu organizator nie dostaje kilku
  /// sprzecznych potwierdzeń od tej samej osoby, a gość może poprawić swoje.
  Future<void> saveRsvp({
    required String uid,
    required String name,
    required bool attending,
    int companions = 0,
    String diet = '',
    String note = '',
  }) =>
      _coll('rsvp').doc(uid).set({
        'name': _cap(name, 80),
        'attending': attending,
        'companions': companions.clamp(0, 20),
        'diet': _cap(diet, 200),
        'note': _cap(note, 500),
        'timestamp': _now,
      });

  /// Odczyt WŁASNEGO wpisu gościa (do wypełnienia formularza przy edycji).
  ///
  /// Zwraca `null`, gdy wpisu nie ma **albo gdy reguły jeszcze go nie
  /// udostępniają** — do etapu C `rsvp` ma odczyt wyłącznie dla organizatora,
  /// więc gość dostanie tu odmowę. Celowo połykamy błąd: brak podglądu własnego
  /// wpisu nie jest awarią, formularz po prostu startuje pusty.
  Future<Map<String, dynamic>?> readOwn(String coll, String uid) async {
    try {
      final snap = await _coll(coll).doc(uid).get();
      return snap.data();
    } catch (_) {
      return null;
    }
  }

  // ── 5b-part-2: galeria, muzyka, gry ───────────────────────────────────────

  /// Zdjęcie gościa do wspólnej galerii. PUBLICZNY odczyt (goście widzą się
  /// nawzajem). [photoUrl] MUSI pochodzić z naszego Cloudinary — reguły
  /// odrzucą adres z innego hosta.
  ///
  /// [authorUid] — patrz komentarz przy [addGuestbookEntry].
  Future<void> addGalleryPhoto({
    required String name,
    required String photoUrl,
    required String photoPublicId,
    String caption = '',
    String? authorUid,
  }) =>
      _coll('gallery').add({
        'name': _cap(name, 80),
        'caption': _cap(caption, 200),
        'photoUrl': photoUrl,
        'photoPublicId': _cap(photoPublicId, 200),
        'timestamp': _now,
        'authorUid': ?authorUid,
      });

  Stream<List<Map<String, dynamic>>> watchGallery() => _watch('gallery');

  /// Propozycja utworu. Odczyt TYLKO organizator (bez publicznego rankingu).
  Future<void> addMusicProposal({
    required String name,
    required String title,
    String artist = '',
    String cover = '',
  }) =>
      _coll('musicProposals').add({
        'name': _cap(name, 80),
        'title': _cap(title, 200),
        'artist': _cap(artist, 200),
        'cover': _cap(cover, 500),
        'timestamp': _now,
      });

  /// Zdjęcie do foto-wyzwania — JEDNO NA WYZWANIE NA GOŚCIA.
  /// PUBLICZNY odczyt (wspólna ściana zdjęć).
  ///
  /// Identyfikator dokumentu to `{uid}__{challengeId}`, więc kolejne zdjęcie do
  /// tego samego wyzwania zastępuje poprzednie zamiast się dokładać. Format ID
  /// musi być zgodny z regułą `isSelfChallenge`.
  Future<void> savePhotoChallenge({
    required String uid,
    required String name,
    required int challengeId,
    required String photoUrl,
    required String photoPublicId,
  }) =>
      _coll('photoChallenges').doc(photoChallengeId(uid, challengeId)).set({
        'name': _cap(name, 80),
        'challengeId': challengeId,
        'photoUrl': photoUrl,
        'photoPublicId': _cap(photoPublicId, 200),
        'timestamp': _now,
        'authorUid': uid,
      });

  /// Identyfikator zgłoszenia foto-wyzwania. Jedno źródło prawdy dla klienta
  /// i dla reguł — zmiana formatu tutaj wymaga zmiany w `firestore.rules`.
  static String photoChallengeId(String uid, int challengeId) =>
      '${uid}__$challengeId';

  Stream<List<Map<String, dynamic>>> watchPhotoChallenges() =>
      _watch('photoChallenges');

  // ── Konkursy fotograficzne z głosowaniem (etap 2: zgłoszenia) ────────────

  /// Zgłasza zdjęcie do podkategorii konkursu — ATOMOWO (WriteBatch): jeden
  /// dokument w `contestSubmissions` (walidacja `vContestSubmission`) + jego
  /// kopia w `gallery` (podwójna widoczność, walidacja `vGallery`, bez zmian
  /// w tamtej regule). Batch = oba zapisy się udają albo żaden.
  ///
  /// `contestId`/`subcategoryId` w Firestore są STRINGAMI (tak wymaga
  /// `_s(...)` w regule) — konwersja z `int` (spójnego z [PhotoContest.id]/
  /// [ContestSubcategory.id]) dzieje się tu, w jednym miejscu.
  ///
  /// [authorUid] jest WYMAGANE (nie opcjonalne jak przy galerii/księdze) —
  /// reguła `vContestSubmission` je wymusza, bo od niego zależy blokada
  /// głosu na własne zdjęcie w etapie 3.
  Future<void> submitContestPhoto({
    required int contestId,
    required int subcategoryId,
    required String name,
    required String photoUrl,
    required String photoPublicId,
    required String authorUid,
  }) async {
    final batch = _db.batch();
    batch.set(_coll('contestSubmissions').doc(), {
      'contestId': '$contestId',
      'subcategoryId': '$subcategoryId',
      'name': _cap(name, 80),
      'photoUrl': photoUrl,
      'photoPublicId': _cap(photoPublicId, 200),
      'authorUid': authorUid,
      'timestamp': _now,
    });
    batch.set(_coll('gallery').doc(), {
      'name': _cap(name, 80),
      'caption': '',
      'photoUrl': photoUrl,
      'photoPublicId': _cap(photoPublicId, 200),
      'timestamp': _now,
      'authorUid': authorUid,
    });
    await batch.commit();
  }

  /// Zgłoszenia JEDNEJ podkategorii jednego konkursu — publiczne (goście
  /// oglądają się nawzajem, tak jak galeria/foto-wyzwania).
  ///
  /// Bez `orderBy` w zapytaniu (dwa równości + sortowanie po trzecim polu
  /// wymagałoby dodatkowego indeksu złożonego) — sortowanie po stronie
  /// klienta, zbiór jest mały (zgłoszenia jednej podkategorii).
  Stream<List<Map<String, dynamic>>> watchContestSubmissions(
          int contestId, int subcategoryId) =>
      _coll('contestSubmissions')
          .where('contestId', isEqualTo: '$contestId')
          .where('subcategoryId', isEqualTo: '$subcategoryId')
          .snapshots()
          .map((snap) {
        final list = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
        list.sort((a, b) => (b['timestamp'] as int? ?? 0)
            .compareTo(a['timestamp'] as int? ?? 0));
        return list;
      });

  /// Identyfikator dokumentu głosu — jedno źródło prawdy dla klienta i dla
  /// reguł (`isSelfContestVote`), tak jak [photoChallengeId].
  static String contestVoteId(String uid, int contestId, int subcategoryId) =>
      '${uid}__${contestId}__$subcategoryId';

  /// Zapisuje KOMPLETNY zestaw 3-2-1 (nadpisuje cały dokument — reguła
  /// `vContestVote` waliduje pełny kształt, więc częściowy `merge: true`
  /// nie miałby sensu: musi zawsze przejść wszystkie 3 pola naraz).
  /// Pierwszy zapis = `create`, kolejne (zmiana głosu) = `update` tego
  /// samego dokumentu — reguła dopuszcza oba przez `isSelfContestVote`.
  Future<void> saveContestVote({
    required String uid,
    required int contestId,
    required int subcategoryId,
    required String first,
    required String second,
    required String third,
  }) =>
      _coll('contestVotes')
          .doc(contestVoteId(uid, contestId, subcategoryId))
          .set({
        'contestId': '$contestId',
        'subcategoryId': '$subcategoryId',
        'first': first,
        'second': second,
        'third': third,
        'timestamp': _now,
      });

  /// Własny głos w danej podkategorii (do odtworzenia obwolut po powrocie
  /// na stronę) — `get` na pojedynczy dokument, dozwolony regułą
  /// `isSelfContestVote`. `null`, gdy gość jeszcze nie głosował.
  Stream<Map<String, dynamic>?> watchOwnContestVote(
          String uid, int contestId, int subcategoryId) =>
      _coll('contestVotes')
          .doc(contestVoteId(uid, contestId, subcategoryId))
          .snapshots()
          .map((s) => s.data());

  /// WSZYSTKIE głosy jednej podkategorii — WYŁĄCZNIE organizator (reguła:
  /// `list: orgOf(token)`). Gość nie może wykonać tego zapytania (stąd
  /// „punkty ukryte" — patrz `computeContestRanking`, etap 4/5/6).
  Stream<List<Map<String, dynamic>>> watchContestVotes(
          int contestId, int subcategoryId) =>
      _coll('contestVotes')
          .where('contestId', isEqualTo: '$contestId')
          .where('subcategoryId', isEqualTo: '$subcategoryId')
          .snapshots()
          .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  /// Wynik gry (quiz / prawda-fałsz / zgadnij zdjęcie) — JEDEN NA GOŚCIA NA GRĘ.
  /// Odczyt: organizator oraz sam autor (własny wynik).
  ///
  /// Identyfikatorem dokumentu jest [uid], więc powtórka nadpisuje poprzedni
  /// wynik. Dzięki temu organizator ma jedną pozycję na osobę, a nie listę prób.
  /// [coll] musi być jedną z: `quizResults`, `trueFalseResults`,
  /// `photoGuessResults` — inne nazwy odrzucą reguły.
  Future<void> saveGameResult({
    required String coll,
    required String uid,
    required String name,
    required int score,
    required int total,
    required Map<String, dynamic> answers,
  }) =>
      _coll(coll).doc(uid).set({
        'name': _cap(name, 80),
        'score': score,
        'total': total,
        'answers': answers,
        'timestamp': _now,
      });

  /// Zgłoszenie bingo — JEDNO NA GOŚCIA. Odczyt: organizator i autor.
  Future<void> saveBingoResult({
    required String uid,
    required String name,
    required int marked,
    required int total,
  }) =>
      _coll('bingoResults').doc(uid).set({
        'name': _cap(name, 80),
        'marked': marked,
        'total': total,
        'timestamp': _now,
      });

  // ── Odczyt dla ORGANIZATORA (moderacja; token = własny guestToken) ─────────

  Stream<List<Map<String, dynamic>>> watchCollection(String coll) =>
      _watch(coll);

  /// Tożsamości z paczek (etap 5, „do przypisania") bez wskazanego gościa.
  ///
  /// NIE korzysta z [_watch] — te dokumenty mają `claimedAt`, nie `timestamp`,
  /// więc `orderBy('timestamp')` po cichu pominąłby je wszystkie (Firestore
  /// wyklucza z wyniku dokumenty bez pola użytego w `orderBy`).
  Stream<List<Map<String, dynamic>>> watchUnassignedIdentities() => _coll(
          'identities')
      .where('guestId', isNull: true)
      .snapshots()
      .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  /// WSZYSTKIE tożsamości z paczek tego wesela (etap 4, „kto co dodał").
  ///
  /// Bez `orderBy` z tego samego powodu co [watchUnassignedIdentities] —
  /// dokumenty mają `claimedAt`, nie `timestamp`. Zbiór jest mały (rząd
  /// wielkości liczby paczek, nie liczby wpisów), więc pobranie całości
  /// naraz jest tanie.
  Stream<List<Map<String, dynamic>>> watchAllIdentities() => _coll(
          'identities')
      .snapshots()
      .map((snap) => snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());

  /// Usuwa wpis (moderacja organizatora).
  Future<void> deleteEntry(String coll, String id) =>
      _coll(coll).doc(id).delete();

  /// Dopisuje pola do wpisu (moderacja organizatora) — np. status propozycji
  /// muzycznej. Reguły dopuszczają `update` wyłącznie dla organizatora, więc
  /// gość tą drogą nic nie zmieni.
  Future<void> updateEntry(
          String coll, String id, Map<String, dynamic> data) =>
      _coll(coll).doc(id).set(data, SetOptions(merge: true));

  /// Przycina i czyści tekst do limitu (spójne z walidacją reguł).
  String _cap(String s, int max) {
    final t = s.trim();
    return t.length <= max ? t : t.substring(0, max);
  }
}
