import 'package:cloud_firestore/cloud_firestore.dart';

/// Dane użytkownika (kolekcja `users`, dokument = uid).
///
/// Przechowuje profil konta: nazwę, e-mail oraz typ konta:
///   • `para`   — Para Młoda (organizuje własne wesele),
///   • `planer` — profesjonalny planer (obsługuje wiele wesel).
class UserService {
  UserService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const String collectionName = 'users';

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(collectionName);

  /// Tworzy/aktualizuje dokument użytkownika (scalanie — nie nadpisuje pól,
  /// których nie podano). `accountType` ustawiany tylko, gdy jeszcze go nie ma.
  Future<void> ensureUser({
    required String uid,
    String? displayName,
    String? email,
    String accountType = 'para',
  }) async {
    final ref = _col.doc(uid);
    final snap = await ref.get();
    final payload = <String, dynamic>{
      if (displayName != null && displayName.isNotEmpty)
        'displayName': displayName,
      if (email != null && email.isNotEmpty) 'email': email.trim().toLowerCase(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    // Typ konta ustawiamy tylko przy pierwszym utworzeniu (nie nadpisujemy).
    if (!snap.exists) {
      payload['accountType'] = accountType;
      payload['createdAt'] = FieldValue.serverTimestamp();
    }
    await ref.set(payload, SetOptions(merge: true));
  }

  /// Jednorazowy odczyt profilu użytkownika.
  Future<Map<String, dynamic>?> read(String uid) async =>
      (await _col.doc(uid).get()).data();

  /// Znajduje użytkownika po adresie e-mail (do dodawania osób do wesela).
  /// Zwraca `(uid, dane)` lub `null`, gdy nikt z tym adresem nie ma konta.
  Future<({String uid, Map<String, dynamic> data})?> findByEmail(
      String email) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    final snap =
        await _col.where('email', isEqualTo: normalized).limit(1).get();
    if (snap.docs.isNotEmpty) {
      final d = snap.docs.first;
      return (uid: d.id, data: d.data());
    }
    return null;
  }

  /// Zmiana typu konta ('para' | 'planer').
  Future<void> setAccountType(String uid, String accountType) =>
      _col.doc(uid).set({'accountType': accountType}, SetOptions(merge: true));
}
