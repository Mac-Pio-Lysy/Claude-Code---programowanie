import 'package:equatable/equatable.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class CheckAuthSession extends AuthEvent {
  const CheckAuthSession();
}

class SignInWithGoogle extends AuthEvent {
  const SignInWithGoogle();
}

class SignInWithApple extends AuthEvent {
  const SignInWithApple();
}

class SignInWithEmail extends AuthEvent {
  const SignInWithEmail({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

class SignUpWithEmail extends AuthEvent {
  const SignUpWithEmail({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

class SignInAsGuest extends AuthEvent {
  const SignInAsGuest();
}

class SignOut extends AuthEvent {
  const SignOut();
}
