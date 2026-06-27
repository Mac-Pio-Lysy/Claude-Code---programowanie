import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

/// Uwierzytelnianie przez Google — odpowiednik zrodlo-web/auth.js.
///
/// Dostęp do aplikacji mają wyłącznie adresy z listy [allowedEmails]
/// (zgodnej z ALLOWED_EMAILS w wersji webowej).
class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// Web OAuth client ID (client_type 3 z google-services.json).
  /// Wymagany przez google_sign_in na Androidzie, aby idToken miał odbiorcę
  /// (audience) akceptowanego przez Firebase Auth.
  static const String _serverClientId =
      '719030954518-02u0vbbfp1tee4cevpm87bg98nt42l7g.apps.googleusercontent.com';

  /// Jednorazowa inicjalizacja google_sign_in (tylko platformy natywne).
  Future<void>? _googleInit;

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

  Future<void> _ensureGoogleInit() =>
      _googleInit ??= GoogleSignIn.instance.initialize(
        serverClientId: _serverClientId,
      );

  /// Logowanie przez Google.
  ///
  /// Web: okno popup Google (jak `signInWithPopup` w wersji webowej).
  /// Android/iOS: natywne logowanie przez google_sign_in → poświadczenie
  /// Firebase (`signInWithCredential`). W obu przypadkach trafiamy do tego
  /// samego konta Firebase i tych samych danych w Firestore.
  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider()
        ..setCustomParameters({'prompt': 'select_account'});
      return _auth.signInWithPopup(provider);
    }

    final google = GoogleSignIn.instance;
    if (!google.supportsAuthenticate()) {
      throw FirebaseAuthException(
        code: 'operation-not-allowed',
        message: 'Logowanie Google nie jest obsługiwane na tej platformie.',
      );
    }

    try {
      await _ensureGoogleInit();
      final account = await google.authenticate(scopeHint: const ['email']);
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw FirebaseAuthException(
          code: 'google-signin-failed',
          message: 'Brak tokenu Google. Spróbuj ponownie.',
        );
      }
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      return await _auth.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      // Anulowanie przez użytkownika — bez komunikatu o błędzie
      // (AuthGate traktuje 'cancelled-popup-request' jako ciche anulowanie).
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw FirebaseAuthException(
          code: 'cancelled-popup-request',
          message: 'Anulowano logowanie.',
        );
      }
      throw FirebaseAuthException(
        code: 'google-signin-failed',
        message: e.description ?? 'Błąd logowania Google.',
      );
    }
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // Wylogowanie z Google nie powinno blokować wylogowania z Firebase.
      }
    }
    await _auth.signOut();
  }
}
