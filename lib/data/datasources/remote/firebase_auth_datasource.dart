import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../../core/errors/auth_failures.dart';
import '../../models/user_model.dart';

abstract class FirebaseAuthDataSource {
  Future<UserModel> login({
    required String email,
    required String password,
  });

  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
  });

  Future<void> logout();

  Future<void> sendPasswordResetEmail({
    required String email,
  });

  Future<UserModel?> getCurrentUser();

  Stream<UserModel?> get authStateChanges;

  Future<void> deleteAccount();
}

class FirebaseAuthDataSourceImpl implements FirebaseAuthDataSource {
  final firebase_auth.FirebaseAuth _firebaseAuth;

  FirebaseAuthDataSourceImpl({
    firebase_auth.FirebaseAuth? firebaseAuth,
  }) : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance;

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw const UnknownAuthFailure();
      }

      return UserModel(
        id: firebaseUser.uid,
        email: firebaseUser.email!,
        name: firebaseUser.displayName ?? email.split('@')[0],
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        isEmailVerified: firebaseUser.emailVerified,
        photoUrl: firebaseUser.photoURL,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw const UnknownAuthFailure();
    }
  }

  @override
  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw const UnknownAuthFailure();
      }

      // Actualizar el displayName
      await firebaseUser.updateDisplayName(name);

      return UserModel(
        id: firebaseUser.uid,
        email: email,
        name: name,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        isEmailVerified: firebaseUser.emailVerified,
        photoUrl: firebaseUser.photoURL,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw const UnknownAuthFailure();
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw const UnknownAuthFailure();
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw const UnknownAuthFailure();
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) return null;

      return UserModel(
        id: firebaseUser.uid,
        email: firebaseUser.email!,
        name: firebaseUser.displayName ?? firebaseUser.email!.split('@')[0],
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        isEmailVerified: firebaseUser.emailVerified,
        photoUrl: firebaseUser.photoURL,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      if (firebaseUser == null) return null;

      return UserModel(
        id: firebaseUser.uid,
        email: firebaseUser.email!,
        name: firebaseUser.displayName ?? firebaseUser.email!.split('@')[0],
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        isEmailVerified: firebaseUser.emailVerified,
        photoUrl: firebaseUser.photoURL,
      );
    });
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.delete();
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw const UnknownAuthFailure();
    }
  }

  AuthFailure _mapFirebaseException(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return const InvalidEmailFailure();
      case 'wrong-password':
        return const WrongPasswordFailure();
      case 'user-not-found':
        return const UserNotFoundFailure();
      case 'email-already-in-use':
        return const EmailAlreadyInUseFailure();
      case 'weak-password':
        return const WeakPasswordFailure();
      case 'user-disabled':
        return const UserDisabledFailure();
      case 'too-many-requests':
        return const TooManyRequestsFailure();
      case 'network-request-failed':
        return const NetworkRequestFailure();
      default:
        return const UnknownAuthFailure();
    }
  }
}