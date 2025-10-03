import 'package:equatable/equatable.dart';

abstract class SessionEvent extends Equatable {
  const SessionEvent();

  @override
  List<Object?> get props => [];
}

class StartSession extends SessionEvent {
  final String userId;
  final String deviceId;
  final double latitude;
  final double longitude;

  const StartSession({
    required this.userId,
    required this.deviceId,
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object> get props => [userId, deviceId, latitude, longitude];
}

class EndSession extends SessionEvent {
  final String sessionId;
  final String userId;
  final double endLatitude;
  final double endLongitude;

  const EndSession({
    required this.sessionId,
    required this.userId,
    required this.endLatitude,
    required this.endLongitude,
  });

  @override
  List<Object> get props => [sessionId, userId, endLatitude, endLongitude];
}

class AddSessionEvent extends SessionEvent {
  final String sessionId;
  final String userId;
  final String eventType;
  final String severity;
  final String description;
  final double latitude;
  final double longitude;
  final Map<String, double> sensorData;

  const AddSessionEvent({
    required this.sessionId,
    required this.userId,
    required this.eventType,
    required this.severity,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.sensorData,
  });

  @override
  List<Object> get props => [
        sessionId,
        userId,
        eventType,
        severity,
        description,
        latitude,
        longitude,
        sensorData,
      ];
}

class LoadUserSessions extends SessionEvent {
  final String userId;

  const LoadUserSessions(this.userId);

  @override
  List<Object> get props => [userId];
}

class LoadSessionEvents extends SessionEvent {
  final String sessionId;
  final String userId;

  const LoadSessionEvents({
    required this.sessionId,
    required this.userId,
  });

  @override
  List<Object> get props => [sessionId, userId];
}

class LoadActiveSession extends SessionEvent {
  final String userId;

  const LoadActiveSession(this.userId);

  @override
  List<Object> get props => [userId];
}

class UpdateSessionStats extends SessionEvent {
  final String sessionId;
  final String userId;
  final double totalDistance;
  final double averageSpeed;
  final double maxSpeed;
  final double riskScore;

  const UpdateSessionStats({
    required this.sessionId,
    required this.userId,
    required this.totalDistance,
    required this.averageSpeed,
    required this.maxSpeed,
    required this.riskScore,
  });

  @override
  List<Object> get props => [
        sessionId,
        userId,
        totalDistance,
        averageSpeed,
        maxSpeed,
        riskScore,
      ];
}