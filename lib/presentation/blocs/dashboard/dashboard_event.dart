part of 'dashboard_bloc.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class DashboardStartMonitoring extends DashboardEvent {}

class DashboardStopMonitoring extends DashboardEvent {}

class DashboardSensorDataReceived extends DashboardEvent {
  final SensorData sensorData;

  const DashboardSensorDataReceived(this.sensorData);

  @override
  List<Object?> get props => [sensorData];
}

class DashboardDetectionEventReceived extends DashboardEvent {
  final DetectionEvent detectionEvent;

  const DashboardDetectionEventReceived(this.detectionEvent);

  @override
  List<Object?> get props => [detectionEvent];
}

class DashboardTriggerAlert extends DashboardEvent {
  final String type;
  final String severity;

  const DashboardTriggerAlert({
    required this.type,
    required this.severity,
  });

  @override
  List<Object?> get props => [type, severity];
}

class DashboardSessionTick extends DashboardEvent {}

class DashboardEmergencyActivated extends DashboardEvent {}

class DashboardEmergencyCancelled extends DashboardEvent {}

class DashboardEmergencyConfirmed extends DashboardEvent {}

class DashboardEmergencyCountdownTick extends DashboardEvent {
  final int countdown;

  const DashboardEmergencyCountdownTick(this.countdown);

  @override
  List<Object?> get props => [countdown];
}

class DashboardConfigurationChanged extends DashboardEvent {}

class _DeviceConnected extends DashboardEvent {
  final String esp32Ip;

  const _DeviceConnected({required this.esp32Ip});

  @override
  List<Object?> get props => [esp32Ip];
}