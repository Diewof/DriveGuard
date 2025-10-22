import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import '../../../domain/entities/sensor_data.dart';
import '../../../core/services/sensor_service_factory.dart';
import '../../../core/services/notification_service.dart';
import '../session/session_bloc.dart';
import '../session/session_event.dart' as session_events;
import '../session/session_state.dart';
import '../auth/auth_bloc.dart';
import '../../../domain/entities/session_event.dart' as domain;

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final ISensorService _sensorService = SensorServiceFactory.create();
  final NotificationService _notificationService;
  final SessionBloc _sessionBloc;
  final AuthBloc _authBloc;
  Timer? _sessionTimer;
  Timer? _alertTimer;
  StreamSubscription<SensorData>? _sensorSubscription;
  String? _currentSessionId;

  DashboardBloc({
    required SessionBloc sessionBloc,
    required AuthBloc authBloc,
  }) : _sessionBloc = sessionBloc,
       _authBloc = authBloc,
       _notificationService = NotificationService(),
       super(const DashboardState()) {
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

  void _onStartMonitoring(DashboardStartMonitoring event, Emitter<DashboardState> emit) async {
    emit(state.copyWith(
      isMonitoring: true,
      sessionDuration: Duration.zero,
      distractionCount: 0,
      recklessCount: 0,
      emergencyCount: 0,
      recentAlerts: [],
    ));

    // Iniciar sesión automáticamente
    await _startSession();

    _sensorService.start();
    _listenToSensorData();
    _startSessionTimer();
    _startAlertTimer();
  }

  void _onStopMonitoring(DashboardStopMonitoring event, Emitter<DashboardState> emit) async {
    emit(state.copyWith(
      isMonitoring: false,
      currentAlertType: 'NORMAL',
      riskScore: 0.0,
    ));

    // Finalizar sesión automáticamente
    await _endSession();

    _sensorService.stop();
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

    // Guardar el evento en la sesión si hay una sesión activa
    _saveSessionEvent(event.type, event.severity);
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
    _sensorSubscription = _sensorService.stream
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

  Future<void> _startSession() async {
    try {
      final userId = _authBloc.state.user?.id;
      if (userId == null) return;

      final position = await _getCurrentPosition();

      _sessionBloc.add(session_events.StartSession(
        userId: userId,
        deviceId: 'ESP32-001', // Este debería venir de la conexión real del dispositivo
        latitude: position.latitude,
        longitude: position.longitude,
      ));

      // Escuchar el resultado para obtener el ID de la sesión
      _sessionBloc.stream.listen((sessionState) {
        if (sessionState is SessionActive) {
          _currentSessionId = sessionState.session.id;
        }
      });
    } catch (e) {
      // Log error but don't stop monitoring
      print('Error starting session: $e');
    }
  }

  Future<void> _endSession() async {
    try {
      final userId = _authBloc.state.user?.id;
      if (userId == null || _currentSessionId == null) return;

      final position = await _getCurrentPosition();

      _sessionBloc.add(session_events.EndSession(
        sessionId: _currentSessionId!,
        userId: userId,
        endLatitude: position.latitude,
        endLongitude: position.longitude,
      ));

      _currentSessionId = null;
    } catch (e) {
      // Log error
      print('Error ending session: $e');
    }
  }

  void _saveSessionEvent(String eventType, String severity) async {
    try {
      final userId = _authBloc.state.user?.id;
      if (userId == null || _currentSessionId == null) return;

      final position = await _getCurrentPosition();
      final currentSensorData = state.currentSensorData;

      String mappedEventType;
      String description;

      // Mapear tipos de eventos del dashboard a tipos de la base de datos
      if (eventType.contains('DISTRACCIÓN') || eventType.contains('CELULAR') || eventType.contains('MIRADA')) {
        mappedEventType = domain.EventType.distraction.value;
        description = 'Distracción detectada: $eventType';
      } else if (eventType.contains('TEMERARIA') || eventType.contains('FRENADA')) {
        mappedEventType = domain.EventType.recklessDriving.value;
        description = 'Conducción imprudente: $eventType';
      } else {
        mappedEventType = domain.EventType.emergency.value;
        description = 'Evento de emergencia: $eventType';
      }

      // Mapear severidad
      String mappedSeverity;
      switch (severity) {
        case 'LOW':
          mappedSeverity = domain.EventSeverity.low.value;
          break;
        case 'MEDIUM':
          mappedSeverity = domain.EventSeverity.medium.value;
          break;
        case 'HIGH':
        case 'CRITICAL':
          mappedSeverity = domain.EventSeverity.high.value;
          break;
        default:
          mappedSeverity = domain.EventSeverity.medium.value;
      }

      final sensorData = currentSensorData ?? SensorData(
        id: 'default-sensor-${DateTime.now().millisecondsSinceEpoch}',
        accelerationX: 0.0,
        accelerationY: 0.0,
        accelerationZ: 9.8,
        gyroscopeX: 0.0,
        gyroscopeY: 0.0,
        gyroscopeZ: 0.0,
        timestamp: DateTime.now(),
      );

      _sessionBloc.add(session_events.AddSessionEvent(
        sessionId: _currentSessionId!,
        userId: userId,
        eventType: mappedEventType,
        severity: mappedSeverity,
        description: description,
        latitude: position.latitude,
        longitude: position.longitude,
        sensorData: {
          'accelX': sensorData.accelerationX,
          'accelY': sensorData.accelerationY,
          'accelZ': sensorData.accelerationZ,
          'gyroX': sensorData.gyroscopeX,
          'gyroY': sensorData.gyroscopeY,
          'gyroZ': sensorData.gyroscopeZ,
        },
      ));
    } catch (e) {
      print('Error saving session event: $e');
    }
  }

  Future<Position> _getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Usar una ubicación por defecto si no hay servicios de ubicación
      return Position(
        latitude: 6.2442,
        longitude: -75.5812,
        timestamp: DateTime.now(),
        accuracy: 0.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Usar ubicación por defecto
        return Position(
          latitude: 6.2442,
          longitude: -75.5812,
          timestamp: DateTime.now(),
          accuracy: 0.0,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Usar ubicación por defecto
      return Position(
        latitude: 6.2442,
        longitude: -75.5812,
        timestamp: DateTime.now(),
        accuracy: 0.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
    }

    try {
      return await Geolocator.getCurrentPosition();
    } catch (e) {
      // Usar ubicación por defecto si falla
      return Position(
        latitude: 6.2442,
        longitude: -75.5812,
        timestamp: DateTime.now(),
        accuracy: 0.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
    }
  }

  @override
  Future<void> close() {
    _sensorService.dispose();
    _sessionTimer?.cancel();
    _alertTimer?.cancel();
    _sensorSubscription?.cancel();
    _notificationService.dispose();
    return super.close();
  }
}