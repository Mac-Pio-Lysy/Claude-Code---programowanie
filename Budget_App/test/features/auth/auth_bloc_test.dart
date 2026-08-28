import 'package:bloc_test/bloc_test.dart';
import 'package:budget_app/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:budget_app/features/auth/domain/models/auth_provider_type.dart';
import 'package:budget_app/features/auth/domain/models/auth_user.dart';
import 'package:budget_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:budget_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:budget_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';

// MockAuthRepository simulates network latency; blocTest's default `wait`
// is zero, so every test that expects the resolved (post-delay) state needs
// to wait it out explicitly.
const _mockLatency = Duration(milliseconds: 400);

void main() {
  group('CheckAuthSession', () {
    blocTest<AuthBloc, AuthState>(
      'emits Unauthenticated when there is no existing session',
      build: () => AuthBloc(MockAuthRepository()),
      act: (bloc) => bloc.add(const CheckAuthSession()),
      wait: _mockLatency,
      expect: () => [const AuthLoading(), const Unauthenticated()],
    );
  });

  group('SignInWithEmail', () {
    blocTest<AuthBloc, AuthState>(
      'authenticates the seeded demo account',
      build: () => AuthBloc(MockAuthRepository()),
      act: (bloc) =>
          bloc.add(const SignInWithEmail(email: 'demo@example.com', password: 'password123')),
      wait: _mockLatency,
      expect: () => [
        const AuthLoading(),
        isA<Authenticated>()
            .having((s) => s.user.email, 'email', 'demo@example.com')
            .having((s) => s.user.authProvider, 'provider', AuthProviderType.email),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'fails with an unknown email',
      build: () => AuthBloc(MockAuthRepository()),
      act: (bloc) =>
          bloc.add(const SignInWithEmail(email: 'nieznany@example.com', password: 'whatever')),
      wait: _mockLatency,
      expect: () => [
        const AuthLoading(),
        const AuthFailure('Nie znaleziono konta dla tego adresu e-mail.'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'fails with the wrong password for a known email',
      build: () => AuthBloc(MockAuthRepository()),
      act: (bloc) =>
          bloc.add(const SignInWithEmail(email: 'demo@example.com', password: 'wrong-pass')),
      wait: _mockLatency,
      expect: () => [const AuthLoading(), const AuthFailure('Nieprawidłowe hasło.')],
    );

    blocTest<AuthBloc, AuthState>(
      'fails on a malformed email address',
      build: () => AuthBloc(MockAuthRepository()),
      act: (bloc) => bloc.add(const SignInWithEmail(email: 'not-an-email', password: 'password123')),
      wait: _mockLatency,
      expect: () => [const AuthLoading(), const AuthFailure('Podaj prawidłowy adres e-mail.')],
    );
  });

  group('SignUpWithEmail', () {
    blocTest<AuthBloc, AuthState>(
      'registers a brand-new account',
      build: () => AuthBloc(MockAuthRepository()),
      act: (bloc) =>
          bloc.add(const SignUpWithEmail(email: 'nowy@example.com', password: 'sekret123')),
      wait: _mockLatency,
      expect: () => [
        const AuthLoading(),
        isA<Authenticated>().having((s) => s.user.email, 'email', 'nowy@example.com'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'rejects a password shorter than 6 characters',
      build: () => AuthBloc(MockAuthRepository()),
      act: (bloc) => bloc.add(const SignUpWithEmail(email: 'nowy@example.com', password: '123')),
      wait: _mockLatency,
      expect: () => [
        const AuthLoading(),
        const AuthFailure('Hasło musi mieć co najmniej 6 znaków.'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'rejects an email that is already registered',
      build: () => AuthBloc(MockAuthRepository()),
      act: (bloc) =>
          bloc.add(const SignUpWithEmail(email: 'demo@example.com', password: 'sekret123')),
      wait: _mockLatency,
      expect: () => [
        const AuthLoading(),
        const AuthFailure('Konto z tym adresem e-mail już istnieje.'),
      ],
    );
  });

  group('SSO and guest sign-in', () {
    blocTest<AuthBloc, AuthState>(
      'SignInWithGoogle authenticates with the google provider',
      build: () => AuthBloc(MockAuthRepository()),
      act: (bloc) => bloc.add(const SignInWithGoogle()),
      wait: _mockLatency,
      expect: () => [
        const AuthLoading(),
        isA<Authenticated>().having((s) => s.user.authProvider, 'provider', AuthProviderType.google),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'SignInWithApple authenticates with the apple provider',
      build: () => AuthBloc(MockAuthRepository()),
      act: (bloc) => bloc.add(const SignInWithApple()),
      wait: _mockLatency,
      expect: () => [
        const AuthLoading(),
        isA<Authenticated>().having((s) => s.user.authProvider, 'provider', AuthProviderType.apple),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'SignInAsGuest authenticates with the guest provider',
      build: () => AuthBloc(MockAuthRepository()),
      act: (bloc) => bloc.add(const SignInAsGuest()),
      wait: _mockLatency,
      expect: () => [
        const AuthLoading(),
        isA<Authenticated>().having((s) => s.user.authProvider, 'provider', AuthProviderType.guest),
      ],
    );
  });

  group('SignOut', () {
    blocTest<AuthBloc, AuthState>(
      'returns to Unauthenticated',
      build: () => AuthBloc(MockAuthRepository()),
      seed: () => const Authenticated(
        AuthUser(id: 'u1', email: 'demo@example.com', authProvider: AuthProviderType.email),
      ),
      act: (bloc) => bloc.add(const SignOut()),
      expect: () => [const Unauthenticated()],
    );
  });
}
