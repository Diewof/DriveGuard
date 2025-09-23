import 'package:dartz/dartz.dart';
import '../../core/errors/auth_failures.dart';
import '../entities/auth_result.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<Either<AuthFailure, AuthResult>> call({
    required String email,
    required String password,
  }) async {
    return await repository.login(
      email: email.trim().toLowerCase(),
      password: password,
    );
  }
}