import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
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
  final FirebaseFirestore _firestore;

  FirebaseAuthDataSourceImpl({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

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

      // Actualizar lastLoginAt en Firestore
      await _updateLastLogin(firebaseUser.uid);

      // Obtener datos del usuario desde Firestore
      final userDoc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(firebaseUser.uid)
          .get();

      if (userDoc.exists) {
        return UserModel.fromFirestore(userDoc);
      } else {
        // Si no existe en Firestore, crear el documento
        final newUser = UserModel(
          id: firebaseUser.uid,
          email: firebaseUser.email!,
          name: firebaseUser.displayName ?? email.split('@')[0],
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          isEmailVerified: firebaseUser.emailVerified,
          photoUrl: firebaseUser.photoURL,
        );

        await _firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(firebaseUser.uid)
            .set(newUser.toFirestore());

        return newUser;
      }
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

      // Crear usuario en Firestore
      final newUser = UserModel(
        id: firebaseUser.uid,
        email: email,
        name: name,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        isEmailVerified: firebaseUser.emailVerified,
        photoUrl: firebaseUser.photoURL,
      );

      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(firebaseUser.uid)
          .set(newUser.toFirestore());

      return newUser;
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

      final userDoc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(firebaseUser.uid)
          .get();

      if (userDoc.exists) {
        return UserModel.fromFirestore(userDoc);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;

      try {
        final userDoc = await _firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(firebaseUser.uid)
            .get();

        if (userDoc.exists) {
          return UserModel.fromFirestore(userDoc);
        }
        return null;
      } catch (e) {
        return null;
      }
    });
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        // Eliminar datos de Firestore
        await _firestore
            .collection(FirebaseConstants.usersCollection)
            .doc(user.uid)
            .delete();

        // Eliminar cuenta de Firebase Auth
        await user.delete();
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw const UnknownAuthFailure();
    }
  }

  Future<void> _updateLastLogin(String userId) async {
    try {
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .update({'lastLoginAt': Timestamp.now()});
    } catch (e) {
      // No es crítico si falla
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