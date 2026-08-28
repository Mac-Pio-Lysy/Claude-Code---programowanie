import '../models/auth_user.dart';

/// Clean interface a real backend (Supabase Auth / Firebase) drops in
/// behind later — everything above this (AuthBloc, UI) is unaware whether
/// it's talking to the mock or a live provider.
abstract interface class AuthRepository {
  /// The current session's user, or null if signed out. Also used at
  /// startup (from the splash screen) to decide /login vs /workspace.
  Future<AuthUser?> getCurrentUser();

  Future<AuthUser> signInWithGoogle();
  Future<AuthUser> signInWithApple();
  Future<AuthUser> signInWithEmail({required String email, required String password});
  Future<AuthUser> signUpWithEmail({required String email, required String password});
  Future<AuthUser> signInAsGuest();
  Future<void> signOut();
}
