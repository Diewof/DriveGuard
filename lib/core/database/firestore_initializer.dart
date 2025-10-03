import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Script para inicializar la estructura de base de datos en Firestore
/// Ejecutar desde main.dart temporal o desde un script separado
class FirestoreInitializer {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Método principal para ejecutar la inicialización
  Future<void> initializeDatabase() async {
    print('🚀 Iniciando creación de estructura de base de datos...');

    try {
      // 1. Crear usuario de prueba
      final userId = await _createTestUser();

      // 2. Crear contactos de emergencia
      await _createEmergencyContacts(userId);

      // 3. Crear sesión de conducción
      final sessionId = await _createDrivingSession(userId);

      // 4. Crear eventos de sesión
      await _createSessionEvents(sessionId, userId);

      print('✅ Base de datos inicializada correctamente');
      print('📋 Usuario de prueba: test@driveguard.com / password123');

    } catch (e) {
      print('❌ Error al inicializar base de datos: $e');
      rethrow;
    }
  }

  /// Crear usuario de prueba en Authentication y Firestore
  Future<String> _createTestUser() async {
    print('👤 Creando usuario de prueba...');

    try {
      // Crear en Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: 'test@driveguard.com',
        password: 'password123',
      );

      final userId = userCredential.user!.uid;

      // Crear documento en Firestore
      await _firestore.collection('users').doc(userId).set({
        'email': 'test@driveguard.com',
        'name': 'Juan Pérez',
        'phoneNumber': '+573001234567',
        'address': 'Calle 123 #45-67, Medellín',
        'age': 30,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'photoUrl': '',
      });

      print('✓ Usuario creado con ID: $userId');
      return userId;

    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        // Si el usuario ya existe, obtener su ID
        print('⚠️  Usuario ya existe, obteniendo ID existente...');
        final user = await _auth.signInWithEmailAndPassword(
          email: 'test@driveguard.com',
          password: 'password123',
        );
        return user.user!.uid;
      }
      rethrow;
    }
  }

  /// Crear contactos de emergencia
  Future<void> _createEmergencyContacts(String userId) async {
    print('📞 Creando contactos de emergencia...');

    try {
      final contacts = [
        {
          'userId': userId,
          'name': 'María García',
          'phoneNumber': '+573009876543',
          'relationship': 'Esposa',
          'priority': 1,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'userId': userId,
          'name': 'Pedro Rodríguez',
          'phoneNumber': '+573005551234',
          'relationship': 'Hermano',
          'priority': 2,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        },
      ];

      int count = 0;
      for (var contact in contacts) {
        final docRef = await _firestore
            .collection('users')
            .doc(userId)
            .collection('emergency_contacts')
            .add(contact);
        count++;
        print('  ✓ Contacto ${count} creado: ${docRef.id}');
      }

      print('✓ ${contacts.length} contactos de emergencia creados');
    } catch (e) {
      print('❌ Error al crear contactos: $e');
      rethrow;
    }
  }

  /// Crear sesión de conducción
  Future<String> _createDrivingSession(String userId) async {
    print('🚗 Creando sesión de conducción...');

    final sessionRef = await _firestore
        .collection('users')
        .doc(userId)
        .collection('driving_sessions')
        .add({
      'userId': userId,
      'deviceId': 'ESP32-001',
      'startTime': Timestamp.fromDate(DateTime.now().subtract(Duration(hours: 1))),
      'endTime': null, // Sesión activa
      'startLocation': GeoPoint(6.2442, -75.5812), // Medellín
      'endLocation': null,
      'totalDistance': 15.5,
      'averageSpeed': 45.2,
      'maxSpeed': 80.0,
      'riskScore': 35.0,
      'status': 'ACTIVE',
      'dailyStats': {
        'date': DateTime.now().toIso8601String().split('T')[0],
        'totalDrivingTime': 3600, // 1 hora en segundos
        'distractionCount': 3,
        'recklessCount': 1,
        'emergencyCount': 0,
        'totalAlerts': 4,
        'averageRiskScore': 35.0,
      },
    });

    print('✓ Sesión creada con ID: ${sessionRef.id}');
    return sessionRef.id;
  }

  /// Crear eventos de sesión
  Future<void> _createSessionEvents(String sessionId, String userId) async {
    print('⚠️  Creando eventos de sesión...');

    final events = [
      {
        'sessionId': sessionId,
        'userId': userId,
        'timestamp': Timestamp.fromDate(DateTime.now().subtract(Duration(minutes: 45))),
        'eventType': 'DISTRACTION',
        'severity': 'MEDIUM',
        'description': 'Conductor mirando el celular',
        'location': GeoPoint(6.2442, -75.5812),
        'sensorSnapshot': {
          'accelX': -0.5,
          'accelY': 2.3,
          'accelZ': 9.8,
          'gyroX': 15.2,
          'gyroY': -5.7,
          'gyroZ': 8.1,
        },
      },
      {
        'sessionId': sessionId,
        'userId': userId,
        'timestamp': Timestamp.fromDate(DateTime.now().subtract(Duration(minutes: 30))),
        'eventType': 'RECKLESS_DRIVING',
        'severity': 'HIGH',
        'description': 'Giro brusco detectado',
        'location': GeoPoint(6.2450, -75.5820),
        'sensorSnapshot': {
          'accelX': -3.2,
          'accelY': 4.8,
          'accelZ': 10.5,
          'gyroX': 55.3,
          'gyroY': -45.2,
          'gyroZ': 60.8,
        },
      },
      {
        'sessionId': sessionId,
        'userId': userId,
        'timestamp': Timestamp.fromDate(DateTime.now().subtract(Duration(minutes: 15))),
        'eventType': 'DISTRACTION',
        'severity': 'LOW',
        'description': 'Desvío de mirada breve',
        'location': GeoPoint(6.2455, -75.5825),
        'sensorSnapshot': {
          'accelX': -0.3,
          'accelY': 1.2,
          'accelZ': 9.9,
          'gyroX': 8.5,
          'gyroY': -3.2,
          'gyroZ': 5.7,
        },
      },
    ];

    final batch = _firestore.batch();
    final sessionRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('driving_sessions')
        .doc(sessionId);

    for (var event in events) {
      final eventRef = sessionRef.collection('session_events').doc();
      batch.set(eventRef, event);
    }

    await batch.commit();
    print('✓ ${events.length} eventos creados');
  }

  /// Método para limpiar toda la base de datos (usar con precaución)
  Future<void> clearDatabase() async {
    print('🗑️  Limpiando base de datos...');

    try {
      // Eliminar usuario de prueba
      final userSnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: 'test@driveguard.com')
          .get();

      for (var doc in userSnapshot.docs) {
        await _deleteUserAndSubcollections(doc.id);
      }

      // Eliminar de Authentication
      try {
        final user = await _auth.signInWithEmailAndPassword(
          email: 'test@driveguard.com',
          password: 'password123',
        );
        await user.user?.delete();
      } catch (e) {
        print('⚠️  Usuario no encontrado en Authentication');
      }

      print('✅ Base de datos limpiada');

    } catch (e) {
      print('❌ Error al limpiar base de datos: $e');
    }
  }

  /// Método auxiliar para eliminar usuario y todas sus subcolecciones
  Future<void> _deleteUserAndSubcollections(String userId) async {
    final userRef = _firestore.collection('users').doc(userId);

    // Eliminar emergency_contacts
    final contactsSnapshot = await userRef.collection('emergency_contacts').get();
    for (var doc in contactsSnapshot.docs) {
      await doc.reference.delete();
    }

    // Eliminar driving_sessions y sus eventos
    final sessionsSnapshot = await userRef.collection('driving_sessions').get();
    for (var sessionDoc in sessionsSnapshot.docs) {
      // Eliminar session_events
      final eventsSnapshot = await sessionDoc.reference.collection('session_events').get();
      for (var eventDoc in eventsSnapshot.docs) {
        await eventDoc.reference.delete();
      }
      await sessionDoc.reference.delete();
    }

    // Eliminar usuario
    await userRef.delete();
  }
}

/// Función helper para ejecutar desde main.dart
Future<void> runFirestoreInitialization() async {
  final initializer = FirestoreInitializer();

  // Opcional: limpiar datos anteriores
  // await initializer.clearDatabase();

  // Crear estructura nueva
  await initializer.initializeDatabase();
}