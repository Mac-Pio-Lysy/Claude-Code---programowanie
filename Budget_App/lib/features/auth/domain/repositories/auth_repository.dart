/// Authentication against Google/Apple, per architecture.c4's Auth Module.
abstract interface class AuthRepository {
  Future<String?> get currentUserId;
  Future<void> signInWithGoogle();
  Future<void> signInWithApple();
  Future<void> signOut();
}
