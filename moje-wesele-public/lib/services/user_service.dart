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

  /// Indeks e-mail → uid (odczyt profilu innego użytkownika po e-mailu jest
  /// zablokowany regułami; ten indeks pozwala właścicielowi znaleźć konto do
  /// dodania do wesela). Dokument = e-mail (małe litery) → `{ uid }`.
  static const String emailIndexCollection = 'usersByEmail';

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(collectionName);

  /// Tworzy/aktualizuje dokument użytkownika (scalanie — nie nadpisuje pól,
  /// których nie podano). `accountType` ustawiany tylko, gdy jeszcze go nie ma.
  /// Dodatkowo utrzymuje indeks `usersByEmail/{email}` → `{ uid }`.
  Future<void> ensureUser({
    required String uid,
    String? displayName,
    String? email,
    String accountType = 'para',
  }) async {
    final ref = _col.doc(uid);
    final snap = await ref.get();
    final normalizedEmail =
        (email != null && email.isNotEmpty) ? email.trim().toLowerCase() : null;
    final payload = <String, dynamic>{
      if (displayName != null && displayName.isNotEmpty)
        'displayName': displayName,
      'email': ?normalizedEmail,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    // Typ konta ustawiamy tylko przy pierwszym utworzeniu (nie nadpisujemy).
    if (!snap.exists) {
      payload['accountType'] = accountType;
      payload['createdAt'] = FieldValue.serverTimestamp();
    }
    await ref.set(payload, SetOptions(merge: true));

    // Indeks e-mail → uid (do dodawania osób po adresie).
    if (normalizedEmail != null) {
      await _db
          .collection(emailIndexCollection)
          .doc(normalizedEmail)
          .set({'uid': uid}, SetOptions(merge: true));
    }
  }

  /// Jednorazowy odczyt profilu użytkownika.
  Future<Map<String, dynamic>?> read(String uid) async =>
      (await _col.doc(uid).get()).data();

  /// Znajduje uid użytkownika po adresie e-mail (przez indeks `usersByEmail`).
  /// Zwraca `(uid: ...)` lub `null`, gdy nikt z tym adresem nie ma konta.
  Future<({String uid})?> findByEmail(String email) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    final snap =
        await _db.collection(emailIndexCollection).doc(normalized).get();
    final uid = snap.data()?['uid'] as String?;
    return (uid != null && uid.isNotEmpty) ? (uid: uid) : null;
  }

  /// Zmiana typu konta ('para' | 'planer').
  Future<void> setAccountType(String uid, String accountType) =>
      _col.doc(uid).set({'accountType': accountType}, SetOptions(merge: true));
}
