import 'package:equatable/equatable.dart';
import '../../../domain/entities/user.dart';

enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated,
  loading
}

class AuthState extends Equatable {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;
  final String? successMessage;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.errorMessage,
    this.successMessage,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;
  bool get isLoading => status == AuthStatus.loading;
  bool get isUnknown => status == AuthStatus.unknown;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
    String? successMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  AuthState clearMessages() {
    return copyWith(
      errorMessage: null,
      successMessage: null,
    );
  }

  @override
  List<Object?> get props => [status, user, errorMessage, successMessage];
}