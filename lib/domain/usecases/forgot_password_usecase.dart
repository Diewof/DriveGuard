import 'package:dartz/dartz.dart';
import '../../core/errors/auth_failures.dart';
import '../repositories/auth_repository.dart';

class ForgotPasswordUseCase {
  final AuthRepository repository;

  ForgotPasswordUseCase(this.repository);

  Future<Either<AuthFailure, void>> call({
    required String email,
  }) async {
    return await repository.sendPasswordResetEmail(
      email: email.trim().toLowerCase(),
    );
  }
}