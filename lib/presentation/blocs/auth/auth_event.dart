import 'package:equatable/equatable.dart';
import '../../../domain/entities/emergency_contact.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  final bool rememberMe;

  const AuthLoginRequested({
    required this.email,
    required this.password,
    this.rememberMe = false,
  });

  @override
  List<Object?> get props => [email, password, rememberMe];
}

class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String name;
  final String phoneNumber;
  final String address;
  final int age;
  final List<EmergencyContact> emergencyContacts;

  const AuthRegisterRequested({
    required this.email,
    required this.password,
    required this.name,
    required this.phoneNumber,
    required this.address,
    required this.age,
    required this.emergencyContacts,
  });

  @override
  List<Object?> get props => [
        email,
        password,
        name,
        phoneNumber,
        address,
        age,
        emergencyContacts,
      ];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthForgotPasswordRequested extends AuthEvent {
  final String email;

  const AuthForgotPasswordRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

class AuthDeleteAccountRequested extends AuthEvent {}

class AuthStateChanged extends AuthEvent {
  final dynamic user;

  const AuthStateChanged(this.user);

  @override
  List<Object?> get props => [user];
}