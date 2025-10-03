import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../../core/errors/auth_failures.dart';
import '../../../domain/entities/emergency_contact.dart';
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
    required String phoneNumber,
    required String address,
    required int age,
    required List<EmergencyContact> emergencyContacts,
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

      // Obtener datos adicionales de Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (!userDoc.exists) {
        // Si no existe el documento, crear uno básico
        return UserModel(
          id: firebaseUser.uid,
          email: firebaseUser.email!,
          name: firebaseUser.displayName ?? email.split('@')[0],
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          isEmailVerified: firebaseUser.emailVerified,
          photoUrl: firebaseUser.photoURL,
        );
      }

      final data = userDoc.data()!;
      return UserModel(
        id: firebaseUser.uid,
        email: firebaseUser.email!,
        name: data['name'] ?? firebaseUser.displayName ?? email.split('@')[0],
        phoneNumber: data['phoneNumber'],
        address: data['address'],
        age: data['age'],
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        lastLoginAt: DateTime.now(),
        isEmailVerified: firebaseUser.emailVerified,
        photoUrl: data['photoUrl'] ?? firebaseUser.photoURL,
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
    required String phoneNumber,
    required String address,
    required int age,
    required List<EmergencyContact> emergencyContacts,
  }) async {
    try {
      // 1. Crear usuario en Firebase Authentication
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw const UnknownAuthFailure();
      }

      // 2. Actualizar el displayName
      await firebaseUser.updateDisplayName(name);

      final userId = firebaseUser.uid;
      final now = Timestamp.now();

      // 3. Crear documento del usuario en Firestore
      await _firestore.collection('users').doc(userId).set({
        'email': email,
        'name': name,
        'phoneNumber': phoneNumber,
        'address': address,
        'age': age,
        'createdAt': now,
        'updatedAt': now,
        'isActive': true,
        'photoUrl': '',
      });

      // 4. Crear subcolección de contactos de emergencia
      final batch = _firestore.batch();
      for (var contact in emergencyContacts) {
        final contactRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('emergency_contacts')
            .doc();

        batch.set(contactRef, {
          'userId': userId,
          'name': contact.name,
          'phoneNumber': contact.phoneNumber,
          'relationship': contact.relationship,
          'priority': contact.priority,
          'isActive': contact.isActive,
          'createdAt': now,
        });
      }
      await batch.commit();

      return UserModel(
        id: userId,
        email: email,
        name: name,
        phoneNumber: phoneNumber,
        address: address,
        age: age,
        createdAt: now.toDate(),
        lastLoginAt: now.toDate(),
        isEmailVerified: firebaseUser.emailVerified,
        photoUrl: '',
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _mapFirebaseException(e);
    } catch (e) {
      throw UnknownAuthFailure(message: 'Error al registrar: $e');
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

      // Obtener datos adicionales de Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (!userDoc.exists) {
        return UserModel(
          id: firebaseUser.uid,
          email: firebaseUser.email!,
          name: firebaseUser.displayName ?? firebaseUser.email!.split('@')[0],
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          isEmailVerified: firebaseUser.emailVerified,
          photoUrl: firebaseUser.photoURL,
        );
      }

      final data = userDoc.data()!;
      return UserModel(
        id: firebaseUser.uid,
        email: firebaseUser.email!,
        name: data['name'] ?? firebaseUser.displayName ?? firebaseUser.email!.split('@')[0],
        phoneNumber: data['phoneNumber'],
        address: data['address'],
        age: data['age'],
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        lastLoginAt: DateTime.now(),
        isEmailVerified: firebaseUser.emailVerified,
        photoUrl: data['photoUrl'] ?? firebaseUser.photoURL,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;

      // Obtener datos adicionales de Firestore
      try {
        final userDoc = await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .get();

        if (!userDoc.exists) {
          return UserModel(
            id: firebaseUser.uid,
            email: firebaseUser.email!,
            name: firebaseUser.displayName ?? firebaseUser.email!.split('@')[0],
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
            isEmailVerified: firebaseUser.emailVerified,
            photoUrl: firebaseUser.photoURL,
          );
        }

        final data = userDoc.data()!;
        return UserModel(
          id: firebaseUser.uid,
          email: firebaseUser.email!,
          name: data['name'] ?? firebaseUser.displayName ?? firebaseUser.email!.split('@')[0],
          phoneNumber: data['phoneNumber'],
          address: data['address'],
          age: data['age'],
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          lastLoginAt: DateTime.now(),
          isEmailVerified: firebaseUser.emailVerified,
          photoUrl: data['photoUrl'] ?? firebaseUser.photoURL,
        );
      } catch (e) {
        return UserModel(
          id: firebaseUser.uid,
          email: firebaseUser.email!,
          name: firebaseUser.displayName ?? firebaseUser.email!.split('@')[0],
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          isEmailVerified: firebaseUser.emailVerified,
          photoUrl: firebaseUser.photoURL,
        );
      }
    });
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        // Eliminar documento de Firestore
        await _firestore.collection('users').doc(user.uid).delete();

        // Eliminar cuenta de Authentication
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