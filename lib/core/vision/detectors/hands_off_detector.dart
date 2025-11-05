import 'dart:async';
import '../models/hand_data.dart';
import '../models/vision_event.dart';
import '../../detection/models/event_type.dart';
import '../../detection/models/event_severity.dart';
import '../../../domain/entities/sensor_data.dart';

/// Detector híbrido: manos fuera del volante (visión + IMU)
///
/// Combina análisis de visión (detección de manos en ROI del volante)
/// con datos del IMU (movimiento del vehículo) para reducir falsos positivos.
class HandsOffDetector {
  final List<HandData> _recentHandData = [];
  // OPTIMIZADO: Reducido de 15 a 10 frames (2s @ 5 FPS) para mejor balance
  // Hands-off es más crítico, necesita buffer ligeramente mayor que otros detectores
  static const int _maxBufferSize = 10;

  bool _isHandsOff = false;
  DateTime? _handsOffStartTime;

  // Umbrales de detección optimizados para 80% precisión / 20% falsos positivos
  // OPTIMIZADO: Reducido de 3s a 2s para respuesta más rápida
  // Manos fuera del volante por 2s en movimiento es suficientemente peligroso
  static const Duration _minHandsOffDuration = Duration(seconds: 2);
  // OPTIMIZADO: Reducido de 8s a 6s para permitir más alertas si persiste
  static const Duration _cooldownDuration = Duration(seconds: 6);

  // Umbrales IMU para detectar movimiento (sin cambios - ya son adecuados)
  static const double _minAccelMagnitude = 1.5;  // m/s²
  static const double _minGyroMagnitude = 20.0;  // °/s

  DateTime? _lastEventTime;
  SensorData? _latestSensorData;

  final _eventController = StreamController<VisionEvent>.broadcast();
  Stream<VisionEvent> get eventStream => _eventController.stream;

  /// Actualizar datos del IMU (llamado desde SensorDataProcessor)
  void updateSensorData(SensorData sensorData) {
    _latestSensorData = sensorData;
  }

  void processHandData(HandData? handData) {
    if (handData == null) {
      _resetDetection();
      return;
    }

    _recentHandData.add(handData);
    if (_recentHandData.length > _maxBufferSize) {
      _recentHandData.removeAt(0);
    }

    // Verificar cooldown
    if (_lastEventTime != null) {
      final timeSinceLastEvent = DateTime.now().difference(_lastEventTime!);
      if (timeSinceLastEvent < _cooldownDuration) {
        return;
      }
    }

    // CONDICIÓN 1 (Visión): Sin manos en volante
    final hasHandsOff = handData.handsOnWheel == 0;

    // CONDICIÓN 2 (IMU): Vehículo en movimiento
    final isMoving = _isVehicleMoving();

    // DETECCIÓN HÍBRIDA: Ambas condiciones deben cumplirse
    if (hasHandsOff && isMoving) {
      _handsOffStartTime ??= DateTime.now();

      final handsOffDuration = DateTime.now().difference(_handsOffStartTime!);

      if (handsOffDuration >= _minHandsOffDuration && !_isHandsOff) {
        _isHandsOff = true;
        _emitHandsOffEvent(handsOffDuration);
      }
    } else {
      _resetDetection();
    }
  }

  bool _isVehicleMoving() {
    if (_latestSensorData == null) return false;

    final accelMagnitude = _latestSensorData!.accelerationMagnitude;
    final gyroMagnitude = _latestSensorData!.gyroscopeMagnitude;

    // Vehículo se considera en movimiento si hay aceleración o rotación significativa
    return accelMagnitude > _minAccelMagnitude || gyroMagnitude > _minGyroMagnitude;
  }

  void _emitHandsOffEvent(Duration duration) {
    final severity = _calculateSeverity(duration);
    final confidence = _calculateConfidence();

    final event = VisionEvent(
      type: EventType.handsOff,
      severity: severity,
      timestamp: DateTime.now(),
      confidence: confidence,
      metadata: {
        'duration': duration.inSeconds,
        'isMoving': _isVehicleMoving(),
        'accelMagnitude': _latestSensorData?.accelerationMagnitude ?? 0.0,
        'gyroMagnitude': _latestSensorData?.gyroscopeMagnitude ?? 0.0,
        'detectionMethod': 'hybrid',
      },
    );

    _eventController.add(event);
    _lastEventTime = DateTime.now();

    print('[HandsOffDetector] 🚨 Manos fuera del volante detectado '
        '(duración: ${duration.inSeconds}s, severidad: ${severity.name})');
  }

  EventSeverity _calculateSeverity(Duration duration) {
    if (duration.inSeconds >= 8) {
      return EventSeverity.critical;
    } else if (duration.inSeconds >= 6) {
      return EventSeverity.high;
    } else if (duration.inSeconds >= 4) {
      return EventSeverity.medium;
    } else {
      return EventSeverity.low;
    }
  }

  double _calculateConfidence() {
    if (_recentHandData.isEmpty) return 0.0;

    final handsOffCount = _recentHandData
        .where((data) => data.handsOnWheel == 0)
        .length;

    final visionConfidence = (handsOffCount / _recentHandData.length).clamp(0.0, 1.0);

    // Confidence híbrida: 70% visión + 30% IMU
    final imuConfidence = _isVehicleMoving() ? 1.0 : 0.0;

    return (visionConfidence * 0.7 + imuConfidence * 0.3).clamp(0.0, 1.0);
  }

  void _resetDetection() {
    _isHandsOff = false;
    _handsOffStartTime = null;
  }

  void reset() {
    _recentHandData.clear();
    _resetDetection();
    _lastEventTime = null;
  }

  void dispose() {
    _eventController.close();
  }
}
