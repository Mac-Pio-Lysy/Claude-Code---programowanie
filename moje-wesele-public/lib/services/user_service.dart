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
      if (email != null && email.isNotEmpty) 'email': email,
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

  /// Zmiana typu konta ('para' | 'planer').
  Future<void> setAccountType(String uid, String accountType) =>
      _col.doc(uid).set({'accountType': accountType}, SetOptions(merge: true));
}
