import 'package:dartz/dartz.dart';
import '../../core/errors/auth_failures.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/local/auth_local_datasource.dart';
import '../datasources/remote/firebase_auth_datasource.dart';
import '../models/auth_result_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<AuthFailure, AuthResult>> login({
    required String email,
    required String password,
  }) async {
    try {
      final user = await remoteDataSource.login(
        email: email,
        password: password,
      );

      // Cache user locally
      await localDataSource.cacheUser(user);

      final authResult = AuthResultModel.create(
        user: user,
        isNewUser: false,
        message: 'Inicio de sesión exitoso',
      );

      return Right(authResult);
    } on AuthFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return const Left(UnknownAuthFailure());
    }
  }

  @override
  Future<Either<AuthFailure, AuthResult>> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final user = await remoteDataSource.register(
        email: email,
        password: password,
        name: name,
      );

      // Cache user locally
      await localDataSource.cacheUser(user);

      final authResult = AuthResultModel.create(
        user: user,
        isNewUser: true,
        message: 'Cuenta creada exitosamente',
      );

      return Right(authResult);
    } on AuthFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return const Left(UnknownAuthFailure());
    }
  }

  @override
  Future<Either<AuthFailure, void>> logout() async {
    try {
      await remoteDataSource.logout();
      await localDataSource.clearCache();
      return const Right(null);
    } on AuthFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return const Left(UnknownAuthFailure());
    }
  }

  @override
  Future<Either<AuthFailure, void>> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      await remoteDataSource.sendPasswordResetEmail(email: email);
      return const Right(null);
    } on AuthFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return const Left(UnknownAuthFailure());
    }
  }

  @override
  Future<Either<AuthFailure, User?>> getCurrentUser() async {
    try {
      final user = await remoteDataSource.getCurrentUser();
      return Right(user);
    } on AuthFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return const Left(UnknownAuthFailure());
    }
  }

  @override
  Stream<User?> get authStateChanges {
    return remoteDataSource.authStateChanges;
  }

  @override
  Future<Either<AuthFailure, void>> deleteAccount() async {
    try {
      await remoteDataSource.deleteAccount();
      await localDataSource.clearCache();
      return const Right(null);
    } on AuthFailure catch (failure) {
      return Left(failure);
    } catch (e) {
      return const Left(UnknownAuthFailure());
    }
  }
}