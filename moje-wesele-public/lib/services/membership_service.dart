import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/membership.dart';

/// Operacje na powiązaniach użytkownik ↔ wesele (kolekcja `memberships`).
///
/// ID dokumentu jest DETERMINISTYCZNE: `{userId}__{weddingId}` — dzięki temu
/// reguły bezpieczeństwa mogą sprawdzić członkostwo przez `exists()/get()` po
/// znanej ścieżce (izolacja wesel).
///
/// Pola: userId, weddingId, role, status ('active'/'blocked'), email,
/// displayName, expiresAt ("YYYY-MM-DD", planer) oraz `expiresAtTs` (Timestamp
/// — do porównania daty w regułach). `claimCode` bywa dołączane, gdy członkostwo
/// powstaje z odebrania zaproszenia kodem (reguła weryfikuje `roleInvites`).
class MembershipService {
  MembershipService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const String collectionName = 'memberships';

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(collectionName);

  /// Deterministyczne ID członkostwa.
  static String idFor(String userId, String weddingId) =>
      '${userId}__$weddingId';

  /// Tworzy/ustawia członkostwo pod deterministycznym ID. Zwraca ID dokumentu.
  Future<String> create({
    required String userId,
    required String weddingId,
    required String role,
    String status = 'active',
    String? expiresAt,
    String email = '',
    String displayName = '',
    String? claimCode,
  }) async {
    final id = idFor(userId, weddingId);
    await _col.doc(id).set({
      'userId': userId,
      'weddingId': weddingId,
      'role': role,
      'status': status,
      'expiresAt': expiresAt,
      'expiresAtTs': expiresAtTimestamp(expiresAt),
      'email': email,
      'displayName': displayName,
      'claimCode': ?claimCode,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return id;
  }

  /// Aktualizuje wybrane pola członkostwa (scalanie). Zmiana `expiresAt`
  /// synchronizuje też `expiresAtTs`.
  Future<void> update(
    String membershipId, {
    String? role,
    String? status,
    String? expiresAt,
    bool clearExpiresAt = false,
    String? displayName,
  }) async {
    final payload = <String, dynamic>{
      'role': ?role,
      'status': ?status,
      'displayName': ?displayName,
    };
    if (clearExpiresAt) {
      payload['expiresAt'] = null;
      payload['expiresAtTs'] = null;
    } else if (expiresAt != null) {
      payload['expiresAt'] = expiresAt;
      payload['expiresAtTs'] = expiresAtTimestamp(expiresAt);
    }
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
    final snap = await _col.doc(idFor(userId, weddingId)).get();
    if (!snap.exists) return null;
    return Membership.fromMap(snap.id, snap.data()!);
  }

  /// Strumień członkostw użytkownika (na żywo).
  Stream<List<Membership>> watchForUser(String userId) => _col
      .where('userId', isEqualTo: userId)
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => Membership.fromMap(d.id, d.data())).toList());
}

/// Zamienia datę "YYYY-MM-DD" na Timestamp KOŃCA ważności = początek dnia
/// NASTĘPNEGO (00:00 UTC). Dzięki temu dostęp obowiązuje przez CAŁY dzień
/// `expiresAt` (reguła: `request.time < expiresAtTs`). Uwaga: granica liczona
/// w UTC (ok. 01:00–02:00 czasu polskiego — nieznacznie „na korzyść" osoby).
Timestamp? expiresAtTimestamp(String? ymd) {
  if (ymd == null) return null;
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(ymd);
  if (m == null) return null;
  final next = DateTime.utc(
      int.parse(m.group(1)!), int.parse(m.group(2)!), int.parse(m.group(3)!) + 1);
  return Timestamp.fromDate(next);
}
