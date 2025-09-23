import 'package:dartz/dartz.dart';
import '../../core/errors/auth_failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class GetCurrentUserUseCase {
  final AuthRepository repository;

  GetCurrentUserUseCase(this.repository);

  Future<Either<AuthFailure, User?>> call() async {
    return await repository.getCurrentUser();
  }

  Stream<User?> get authStateChanges => repository.authStateChanges;
}