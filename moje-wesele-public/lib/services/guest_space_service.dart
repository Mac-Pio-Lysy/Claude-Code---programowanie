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

  DocumentReference<Map<String, dynamic>> get _space =>
      _db.collection('guestSpaces').doc(token);

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
  Future<void> addGuestbookEntry(
          {required String name, required String message}) =>
      _coll('guestbook').add({
        'name': _cap(name, 80),
        'message': _cap(message, 1000),
        'timestamp': _now,
      });

  Stream<List<Map<String, dynamic>>> watchGuestbook() => _watch('guestbook');

  /// Rada dla Pary Młodej. PUBLICZNY odczyt.
  Future<void> addAdvice({required String name, required String message}) =>
      _coll('advice').add({
        'name': _cap(name, 80),
        'message': _cap(message, 1000),
        'timestamp': _now,
      });

  Stream<List<Map<String, dynamic>>> watchAdvice() => _watch('advice');

  /// Wpis na mapę gości (miasto). PUBLICZNY odczyt.
  Future<void> addGuestMapEntry({
    required String name,
    required String city,
    String greeting = '',
  }) =>
      _coll('guestMap').add({
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

  /// Potwierdzenie obecności (RSVP). Odczyt TYLKO organizator (nie inni goście).
  Future<void> addRsvp({
    required String name,
    required bool attending,
    int companions = 0,
    String diet = '',
    String note = '',
  }) =>
      _coll('rsvp').add({
        'name': _cap(name, 80),
        'attending': attending,
        'companions': companions.clamp(0, 20),
        'diet': _cap(diet, 200),
        'note': _cap(note, 500),
        'timestamp': _now,
      });

  // ── 5b-part-2: galeria, muzyka, gry ───────────────────────────────────────

  /// Zdjęcie gościa do wspólnej galerii. PUBLICZNY odczyt (goście widzą się
  /// nawzajem). [photoUrl] MUSI pochodzić z naszego Cloudinary — reguły
  /// odrzucą adres z innego hosta.
  Future<void> addGalleryPhoto({
    required String name,
    required String photoUrl,
    required String photoPublicId,
    String caption = '',
  }) =>
      _coll('gallery').add({
        'name': _cap(name, 80),
        'caption': _cap(caption, 200),
        'photoUrl': photoUrl,
        'photoPublicId': _cap(photoPublicId, 200),
        'timestamp': _now,
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

  /// Zdjęcie do foto-wyzwania. PUBLICZNY odczyt (wspólna ściana zdjęć).
  Future<void> addPhotoChallenge({
    required String name,
    required int challengeId,
    required String photoUrl,
    required String photoPublicId,
  }) =>
      _coll('photoChallenges').add({
        'name': _cap(name, 80),
        'challengeId': challengeId,
        'photoUrl': photoUrl,
        'photoPublicId': _cap(photoPublicId, 200),
        'timestamp': _now,
      });

  Stream<List<Map<String, dynamic>>> watchPhotoChallenges() =>
      _watch('photoChallenges');

  /// Wynik gry (quiz / prawda-fałsz / zgadnij zdjęcie). Odczyt TYLKO organizator.
  /// [coll] musi być jedną z: `quizResults`, `trueFalseResults`,
  /// `photoGuessResults` — inne nazwy odrzucą reguły.
  Future<void> addGameResult({
    required String coll,
    required String name,
    required int score,
    required int total,
    required Map<String, dynamic> answers,
  }) =>
      _coll(coll).add({
        'name': _cap(name, 80),
        'score': score,
        'total': total,
        'answers': answers,
        'timestamp': _now,
      });

  /// Zgłoszenie bingo (ile pól skreślonych z ilu). Odczyt TYLKO organizator.
  Future<void> addBingoResult({
    required String name,
    required int marked,
    required int total,
  }) =>
      _coll('bingoResults').add({
        'name': _cap(name, 80),
        'marked': marked,
        'total': total,
        'timestamp': _now,
      });

  // ── Odczyt dla ORGANIZATORA (moderacja; token = własny guestToken) ─────────

  Stream<List<Map<String, dynamic>>> watchCollection(String coll) =>
      _watch(coll);

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
