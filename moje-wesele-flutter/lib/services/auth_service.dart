import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Uwierzytelnianie przez Google — odpowiednik zrodlo-web/auth.js.
///
/// Dostęp do aplikacji mają wyłącznie adresy z listy [allowedEmails]
/// (zgodnej z ALLOWED_EMAILS w wersji webowej).
class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// Lista dozwolonych adresów e-mail — identyczna jak w aplikacji webowej.
  static const List<String> allowedEmails = [
    'macholak.piotr@gmail.com',
    'ceremonia.panstwa.macholak@gmail.com',
    'patrycja.staniow@gmail.com',
  ];

  /// Strumień zmian stanu logowania (umożliwia auto-login po starcie aplikacji).
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Czy dany użytkownik jest na liście dozwolonych adresów.
  static bool isAllowed(User? user) {
    final email = (user?.email ?? '').toLowerCase();
    return allowedEmails.contains(email);
  }

  /// Logowanie przez Google.
  ///
  /// Web: okno popup Google (jak `signInWithPopup` w wersji webowej).
  /// Android/iOS: zostanie dodane po skonfigurowaniu odcisku SHA-1.
  Future<UserCredential> signInWithGoogle() {
    final provider = GoogleAuthProvider()
      ..setCustomParameters({'prompt': 'select_account'});

    if (kIsWeb) {
      return _auth.signInWithPopup(provider);
    }

    throw UnsupportedError(
      'Logowanie Google na tej platformie nie jest jeszcze skonfigurowane '
      '(wymaga SHA-1 dla Androida).',
    );
  }

  Future<void> signOut() => _auth.signOut();
}
