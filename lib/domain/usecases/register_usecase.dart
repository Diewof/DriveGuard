import '../entities/auth_result.dart';
import '../entities/emergency_contact.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<AuthResult> call({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
    required String address,
    required int age,
    required List<EmergencyContact> emergencyContacts,
  }) async {
    return await repository.register(
      email: email.trim().toLowerCase(),
      password: password,
      name: name.trim(),
      phoneNumber: phoneNumber.trim(),
      address: address.trim(),
      age: age,
      emergencyContacts: emergencyContacts,
    );
  }
}