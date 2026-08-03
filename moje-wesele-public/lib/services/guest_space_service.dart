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

  // ── Odczyt dla ORGANIZATORA (moderacja; token = własny guestToken) ─────────

  Stream<List<Map<String, dynamic>>> watchCollection(String coll) =>
      _watch(coll);

  /// Usuwa wpis (moderacja organizatora).
  Future<void> deleteEntry(String coll, String id) =>
      _coll(coll).doc(id).delete();

  /// Przycina i czyści tekst do limitu (spójne z walidacją reguł).
  String _cap(String s, int max) {
    final t = s.trim();
    return t.length <= max ? t : t.substring(0, max);
  }
}
