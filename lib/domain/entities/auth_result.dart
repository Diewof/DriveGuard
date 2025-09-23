import 'package:equatable/equatable.dart';
import 'user.dart';

class AuthResult extends Equatable {
  final User user;
  final bool isNewUser;
  final String? message;

  const AuthResult({
    required this.user,
    this.isNewUser = false,
    this.message,
  });

  @override
  List<Object?> get props => [user, isNewUser, message];
}