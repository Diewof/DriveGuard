import '../repositories/auth_repository.dart';

class ForgotPasswordUseCase {
  final AuthRepository repository;

  ForgotPasswordUseCase(this.repository);

  Future<void> call({
    required String email,
  }) async {
    return await repository.sendPasswordResetEmail(
      email: email.trim().toLowerCase(),
    );
  }
}