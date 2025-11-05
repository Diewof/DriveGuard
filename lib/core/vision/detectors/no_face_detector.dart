import 'dart:async';
import '../models/face_data.dart';
import '../models/vision_event.dart';
import '../../detection/models/event_type.dart';
import '../../detection/models/event_severity.dart';

/// Detector de ausencia de rostro
///
/// Detecta cuando no se detecta el rostro del conductor por un período
/// prolongado (>10 segundos), lo cual puede indicar que el conductor está
/// mal posicionado o fuera del campo de visión de la cámara.
///
/// NOTA IMPORTANTE: Esta alerta es INFORMATIVA, no se considera como
/// distracción o conducción temeraria. Solo notifica al usuario para que
/// ajuste su posición.
class NoFaceDetector {
  DateTime? _noFaceStartTime;
  bool _isNoFaceAlertActive = false;

  // Tiempo mínimo sin rostro antes de emitir alerta: 10 segundos
  static const Duration _minNoFaceDuration = Duration(seconds: 10);

  // Cooldown entre alertas: 30 segundos (para no saturar con alertas repetitivas)
  static const Duration _cooldownDuration = Duration(seconds: 30);

  DateTime? _lastEventTime;

  final _eventController = StreamController<VisionEvent>.broadcast();
  Stream<VisionEvent> get eventStream => _eventController.stream;

  /// Procesa datos de rostro (o ausencia de ellos)
  void processFaceData(FaceData? faceData) {
    if (faceData != null) {
      // Rostro detectado - resetear detección
      _resetDetection();
      return;
    }

    // Sin rostro detectado
    if (_noFaceStartTime == null) {
      // Iniciar conteo de tiempo sin rostro
      _noFaceStartTime = DateTime.now();
      return;
    }

    // Verificar cooldown
    if (_lastEventTime != null) {
      final timeSinceLastEvent = DateTime.now().difference(_lastEventTime!);
      if (timeSinceLastEvent < _cooldownDuration) {
        return;
      }
    }

    // Calcular duración sin rostro
    final noFaceDuration = DateTime.now().difference(_noFaceStartTime!);

    // Si supera el umbral y no hay alerta activa, emitir evento
    if (noFaceDuration >= _minNoFaceDuration && !_isNoFaceAlertActive) {
      _isNoFaceAlertActive = true;
      _emitNoFaceEvent(noFaceDuration);
    }
  }

  void _emitNoFaceEvent(Duration duration) {
    // Severidad baja - es informativa, no crítica
    const severity = EventSeverity.low;
    const confidence = 1.0; // Alta confianza - sabemos con certeza que no hay rostro

    final event = VisionEvent(
      type: EventType.noFaceDetected,
      severity: severity,
      timestamp: DateTime.now(),
      confidence: confidence,
      metadata: {
        'duration': duration.inSeconds,
        'isInformative': true, // Marcador especial para indicar que es solo informativa
      },
    );

    _eventController.add(event);
    _lastEventTime = DateTime.now();

    print('[NoFaceDetector] ℹ️ Sin rostro detectado '
        '(duración: ${duration.inSeconds}s) - ALERTA INFORMATIVA');
  }

  void _resetDetection() {
    _isNoFaceAlertActive = false;
    _noFaceStartTime = null;
  }

  void reset() {
    _resetDetection();
    _lastEventTime = null;
  }

  void dispose() {
    _eventController.close();
  }
}
