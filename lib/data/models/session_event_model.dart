import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/session_event.dart';

class SessionEventModel extends SessionEvent {
  const SessionEventModel({
    super.id,
    required super.sessionId,
    required super.userId,
    required super.timestamp,
    required super.eventType,
    required super.severity,
    required super.description,
    required super.location,
    required super.sensorSnapshot,
  });

  factory SessionEventModel.fromMap(Map<String, dynamic> map, String id) {
    return SessionEventModel(
      id: id,
      sessionId: map['sessionId'] ?? '',
      userId: map['userId'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      eventType: map['eventType'] ?? '',
      severity: map['severity'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] as GeoPoint,
      sensorSnapshot: SensorSnapshotModel.fromMap(map['sensorSnapshot'] ?? {}),
    );
  }

  factory SessionEventModel.fromEntity(SessionEvent event) {
    return SessionEventModel(
      id: event.id,
      sessionId: event.sessionId,
      userId: event.userId,
      timestamp: event.timestamp,
      eventType: event.eventType,
      severity: event.severity,
      description: event.description,
      location: event.location,
      sensorSnapshot: event.sensorSnapshot,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'userId': userId,
      'timestamp': Timestamp.fromDate(timestamp),
      'eventType': eventType,
      'severity': severity,
      'description': description,
      'location': location,
      'sensorSnapshot': SensorSnapshotModel.fromEntity(sensorSnapshot).toMap(),
    };
  }

  @override
  SessionEventModel copyWith({
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
    return SessionEventModel(
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
}

class SensorSnapshotModel extends SensorSnapshot {
  const SensorSnapshotModel({
    required super.accelX,
    required super.accelY,
    required super.accelZ,
    required super.gyroX,
    required super.gyroY,
    required super.gyroZ,
  });

  factory SensorSnapshotModel.fromMap(Map<String, dynamic> map) {
    return SensorSnapshotModel(
      accelX: (map['accelX'] ?? 0.0).toDouble(),
      accelY: (map['accelY'] ?? 0.0).toDouble(),
      accelZ: (map['accelZ'] ?? 0.0).toDouble(),
      gyroX: (map['gyroX'] ?? 0.0).toDouble(),
      gyroY: (map['gyroY'] ?? 0.0).toDouble(),
      gyroZ: (map['gyroZ'] ?? 0.0).toDouble(),
    );
  }

  factory SensorSnapshotModel.fromEntity(SensorSnapshot snapshot) {
    return SensorSnapshotModel(
      accelX: snapshot.accelX,
      accelY: snapshot.accelY,
      accelZ: snapshot.accelZ,
      gyroX: snapshot.gyroX,
      gyroY: snapshot.gyroY,
      gyroZ: snapshot.gyroZ,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'accelX': accelX,
      'accelY': accelY,
      'accelZ': accelZ,
      'gyroX': gyroX,
      'gyroY': gyroY,
      'gyroZ': gyroZ,
    };
  }
}