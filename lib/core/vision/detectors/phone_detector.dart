import 'dart:async';
import 'dart:math';
import '../models/face_data.dart';
import '../models/hand_data.dart';
import '../models/vision_event.dart';
import '../../detection/models/event_type.dart';
import '../../detection/models/event_severity.dart';

/// Detector de distracción por uso de teléfono móvil
///
/// Diferenciado de InattentionDetector mediante:
/// 1. Zonas específicas de uso de teléfono (tablero, regazo)
/// 2. Detección de teléfono en manos
/// 3. Duración más sostenida (>2 segundos)
/// 4. Ángulos más precisos para posición típica de teléfono
class PhoneDetector {
  // Buffers de datos
  final List<FaceData> _recentFaceData = [];
  final List<HandData> _recentHandData = [];
  static const int _maxBufferSize = 10; // 2 segundos @ 5 FPS

  // Estado del detector
  bool _isUsingPhone = false;
  DateTime? _phoneUseStartTime;

  // Umbrales de detección optimizados para uso de teléfono
  // ZONA TABLERO: Conductor mira ligeramente abajo hacia el soporte del teléfono
  static const double _dashboardPitchStart = -12.0;  // Inicio del rango (más sensible)
  static const double _dashboardPitchEnd = -35.0;    // Fin del rango (rango más amplio)

  // ZONA REGAZO: Conductor mira muy abajo hacia sus piernas
  static const double _lapPitchThreshold = -30.0;  // Muy abajo (más negativo)

  // YAW: Permitir ligera rotación lateral (teléfono puede estar un poco al lado)
  static const double _maxYawDeviation = 30.0;    // Más tolerante (antes: 25°)

  // DURACIÓN: Reducido para mejor sensibilidad en BETA
  static const Duration _minPhoneUseDuration = Duration(milliseconds: 1000); // 1 segundo (antes: 2s)
  static const Duration _cooldownDuration = Duration(seconds: 5);

  // SISTEMA DE CONFIANZA ACUMULATIVA
  int _consecutiveDetectionFrames = 0;

  // TOLERANCIA A INTERRUPCIONES: Permitir pequeños gaps en detección
  static const int _maxMissedFrames = 2; // Permitir 2 frames perdidos (~400ms @ 5fps)
  int _missedFramesCount = 0;

  DateTime? _lastEventTime;

  final _eventController = StreamController<VisionEvent>.broadcast();
  Stream<VisionEvent> get eventStream => _eventController.stream;

  /// Procesa datos faciales y de manos para detectar uso de teléfono
  void processData(FaceData? faceData, HandData? handData) {
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

    if (handData != null) {
      _recentHandData.add(handData);
      if (_recentHandData.length > _maxBufferSize) {
        _recentHandData.removeAt(0);
      }
    }

    // Verificar cooldown
    if (_lastEventTime != null) {
      final timeSinceLastEvent = DateTime.now().difference(_lastEventTime!);
      if (timeSinceLastEvent < _cooldownDuration) {
        return;
      }
    }

    // DETECCIÓN MULTI-CRITERIO: Combinar pose facial + posición de manos
    final detection = _detectPhoneUse(faceData, handData);

    if (detection.isUsingPhone) {
      // Iniciar o continuar detección
      _phoneUseStartTime ??= DateTime.now();

      final useDuration = DateTime.now().difference(_phoneUseStartTime!);

      // Incrementar frames consecutivos para confianza
      _consecutiveDetectionFrames++;

      // DEBUG MEJORADO: Log continuo con progreso
      print('[PhoneDetector] 📱 USO TELÉFONO DETECTADO: '
          'pitch=${faceData.headPitch.toStringAsFixed(1)}°, '
          'yaw=${faceData.headYaw.toStringAsFixed(1)}°, '
          'zona=${detection.zone?.name ?? "unknown"}, '
          'manos=${detection.hasPhoneInHand ? "SÍ" : "no"}, '
          'duración=${useDuration.inMilliseconds}ms / ${_minPhoneUseDuration.inMilliseconds}ms '
          '(${(useDuration.inMilliseconds / _minPhoneUseDuration.inMilliseconds * 100).toStringAsFixed(0)}% progreso), '
          'frames=${_consecutiveDetectionFrames}, '
          'confianza=${(detection.confidence * 100).toStringAsFixed(0)}%');

      // Reset contador de frames perdidos (está detectando correctamente)
      _missedFramesCount = 0;

      if (useDuration >= _minPhoneUseDuration && !_isUsingPhone) {
        _isUsingPhone = true;
        _emitPhoneEvent(useDuration, detection);
      }
    } else {
      // No está usando teléfono en este frame

      // TOLERANCIA: Permitir algunos frames perdidos antes de resetear
      if (_phoneUseStartTime != null) {
        _missedFramesCount++;

        if (_missedFramesCount > _maxMissedFrames) {
          // Muchos frames perdidos, resetear completamente
          print('[PhoneDetector] ⏸️ Detección interrumpida (>$_maxMissedFrames frames perdidos)');
          _resetDetection();
        } else {
          // Dentro de tolerancia, mantener detección activa
          print('[PhoneDetector] ⚠️ Frame perdido: $_missedFramesCount/$_maxMissedFrames');
        }
      }
    }
  }

