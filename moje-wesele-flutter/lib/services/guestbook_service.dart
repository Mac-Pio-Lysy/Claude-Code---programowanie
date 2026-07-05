import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/guestbook_entry.dart';

/// Dostęp do księgi gości — osobnej kolekcji `guestbook` w Firestore
/// (publiczny zapis ze strony `ksiega.html`, jak `musicProposals`).
///
/// Wpisy NIE są w dokumencie `weddingPlanner/main`, więc nie ruszają danych
/// planera — to niezależna kolekcja. Usuwanie dozwolone tylko dla zalogowanych
/// organizatorów (reguły Firestore).
class GuestbookService {
  GuestbookService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const String collectionName = 'guestbook';

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(collectionName);

  /// Strumień wszystkich wpisów (najnowsze pierwsze).
  Stream<List<GuestbookEntry>> watchEntries() => _col
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(GuestbookEntry.fromDoc).toList());

  /// Usuwa wpis (np. nieodpowiedni). Wymaga zalogowanego organizatora.
  Future<void> deleteEntry(String id) => _col.doc(id).delete();
}
