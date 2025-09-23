import 'package:dartz/dartz.dart';
import '../../core/errors/auth_failures.dart';
import '../entities/auth_result.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<AuthFailure, AuthResult>> login({
    required String email,
    required String password,
  });

  Future<Either<AuthFailure, AuthResult>> register({
    required String email,
    required String password,
    required String name,
  });

  Future<Either<AuthFailure, void>> logout();

  Future<Either<AuthFailure, void>> sendPasswordResetEmail({
    required String email,
  });

  Future<Either<AuthFailure, User?>> getCurrentUser();

  Stream<User?> get authStateChanges;

  Future<Either<AuthFailure, void>> deleteAccount();
}