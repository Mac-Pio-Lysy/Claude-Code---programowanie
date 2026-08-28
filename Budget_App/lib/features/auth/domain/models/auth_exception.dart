/// A user-facing authentication failure (bad credentials, taken email, …).
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
