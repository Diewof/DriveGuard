part of 'dashboard_bloc.dart';

class DashboardState extends Equatable {
  final bool isMonitoring;
  final String deviceStatus;
  final String currentAlertType;
  final double riskScore;
  final Duration sessionDuration;
  final SensorData? currentSensorData;
  final List<Map<String, dynamic>> recentAlerts;
  final int distractionCount;
  final int recklessCount;
  final int emergencyCount;

  const DashboardState({
    this.isMonitoring = false,
    this.deviceStatus = 'DESCONECTADO',
    this.currentAlertType = 'NORMAL',
    this.riskScore = 0.0,
    this.sessionDuration = Duration.zero,
    this.currentSensorData,
    this.recentAlerts = const [],
    this.distractionCount = 0,
    this.recklessCount = 0,
    this.emergencyCount = 0,
  });

  DashboardState copyWith({
    bool? isMonitoring,
    String? deviceStatus,
    String? currentAlertType,
    double? riskScore,
    Duration? sessionDuration,
    SensorData? currentSensorData,
    List<Map<String, dynamic>>? recentAlerts,
    int? distractionCount,
    int? recklessCount,
    int? emergencyCount,
  }) {
    return DashboardState(
      isMonitoring: isMonitoring ?? this.isMonitoring,
      deviceStatus: deviceStatus ?? this.deviceStatus,
      currentAlertType: currentAlertType ?? this.currentAlertType,
      riskScore: riskScore ?? this.riskScore,
      sessionDuration: sessionDuration ?? this.sessionDuration,
      currentSensorData: currentSensorData ?? this.currentSensorData,
      recentAlerts: recentAlerts ?? this.recentAlerts,
      distractionCount: distractionCount ?? this.distractionCount,
      recklessCount: recklessCount ?? this.recklessCount,
      emergencyCount: emergencyCount ?? this.emergencyCount,
    );
  }

  @override
  List<Object?> get props => [
        isMonitoring,
        deviceStatus,
        currentAlertType,
        riskScore,
        sessionDuration,
        currentSensorData,
        recentAlerts,
        distractionCount,
        recklessCount,
        emergencyCount,
      ];
}