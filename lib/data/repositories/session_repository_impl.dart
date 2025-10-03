import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../../domain/entities/driving_session.dart';
import '../../domain/entities/session_event.dart';
import '../../domain/repositories/session_repository.dart';
import '../models/driving_session_model.dart';
import '../models/session_event_model.dart';

class SessionRepositoryImpl implements SessionRepository {
  final FirebaseFirestore _firestore;

  SessionRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Either<Failure, String>> startSession({
    required String userId,
    required String deviceId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final now = DateTime.now();
      final session = DrivingSessionModel(
        userId: userId,
        deviceId: deviceId,
        startTime: now,
        startLocation: GeoPoint(latitude, longitude),
        totalDistance: 0.0,
        averageSpeed: 0.0,
        maxSpeed: 0.0,
        riskScore: 0.0,
        status: SessionStatus.active.value,
        dailyStats: DailyStatsModel(
          date: now.toIso8601String().split('T')[0],
          totalDrivingTime: 0,
          distractionCount: 0,
          recklessCount: 0,
          emergencyCount: 0,
          totalAlerts: 0,
          averageRiskScore: 0.0,
        ),
      );

      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('driving_sessions')
          .add(session.toMap());

      return Right(docRef.id);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DrivingSession>> endSession({
    required String sessionId,
    required String userId,
    required double endLatitude,
    required double endLongitude,
  }) async {
    try {
      final sessionRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('driving_sessions')
          .doc(sessionId);

      final sessionDoc = await sessionRef.get();
      if (!sessionDoc.exists) {
        return Left(ServerFailure('Session not found'));
      }

      final sessionData = sessionDoc.data()!;
      final startTime = (sessionData['startTime'] as Timestamp).toDate();
      final endTime = DateTime.now();
      final totalDrivingTime = endTime.difference(startTime).inSeconds;

      // Calcular distancia aproximada basada en el tiempo (simulado)
      final totalDistance = _calculateDistance(
        sessionData['startLocation'] as GeoPoint,
        GeoPoint(endLatitude, endLongitude),
        totalDrivingTime,
      );

      // Calcular velocidades basadas en datos simulados
      final averageSpeed = totalDrivingTime > 0 ? (totalDistance / (totalDrivingTime / 3600)) : 0.0;
      final maxSpeed = averageSpeed * 1.5; // Simulación de velocidad máxima

      // Calcular puntuación de riesgo basada en eventos
      final dailyStats = sessionData['dailyStats'] as Map<String, dynamic>;
      final totalAlerts = dailyStats['totalAlerts'] ?? 0;
      final riskScore = _calculateRiskScore(totalAlerts, totalDrivingTime);

      final updatedData = {
        'endTime': Timestamp.fromDate(endTime),
        'endLocation': GeoPoint(endLatitude, endLongitude),
        'status': SessionStatus.completed.value,
        'totalDistance': totalDistance,
        'averageSpeed': averageSpeed,
        'maxSpeed': maxSpeed,
        'riskScore': riskScore,
        'dailyStats.totalDrivingTime': totalDrivingTime,
        'dailyStats.averageRiskScore': riskScore,
      };

      await sessionRef.update(updatedData);

      final updatedDoc = await sessionRef.get();
      final session = DrivingSessionModel.fromMap(updatedDoc.data()!, sessionId);

      return Right(session);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addSessionEvent({
    required String sessionId,
    required String userId,
    required String eventType,
    required String severity,
    required String description,
    required double latitude,
    required double longitude,
    required Map<String, double> sensorData,
  }) async {
    try {
      final event = SessionEventModel(
        sessionId: sessionId,
        userId: userId,
        timestamp: DateTime.now(),
        eventType: eventType,
        severity: severity,
        description: description,
        location: GeoPoint(latitude, longitude),
        sensorSnapshot: SensorSnapshotModel(
          accelX: sensorData['accelX'] ?? 0.0,
          accelY: sensorData['accelY'] ?? 0.0,
          accelZ: sensorData['accelZ'] ?? 0.0,
          gyroX: sensorData['gyroX'] ?? 0.0,
          gyroY: sensorData['gyroY'] ?? 0.0,
          gyroZ: sensorData['gyroZ'] ?? 0.0,
        ),
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('driving_sessions')
          .doc(sessionId)
          .collection('session_events')
          .add(event.toMap());

      await _updateSessionEventCounts(sessionId, userId, eventType);

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<void> _updateSessionEventCounts(
      String sessionId, String userId, String eventType) async {
    final sessionRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('driving_sessions')
        .doc(sessionId);

    await _firestore.runTransaction((transaction) async {
      final sessionDoc = await transaction.get(sessionRef);
      if (!sessionDoc.exists) return;

      final data = sessionDoc.data()!;
      final dailyStats = data['dailyStats'] as Map<String, dynamic>;

      int distractionCount = dailyStats['distractionCount'] ?? 0;
      int recklessCount = dailyStats['recklessCount'] ?? 0;
      int emergencyCount = dailyStats['emergencyCount'] ?? 0;
      int totalAlerts = dailyStats['totalAlerts'] ?? 0;

      switch (eventType) {
        case 'DISTRACTION':
          distractionCount++;
          break;
        case 'RECKLESS_DRIVING':
          recklessCount++;
          break;
        case 'EMERGENCY':
          emergencyCount++;
          break;
      }
      totalAlerts++;

      transaction.update(sessionRef, {
        'dailyStats.distractionCount': distractionCount,
        'dailyStats.recklessCount': recklessCount,
        'dailyStats.emergencyCount': emergencyCount,
        'dailyStats.totalAlerts': totalAlerts,
      });
    });
  }

  @override
  Future<Either<Failure, DrivingSession>> updateSessionStats({
    required String sessionId,
    required String userId,
    required double totalDistance,
    required double averageSpeed,
    required double maxSpeed,
    required double riskScore,
  }) async {
    try {
      final sessionRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('driving_sessions')
          .doc(sessionId);

      await sessionRef.update({
        'totalDistance': totalDistance,
        'averageSpeed': averageSpeed,
        'maxSpeed': maxSpeed,
        'riskScore': riskScore,
        'dailyStats.averageRiskScore': riskScore,
      });

      final updatedDoc = await sessionRef.get();
      final session = DrivingSessionModel.fromMap(updatedDoc.data()!, sessionId);

      return Right(session);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DrivingSession>>> getUserSessions(
      String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('driving_sessions')
          .orderBy('startTime', descending: true)
          .get();

      final sessions = querySnapshot.docs
          .map((doc) => DrivingSessionModel.fromMap(doc.data(), doc.id))
          .toList();

      return Right(sessions);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DrivingSession>> getSessionById({
    required String sessionId,
    required String userId,
  }) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('driving_sessions')
          .doc(sessionId)
          .get();

      if (!doc.exists) {
        return Left(ServerFailure('Session not found'));
      }

      final session = DrivingSessionModel.fromMap(doc.data()!, sessionId);
      return Right(session);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SessionEvent>>> getSessionEvents({
    required String sessionId,
    required String userId,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('driving_sessions')
          .doc(sessionId)
          .collection('session_events')
          .orderBy('timestamp', descending: false)
          .get();

      final events = querySnapshot.docs
          .map((doc) => SessionEventModel.fromMap(doc.data(), doc.id))
          .toList();

      return Right(events);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DrivingSession?>> getActiveSession(
      String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('driving_sessions')
          .where('status', isEqualTo: SessionStatus.active.value)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return const Right(null);
      }

      final doc = querySnapshot.docs.first;
      final session = DrivingSessionModel.fromMap(doc.data(), doc.id);
      return Right(session);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DrivingSession>>> getSessionsByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('driving_sessions')
          .where('startTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('startTime', descending: true)
          .get();

      final sessions = querySnapshot.docs
          .map((doc) => DrivingSessionModel.fromMap(doc.data(), doc.id))
          .toList();

      return Right(sessions);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // Métodos auxiliares para cálculos

  double _calculateDistance(GeoPoint start, GeoPoint end, int drivingTimeSeconds) {
    // Cálculo simple de distancia usando fórmula de Haversine
    const double earthRadius = 6371; // Radio de la Tierra en km

    final double lat1Rad = start.latitude * (3.14159 / 180);
    final double lat2Rad = end.latitude * (3.14159 / 180);
    final double deltaLatRad = (end.latitude - start.latitude) * (3.14159 / 180);
    final double deltaLonRad = (end.longitude - start.longitude) * (3.14159 / 180);

    final double a = (sin(deltaLatRad / 2) * sin(deltaLatRad / 2)) +
        (cos(lat1Rad) * cos(lat2Rad) * sin(deltaLonRad / 2) * sin(deltaLonRad / 2));
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    double directDistance = earthRadius * c;

    // Si la distancia directa es muy pequeña, simular una distancia más realista
    // basada en el tiempo de conducción
    if (directDistance < 1.0 && drivingTimeSeconds > 300) { // 5 minutos
      // Simular velocidad promedio de ciudad (30 km/h)
      directDistance = (drivingTimeSeconds / 3600.0) * 30.0;
    }

    return directDistance;
  }

  double _calculateRiskScore(int totalAlerts, int drivingTimeSeconds) {
    if (drivingTimeSeconds == 0) return 0.0;

    // Calcular puntuación base según eventos por minuto
    final double alertsPerMinute = totalAlerts / (drivingTimeSeconds / 60.0);
    double riskScore = 0.0;

    if (alertsPerMinute < 0.1) {
      riskScore = 15.0; // Muy bajo riesgo
    } else if (alertsPerMinute < 0.3) {
      riskScore = 35.0; // Riesgo moderado
    } else if (alertsPerMinute < 0.5) {
      riskScore = 60.0; // Riesgo alto
    } else {
      riskScore = 85.0; // Riesgo muy alto
    }

    // Ajustar por duración del viaje
    if (drivingTimeSeconds < 300) { // Menos de 5 minutos
      riskScore *= 0.8; // Reducir score para viajes muy cortos
    }

    return riskScore.clamp(0.0, 100.0);
  }

  double sin(double x) => math.sin(x);
  double cos(double x) => math.cos(x);
  double sqrt(double x) => math.sqrt(x);
  double atan2(double y, double x) => math.atan2(y, x);
}