import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/get_current_user_usecase.dart';
import '../../../domain/usecases/login_usecase.dart';
import '../../../domain/usecases/logout_usecase.dart';
import '../../../domain/usecases/register_usecase.dart';
import '../../../domain/usecases/forgot_password_usecase.dart';
import '../../../core/errors/auth_failures.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final LogoutUseCase _logoutUseCase;
  final ForgotPasswordUseCase _forgotPasswordUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;

  StreamSubscription<dynamic>? _authStateSubscription;

  AuthBloc({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required LogoutUseCase logoutUseCase,
    required ForgotPasswordUseCase forgotPasswordUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
  })  : _loginUseCase = loginUseCase,
        _registerUseCase = registerUseCase,
        _logoutUseCase = logoutUseCase,
        _forgotPasswordUseCase = forgotPasswordUseCase,
        _getCurrentUserUseCase = getCurrentUserUseCase,
        super(const AuthState()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthRegisterRequested>(_onAuthRegisterRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthForgotPasswordRequested>(_onAuthForgotPasswordRequested);
    on<AuthStateChanged>(_onAuthStateChanged);

    // Escuchar cambios en el estado de autenticación
    _authStateSubscription = _getCurrentUserUseCase.authStateChanges.listen(
      (user) => add(AuthStateChanged(user)),
    );
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      final user = await _getCurrentUserUseCase();
      emit(state.copyWith(
        status: user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated,
        user: user,
      ));
    } on AuthFailure catch (failure) {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        user: null,
        errorMessage: failure.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        user: null,
        errorMessage: 'Error desconocido',
      ));
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      final authResult = await _loginUseCase(
        email: event.email,
        password: event.password,
      );

      if (authResult.isSuccess && authResult.user != null) {
        emit(state.copyWith(
          status: AuthStatus.authenticated,
          user: authResult.user,
          successMessage: authResult.message,
        ));
      } else {
        emit(state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: authResult.errorMessage ?? 'Error de autenticación',
        ));
      }
    } on AuthFailure catch (failure) {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: failure.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Error desconocido',
      ));
    }
  }

  Future<void> _onAuthRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      final authResult = await _registerUseCase(
        email: event.email,
        password: event.password,
        name: event.name,
        phoneNumber: event.phoneNumber,
        address: event.address,
        age: event.age,
        emergencyContacts: event.emergencyContacts,
      );

      if (authResult.isSuccess && authResult.user != null) {
        emit(state.copyWith(
          status: AuthStatus.authenticated,
          user: authResult.user,
          successMessage: authResult.message,
        ));
      } else {
        emit(state.copyWith(
          status: AuthStatus.unauthenticated,
          errorMessage: authResult.errorMessage ?? 'Error de registro',
        ));
      }
    } on AuthFailure catch (failure) {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: failure.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Error desconocido',
      ));
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      await _logoutUseCase();
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        user: null,
        successMessage: 'Sesión cerrada exitosamente',
      ));
    } on AuthFailure catch (failure) {
      emit(state.copyWith(
        errorMessage: failure.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Error al cerrar sesión',
      ));
    }
  }

  Future<void> _onAuthForgotPasswordRequested(
    AuthForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      await _forgotPasswordUseCase(email: event.email);
      emit(state.copyWith(
        status: state.user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated,
        successMessage: 'Email de recuperación enviado',
      ));
    } on AuthFailure catch (failure) {
      emit(state.copyWith(
        status: state.user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated,
        errorMessage: failure.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: state.user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated,
        errorMessage: 'Error al enviar email de recuperación',
      ));
    }
  }

  void _onAuthStateChanged(
    AuthStateChanged event,
    Emitter<AuthState> emit,
  ) {
    final user = event.user;
    if (user != null) {
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      ));
    } else {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        user: null,
      ));
    }
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}