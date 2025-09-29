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

class _DeviceConnected extends DashboardEvent {}