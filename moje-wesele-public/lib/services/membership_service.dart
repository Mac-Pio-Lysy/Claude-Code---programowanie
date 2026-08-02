import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/membership.dart';

/// Operacje na powiązaniach użytkownik ↔ wesele (kolekcja `memberships`).
///
/// Każdy dokument łączy `userId` z `weddingId`, nadaje rolę, status i (dla
/// planera) datę ważności. Lista wesel użytkownika powstaje z zapytania
/// `where('userId', ==, uid)`; lista osób wesela z `where('weddingId', ==, id)`.
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
    String status = 'active',
    String? expiresAt,
    String email = '',
    String displayName = '',
    String? inviteCode,
  }) async {
    final ref = _col.doc();
    await ref.set({
      'userId': userId,
      'weddingId': weddingId,
      'role': role,
      'status': status,
      'expiresAt': expiresAt,
      'email': email,
      'displayName': displayName,
      'inviteCode': ?inviteCode,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Aktualizuje wybrane pola członkostwa (scalanie).
  Future<void> update(
    String membershipId, {
    String? role,
    String? status,
    String? expiresAt,
    bool clearExpiresAt = false,
    String? userId,
    String? email,
    String? displayName,
    Object? inviteCode = _noChange,
  }) async {
    final payload = <String, dynamic>{
      'role': ?role,
      'status': ?status,
      if (clearExpiresAt) 'expiresAt': null else 'expiresAt': ?expiresAt,
      'userId': ?userId,
      'email': ?email,
      'displayName': ?displayName,
      if (!identical(inviteCode, _noChange)) 'inviteCode': inviteCode,
    };
    if (payload.isEmpty) return;
    await _col.doc(membershipId).set(payload, SetOptions(merge: true));
  }

  /// Usuwa członkostwo całkowicie.
  Future<void> delete(String membershipId) => _col.doc(membershipId).delete();

  /// Jednorazowa lista członkostw danego użytkownika.
  Future<List<Membership>> forUser(String userId) async {
    final snap = await _col.where('userId', isEqualTo: userId).get();
    return snap.docs.map((d) => Membership.fromMap(d.id, d.data())).toList();
  }

  /// Wszystkie osoby powiązane z danym weselem (dla panelu właściciela).
  Future<List<Membership>> forWedding(String weddingId) async {
    final snap = await _col.where('weddingId', isEqualTo: weddingId).get();
    return snap.docs.map((d) => Membership.fromMap(d.id, d.data())).toList();
  }

  /// Strumień osób wesela (na żywo) — panel „Osoby i dostęp".
  Stream<List<Membership>> watchForWedding(String weddingId) => _col
      .where('weddingId', isEqualTo: weddingId)
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => Membership.fromMap(d.id, d.data())).toList());

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

  /// Znajduje OCZEKUJĄCE zaproszenie po kodzie (do odebrania roli).
  Future<Membership?> findPendingByInviteCode(String code) async {
    final snap = await _col
        .where('inviteCode', isEqualTo: code)
        .where('status', isEqualTo: 'pending')
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

/// Sentinel — odróżnia „nie zmieniaj" od „ustaw na null".
const Object _noChange = Object();
