import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../screens/lock/lock_screen.dart';
import '../screens/login_screen.dart';
import '../screens/main_navigation.dart';
import '../services/app_lock_service.dart';
import '../services/auth_service.dart';

/// Bramka autoryzacji — decyduje, który ekran pokazać w zależności od
/// stanu logowania. Odpowiednik `onAuthStateChanged` z zrodlo-web/auth.js:
///
///  • brak użytkownika           → [LoginScreen]
///  • użytkownik spoza listy     → wylogowanie + komunikat „Brak dostępu"
///  • użytkownik dozwolony       → [HomeScreen]
///
/// Sesja jest zapamiętywana przez Firebase, więc po ponownym otwarciu
/// aplikacji następuje automatyczne logowanie.
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
      if (!mounted) return;
      setState(() {
        _user = null;
        _unlocked = false;
        _initializing = false;
      });
      return;
    }

    // Użytkownik spoza listy dozwolonych → wyloguj i pokaż komunikat
    if (!AuthService.isAllowed(user)) {
      await _authService.signOut();
      if (!mounted) return;
      setState(() {
        _user = null;
        _signingIn = false;
        _initializing = false;
        _error = 'Brak dostępu — ta aplikacja jest prywatna.\n'
            'Skontaktuj się z organizatorem.';
      });
      return;
    }

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
          _error = 'Błąd logowania. Spróbuj ponownie.';
        });
      }
    }
  }

  /// Mapowanie kodów błędów na polskie komunikaty (jak `_errMsg` w wersji web).
  String _errorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'network-request-failed':
        return 'Błąd sieci — sprawdź połączenie z internetem.';
      case 'too-many-requests':
        return 'Zbyt wiele prób logowania. Poczekaj chwilę i spróbuj ponownie.';
      case 'user-disabled':
        return 'To konto Google zostało wyłączone.';
      case 'operation-not-allowed':
        return 'Logowanie przez Google nie jest włączone. '
            'Skontaktuj się z administratorem.';
      case 'popup-blocked':
        return 'Okno logowania zostało zablokowane przez przeglądarkę — '
            'zezwól na wyskakujące okienka i spróbuj ponownie.';
      default:
        return 'Błąd logowania (${e.code}). Spróbuj ponownie.';
    }
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
      return MainNavigation(
        user: user,
        onSignOut: () => _authService.signOut(),
      );
    }
    return LoginScreen(
      onGoogleSignIn: _handleSignIn,
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
