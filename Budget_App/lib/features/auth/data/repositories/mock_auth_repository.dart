import '../../domain/repositories/auth_repository.dart';

/// In-memory stand-in until Supabase auth (Google/Apple) is wired in.
class MockAuthRepository implements AuthRepository {
  String? _userId;

  @override
  Future<String?> get currentUserId async => _userId;

  @override
  Future<void> signInWithGoogle() async => _userId = 'mock-google-user';

  @override
  Future<void> signInWithApple() async => _userId = 'mock-apple-user';

  @override
  Future<void> signOut() async => _userId = null;
}
