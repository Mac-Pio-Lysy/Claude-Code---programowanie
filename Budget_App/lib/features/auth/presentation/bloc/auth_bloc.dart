import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/auth_exception.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repository) : super(const AuthInitial()) {
    on<CheckAuthSession>(_onCheckSession);
    on<SignInWithGoogle>((event, emit) => _guarded(emit, _repository.signInWithGoogle));
    on<SignInWithApple>((event, emit) => _guarded(emit, _repository.signInWithApple));
    on<SignInAsGuest>((event, emit) => _guarded(emit, _repository.signInAsGuest));
    on<SignInWithEmail>(_onSignInWithEmail);
    on<SignUpWithEmail>(_onSignUpWithEmail);
    on<SignOut>(_onSignOut);
  }

  final AuthRepository _repository;

  Future<void> _onCheckSession(CheckAuthSession event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final user = await _repository.getCurrentUser();
    emit(user != null ? Authenticated(user) : const Unauthenticated());
  }

  Future<void> _onSignInWithEmail(SignInWithEmail event, Emitter<AuthState> emit) {
    return _guarded(
      emit,
      () => _repository.signInWithEmail(email: event.email, password: event.password),
    );
  }

  Future<void> _onSignUpWithEmail(SignUpWithEmail event, Emitter<AuthState> emit) {
    return _guarded(
      emit,
      () => _repository.signUpWithEmail(email: event.email, password: event.password),
    );
  }

  Future<void> _onSignOut(SignOut event, Emitter<AuthState> emit) async {
    await _repository.signOut();
    emit(const Unauthenticated());
  }

  Future<void> _guarded(
    Emitter<AuthState> emit,
    Future<AuthUser> Function() action,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await action();
      emit(Authenticated(user));
    } on AuthException catch (e) {
      emit(AuthFailure(e.message));
    } catch (_) {
      emit(const AuthFailure('Coś poszło nie tak. Spróbuj ponownie.'));
    }
  }
}
