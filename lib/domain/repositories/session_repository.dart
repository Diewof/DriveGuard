import 'package:dartz/dartz.dart';
import '../entities/driving_session.dart';
import '../entities/session_event.dart';
import '../../core/errors/failures.dart';

abstract class SessionRepository {
  Future<Either<Failure, String>> startSession({
    required String userId,
    required String deviceId,
    required double latitude,
    required double longitude,
  });

  Future<Either<Failure, DrivingSession>> endSession({
    required String sessionId,
    required String userId,
    required double endLatitude,
    required double endLongitude,
  });

  Future<Either<Failure, void>> addSessionEvent({
    required String sessionId,
    required String userId,
    required String eventType,
    required String severity,
    required String description,
    required double latitude,
    required double longitude,
    required Map<String, double> sensorData,
  });

  Future<Either<Failure, DrivingSession>> updateSessionStats({
    required String sessionId,
    required String userId,
    required double totalDistance,
    required double averageSpeed,
    required double maxSpeed,
    required double riskScore,
  });

  Future<Either<Failure, List<DrivingSession>>> getUserSessions(String userId);

  Future<Either<Failure, DrivingSession>> getSessionById({
    required String sessionId,
    required String userId,
  });

  Future<Either<Failure, List<SessionEvent>>> getSessionEvents({
    required String sessionId,
    required String userId,
  });

  Future<Either<Failure, DrivingSession?>> getActiveSession(String userId);

  Future<Either<Failure, List<DrivingSession>>> getSessionsByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });
}