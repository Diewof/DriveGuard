import '../entities/auth_result.dart';
import '../entities/emergency_contact.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<AuthResult> login({
    required String email,
    required String password,
  });

  Future<AuthResult> register({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
    required String address,
    required int age,
    required List<EmergencyContact> emergencyContacts,
  });

  Future<void> logout();

  Future<void> sendPasswordResetEmail({
    required String email,
  });

  Future<User?> getCurrentUser();

  Stream<User?> get authStateChanges;

  Future<void> deleteAccount();
}