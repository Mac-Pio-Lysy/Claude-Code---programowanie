import 'package:equatable/equatable.dart';

import 'auth_provider_type.dart';

class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.email,
    required this.authProvider,
    this.displayName,
    this.photoUrl,
  });

  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final AuthProviderType authProvider;

  @override
  List<Object?> get props => [id, email, displayName, photoUrl, authProvider];
}