  /// Detecta uso de teléfono mediante múltiples criterios
  PhoneDetection _detectPhoneUse(FaceData faceData, HandData? handData) {
    final pitch = faceData.headPitch;
    final yaw = faceData.headYaw.abs();

    // CRITERIO 1: Zona de mirada
    PhoneZone? zone;
    bool isInPhoneZone = false;

    // ZONA TABLERO: Mirando ligeramente abajo (típico soporte de teléfono)
    // Rango: entre -12° y -35° (ampliado para mayor sensibilidad)
    if (pitch <= _dashboardPitchStart && pitch >= _dashboardPitchEnd && yaw <= _maxYawDeviation) {
      zone = PhoneZone.dashboard;
      isInPhoneZone = true;
    }
    // ZONA REGAZO: Mirando muy abajo (teléfono en las piernas)
    // pitch < -30° (más negativo que tablero)
    else if (pitch < _lapPitchThreshold && yaw <= _maxYawDeviation) {
      zone = PhoneZone.lap;
      isInPhoneZone = true;
    }

    // CRITERIO 2: Detección de teléfono en manos
    bool hasPhoneInHand = _detectPhoneInHands(handData);

    // DECISIÓN FINAL: Combinar ambos criterios
    // Caso 1: Mirando zona de teléfono + teléfono en manos = USO SEGURO
    if (isInPhoneZone && hasPhoneInHand) {
      return PhoneDetection(
        isUsingPhone: true,
        zone: zone,
        hasPhoneInHand: true,
        confidence: 0.95,
      );
    }

    // Caso 2: Solo mirando zona de teléfono (sin datos de manos o sin teléfono visible)
    // Sistema de confianza gradual: más frames consecutivos = mayor confianza
    if (isInPhoneZone) {
      // Confianza base: 0.6
      // +0.05 por cada 3 frames consecutivos (máximo +0.3)
      double baseConfidence = 0.6;
      double frameBonus = (_consecutiveDetectionFrames / 3).clamp(0, 6) * 0.05;
      double finalConfidence = (baseConfidence + frameBonus).clamp(0.6, 0.9);

      return PhoneDetection(
        isUsingPhone: true,
        zone: zone,
        hasPhoneInHand: false,
        confidence: finalConfidence,
      );
    }

    // Caso 3: Teléfono en manos pero no mirando zona típica
    // Puede estar hablando por teléfono (también es distracción)
    if (hasPhoneInHand) {
      return PhoneDetection(
        isUsingPhone: true,
        zone: PhoneZone.hand,
        hasPhoneInHand: true,
        confidence: 0.8,
      );
    }

    // No está usando teléfono
    return PhoneDetection(
      isUsingPhone: false,
      zone: null,
      hasPhoneInHand: false,
      confidence: 0.0,
    );
  }

  /// Detecta si hay un teléfono en las manos del conductor
  ///
  /// Heurística: Si ambas manos están fuera del volante Y están cerca una de la otra
  /// es probable que esté sosteniendo un objeto (teléfono).
  bool _detectPhoneInHands(HandData? handData) {
    if (handData == null) return false;

    final leftPos = handData.leftHandPosition;
    final rightPos = handData.rightHandPosition;

    // Ambas manos deben estar detectadas
    if (leftPos == null || rightPos == null) return false;

    // Ambas manos deben estar FUERA del volante
    if (!handData.bothHandsOff) return false;

    // Calcular distancia entre manos usando teorema de Pitágoras
    final dx = leftPos.dx - rightPos.dx;
    final dy = leftPos.dy - rightPos.dy;
    final distanceSquared = dx * dx + dy * dy;
    final distance = pow(distanceSquared, 0.5).toDouble();

    // Si las manos están relativamente cerca (< 200 píxeles en imagen 640x480)
    // y ambas fuera del volante → probable teléfono en manos
    const double maxHandDistance = 200.0;

    if (distance < maxHandDistance) {
      // Teléfono posiblemente en manos
      return true;
    }

    return false;
  }

