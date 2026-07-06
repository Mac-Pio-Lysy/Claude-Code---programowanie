import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/time_capsule_message.dart';

/// Dostęp do kapsuły czasu — osobna kolekcja `timeCapsule` w Firestore
/// (publiczny zapis ze strony `kapsula.html`, jak `guestbook`).
///
/// NIE rusza dokumentu `weddingPlanner/main`. Usuwanie tylko dla zalogowanych
/// organizatorów (reguły Firestore). „Pieczętowanie" (ukrywanie treści do daty
/// otwarcia) liczone jest po stronie aplikacji z pola `openDate`.
class TimeCapsuleService {
  TimeCapsuleService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const String collectionName = 'timeCapsule';

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(collectionName);

  /// Strumień wszystkich wiadomości (wg daty otwarcia rosnąco).
  Stream<List<TimeCapsuleMessage>> watchMessages() => _col
      .orderBy('openDate')
      .snapshots()
      .map((snap) => snap.docs.map(TimeCapsuleMessage.fromDoc).toList());

  Future<void> deleteMessage(String id) => _col.doc(id).delete();
}
