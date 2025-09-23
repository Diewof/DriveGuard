import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isEmailVerified;
  final String? photoUrl;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.createdAt,
    this.lastLoginAt,
    this.isEmailVerified = false,
    this.photoUrl,
  });

  User copyWith({
    String? id,
    String? email,
    String? name,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isEmailVerified,
    String? photoUrl,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        createdAt,
        lastLoginAt,
        isEmailVerified,
        photoUrl,
      ];
}