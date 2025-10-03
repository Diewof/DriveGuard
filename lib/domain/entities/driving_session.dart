import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class DrivingSession extends Equatable {
  final String? id;
  final String userId;
  final String deviceId;
  final DateTime startTime;
  final DateTime? endTime;
  final GeoPoint startLocation;
  final GeoPoint? endLocation;
  final double totalDistance;
  final double averageSpeed;
  final double maxSpeed;
  final double riskScore;
  final String status;
  final DailyStats dailyStats;

  const DrivingSession({
    this.id,
    required this.userId,
    required this.deviceId,
    required this.startTime,
    this.endTime,
    required this.startLocation,
    this.endLocation,
    required this.totalDistance,
    required this.averageSpeed,
    required this.maxSpeed,
    required this.riskScore,
    required this.status,
    required this.dailyStats,
  });

  DrivingSession copyWith({
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
    return DrivingSession(
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

  @override
  List<Object?> get props => [
        id,
        userId,
        deviceId,
        startTime,
        endTime,
        startLocation,
        endLocation,
        totalDistance,
        averageSpeed,
        maxSpeed,
        riskScore,
        status,
        dailyStats,
      ];
}

class DailyStats extends Equatable {
  final String date;
  final int totalDrivingTime;
  final int distractionCount;
  final int recklessCount;
  final int emergencyCount;
  final int totalAlerts;
  final double averageRiskScore;

  const DailyStats({
    required this.date,
    required this.totalDrivingTime,
    required this.distractionCount,
    required this.recklessCount,
    required this.emergencyCount,
    required this.totalAlerts,
    required this.averageRiskScore,
  });

  DailyStats copyWith({
    String? date,
    int? totalDrivingTime,
    int? distractionCount,
    int? recklessCount,
    int? emergencyCount,
    int? totalAlerts,
    double? averageRiskScore,
  }) {
    return DailyStats(
      date: date ?? this.date,
      totalDrivingTime: totalDrivingTime ?? this.totalDrivingTime,
      distractionCount: distractionCount ?? this.distractionCount,
      recklessCount: recklessCount ?? this.recklessCount,
      emergencyCount: emergencyCount ?? this.emergencyCount,
      totalAlerts: totalAlerts ?? this.totalAlerts,
      averageRiskScore: averageRiskScore ?? this.averageRiskScore,
    );
  }

  @override
  List<Object?> get props => [
        date,
        totalDrivingTime,
        distractionCount,
        recklessCount,
        emergencyCount,
        totalAlerts,
        averageRiskScore,
      ];
}