  void _emitPhoneEvent(Duration duration, PhoneDetection detection) {
    final severity = _calculateSeverity(duration, detection);

    final event = VisionEvent(
      type: EventType.distraction, // Usar el mismo tipo pero con metadata diferente
      severity: severity,
      timestamp: DateTime.now(),
      confidence: detection.confidence,
      metadata: {
        'duration': duration.inSeconds,
        'zone': detection.zone?.name ?? 'unknown',
        'hasPhoneInHand': detection.hasPhoneInHand,
        'avgPitch': _getAveragePitch(),
        'detectionMethod': 'phoneUse',
      },
    );

    _eventController.add(event);
    _lastEventTime = DateTime.now();

    print('[PhoneDetector] 🚨🚨🚨 ALERTA: USO DE TELÉFONO CONFIRMADO 🚨🚨🚨');
    print('[PhoneDetector] 📊 Detalles:');
    print('[PhoneDetector]   - Zona: ${detection.zone?.name}');
    print('[PhoneDetector]   - Duración: ${duration.inSeconds}s (${duration.inMilliseconds}ms)');
    print('[PhoneDetector]   - Severidad: ${severity.name.toUpperCase()}');
    print('[PhoneDetector]   - Teléfono en manos: ${detection.hasPhoneInHand ? "SÍ" : "NO"}');
    print('[PhoneDetector]   - Confianza: ${(detection.confidence * 100).toStringAsFixed(0)}%');
    print('[PhoneDetector]   - Frames consecutivos: $_consecutiveDetectionFrames');
    print('[PhoneDetector]   - Pitch promedio: ${_getAveragePitch().toStringAsFixed(1)}°');
  }

  EventSeverity _calculateSeverity(Duration duration, PhoneDetection detection) {
    // IMPORTANTE: Uso de teléfono SIEMPRE es MEDIUM o superior
    // La mayoría de accidentes comienzan al ver el celular
    int severityScore = 2; // BASE: Empieza en MEDIUM (no LOW)

    // Duración aumenta severidad
    if (duration.inSeconds >= 8) {
      severityScore += 3; // Total: 5+ = CRITICAL
    } else if (duration.inSeconds >= 5) {
      severityScore += 2; // Total: 4 = HIGH
    } else if (duration.inSeconds >= 3) {
      severityScore += 1; // Total: 3 = HIGH
    }
    // 2 segundos = score 2 = MEDIUM (base)

    // Teléfono visible en manos: aumenta riesgo
    if (detection.hasPhoneInHand) {
      severityScore += 1;
    }

    // Zona de riesgo: regazo es MÁS peligroso (no ve la carretera)
    if (detection.zone == PhoneZone.lap) {
      severityScore += 1;
    }

    // Mapear score a severidad
    if (severityScore >= 5) {
      return EventSeverity.critical; // 8+ segundos o regazo+manos
    } else if (severityScore >= 3) {
      return EventSeverity.high;     // 3+ segundos o manos detectadas
    } else {
      return EventSeverity.medium;   // Mínimo: 2 segundos mirando teléfono
    }
    // NOTA: LOW ya no es posible para uso de teléfono
  }

  double _getAveragePitch() {
    if (_recentFaceData.isEmpty) return 0.0;

    final totalPitch = _recentFaceData
        .map((data) => data.headPitch)
        .reduce((a, b) => a + b);

    return totalPitch / _recentFaceData.length;
  }

  void _resetDetection() {
    _isUsingPhone = false;
    _phoneUseStartTime = null;
    _consecutiveDetectionFrames = 0;
    _missedFramesCount = 0;
  }

  void reset() {
    _recentFaceData.clear();
    _recentHandData.clear();
    _resetDetection();
    _lastEventTime = null;
  }

  void dispose() {
    _eventController.close();
  }
}

/// Zonas donde típicamente se usa el teléfono al conducir
enum PhoneZone {
  dashboard,  // Tablero (soporte de teléfono)
  lap,        // Regazo (entre las piernas)
  hand,       // En la mano (hablando)
}

/// Resultado de detección de uso de teléfono
class PhoneDetection {
  final bool isUsingPhone;
  final PhoneZone? zone;
  final bool hasPhoneInHand;
  final double confidence;

  PhoneDetection({
    required this.isUsingPhone,
    this.zone,
    required this.hasPhoneInHand,
    required this.confidence,
  });
}
