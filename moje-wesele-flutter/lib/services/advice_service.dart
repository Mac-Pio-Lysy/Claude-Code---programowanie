import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/advice.dart';

/// Dostęp do rad dla Pary Młodej — osobna kolekcja `advices` w Firestore
/// (publiczny zapis ze strony `rady.html`, jak `guestbook`/`musicProposals`).
///
/// NIE rusza dokumentu `weddingPlanner/main`. Usuwanie tylko dla zalogowanych
/// organizatorów (reguły Firestore).
class AdviceService {
  AdviceService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const String collectionName = 'advices';

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(collectionName);

  /// Strumień wszystkich rad (najnowsze pierwsze).
  Stream<List<Advice>> watchAdvices() => _col
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(Advice.fromDoc).toList());

  /// Usuwa radę (np. nieodpowiednią). Wymaga zalogowanego organizatora.
  Future<void> deleteAdvice(String id) => _col.doc(id).delete();
}
