import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../screens/login_screen.dart';
import '../screens/main_navigation.dart';
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
  StreamSubscription<User?>? _sub;

  User? _user;
  bool _initializing = true;
  bool _signingIn = false;
  String? _error;

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

    // Użytkownik dozwolony
    if (!mounted) return;
    setState(() {
      _user = user;
      _signingIn = false;
      _initializing = false;
      _error = null;
    });
  }

  Future<void> _handleSignIn() async {
    setState(() {
      _signingIn = true;
      _error = null;
    });
    try {
      await _authService.signInWithGoogle();
      // Powodzenie obsłuży nasłuch authStateChanges → _onAuthChanged.
    } on FirebaseAuthException catch (e) {
      // Użytkownik sam zamknął okno logowania — bez komunikatu o błędzie.
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request') {
        if (mounted) setState(() => _signingIn = false);
        return;
      }
      if (mounted) {
        setState(() {
          _signingIn = false;
          _error = _errorMessage(e);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _signingIn = false;
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
