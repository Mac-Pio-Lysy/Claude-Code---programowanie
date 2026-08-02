import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../screens/guest/guest_home_screen.dart';
import '../screens/lock/lock_screen.dart';
import '../screens/login_screen.dart';
import '../screens/main_navigation.dart';
import '../screens/weddings/weddings_list_screen.dart';
import '../screens/welcome_screen.dart';
import '../services/active_wedding.dart';
import '../services/app_lock_service.dart';
import '../services/auth_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PRZEŁĄCZNIK TEST/PROD (ETAP 4a: logowanie WŁĄCZONE — domyślnie false)
//
// Gdy `bypassLogin == true`, aplikacja POMIJA ekran logowania Google i blokadę
// biometryczną/PIN, wchodząc od razu do listy wesel (z testowym uid). Przydatne
// przy pracy nad wyglądem bez ciągłego logowania.
//
// Gdy `bypassLogin == false` (produkcyjnie), działa normalne logowanie Google:
//   • brak sesji           → ekran logowania,
//   • po zalogowaniu       → „Twoje wesela" → panel wybranego wesela,
//   • wylogowanie          → powrót do ekranu logowania.
//
// Rejestracja jest OTWARTA — dawna lista dozwolonych maili jest wyłączona
// (zakomentowana tu i w AuthService).
const bool bypassLogin = false; // przełącznik test/prod
// ═══════════════════════════════════════════════════════════════════════════

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

  /// TRYB TESTOWY: czy użytkownik przeszedł ekran tytułowy do aplikacji.
  bool _entered = false;

  /// Aktywne wesele (multi-wedding). `null` → pokazujemy ekran „Twoje wesela".
  /// Ustawiane po wyborze wesela z listy, czyszczone przy „Zmień wesele".
  String? _activeWeddingId;

  /// Rola użytkownika w aktywnym weselu ('owner'/'planner'/'collaborator'/
  /// 'guest'). Decyduje o interfejsie: gość dostaje uproszczony panel.
  String _activeRole = 'owner';

  /// Identyfikator używany do danych — uid zalogowanego użytkownika lub
  /// zastępczy w trybie bez logowania (bypassLogin).
  String get _dataUid => _user?.uid ?? 'tryb-testowy';

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

    // TRYB TESTOWY - przywrócić logowanie przed wydaniem
    // Best-effort: bez zapamiętanej sesji próbujemy zalogować anonimowo w tle,
    // aby Firestore działał. Panel i tak pokaże się od razu (patrz build()),
    // więc ewentualna porażka (anonimowe wyłączone w projekcie) niczego nie
    // blokuje — po prostu dane z Firestore mogą być wtedy niedostępne.
    if (bypassLogin && _authService.currentUser == null) {
      _authService.signInAnonymously().then((_) {}, onError: (_) {});
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _onAuthChanged(User? user) async {
    // ───────────────────────────────────────────────────────────────────────
    // TRYB TESTOWY - przywrócić logowanie przed wydaniem
    // W trybie testowym panel jest pokazywany OD RAZU w build() — niezależnie
    // od FirebaseAuth. Tu tylko aktualizujemy `_user`, gdy pojawi się realna
    // (lub anonimowa) sesja, żeby Firestore dostał prawdziwy uid.
    if (bypassLogin) {
      if (!mounted) return;
      setState(() {
        _user = user;
        _initializing = false;
      });
      return;
    }
    // ───────────────────────────────────────────────────────────────────────

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

  /// Wybór między ekranem „Twoje wesela" a panelem głównym aktywnego wesela.
  /// Wspólne dla trybu testowego (bypassLogin) i normalnego logowania.
  Widget _weddingsOrApp(User? user) {
    if (_activeWeddingId == null) {
      return WeddingsListScreen(
        userId: _dataUid,
        displayName: user?.displayName,
        email: user?.email,
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
      onSwitchWedding: _switchWedding,
      onSignOut: () => _authService.signOut(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ───────────────────────────────────────────────────────────────────────
    // TRYB TESTOWY - przywrócić logowanie przed wydaniem
    // Panel pokazywany OD RAZU, całkowicie z pominięciem ekranu logowania,
    // sprawdzania FirebaseAuth i blokady PIN/biometrii. `_user` może być null
    // (dopóki ewentualne logowanie anonimowe w tle nie ustawi realnej sesji).
    if (bypassLogin) {
      // Najpierw elegancki ekran tytułowy (docelowo logowanie/rejestracja),
      // potem — po „Wejdź" — ekran „Twoje wesela", a po wyborze — panel główny.
      if (!_entered) {
        return WelcomeScreen(onEnter: () => setState(() => _entered = true));
      }
      return _weddingsOrApp(_user);
    }
    // ───────────────────────────────────────────────────────────────────────

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
