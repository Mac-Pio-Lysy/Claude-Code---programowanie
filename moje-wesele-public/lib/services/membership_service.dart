import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/membership.dart';

/// Operacje na powiązaniach użytkownik ↔ wesele (kolekcja `memberships`).
///
/// Każdy dokument łączy `userId` z `weddingId` i nadaje rolę. Lista wesel
/// użytkownika powstaje z zapytania `where('userId', ==, uid)`.
class MembershipService {
  MembershipService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const String collectionName = 'memberships';

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(collectionName);

  /// Tworzy członkostwo (auto-ID). Zwraca ID utworzonego dokumentu.
  Future<String> create({
    required String userId,
    required String weddingId,
    required String role,
  }) async {
    final ref = _col.doc();
    await ref.set({
      'userId': userId,
      'weddingId': weddingId,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Jednorazowa lista członkostw danego użytkownika.
  Future<List<Membership>> forUser(String userId) async {
    final snap = await _col.where('userId', isEqualTo: userId).get();
    return snap.docs
        .map((d) => Membership.fromMap(d.id, d.data()))
        .toList();
  }

  /// Znajduje członkostwo danego użytkownika w danym weselu (lub null).
  Future<Membership?> findFor(String userId, String weddingId) async {
    final snap = await _col
        .where('userId', isEqualTo: userId)
        .where('weddingId', isEqualTo: weddingId)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return Membership.fromMap(snap.docs.first.id, snap.docs.first.data());
  }

  /// Strumień członkostw użytkownika (na żywo).
  Stream<List<Membership>> watchForUser(String userId) => _col
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => Membership.fromMap(d.id, d.data())).toList());
}
