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

  // ── Interakcje gości ──────────────────────────────────────────────────────

  /// Wpis do księgi gości (imię + treść).
  Future<void> addGuestbookEntry({
    required String name,
    required String message,
  }) =>
      _coll('guestbook').add({
        'name': name.trim(),
        'message': message.trim(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

  /// Strumień wpisów księgi gości (najnowsze pierwsze).
  Stream<List<Map<String, dynamic>>> watchGuestbook() => _coll('guestbook')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => {'id': d.id, ...d.data()}).toList());
}
