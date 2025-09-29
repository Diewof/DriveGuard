import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/sensor_data.dart';
import '../../../core/mocks/sensor_simulator.dart';
import '../../../core/services/notification_service.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final SensorSimulator _sensorSimulator = SensorSimulator();
  final NotificationService _notificationService;
  Timer? _sessionTimer;
  Timer? _alertTimer;
  StreamSubscription<SensorData>? _sensorSubscription;

  DashboardBloc() : _notificationService = NotificationService(), super(const DashboardState()) {
    on<DashboardStartMonitoring>(_onStartMonitoring);
    on<DashboardStopMonitoring>(_onStopMonitoring);
    on<DashboardSensorDataReceived>(_onSensorDataReceived);
    on<DashboardTriggerAlert>(_onTriggerAlert);
    on<DashboardSessionTick>(_onSessionTick);
    on<DashboardEmergencyActivated>(_onEmergencyActivated);
    on<_DeviceConnected>(_onDeviceConnected);

    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _notificationService.initialize();

    // Simular conexión del dispositivo
    Future.delayed(const Duration(seconds: 2), () {
      add(_DeviceConnected());
    });
  }

  void _onStartMonitoring(DashboardStartMonitoring event, Emitter<DashboardState> emit) {
    emit(state.copyWith(
      isMonitoring: true,
      sessionDuration: Duration.zero,
      distractionCount: 0,
      recklessCount: 0,
      emergencyCount: 0,
      recentAlerts: [],
    ));

    _sensorSimulator.startSimulation(SimulationMode.normal);
    _listenToSensorData();
    _startSessionTimer();
    _startAlertTimer();
  }

  void _onStopMonitoring(DashboardStopMonitoring event, Emitter<DashboardState> emit) {
    emit(state.copyWith(
      isMonitoring: false,
      currentAlertType: 'NORMAL',
      riskScore: 0.0,
    ));

    _sensorSimulator.stopSimulation();
    _sessionTimer?.cancel();
    _alertTimer?.cancel();
    _sensorSubscription?.cancel();
  }

  void _onSensorDataReceived(DashboardSensorDataReceived event, Emitter<DashboardState> emit) {
    final sensorData = event.sensorData;
    final riskScore = _calculateRiskScore(sensorData);

    emit(state.copyWith(
      currentSensorData: sensorData,
      riskScore: riskScore,
    ));

    _checkCriticalAlerts(sensorData);
  }

  void _onTriggerAlert(DashboardTriggerAlert event, Emitter<DashboardState> emit) {
    final newAlerts = List<Map<String, dynamic>>.from(state.recentAlerts);
    newAlerts.insert(0, {
      'type': event.type,
      'severity': event.severity,
      'time': DateTime.now(),
    });

    if (newAlerts.length > 5) {
      newAlerts.removeRange(5, newAlerts.length);
    }

    int newDistractionCount = state.distractionCount;
    int newRecklessCount = state.recklessCount;
    int newEmergencyCount = state.emergencyCount;

    if (event.type.contains('DISTRACCIÓN') || event.type.contains('CELULAR') || event.type.contains('MIRADA')) {
      newDistractionCount++;
    } else if (event.type.contains('TEMERARIA') || event.type.contains('FRENADA')) {
      newRecklessCount++;
    } else if (event.type.contains('IMPACTO') || event.severity == 'CRITICAL') {
      newEmergencyCount++;
    }

    emit(state.copyWith(
      currentAlertType: event.type,
      recentAlerts: newAlerts,
      distractionCount: newDistractionCount,
      recklessCount: newRecklessCount,
      emergencyCount: newEmergencyCount,
    ));
  }

  void _onSessionTick(DashboardSessionTick event, Emitter<DashboardState> emit) {
    if (state.isMonitoring) {
      emit(state.copyWith(
        sessionDuration: state.sessionDuration + const Duration(seconds: 1),
      ));
    }
  }

  void _onEmergencyActivated(DashboardEmergencyActivated event, Emitter<DashboardState> emit) {
    add(const DashboardTriggerAlert(type: 'EMERGENCIA ACTIVADA', severity: 'CRITICAL'));
  }

  void _onDeviceConnected(_DeviceConnected event, Emitter<DashboardState> emit) {
    emit(state.copyWith(deviceStatus: 'CONECTADO'));
  }

  void _listenToSensorData() {
    _sensorSubscription?.cancel();
    _sensorSubscription = _sensorSimulator.stream
        .where((data) => state.isMonitoring)
        .listen((sensorData) {
      add(DashboardSensorDataReceived(sensorData));
    });
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      add(DashboardSessionTick());
    });
  }

  void _startAlertTimer() {
    _scheduleNextAlert();
  }

  void _scheduleNextAlert() {
    _alertTimer?.cancel();

    // Intervalo aleatorio entre 15-30 segundos
    const minInterval = 15; // AppConstants.randomEventMinInterval
    const maxInterval = 30; // AppConstants.randomEventMaxInterval
    final randomInterval = minInterval + Random().nextInt(maxInterval - minInterval + 1);

    _alertTimer = Timer(Duration(seconds: randomInterval), () {
      if (state.isMonitoring) {
        _simulateRandomEvent();
        _scheduleNextAlert(); // Programar la siguiente alerta
      }
    });
  }

  void _checkCriticalAlerts(SensorData sensorData) {
    if (sensorData.isRecklessDriving) {
      add(const DashboardTriggerAlert(type: 'CONDUCCIÓN TEMERARIA', severity: 'HIGH'));
      _notificationService.showAlert(
        type: AlertType.recklessDriving,
        severity: AlertSeverity.high,
      );
    } else if (sensorData.isCrashDetected) {
      add(const DashboardTriggerAlert(type: 'IMPACTO DETECTADO', severity: 'CRITICAL'));
      _notificationService.showAlert(
        type: AlertType.impact,
        severity: AlertSeverity.critical,
      );
    }
  }

  double _calculateRiskScore(SensorData data) {
    double score = 0.0;

    double accelMagnitude = sqrt(
      pow(data.accelerationX, 2) +
      pow(data.accelerationY, 2) +
      pow((data.accelerationZ - 9.8).abs(), 2)
    );
    score += min(accelMagnitude * 10, 30);

    double gyroMagnitude = sqrt(
      pow(data.gyroscopeX, 2) +
      pow(data.gyroscopeY, 2) +
      pow(data.gyroscopeZ, 2)
    );
    score += min(gyroMagnitude / 2, 30);

    if (state.recentAlerts.isNotEmpty) {
      score += min(state.recentAlerts.length * 5, 40);
    }

    return min(score, 100);
  }

  void _simulateRandomEvent() {
    final events = [
      {'type': 'DISTRACCIÓN', 'severity': 'MEDIUM', 'alertType': AlertType.distraction},
      {'type': 'MIRADA FUERA', 'severity': 'MEDIUM', 'alertType': AlertType.lookAway},
      {'type': 'USO DE CELULAR', 'severity': 'HIGH', 'alertType': AlertType.phoneUsage},
      {'type': 'FRENADA BRUSCA', 'severity': 'MEDIUM', 'alertType': AlertType.harshBraking},
      {'type': 'CONDUCCIÓN TEMERARIA', 'severity': 'HIGH', 'alertType': AlertType.recklessDriving},
    ];

    final event = events[Random().nextInt(events.length)];

    // Agregar evento al BLoC para actualizar el estado
    add(DashboardTriggerAlert(
      type: event['type']! as String,
      severity: event['severity']! as String,
    ));

    // Activar notificación multimodal
    final alertType = event['alertType']! as AlertType;
    final alertSeverity = _stringToAlertSeverity(event['severity']! as String);


    _notificationService.showAlert(
      type: alertType,
      severity: alertSeverity,
      customMessage: event['type']! as String,
    );
  }

  AlertSeverity _stringToAlertSeverity(String severity) {
    switch (severity) {
      case 'LOW':
        return AlertSeverity.low;
      case 'MEDIUM':
        return AlertSeverity.medium;
      case 'HIGH':
        return AlertSeverity.high;
      case 'CRITICAL':
        return AlertSeverity.critical;
      default:
        return AlertSeverity.medium;
    }
  }

  @override
  Future<void> close() {
    _sensorSimulator.dispose();
    _sessionTimer?.cancel();
    _alertTimer?.cancel();
    _sensorSubscription?.cancel();
    _notificationService.dispose();
    return super.close();
  }
}