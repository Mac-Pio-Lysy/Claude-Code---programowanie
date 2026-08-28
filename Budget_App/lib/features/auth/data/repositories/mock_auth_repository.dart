import 'package:uuid/uuid.dart';

import '../../domain/models/auth_exception.dart';
import '../../domain/models/auth_provider_type.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

const _uuid = Uuid();

/// In-memory stand-in until Supabase/Firebase Auth is wired in. Seeds one
/// demo account (demo@example.com / password123) so email sign-in has a
/// real success path to exercise, plus realistic failure cases (unknown
/// email, wrong password, email already registered).
class MockAuthRepository implements AuthRepository {
  MockAuthRepository() {
    _registeredPasswords['demo@example.com'] = 'password123';
  }

  final Map<String, String> _registeredPasswords = {};
  AuthUser? _currentUser;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  Future<AuthUser?> getCurrentUser() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return _currentUser;
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    return _signInAs(
      id: 'google-demo-user',
      email: 'demo.gmail@gmail.com',
      displayName: 'Demo Google',
      authProvider: AuthProviderType.google,
    );
  }

  @override
  Future<AuthUser> signInWithApple() async {
    return _signInAs(
      id: 'apple-demo-user',
      email: 'demo.apple@icloud.com',
      displayName: 'Demo Apple',
      authProvider: AuthProviderType.apple,
    );
  }

  @override
  Future<AuthUser> signInAsGuest() async {
    return _signInAs(
      id: 'guest-${_uuid.v4()}',
      email: 'gość@lokalnie.app',
      displayName: 'Gość',
      authProvider: AuthProviderType.guest,
    );
  }

  @override
  Future<AuthUser> signInWithEmail({required String email, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final normalized = email.trim().toLowerCase();

    if (!_emailPattern.hasMatch(normalized)) {
      throw const AuthException('Podaj prawidłowy adres e-mail.');
    }
    final knownPassword = _registeredPasswords[normalized];
    if (knownPassword == null) {
      throw const AuthException('Nie znaleziono konta dla tego adresu e-mail.');
    }
    if (knownPassword != password) {
      throw const AuthException('Nieprawidłowe hasło.');
    }

    final user = AuthUser(
      id: 'email-$normalized',
      email: normalized,
      authProvider: AuthProviderType.email,
    );
    _currentUser = user;
    return user;
  }

  @override
  Future<AuthUser> signUpWithEmail({required String email, required String password}) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final normalized = email.trim().toLowerCase();

    if (!_emailPattern.hasMatch(normalized)) {
      throw const AuthException('Podaj prawidłowy adres e-mail.');
    }
    if (password.length < 6) {
      throw const AuthException('Hasło musi mieć co najmniej 6 znaków.');
    }
    if (_registeredPasswords.containsKey(normalized)) {
      throw const AuthException('Konto z tym adresem e-mail już istnieje.');
    }

    _registeredPasswords[normalized] = password;
    final user = AuthUser(
      id: 'email-$normalized',
      email: normalized,
      authProvider: AuthProviderType.email,
    );
    _currentUser = user;
    return user;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
  }

  Future<AuthUser> _signInAs({
    required String id,
    required String email,
    required String displayName,
    required AuthProviderType authProvider,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final user = AuthUser(id: id, email: email, displayName: displayName, authProvider: authProvider);
    _currentUser = user;
    return user;
  }
}
