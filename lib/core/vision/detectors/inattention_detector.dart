import 'dart:async';
import '../models/face_data.dart';
import '../models/vision_event.dart';
import '../../detection/models/event_type.dart';
import '../../detection/models/event_severity.dart';

/// Detector de desatención visual (mirada fuera de la carretera)
///
/// Detecta cuando el conductor no está mirando al frente de forma sostenida,
/// específicamente mirando hacia los LADOS o ARRIBA.
///
/// DIFERENCIACIÓN: NO detecta miradas hacia abajo (eso es PhoneDetector)
/// - InattentionDetector: Miradas laterales y hacia arriba (fuera de la vía)
/// - PhoneDetector: Miradas hacia abajo (tablero/regazo/teléfono)
class InattentionDetector {
  final List<FaceData> _recentFaceData = [];
  // OPTIMIZADO: Reducido de 15 a 8 frames para detección más rápida
  // @ 5 FPS: 8 frames = 1.6 segundos de buffer
  static const int _maxBufferSize = 8;

  bool _isInattentive = false;
  DateTime? _inattentionStartTime;

  // Umbrales de detección optimizados para 80% precisión / 20% falsos positivos
  // ELIMINADOS: _maxYawDeviation y _maxPitchDeviation (ahora se usan los de FaceData)
  // OPTIMIZADO: Reducido de 2s a 1.5s para respuesta más rápida
  static const Duration _minInattentionDuration = Duration(milliseconds: 1500);
  // OPTIMIZADO: Reducido de 5s a 4s para permitir más alertas si persiste
  static const Duration _cooldownDuration = Duration(seconds: 4);

  DateTime? _lastEventTime;

  final _eventController = StreamController<VisionEvent>.broadcast();
  Stream<VisionEvent> get eventStream => _eventController.stream;

  void processFaceData(FaceData? faceData) {
    if (faceData == null) {
      _resetDetection();
      return;
    }

    _recentFaceData.add(faceData);
    if (_recentFaceData.length > _maxBufferSize) {
      _recentFaceData.removeAt(0);
    }

    // Verificar cooldown
    if (_lastEventTime != null) {
      final timeSinceLastEvent = DateTime.now().difference(_lastEventTime!);
      if (timeSinceLastEvent < _cooldownDuration) {
        return;
      }
    }

    // Detectar desatención: NO está mirando al frente
    // IMPORTANTE: Excluir miradas hacia abajo (< -15°) que son manejadas por PhoneDetector
    final isNotLookingForward = !faceData.isLookingForward;
    final isLookingDown = faceData.headPitch < -15.0; // Umbral para considerar "hacia abajo"

    // Solo detectar desatención si NO está mirando al frente Y NO está mirando hacia abajo
    if (isNotLookingForward && !isLookingDown) {
      _inattentionStartTime ??= DateTime.now();

      final inattentionDuration = DateTime.now().difference(_inattentionStartTime!);

      if (inattentionDuration >= _minInattentionDuration && !_isInattentive) {
        _isInattentive = true;
        _emitInattentionEvent(inattentionDuration);
      }
    } else {
      _resetDetection();
    }
  }

  void _emitInattentionEvent(Duration duration) {
    final severity = _calculateSeverity(duration);
    final confidence = _calculateConfidence();

    final event = VisionEvent(
      type: EventType.inattention,
      severity: severity,
      timestamp: DateTime.now(),
      confidence: confidence,
      metadata: {
        'duration': duration.inSeconds,
        'avgYaw': _getAverageYaw(),
        'avgPitch': _getAveragePitch(),
        'maxDeviation': _getMaxDeviation(),
      },
    );

    _eventController.add(event);
    _lastEventTime = DateTime.now();

    print('[InattentionDetector] 🚨 Desatención detectada '
        '(duración: ${duration.inSeconds}s, severidad: ${severity.name})');
  }

  EventSeverity _calculateSeverity(Duration duration) {
    final maxDeviation = _getMaxDeviation();

    // Severidad basada en duración + desviación
    if (duration.inSeconds >= 5 || maxDeviation > 60.0) {
      return EventSeverity.critical;
    } else if (duration.inSeconds >= 4 || maxDeviation > 45.0) {
      return EventSeverity.high;
    } else if (duration.inSeconds >= 3 || maxDeviation > 35.0) {
      return EventSeverity.medium;
    } else {
      return EventSeverity.low;
    }
  }

  double _calculateConfidence() {
    if (_recentFaceData.isEmpty) return 0.0;

    final notLookingForwardCount = _recentFaceData
        .where((data) => !data.isLookingForward)
        .length;

    return (notLookingForwardCount / _recentFaceData.length).clamp(0.0, 1.0);
  }

  double _getAverageYaw() {
    if (_recentFaceData.isEmpty) return 0.0;
    return _recentFaceData.map((d) => d.headYaw).reduce((a, b) => a + b) /
        _recentFaceData.length;
  }

  double _getAveragePitch() {
    if (_recentFaceData.isEmpty) return 0.0;
    return _recentFaceData.map((d) => d.headPitch).reduce((a, b) => a + b) /
        _recentFaceData.length;
  }

  double _getMaxDeviation() {
    if (_recentFaceData.isEmpty) return 0.0;

    return _recentFaceData
        .map((data) => [data.headYaw.abs(), data.headPitch.abs()].reduce((a, b) => a > b ? a : b))
        .reduce((a, b) => a > b ? a : b);
  }

  void _resetDetection() {
    _isInattentive = false;
    _inattentionStartTime = null;
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
