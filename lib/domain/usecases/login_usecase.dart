import '../entities/auth_result.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<AuthResult> call({
    required String email,
    required String password,
  }) async {
    return await repository.login(
      email: email.trim().toLowerCase(),
      password: password,
    );
  }
}