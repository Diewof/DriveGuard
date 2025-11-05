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
  // ESP32-CAM connection info
  final String? esp32Ip;
  final String? serverIp;
  final int? serverPort;
  // Emergency confirmation state
  final bool showEmergencyConfirmation;
  final int emergencyCountdown;

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
    this.esp32Ip,
    this.serverIp,
    this.serverPort,
    this.showEmergencyConfirmation = false,
    this.emergencyCountdown = 5,
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
    String? esp32Ip,
    String? serverIp,
    int? serverPort,
    bool? showEmergencyConfirmation,
    int? emergencyCountdown,
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
      esp32Ip: esp32Ip ?? this.esp32Ip,
      serverIp: serverIp ?? this.serverIp,
      serverPort: serverPort ?? this.serverPort,
      showEmergencyConfirmation: showEmergencyConfirmation ?? this.showEmergencyConfirmation,
      emergencyCountdown: emergencyCountdown ?? this.emergencyCountdown,
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
        esp32Ip,
        serverIp,
        serverPort,
        showEmergencyConfirmation,
        emergencyCountdown,
      ];
}