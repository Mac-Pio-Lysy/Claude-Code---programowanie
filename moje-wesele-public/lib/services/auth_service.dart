import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import '../l10n/app_text.dart';
import '../l10n/locale_controller.dart';

/// Uwierzytelnianie przez Google — odpowiednik zrodlo-web/auth.js.
///
/// ETAP 4a: REJESTRACJA OTWARTA — każde konto Google może się zalogować
/// i założyć własne wesele. Dawne ograniczenie do listy dozwolonych adresów
/// jest zachowane (zakomentowane niżej) na wypadek potrzeby przywrócenia.
class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// Web OAuth client ID (client_type 3 z google-services.json).
  /// Wymagany przez google_sign_in na Androidzie, aby idToken miał odbiorcę
  /// (audience) akceptowanego przez Firebase Auth.
  ///
  /// ⚠️ MUSI pochodzić z TEGO SAMEGO projektu Firebase co aplikacja Android.
  /// Prefiks przed myślnikiem to numer projektu — tu `221816723659`, czyli
  /// `wedding-planner-pub`. Wartość z innego projektu daje na Androidzie błąd
  /// „Android clients and Web clients (server client ID) must be in the same
  /// project" (kod 28444/10), a logowanie na webie działa dalej, bo tam
  /// `signInWithPopup` w ogóle tej stałej nie używa.
  static const String _serverClientId =
      '221816723659-n11bpn1iurom23mmt8eukl4dlbl0b4u2.apps.googleusercontent.com';

  /// Jednorazowa inicjalizacja google_sign_in (tylko platformy natywne).
  Future<void>? _googleInit;

  // ───────────────────────────────────────────────────────────────────────
  // ETAP 4a: rejestracja otwarta — lista dozwolonych maili WYŁĄCZONA.
  // Zachowana (zakomentowana) na wypadek powrotu do dostępu prywatnego.
  //
  // /// Lista dozwolonych adresów e-mail — identyczna jak w aplikacji webowej.
  // static const List<String> allowedEmails = [
  //   'macholak.piotr@gmail.com',
  //   'ceremonia.panstwa.macholak@gmail.com',
  //   'patrycja.staniow@gmail.com',
  // ];
  //
  // /// Czy dany użytkownik jest na liście dozwolonych adresów.
  // static bool isAllowed(User? user) {
  //   final email = (user?.email ?? '').toLowerCase();
  //   return allowedEmails.contains(email);
  // }
  // ───────────────────────────────────────────────────────────────────────

  /// Strumień zmian stanu logowania (umożliwia auto-login po starcie aplikacji).
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

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
        message: AppText.t.auth_googleUnsupported,
      );
    }

    try {
      await _ensureGoogleInit();
      final account = await google.authenticate(scopeHint: const ['email']);
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw FirebaseAuthException(
          code: 'google-signin-failed',
          message: AppText.t.auth_noToken,
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
          message: AppText.t.auth_cancelled,
        );
      }
      throw FirebaseAuthException(
        code: 'google-signin-failed',
        message: e.description ?? AppText.t.auth_googleError,
      );
    }
  }

  /// Rejestracja e-mailem i hasłem — osobne konto od logowania Google
  /// (świadomie NIE łączymy kont). Po założeniu konta best-effort wysyłamy
  /// e-mail weryfikacyjny; niepowodzenie wysyłki nie przerywa rejestracji.
  Future<UserCredential> registerWithEmail(
    String email,
    String password,
  ) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    try {
      _syncAuthLanguage();
      await credential.user?.sendEmailVerification();
    } catch (_) {
      // Best-effort — rejestracja i tak się powiodła.
    }
    return credential;
  }

  /// Ustawia język maili Firebase Auth (weryfikacja, reset hasła) wg
  /// bieżącego języka aplikacji — treść samych szablonów konfiguruje się
  /// w Firebase Console (Authentication → Templates), to tylko wybór wariantu.
  void _syncAuthLanguage() {
    _auth.setLanguageCode(
      LocaleController.locale.value?.languageCode ??
          LocaleController.fallback.languageCode,
    );
  }

  /// Logowanie e-mailem i hasłem.
  Future<UserCredential> signInWithEmail(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  /// Wysyłka maila do resetu hasła (konto e-mail/hasło).
  Future<void> sendPasswordResetEmail(String email) {
    _syncAuthLanguage();
    return _auth.sendPasswordResetEmail(email: email);
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
