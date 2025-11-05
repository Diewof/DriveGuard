import 'dart:async';
import '../models/face_data.dart';
import '../models/vision_event.dart';
import '../../detection/models/event_type.dart';
import '../../detection/models/event_severity.dart';

/// Detector de distracción por uso de teléfono móvil
///
/// Detecta cuando el conductor está mirando hacia abajo (headPitch < -25°)
/// de forma sostenida, lo cual es indicativo de uso de teléfono móvil.
class DistractionDetector {
  // Buffer de datos faciales recientes
  final List<FaceData> _recentFaceData = [];
  // OPTIMIZADO: Reducido de 15 a 8 frames (1.6s @ 5 FPS) para detección más rápida
  static const int _maxBufferSize = 8;

  // Estado del detector
  bool _isDistracted = false;
  DateTime? _distractionStartTime;

  // Umbrales de detección optimizados para 80% precisión / 20% falsos positivos
  // OPTIMIZADO: Ajustado de -20° a -18° para alinearse con FaceData.isLookingAway
  // Esto reduce el gap y mejora la cobertura de detección
  static const double _downwardPitchThreshold = -18.0;
  // OPTIMIZADO: Reducido de 2s a 1.2s para respuesta más rápida
  // Mirar el celular por >1 segundo es suficiente para alertar
  static const Duration _minDistractionDuration = Duration(milliseconds: 1200);
  // OPTIMIZADO: Reducido de 5s a 4s para permitir más alertas si persiste
  static const Duration _cooldownDuration = Duration(seconds: 4);

  DateTime? _lastEventTime;

  final _eventController = StreamController<VisionEvent>.broadcast();
  Stream<VisionEvent> get eventStream => _eventController.stream;

  /// Procesa datos faciales para detectar distracción
  void processFaceData(FaceData? faceData) {
    // Si no hay datos faciales, resetear
    if (faceData == null) {
      _resetDetection();
      return;
    }

    // Agregar al buffer
    _recentFaceData.add(faceData);
    if (_recentFaceData.length > _maxBufferSize) {
      _recentFaceData.removeAt(0);
    }

    // DEBUG: Log de pitch cada 10 frames para diagnosticar
    if (_recentFaceData.length % 10 == 0) {
      print('[DistractionDetector] 🔍 DEBUG: headPitch = ${faceData.headPitch.toStringAsFixed(1)}° '
          '(umbral: $_downwardPitchThreshold°, mirando abajo: ${faceData.headPitch < _downwardPitchThreshold})');
    }

    // Verificar cooldown
    if (_lastEventTime != null) {
      final timeSinceLastEvent = DateTime.now().difference(_lastEventTime!);
      if (timeSinceLastEvent < _cooldownDuration) {
        return; // Aún en cooldown
      }
    }

    // Detectar si está mirando hacia abajo (usando teléfono)
    final isLookingDown = faceData.headPitch < _downwardPitchThreshold;

    if (isLookingDown) {
      // Iniciar o continuar detección
      _distractionStartTime ??= DateTime.now();

      final distractionDuration = DateTime.now().difference(_distractionStartTime!);

      // DEBUG: Log cuando está mirando hacia abajo
      print('[DistractionDetector] 👀 Mirando hacia abajo: ${faceData.headPitch.toStringAsFixed(1)}° '
          '(duración: ${distractionDuration.inSeconds}s / ${_minDistractionDuration.inSeconds}s)');

      if (distractionDuration >= _minDistractionDuration && !_isDistracted) {
        // Detectar evento
        _isDistracted = true;
        _emitDistractionEvent(distractionDuration);
      }
    } else {
      // No está mirando hacia abajo, resetear
      _resetDetection();
    }
  }

  void _emitDistractionEvent(Duration duration) {
    final severity = _calculateSeverity(duration);
    final confidence = _calculateConfidence();

    final event = VisionEvent(
      type: EventType.distraction,
      severity: severity,
      timestamp: DateTime.now(),
      confidence: confidence,
      metadata: {
        'duration': duration.inSeconds,
        'avgPitch': _getAveragePitch(),
        'detectionMethod': 'headPose',
      },
    );

    _eventController.add(event);
    _lastEventTime = DateTime.now();

    print('[DistractionDetector] 🚨 Distracción detectada '
        '(duración: ${duration.inSeconds}s, severidad: ${severity.name})');
  }

  EventSeverity _calculateSeverity(Duration duration) {
    if (duration.inSeconds >= 6) {
      return EventSeverity.critical;
    } else if (duration.inSeconds >= 4) {
      return EventSeverity.high;
    } else if (duration.inSeconds >= 3) {
      return EventSeverity.medium;
    } else {
      return EventSeverity.low;
    }
  }

  double _calculateConfidence() {
    if (_recentFaceData.isEmpty) return 0.0;

    // Contar cuántos frames están mirando hacia abajo
    final lookingDownCount = _recentFaceData
        .where((data) => data.headPitch < _downwardPitchThreshold)
        .length;

    return (lookingDownCount / _recentFaceData.length).clamp(0.0, 1.0);
  }

  double _getAveragePitch() {
    if (_recentFaceData.isEmpty) return 0.0;

    final totalPitch = _recentFaceData
        .map((data) => data.headPitch)
        .reduce((a, b) => a + b);

    return totalPitch / _recentFaceData.length;
  }

  void _resetDetection() {
    _isDistracted = false;
    _distractionStartTime = null;
  }

  void reset() {
    _recentFaceData.clear();
    _resetDetection();
    _lastEventTime = null;
  }

  void dispose() {
    _eventController.close();
  }
}
