import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import '../../../domain/entities/sensor_data.dart';
import '../../../core/services/sensor_service_factory.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/detection_config_service.dart';
import '../../../core/services/emergency_whatsapp_service.dart';
import '../../../core/detection/processors/sensor_data_processor_v2.dart';
import '../../../core/detection/processors/event_aggregator.dart';
import '../../../core/detection/models/detection_event.dart';
import '../../../core/detection/models/event_type.dart' as det;
import '../../../core/detection/models/event_severity.dart' as det;
import '../session/session_bloc.dart';
import '../session/session_event.dart' as session_events;
import '../session/session_state.dart';
import '../auth/auth_bloc.dart';
import '../../../domain/entities/session_event.dart' as domain;
// NUEVO - Vision Processing (Fase 2)
import '../../../core/vision/processors/vision_processor.dart';
import '../../../core/vision/models/vision_event.dart';
import '../../../core/vision/utils/frame_converter.dart';
import '../../../domain/repositories/camera_repository.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final ISensorService _sensorService = SensorServiceFactory.create();
  final NotificationService _notificationService;
  final EmergencyWhatsAppService _emergencyService = EmergencyWhatsAppService();
  late SensorDataProcessorV2 _sensorProcessor;
  late DetectionConfigService _configService;
  final EventAggregator _eventAggregator = EventAggregator();
  final SessionBloc _sessionBloc;
  final AuthBloc _authBloc;
  Timer? _sessionTimer;
  Timer? _emergencyCountdownTimer;
  StreamSubscription<SensorData>? _sensorSubscription;
  StreamSubscription<DetectionEvent>? _detectionEventSubscription;
  StreamSubscription<DetectionEvent>? _aggregatedEventSubscription;
  String? _currentSessionId;

  // NUEVO - Vision Processing (Fase 2) - Usar CameraRepository en lugar de HttpServerService directo
  final CameraRepository _cameraRepository;
  VisionProcessor? _visionProcessor;
  StreamSubscription<VisionEvent>? _visionEventSubscription;
  StreamSubscription? _frameSubscription;
  StreamSubscription<SensorData>? _sensorForVisionSubscription;

  // Stream para estado de conexión ESP32
  StreamSubscription<String>? _esp32ConnectionSubscription;

  DashboardBloc({
    required SessionBloc sessionBloc,
    required AuthBloc authBloc,
    required CameraRepository cameraRepository,
  }) : _sessionBloc = sessionBloc,
       _authBloc = authBloc,
       _cameraRepository = cameraRepository,
       _notificationService = NotificationService(),
       super(const DashboardState()) {
    on<DashboardStartMonitoring>(_onStartMonitoring);
    on<DashboardStopMonitoring>(_onStopMonitoring);
    on<DashboardSensorDataReceived>(_onSensorDataReceived);
    on<DashboardDetectionEventReceived>(_onDetectionEventReceived);
    on<DashboardTriggerAlert>(_onTriggerAlert);
    on<DashboardSessionTick>(_onSessionTick);
    on<DashboardEmergencyActivated>(_onEmergencyActivated);
    on<DashboardEmergencyCancelled>(_onEmergencyCancelled);
    on<DashboardEmergencyConfirmed>(_onEmergencyConfirmed);
    on<DashboardEmergencyCountdownTick>(_onEmergencyCountdownTick);
    on<DashboardConfigurationChanged>(_onConfigurationChanged);
    on<_DeviceConnected>(_onDeviceConnected);

    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _notificationService.initialize();

    // Configurar contacto de emergencia desde el usuario autenticado
    _configureEmergencyContact();

    // No simular conexión - se actualizará cuando el ESP32 se conecte realmente
  }

  void _configureEmergencyContact() {
    final user = _authBloc.state.user;
    if (user != null && user.emergencyContacts != null && user.emergencyContacts!.isNotEmpty) {
      // Obtener el contacto con mayor prioridad (priority = 1)
      final primaryContact = user.emergencyContacts!
          .where((contact) => contact.isActive)
          .reduce((a, b) => a.priority < b.priority ? a : b);

      // Configurar en el servicio de WhatsApp
      _emergencyService.setEmergencyContact(primaryContact.phoneNumber);

      // ignore: avoid_print
      print('[DASHBOARD] ✅ Contacto de emergencia configurado: ${primaryContact.name} (${primaryContact.phoneNumber})');
    } else {
      // ignore: avoid_print
      print('[DASHBOARD] ⚠️ No hay contactos de emergencia configurados para este usuario');
    }
  }

  void _onStartMonitoring(DashboardStartMonitoring event, Emitter<DashboardState> emit) async {
    // ignore: avoid_print
    print('\n╔═══════════════════════════════════════════════════════════╗');
    // ignore: avoid_print
    print('║  🚀 MONITOREO INICIADO - Sistema de Detección Activo    ║');
    // ignore: avoid_print
    print('╚═══════════════════════════════════════════════════════════╝\n');

    // Cargar configuración de detección
    _configService = await DetectionConfigService.getInstance();
    final config = _configService.config;

    // ignore: avoid_print
    print('[DASHBOARD] 📝 Configuración: ${config.mode.displayName}, Gimbal: ${config.useGimbal}');

    // Inicializar procesador con configuración
    _sensorProcessor = SensorDataProcessorV2(initialConfig: config);

    // Obtener info del servidor HTTP antes de emitir el estado
    final serverInfo = _cameraRepository.getServerInfo();

    emit(state.copyWith(
      isMonitoring: true,
      sessionDuration: Duration.zero,
      distractionCount: 0,
      recklessCount: 0,
      emergencyCount: 0,
      recentAlerts: [],
      serverIp: serverInfo['ip'] as String?,
      serverPort: serverInfo['port'] as int?,
    ));

    // Iniciar sesión automáticamente
    await _startSession();

    _sensorService.start();
    // ignore: avoid_print
    print('[DASHBOARD] ✅ Servicio de sensores iniciado');
    _listenToSensorData();
    // ignore: avoid_print
    print('[DASHBOARD] ✅ Escuchando datos de sensores');
    _listenToDetectionEvents();
    // ignore: avoid_print
    print('[DASHBOARD] ✅ Escuchando eventos de detección');

    // NUEVO - Iniciar procesamiento de visión (Fase 2)
    _startVisionProcessing();
    // ignore: avoid_print
    print('[DASHBOARD] ✅ Procesamiento de visión iniciado');

    // Escuchar conexión del ESP32
    _listenToEsp32Connection();

    _startSessionTimer();
  }

  void _onStopMonitoring(DashboardStopMonitoring event, Emitter<DashboardState> emit) async {
    emit(state.copyWith(
      isMonitoring: false,
      currentAlertType: 'NORMAL',
      riskScore: 0.0,
      deviceStatus: 'DESCONECTADO',
    ));

    // Finalizar sesión automáticamente
    await _endSession();

    _sensorService.stop();
    _sessionTimer?.cancel();
    _sensorSubscription?.cancel();
    _detectionEventSubscription?.cancel();
    _aggregatedEventSubscription?.cancel();
    _esp32ConnectionSubscription?.cancel();

    // NUEVO - Detener procesamiento de visión (Fase 2)
    _stopVisionProcessing();

    // Resetear procesadores
    _sensorProcessor.resetDetectors();
    _eventAggregator.clearHistory();
  }

  void _onSensorDataReceived(DashboardSensorDataReceived event, Emitter<DashboardState> emit) {
    final sensorData = event.sensorData;

    // Procesar datos a través del nuevo sistema de detección
    _sensorProcessor.processSensorData(sensorData);

    // Calcular risk score global
    final riskScore = _eventAggregator.calculateGlobalRiskScore();

    emit(state.copyWith(
      currentSensorData: sensorData,
      riskScore: riskScore,
    ));
  }

  void _onDetectionEventReceived(DashboardDetectionEventReceived event, Emitter<DashboardState> emit) {
    final detectionEvent = event.detectionEvent;

    // ignore: avoid_print
    print('\n🎯 [DASHBOARD] EVENTO RECIBIDO EN DASHBOARD:');
    // ignore: avoid_print
    print('   Tipo: ${detectionEvent.type.displayName}');
    // ignore: avoid_print
    print('   Severidad: ${detectionEvent.severity.value}');
    // ignore: avoid_print
    print('   Confianza: ${detectionEvent.confidence.toStringAsFixed(2)}');
    // ignore: avoid_print
    print('   Timestamp: ${detectionEvent.timestamp}');

    // Convertir DetectionEvent a alerta del dashboard
    final alertType = _mapEventTypeToString(detectionEvent.type);
    final severity = _mapSeverityToString(detectionEvent.severity);

    // Agregar a la lista de alertas recientes
    final newAlerts = List<Map<String, dynamic>>.from(state.recentAlerts);
    newAlerts.insert(0, {
      'type': alertType,
      'severity': severity,
      'time': detectionEvent.timestamp,
      'confidence': detectionEvent.confidence,
      'riskScore': detectionEvent.getRiskScore(),
    });

    if (newAlerts.length > 10) {
      newAlerts.removeRange(10, newAlerts.length);
    }

    // Actualizar contadores según tipo de evento
    int newDistractionCount = state.distractionCount;
    int newRecklessCount = state.recklessCount;
    int newEmergencyCount = state.emergencyCount;

    switch (detectionEvent.type) {
      case det.EventType.weaving:
        newDistractionCount++;
        break;
      case det.EventType.harshBraking:
      case det.EventType.aggressiveAcceleration:
      case det.EventType.sharpTurn:
        newRecklessCount++;
        break;
      case det.EventType.roughRoad:
      case det.EventType.speedBump:
      case det.EventType.noFaceDetected:
        // No se cuentan como eventos críticos, son informativos
        break;
      // Nuevos eventos de visión (Fase 1 - preparación para Fase 2)
      case det.EventType.distraction:
      case det.EventType.inattention:
        newDistractionCount++;
        break;
      case det.EventType.handsOff:
        newRecklessCount++;
        break;
    }

    if (detectionEvent.severity == det.EventSeverity.critical) {
      newEmergencyCount++;
    }

    // ignore: avoid_print
    print('   📊 Contadores actualizados: distraction=$newDistractionCount, '
        'reckless=$newRecklessCount, emergency=$newEmergencyCount');

    emit(state.copyWith(
      currentAlertType: alertType,
      recentAlerts: newAlerts,
      distractionCount: newDistractionCount,
      recklessCount: newRecklessCount,
      emergencyCount: newEmergencyCount,
    ));

    // Mostrar notificación
    // ignore: avoid_print
    print('   🔔 Mostrando notificación...');
    _showDetectionNotification(detectionEvent);

    // Guardar evento en sesión
    _saveDetectionEvent(detectionEvent);
  }

  void _showDetectionNotification(DetectionEvent detectionEvent) {
    final alertType = _mapEventTypeToAlertType(detectionEvent.type);
    final severity = _mapDetectionSeverityToAlertSeverity(detectionEvent.severity);

    _notificationService.showAlert(
      type: alertType,
      severity: severity,
      customMessage: detectionEvent.toAlertMessage(),
    );
  }

  AlertType _mapEventTypeToAlertType(det.EventType type) {
    switch (type) {
      case det.EventType.harshBraking:
        return AlertType.harshBraking;
      case det.EventType.aggressiveAcceleration:
        return AlertType.aggressiveAcceleration;
      case det.EventType.sharpTurn:
        return AlertType.sharpTurn;
      case det.EventType.weaving:
        return AlertType.weaving;
      case det.EventType.roughRoad:
        return AlertType.roughRoad;
      case det.EventType.speedBump:
        return AlertType.speedBump;
      // Eventos de visión con tipos propios
      case det.EventType.distraction:
        return AlertType.distraction;
      case det.EventType.inattention:
        return AlertType.inattention;
      case det.EventType.handsOff:
        return AlertType.handsOff;
      case det.EventType.noFaceDetected:
        return AlertType.noFaceDetected;
    }
  }

  AlertSeverity _mapDetectionSeverityToAlertSeverity(det.EventSeverity severity) {
    switch (severity) {
      case det.EventSeverity.low:
        return AlertSeverity.low;
      case det.EventSeverity.medium:
        return AlertSeverity.medium;
      case det.EventSeverity.high:
        return AlertSeverity.high;
      case det.EventSeverity.critical:
        return AlertSeverity.critical;
    }
  }

  String _mapEventTypeToString(det.EventType type) {
    return type.displayName.toUpperCase();
  }

  String _mapSeverityToString(det.EventSeverity severity) {
    return severity.value;
  }

  void _onTriggerAlert(DashboardTriggerAlert event, Emitter<DashboardState> emit) {
    final newAlerts = List<Map<String, dynamic>>.from(state.recentAlerts);
    newAlerts.insert(0, {
      'type': event.type,
      'severity': event.severity,
      'time': DateTime.now(),
    });

    if (newAlerts.length > 10) {
      newAlerts.removeRange(10, newAlerts.length);
    }

    emit(state.copyWith(
      currentAlertType: event.type,
      recentAlerts: newAlerts,
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
    // Mostrar card de confirmación y empezar countdown
    emit(state.copyWith(
      showEmergencyConfirmation: true,
      emergencyCountdown: 5,
    ));

    // Iniciar temporizador de cuenta regresiva
    _startEmergencyCountdown();
  }

  void _onEmergencyCancelled(DashboardEmergencyCancelled event, Emitter<DashboardState> emit) {
    // Cancelar temporizador y ocultar card
    _emergencyCountdownTimer?.cancel();
    _emergencyCountdownTimer = null;

    emit(state.copyWith(
      showEmergencyConfirmation: false,
      emergencyCountdown: 5,
    ));

    // ignore: avoid_print
    print('[DASHBOARD] ⚠️ Protocolo de emergencia cancelado por el usuario');
  }

  void _onEmergencyConfirmed(DashboardEmergencyConfirmed event, Emitter<DashboardState> emit) async {
    // Detener temporizador
    _emergencyCountdownTimer?.cancel();
    _emergencyCountdownTimer = null;

    // Ocultar card de confirmación
    emit(state.copyWith(
      showEmergencyConfirmation: false,
      emergencyCountdown: 5,
    ));

    // Agregar a alertas recientes
    add(const DashboardTriggerAlert(type: 'EMERGENCIA ACTIVADA', severity: 'CRITICAL'));

    // ignore: avoid_print
    print('\n🚨 [DASHBOARD] PROTOCOLO DE EMERGENCIA CONFIRMADO');
    // ignore: avoid_print
    print('   📍 Preparando datos para envío...');

    // Enviar alerta por WhatsApp
    await _sendEmergencyWhatsApp();

    // Mostrar notificación
    _notificationService.showAlert(
      type: AlertType.harshBraking, // Usamos tipo existente con máxima severidad
      severity: AlertSeverity.critical,
      customMessage: 'Protocolo de Emergencia activado. Notificando contacto...',
    );
  }

  Future<void> _sendEmergencyWhatsApp() async {
    try {
      // Obtener posición actual
      final position = await _getCurrentPosition();

      // Obtener últimos eventos de la sesión
      final eventHistory = state.recentAlerts;

      // Obtener risk score actual
      final riskScore = state.riskScore;

      // Obtener IP de ESP32-CAM si está conectado
      String? esp32ImageUrl;
      if (state.esp32Ip != null) {
        esp32ImageUrl = 'http://${state.esp32Ip}/last-frame.jpg';
      }

      // ignore: avoid_print
      print('[DASHBOARD] 📲 Enviando alerta de emergencia por WhatsApp...');
      // ignore: avoid_print
      print('   Contacto: ${_emergencyService.getEmergencyContact() ?? "NO CONFIGURADO"}');
      // ignore: avoid_print
      print('   Eventos: ${eventHistory.length}');
      // ignore: avoid_print
      print('   Risk Score: ${riskScore.toStringAsFixed(1)}');
      // ignore: avoid_print
      print('   Ubicación: ${position.latitude}, ${position.longitude}');

      // Enviar por WhatsApp
      final success = await _emergencyService.sendEmergencyAlert(
        eventHistory: eventHistory,
        riskScore: riskScore,
        position: position,
        esp32ImageUrl: esp32ImageUrl,
      );

      if (success) {
        // ignore: avoid_print
        print('[DASHBOARD] ✅ Alerta de emergencia enviada correctamente');
      } else {
        // ignore: avoid_print
        print('[DASHBOARD] ❌ Error al enviar alerta de emergencia');
        // ignore: avoid_print
        print('   Verifica que hayas configurado un contacto de emergencia');
      }
    } catch (e) {
      // ignore: avoid_print
      print('[DASHBOARD] ❌ Error al preparar alerta de emergencia: $e');
    }
  }

  void _onEmergencyCountdownTick(DashboardEmergencyCountdownTick event, Emitter<DashboardState> emit) {
    if (event.countdown <= 0) {
      // Countdown terminado - confirmar automáticamente
      add(DashboardEmergencyConfirmed());
    } else {
      // Actualizar countdown
      emit(state.copyWith(emergencyCountdown: event.countdown));
    }
  }

  void _startEmergencyCountdown() {
    _emergencyCountdownTimer?.cancel();

    _emergencyCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final newCountdown = state.emergencyCountdown - 1;

      if (newCountdown <= 0) {
        // Countdown terminado - confirmar automáticamente
        timer.cancel();
        add(DashboardEmergencyConfirmed());
      } else {
        // Actualizar countdown
        add(DashboardEmergencyCountdownTick(newCountdown));
      }
    });
  }

  void _onConfigurationChanged(DashboardConfigurationChanged event, Emitter<DashboardState> emit) async {
    if (!state.isMonitoring) {
      // ignore: avoid_print
      print('[DASHBOARD] ⚠️ No se puede actualizar configuración: monitoreo no activo');
      return;
    }

    // Recargar configuración desde el servicio
    final config = _configService.config;

    // Actualizar procesador con la nueva configuración
    _sensorProcessor.updateConfiguration(config);

    // ignore: avoid_print
    print('[DASHBOARD] ✅ Configuración actualizada en tiempo real: ${config.mode.displayName}, Gimbal: ${config.useGimbal}');
  }

  void _onDeviceConnected(_DeviceConnected event, Emitter<DashboardState> emit) {
    emit(state.copyWith(
      deviceStatus: 'CONECTADO',
      esp32Ip: event.esp32Ip,
    ));
  }

  void _listenToSensorData() {
    _sensorSubscription?.cancel();
    _sensorSubscription = _sensorService.stream
        .where((data) => state.isMonitoring)
        .listen((sensorData) {
      add(DashboardSensorDataReceived(sensorData));
    });
  }

  void _listenToDetectionEvents() {
    // Escuchar eventos del procesador
    _detectionEventSubscription?.cancel();
    _detectionEventSubscription = _sensorProcessor.eventStream
        .listen((detectionEvent) {
      // Pasar por el agregador
      _eventAggregator.processEvent(detectionEvent);
    });

    // Escuchar eventos agregados
    _aggregatedEventSubscription?.cancel();
    _aggregatedEventSubscription = _eventAggregator.eventStream
        .listen((aggregatedEvent) {
      if (state.isMonitoring) {
        add(DashboardDetectionEventReceived(aggregatedEvent));
      }
    });
  }

  void _listenToEsp32Connection() {
    _esp32ConnectionSubscription?.cancel();
    _esp32ConnectionSubscription = _cameraRepository.esp32ConnectedStream
        .listen((esp32Ip) {
      // ignore: avoid_print
      print('[DASHBOARD] 📡 ESP32 conectado desde IP: $esp32Ip');
      add(_DeviceConnected(esp32Ip: esp32Ip));
    });
  }

  // NUEVO - Vision Processing (Fase 2)
  void _startVisionProcessing() async {
    // CRÍTICO: Verificar si el servidor ya está corriendo (puede estar activo desde otra página)
    if (!_cameraRepository.isServerRunning) {
      // Solo intentar iniciar si NO está corriendo
      try {
        final result = await _cameraRepository.startServer();
        result.fold(
          (failure) {
            // ignore: avoid_print
            print('[DASHBOARD] ❌ Error al iniciar servidor: $failure');
            return; // No continuar si el servidor no inició
          },
          (_) {
            // ignore: avoid_print
            print('[DASHBOARD] ✅ Servidor HTTP iniciado: ${_cameraRepository.serverAddress}');
          },
        );

        if (!_cameraRepository.isServerRunning) {
          return; // No continuar si el servidor no está corriendo
        }
      } catch (e) {
        // ignore: avoid_print
        print('[DASHBOARD] ❌ Error iniciando servidor: $e');
        return; // No continuar si el servidor no inició
      }
    } else {
      // El servidor ya está corriendo, podemos reutilizarlo
      // ignore: avoid_print
      print('[DASHBOARD] ✅ Servidor HTTP ya está corriendo: ${_cameraRepository.serverAddress}');
    }

    // Inicializar VisionProcessor
    _visionProcessor = VisionProcessor();

    // Suscribirse a frames del CameraRepository directamente
    _frameSubscription = _cameraRepository.frameStream.listen((cameraFrame) {
      // Convertir CameraFrame JPEG a InputImage usando FrameConverter
      try {
        final inputImage = FrameConverter.fromJpegBytes(cameraFrame.imageBytes);
        if (inputImage != null) {
          _visionProcessor!.processFrame(inputImage);
        } else {
          // ignore: avoid_print
          print('[DASHBOARD] ⚠️ Frame inválido recibido');
        }
      } catch (e) {
        // ignore: avoid_print
        print('[DASHBOARD] ⚠️ Error convirtiendo frame: $e');
      }
    });

    // Suscribirse a eventos de visión
    _visionEventSubscription = _visionProcessor!.eventStream.listen((visionEvent) {
      // Convertir VisionEvent → DetectionEvent
      final detectionEvent = DetectionEvent(
        id: 'vision-${visionEvent.timestamp.millisecondsSinceEpoch}',
        type: visionEvent.type,
        severity: visionEvent.severity,
        timestamp: visionEvent.timestamp,
        duration: Duration(seconds: visionEvent.metadata['duration'] as int? ?? 0),
        confidence: visionEvent.confidence,
        metadata: visionEvent.metadata,
        peakValues: const {},
      );

      // Enviar al EventAggregator (existente)
      _eventAggregator.processEvent(detectionEvent);
    });

    // Actualizar HandsOffDetector con datos del IMU
    _sensorForVisionSubscription = _sensorService.stream.listen((sensorData) {
      _visionProcessor?.updateSensorData(sensorData);
    });

    // ignore: avoid_print
    print('[DASHBOARD] ✅ VisionProcessor conectado a streams');
  }

  void _stopVisionProcessing() {
    _frameSubscription?.cancel();
    _visionEventSubscription?.cancel();
    _sensorForVisionSubscription?.cancel();
    _visionProcessor?.resetDetectors();

    // Detener el servidor HTTP solo si no está siendo usado por otra página
    // El servidor se cerrará automáticamente cuando se cierre el CameraStreamBloc
    // NO lo cerramos aquí para evitar conflictos

    // ignore: avoid_print
    print('[DASHBOARD] 🛑 Procesamiento de visión detenido');
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      add(DashboardSessionTick());
    });
  }

  Future<void> _startSession() async {
    try {
      final userId = _authBloc.state.user?.id;
      if (userId == null) return;

      final position = await _getCurrentPosition();

      _sessionBloc.add(session_events.StartSession(
        userId: userId,
        deviceId: 'ESP32-001',
        latitude: position.latitude,
        longitude: position.longitude,
      ));

      _sessionBloc.stream.listen((sessionState) {
        if (sessionState is SessionActive) {
          _currentSessionId = sessionState.session.id;
        }
      });
    } catch (e) {
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
      print('Error ending session: $e');
    }
  }

  void _saveDetectionEvent(DetectionEvent detectionEvent) async {
    try {
      final userId = _authBloc.state.user?.id;
      if (userId == null || _currentSessionId == null) return;

      // NO guardar eventos informativos como noFaceDetected
      if (detectionEvent.type == det.EventType.noFaceDetected) {
        return;
      }

      final position = await _getCurrentPosition();

      // Mapear tipo de evento de detección a tipo de sesión
      String mappedEventType;
      String description = detectionEvent.toAlertMessage();

      switch (detectionEvent.type) {
        case det.EventType.weaving:
          mappedEventType = domain.EventType.distraction.value;
          break;
        case det.EventType.harshBraking:
        case det.EventType.aggressiveAcceleration:
        case det.EventType.sharpTurn:
          mappedEventType = domain.EventType.recklessDriving.value;
          break;
        case det.EventType.roughRoad:
        case det.EventType.speedBump:
          mappedEventType = domain.EventType.emergency.value;
          break;
        // Nuevos eventos de visión
        case det.EventType.distraction:
        case det.EventType.inattention:
          mappedEventType = domain.EventType.distraction.value;
          break;
        case det.EventType.handsOff:
          mappedEventType = domain.EventType.recklessDriving.value;
          break;
        case det.EventType.noFaceDetected:
          // Este caso nunca se ejecuta porque se filtra arriba
          // Solo se incluye para completar el switch exhaustivamente
          return;
      }

      // Mapear severidad
      String mappedSeverity;
      switch (detectionEvent.severity) {
        case det.EventSeverity.low:
          mappedSeverity = domain.EventSeverity.low.value;
          break;
        case det.EventSeverity.medium:
          mappedSeverity = domain.EventSeverity.medium.value;
          break;
        case det.EventSeverity.high:
        case det.EventSeverity.critical:
          mappedSeverity = domain.EventSeverity.high.value;
          break;
      }

      // Obtener datos de sensores del evento
      final sensorData = state.currentSensorData ?? SensorData(
        id: 'default-sensor-${DateTime.now().millisecondsSinceEpoch}',
        accelerationX: 0.0,
        accelerationY: 0.0,
        accelerationZ: 9.8,
        gyroscopeX: 0.0,
        gyroscopeY: 0.0,
        gyroscopeZ: 0.0,
        timestamp: DateTime.now(),
      );

      // Preparar datos de sensores (solo valores double)
      final sensorDataMap = <String, double>{
        'accelX': sensorData.accelerationX,
        'accelY': sensorData.accelerationY,
        'accelZ': sensorData.accelerationZ,
        'gyroX': sensorData.gyroscopeX,
        'gyroY': sensorData.gyroscopeY,
        'gyroZ': sensorData.gyroscopeZ,
        'confidence': detectionEvent.confidence,
        'riskScore': detectionEvent.getRiskScore(),
      };

      // Agregar valores numéricos del metadata
      detectionEvent.metadata.forEach((key, value) {
        if (value is double) {
          sensorDataMap['meta_$key'] = value;
        } else if (value is int) {
          sensorDataMap['meta_$key'] = value.toDouble();
        } else if (value is num) {
          sensorDataMap['meta_$key'] = value.toDouble();
        }
      });

      _sessionBloc.add(session_events.AddSessionEvent(
        sessionId: _currentSessionId!,
        userId: userId,
        eventType: mappedEventType,
        severity: mappedSeverity,
        description: description,
        latitude: position.latitude,
        longitude: position.longitude,
        sensorData: sensorDataMap,
      ));
    } catch (e) {
      print('Error saving detection event: $e');
    }
  }

  void _saveSessionEvent(String eventType, String severity) async {
    try {
      final userId = _authBloc.state.user?.id;
      if (userId == null || _currentSessionId == null) return;

      final position = await _getCurrentPosition();
      final currentSensorData = state.currentSensorData;

      String mappedEventType = domain.EventType.emergency.value;
      String description = eventType;

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
    _sensorSubscription?.cancel();
    _detectionEventSubscription?.cancel();
    _aggregatedEventSubscription?.cancel();
    _esp32ConnectionSubscription?.cancel();

    // NUEVO - Limpiar recursos de visión (Fase 2)
    _frameSubscription?.cancel();
    _visionEventSubscription?.cancel();
    _sensorForVisionSubscription?.cancel();
    _visionProcessor?.dispose();

    // NO detenemos el servidor aquí porque es compartido
    // El CameraStreamBloc lo gestionará cuando sea necesario

    _notificationService.dispose();
    _sensorProcessor.dispose();
    _eventAggregator.dispose();
    return super.close();
  }
}
