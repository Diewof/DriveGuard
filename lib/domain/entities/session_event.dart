import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class SessionEvent extends Equatable {
  final String? id;
  final String sessionId;
  final String userId;
  final DateTime timestamp;
  final String eventType;
  final String severity;
  final String description;
  final GeoPoint location;
  final SensorSnapshot sensorSnapshot;

  const SessionEvent({
    this.id,
    required this.sessionId,
    required this.userId,
    required this.timestamp,
    required this.eventType,
    required this.severity,
    required this.description,
    required this.location,
    required this.sensorSnapshot,
  });

  SessionEvent copyWith({
    String? id,
    String? sessionId,
    String? userId,
    DateTime? timestamp,
    String? eventType,
    String? severity,
    String? description,
    GeoPoint? location,
    SensorSnapshot? sensorSnapshot,
  }) {
    return SessionEvent(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      timestamp: timestamp ?? this.timestamp,
      eventType: eventType ?? this.eventType,
      severity: severity ?? this.severity,
      description: description ?? this.description,
      location: location ?? this.location,
      sensorSnapshot: sensorSnapshot ?? this.sensorSnapshot,
    );
  }

  @override
  List<Object?> get props => [
        id,
        sessionId,
        userId,
        timestamp,
        eventType,
        severity,
        description,
        location,
        sensorSnapshot,
      ];
}

class SensorSnapshot extends Equatable {
  final double accelX;
  final double accelY;
  final double accelZ;
  final double gyroX;
  final double gyroY;
  final double gyroZ;

  const SensorSnapshot({
    required this.accelX,
    required this.accelY,
    required this.accelZ,
    required this.gyroX,
    required this.gyroY,
    required this.gyroZ,
  });

  SensorSnapshot copyWith({
    double? accelX,
    double? accelY,
    double? accelZ,
    double? gyroX,
    double? gyroY,
    double? gyroZ,
  }) {
    return SensorSnapshot(
      accelX: accelX ?? this.accelX,
      accelY: accelY ?? this.accelY,
      accelZ: accelZ ?? this.accelZ,
      gyroX: gyroX ?? this.gyroX,
      gyroY: gyroY ?? this.gyroY,
      gyroZ: gyroZ ?? this.gyroZ,
    );
  }

  @override
  List<Object?> get props => [
        accelX,
        accelY,
        accelZ,
        gyroX,
        gyroY,
        gyroZ,
      ];
}

enum EventType {
  distraction('DISTRACTION'),
  recklessDriving('RECKLESS_DRIVING'),
  emergency('EMERGENCY');

  const EventType(this.value);
  final String value;
}

enum EventSeverity {
  low('LOW'),
  medium('MEDIUM'),
  high('HIGH');

  const EventSeverity(this.value);
  final String value;
}

enum SessionStatus {
  active('ACTIVE'),
  paused('PAUSED'),
  completed('COMPLETED');

  const SessionStatus(this.value);
  final String value;
}