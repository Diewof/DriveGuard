import '../../core/errors/auth_failures.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/entities/emergency_contact.dart';
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
  Future<AuthResult> login({
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

      return AuthResultModel.create(
        user: user,
        isNewUser: false,
        message: 'Inicio de sesión exitoso',
      );
    } on AuthFailure catch (failure) {
      return AuthResultModel.failure(failure.message);
    } catch (e) {
      return AuthResultModel.failure('Error desconocido');
    }
  }

  @override
  Future<AuthResult> register({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
    required String address,
    required int age,
    required List<EmergencyContact> emergencyContacts,
  }) async {
    try {
      final user = await remoteDataSource.register(
        email: email,
        password: password,
        name: name,
        phoneNumber: phoneNumber,
        address: address,
        age: age,
        emergencyContacts: emergencyContacts,
      );

      // Cache user locally
      await localDataSource.cacheUser(user);

      return AuthResultModel.create(
        user: user,
        isNewUser: true,
        message: 'Cuenta creada exitosamente',
      );
    } on AuthFailure catch (failure) {
      return AuthResultModel.failure(failure.message);
    } catch (e) {
      return AuthResultModel.failure('Error desconocido: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await remoteDataSource.logout();
      await localDataSource.clearCache();
    } on AuthFailure {
      rethrow;
    } catch (e) {
      throw const UnknownAuthFailure();
    }
  }

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      await remoteDataSource.sendPasswordResetEmail(email: email);
    } on AuthFailure {
      rethrow;
    } catch (e) {
      throw const UnknownAuthFailure();
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      return await remoteDataSource.getCurrentUser();
    } on AuthFailure {
      rethrow;
    } catch (e) {
      throw const UnknownAuthFailure();
    }
  }

  @override
  Stream<User?> get authStateChanges {
    return remoteDataSource.authStateChanges;
  }

  @override
  Future<void> deleteAccount() async {
    try {
      await remoteDataSource.deleteAccount();
      await localDataSource.clearCache();
    } on AuthFailure {
      rethrow;
    } catch (e) {
      throw const UnknownAuthFailure();
    }
  }
}