import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/driving_session.dart';

class DrivingSessionModel extends DrivingSession {
  const DrivingSessionModel({
    super.id,
    required super.userId,
    required super.deviceId,
    required super.startTime,
    super.endTime,
    required super.startLocation,
    super.endLocation,
    required super.totalDistance,
    required super.averageSpeed,
    required super.maxSpeed,
    required super.riskScore,
    required super.status,
    required super.dailyStats,
  });

  factory DrivingSessionModel.fromMap(Map<String, dynamic> map, String id) {
    return DrivingSessionModel(
      id: id,
      userId: map['userId'] ?? '',
      deviceId: map['deviceId'] ?? '',
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: map['endTime'] != null ? (map['endTime'] as Timestamp).toDate() : null,
      startLocation: map['startLocation'] as GeoPoint,
      endLocation: map['endLocation'] as GeoPoint?,
      totalDistance: (map['totalDistance'] ?? 0.0).toDouble(),
      averageSpeed: (map['averageSpeed'] ?? 0.0).toDouble(),
      maxSpeed: (map['maxSpeed'] ?? 0.0).toDouble(),
      riskScore: (map['riskScore'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'ACTIVE',
      dailyStats: DailyStatsModel.fromMap(map['dailyStats'] ?? {}),
    );
  }

  factory DrivingSessionModel.fromEntity(DrivingSession session) {
    return DrivingSessionModel(
      id: session.id,
      userId: session.userId,
      deviceId: session.deviceId,
      startTime: session.startTime,
      endTime: session.endTime,
      startLocation: session.startLocation,
      endLocation: session.endLocation,
      totalDistance: session.totalDistance,
      averageSpeed: session.averageSpeed,
      maxSpeed: session.maxSpeed,
      riskScore: session.riskScore,
      status: session.status,
      dailyStats: session.dailyStats,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'deviceId': deviceId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'startLocation': startLocation,
      'endLocation': endLocation,
      'totalDistance': totalDistance,
      'averageSpeed': averageSpeed,
      'maxSpeed': maxSpeed,
      'riskScore': riskScore,
      'status': status,
      'dailyStats': DailyStatsModel.fromEntity(dailyStats).toMap(),
    };
  }

  @override
  DrivingSessionModel copyWith({
    String? id,
    String? userId,
    String? deviceId,
    DateTime? startTime,
    DateTime? endTime,
    GeoPoint? startLocation,
    GeoPoint? endLocation,
    double? totalDistance,
    double? averageSpeed,
    double? maxSpeed,
    double? riskScore,
    String? status,
    DailyStats? dailyStats,
  }) {
    return DrivingSessionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      startLocation: startLocation ?? this.startLocation,
      endLocation: endLocation ?? this.endLocation,
      totalDistance: totalDistance ?? this.totalDistance,
      averageSpeed: averageSpeed ?? this.averageSpeed,
      maxSpeed: maxSpeed ?? this.maxSpeed,
      riskScore: riskScore ?? this.riskScore,
      status: status ?? this.status,
      dailyStats: dailyStats ?? this.dailyStats,
    );
  }
}

class DailyStatsModel extends DailyStats {
  const DailyStatsModel({
    required super.date,
    required super.totalDrivingTime,
    required super.distractionCount,
    required super.recklessCount,
    required super.emergencyCount,
    required super.totalAlerts,
    required super.averageRiskScore,
  });

  factory DailyStatsModel.fromMap(Map<String, dynamic> map) {
    return DailyStatsModel(
      date: map['date'] ?? '',
      totalDrivingTime: map['totalDrivingTime'] ?? 0,
      distractionCount: map['distractionCount'] ?? 0,
      recklessCount: map['recklessCount'] ?? 0,
      emergencyCount: map['emergencyCount'] ?? 0,
      totalAlerts: map['totalAlerts'] ?? 0,
      averageRiskScore: (map['averageRiskScore'] ?? 0.0).toDouble(),
    );
  }

  factory DailyStatsModel.fromEntity(DailyStats stats) {
    return DailyStatsModel(
      date: stats.date,
      totalDrivingTime: stats.totalDrivingTime,
      distractionCount: stats.distractionCount,
      recklessCount: stats.recklessCount,
      emergencyCount: stats.emergencyCount,
      totalAlerts: stats.totalAlerts,
      averageRiskScore: stats.averageRiskScore,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'totalDrivingTime': totalDrivingTime,
      'distractionCount': distractionCount,
      'recklessCount': recklessCount,
      'emergencyCount': emergencyCount,
      'totalAlerts': totalAlerts,
      'averageRiskScore': averageRiskScore,
    };
  }
}