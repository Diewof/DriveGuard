import 'package:equatable/equatable.dart';
import 'user.dart';

class AuthResult extends Equatable {
  final User? user;
  final bool isNewUser;
  final String? message;
  final String? errorMessage;
  final bool isSuccess;

  const AuthResult({
    this.user,
    this.isNewUser = false,
    this.message,
    this.errorMessage,
    this.isSuccess = false,
  });

  @override
  List<Object?> get props => [user, isNewUser, message, errorMessage, isSuccess];
}