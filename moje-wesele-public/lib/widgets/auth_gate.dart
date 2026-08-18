import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../screens/email_auth_screen.dart';
import '../screens/guest/guest_home_screen.dart';
import '../screens/lock/lock_screen.dart';
import '../screens/login_screen.dart';
import '../screens/main_navigation.dart';
import '../screens/weddings/weddings_list_screen.dart';
import '../services/active_wedding.dart';
import '../services/app_lock_service.dart';
import '../services/auth_service.dart';
import '../l10n/app_text.dart';

/// Bramka autoryzacji — decyduje, który ekran pokazać w zależności od
/// stanu logowania. Odpowiednik `onAuthStateChanged` z zrodlo-web/auth.js:
///
///  • brak użytkownika           → [LoginScreen]
///  • użytkownik zalogowany      → [WeddingsListScreen] → [MainNavigation]
///
/// Rejestracja jest otwarta (każde konto Google). Sesja jest zapamiętywana
/// przez Firebase, więc po ponownym otwarciu aplikacji następuje automatyczne
/// logowanie.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthService _authService = AuthService();
  final AppLockService _lock = AppLockService();
  StreamSubscription<User?>? _sub;

  User? _user;
  bool _initializing = true;
  bool _signingIn = false;
  String? _error;

  /// Czy włączona jest blokada aplikacji (biometria/PIN) na tym urządzeniu.
  bool _lockEnabled = false;

  /// Czy bieżąca sesja jest odblokowana. Reset przy każdym starcie aplikacji
  /// (stan w pamięci) → przy kolejnym otwarciu znów wymagane odblokowanie.
  bool _unlocked = false;

  /// Ustawiane, gdy użytkownik świadomie loguje się przez Google — wtedy
  /// pomijamy ekran blokady (tożsamość już potwierdzona).
  bool _interactiveSignIn = false;

  /// Aktywne wesele (multi-wedding). `null` → pokazujemy ekran „Twoje wesela".
  /// Ustawiane po wyborze wesela z listy, czyszczone przy „Zmień wesele".
  String? _activeWeddingId;

  /// Rola użytkownika w aktywnym weselu ('owner'/'planner'/'collaborator'/
  /// 'guest'). Decyduje o interfejsie: gość dostaje uproszczony panel.
  String _activeRole = 'owner';

  /// Ustawia aktywne wesele (globalnie i w stanie) — wybór z listy.
  void _openWedding(String weddingId, String role) {
    ActiveWedding.id = weddingId;
    setState(() {
      _activeWeddingId = weddingId;
      _activeRole = role;
    });
  }

  /// Powrót do listy wesel („Zmień wesele").
  void _switchWedding() {
    ActiveWedding.clear();
    setState(() => _activeWeddingId = null);
  }

  @override
  void initState() {
    super.initState();
    _sub = _authService.authStateChanges().listen(_onAuthChanged);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _onAuthChanged(User? user) async {
    // Brak zalogowanego użytkownika
    if (user == null) {
      ActiveWedding.clear();
      if (!mounted) return;
      setState(() {
        _user = null;
        _unlocked = false;
        _initializing = false;
        _activeWeddingId = null;
      });
      return;
    }

    // TRYB TESTOWY - przywrócić logowanie przed wydaniem
    // Blokada dostępu oparta na liście 3 maili — tymczasowo wyłączona, aby nie
    // przeszkadzała w testach. NIE KASOWAĆ: odkomentować przy przywróceniu.
    // // Użytkownik spoza listy dozwolonych → wyloguj i pokaż komunikat
    // if (!AuthService.isAllowed(user)) {
    //   await _authService.signOut();
    //   if (!mounted) return;
    //   setState(() {
    //     _user = null;
    //     _signingIn = false;
    //     _initializing = false;
    //     _error = 'Brak dostępu — ta aplikacja jest prywatna.\n'
    //         'Skontaktuj się z organizatorem.';
    //   });
    //   return;
    // }

    // Użytkownik dozwolony — sprawdź blokadę aplikacji.
    final lockEnabled = await _lock.isLockEnabled();
    if (!mounted) return;
    setState(() {
      _user = user;
      _lockEnabled = lockEnabled;
      // Logowanie interaktywne (Google) pomija ekran blokady; auto-login
      // po starcie aplikacji wymaga odblokowania.
      _unlocked = _interactiveSignIn || !lockEnabled;
      _interactiveSignIn = false;
      _signingIn = false;
      _initializing = false;
      _error = null;
    });
  }

  Future<void> _handleSignIn() async {
    setState(() {
      _signingIn = true;
      _interactiveSignIn = true;
      _error = null;
    });
    try {
      await _authService.signInWithGoogle();
      // Powodzenie obsłuży nasłuch authStateChanges → _onAuthChanged.
    } on FirebaseAuthException catch (e) {
      // Użytkownik sam zamknął okno logowania — bez komunikatu o błędzie.
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request') {
        if (mounted) {
          setState(() {
            _signingIn = false;
            _interactiveSignIn = false;
          });
        }
        return;
      }
      if (mounted) {
        setState(() {
          _signingIn = false;
          _interactiveSignIn = false;
          _error = _errorMessage(e);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _signingIn = false;
          _interactiveSignIn = false;
          _error = AppText.t.auth_generic;
        });
      }
    }
  }

  /// Mapowanie kodów błędów na polskie komunikaty (jak `_errMsg` w wersji web).
  String _errorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'network-request-failed':
        return AppText.t.auth_network;
      case 'too-many-requests':
        return AppText.t.auth_tooMany;
      case 'user-disabled':
        return AppText.t.auth_disabled;
      case 'operation-not-allowed':
        return AppText.t.auth_notEnabled;
      case 'popup-blocked':
        return AppText.t.auth_popupBlocked;
      case 'email-already-in-use':
        return AppText.t.auth_emailInUse;
      case 'weak-password':
        return AppText.t.auth_weakPassword;
      case 'invalid-email':
        return AppText.t.auth_invalidEmail;
      case 'user-not-found':
        return AppText.t.auth_userNotFound;
      case 'wrong-password':
        return AppText.t.auth_wrongPassword;
      // Nowsze wersje Firebase SDK zwracają ten kod zamiast osobnych
      // 'wrong-password'/'user-not-found' przy błędnym logowaniu — dla
      // bezpieczeństwa nie zdradzamy, czy to hasło, czy nieistniejące konto.
      case 'invalid-credential':
        return AppText.t.auth_invalidCredential;
      default:
        return AppText.t.auth_codeError(e.code);
    }
  }

  /// Logowanie e-mailem i hasłem — jak [_handleSignIn], ale zwraca komunikat
  /// błędu zamiast go zapisywać w stanie (ekran e-mail wyświetla go sam).
  /// Sukces obsłuży nasłuch `authStateChanges` → [_onAuthChanged], tak samo
  /// jak po Google.
  Future<String?> _handleEmailSignIn(String email, String password) async {
    _interactiveSignIn = true;
    try {
      await _authService.signInWithEmail(email, password);
      return null;
    } on FirebaseAuthException catch (e) {
      _interactiveSignIn = false;
      return _errorMessage(e);
    } catch (_) {
      _interactiveSignIn = false;
      return AppText.t.auth_generic;
    }
  }

  /// Rejestracja e-mailem i hasłem — osobne konto od Google, bez łączenia.
  Future<String?> _handleEmailRegister(String email, String password) async {
    _interactiveSignIn = true;
    try {
      await _authService.registerWithEmail(email, password);
      return null;
    } on FirebaseAuthException catch (e) {
      _interactiveSignIn = false;
      return _errorMessage(e);
    } catch (_) {
      _interactiveSignIn = false;
      return AppText.t.auth_generic;
    }
  }

  /// Reset hasła (mail resetujący) — nie loguje, więc nie dotyka
  /// `_interactiveSignIn`.
  Future<String?> _handleResetPassword(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
      return null;
    } on FirebaseAuthException catch (e) {
      return _errorMessage(e);
    } catch (_) {
      return AppText.t.auth_generic;
    }
  }

  void _openEmailAuth() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EmailAuthScreen(
          onSignIn: _handleEmailSignIn,
          onRegister: _handleEmailRegister,
          onResetPassword: _handleResetPassword,
        ),
      ),
    );
  }

  /// Wybór między ekranem „Twoje wesela" a panelem głównym aktywnego wesela.
  Widget _weddingsOrApp(User user) {
    if (_activeWeddingId == null) {
      return WeddingsListScreen(
        userId: user.uid,
        displayName: user.displayName,
        email: user.email,
        onOpen: _openWedding,
        onSignOut: () => _authService.signOut(),
      );
    }
    // Gość → uproszczony panel (tylko dozwolone sekcje). Pozostałe role →
    // pełny panel organizatora.
    if (_activeRole == 'guest') {
      return GuestHomeScreen(
        user: user,
        weddingId: _activeWeddingId!,
        onSwitchWedding: _switchWedding,
        onSignOut: () => _authService.signOut(),
      );
    }
    return MainNavigation(
      user: user,
      weddingId: _activeWeddingId!,
      role: _activeRole,
      onSwitchWedding: _switchWedding,
      onSignOut: () => _authService.signOut(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return const _SplashLoader();
    }
    final user = _user;
    if (user != null) {
      if (_lockEnabled && !_unlocked) {
        return LockScreen(
          displayName: user.displayName?.split(' ').first,
          onUnlocked: () => setState(() => _unlocked = true),
          // Po przekroczeniu limitu prób / „nie pamiętam" → ponowne logowanie
          // Google. Czyścimy też zapamiętaną sesję Google, by można było
          // wybrać konto.
          onForceReauth: () => _authService.signOut(),
        );
      }
      return _weddingsOrApp(user);
    }
    return LoginScreen(
      onGoogleSignIn: _handleSignIn,
      onEmailAuth: _openEmailAuth,
      isLoading: _signingIn,
      errorMessage: _error,
    );
  }
}

/// Ekran ładowania pokazywany podczas ustalania stanu logowania
/// (zapobiega mignięciu ekranu logowania przy auto-loginie).
class _SplashLoader extends StatelessWidget {
  const _SplashLoader();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.45, 1.0],
            colors: AppColors.bgGradient,
          ),
        ),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppColors.accent),
          ),
        ),
      ),
    );
  }
}
