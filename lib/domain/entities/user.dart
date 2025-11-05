import 'package:equatable/equatable.dart';
import 'emergency_contact.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? phoneNumber;
  final String? address;
  final int? age;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isEmailVerified;
  final String? photoUrl;
  final List<EmergencyContact>? emergencyContacts;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.phoneNumber,
    this.address,
    this.age,
    required this.createdAt,
    this.lastLoginAt,
    this.isEmailVerified = false,
    this.photoUrl,
    this.emergencyContacts,
  });

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? phoneNumber,
    String? address,
    int? age,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isEmailVerified,
    String? photoUrl,
    List<EmergencyContact>? emergencyContacts,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      age: age ?? this.age,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      photoUrl: photoUrl ?? this.photoUrl,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        phoneNumber,
        address,
        age,
        createdAt,
        lastLoginAt,
        isEmailVerified,
        photoUrl,
        emergencyContacts,
      ];
}