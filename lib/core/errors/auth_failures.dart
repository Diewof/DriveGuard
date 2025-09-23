import 'package:equatable/equatable.dart';

abstract class AuthFailure extends Equatable {
  final String message;

  const AuthFailure(this.message);

  @override
  List<Object> get props => [message];
}

class InvalidEmailFailure extends AuthFailure {
  const InvalidEmailFailure() : super('El email ingresado no es válido');
}

class WrongPasswordFailure extends AuthFailure {
  const WrongPasswordFailure() : super('La contraseña es incorrecta');
}

class UserNotFoundFailure extends AuthFailure {
  const UserNotFoundFailure() : super('No existe una cuenta con este email');
}

class EmailAlreadyInUseFailure extends AuthFailure {
  const EmailAlreadyInUseFailure() : super('Ya existe una cuenta con este email');
}

class WeakPasswordFailure extends AuthFailure {
  const WeakPasswordFailure() : super('La contraseña debe tener al menos 6 caracteres');
}

class UserDisabledFailure extends AuthFailure {
  const UserDisabledFailure() : super('Esta cuenta ha sido deshabilitada');
}

class TooManyRequestsFailure extends AuthFailure {
  const TooManyRequestsFailure() : super('Demasiados intentos. Intenta más tarde');
}

class NetworkRequestFailure extends AuthFailure {
  const NetworkRequestFailure() : super('Error de conexión. Verifica tu internet');
}

class UnknownAuthFailure extends AuthFailure {
  const UnknownAuthFailure() : super('Error desconocido. Intenta nuevamente');
}