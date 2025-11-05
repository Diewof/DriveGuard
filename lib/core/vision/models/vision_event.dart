import 'package:equatable/equatable.dart';
import '../../detection/models/event_type.dart';
import '../../detection/models/event_severity.dart';

/// Evento de detección basado en visión por computadora (ESP32-CAM)
///
/// Representa un evento detectado mediante el análisis de frames de video
/// provenientes del ESP32-CAM, procesados con MediaPipe en el dispositivo móvil.
class VisionEvent extends Equatable {
  /// Tipo de evento detectado
  final EventType type;

  /// Severidad del evento (LOW, MEDIUM, HIGH, CRITICAL)
  final EventSeverity severity;

  /// Momento en que se detectó el evento
  final DateTime timestamp;

  /// Nivel de confianza de la detección (0.0 - 1.0)
  ///
  /// Representa la certeza del modelo ML sobre la detección.
  /// Valores típicos:
  /// - 0.0 - 0.5: Baja confianza (descartar)
  /// - 0.5 - 0.7: Confianza moderada (considerar contexto)
  /// - 0.7 - 0.9: Alta confianza (confiable)
  /// - 0.9 - 1.0: Muy alta confianza (muy confiable)
  final double confidence;

  /// Metadata adicional específica del evento
  ///
  /// Puede contener información como:
  /// - headYaw, headPitch: Para eventos de desatención
  /// - handPosition: Para eventos de distracción o manos fuera del volante
  /// - frameNumber: Número de frame donde se detectó
  /// - processingTimeMs: Tiempo de procesamiento del frame
  final Map<String, dynamic> metadata;

  const VisionEvent({
    required this.type,
    required this.severity,
    required this.timestamp,
    required this.confidence,
    this.metadata = const {},
  });

  /// Verifica si el evento tiene confianza suficiente
  bool get isHighConfidence => confidence >= 0.7;

  /// Verifica si el evento es crítico
  bool get isCritical => severity == EventSeverity.critical;

  /// Verifica si el evento requiere alerta inmediata
  bool get requiresImmediateAlert =>
      (severity >= EventSeverity.high) && isHighConfidence;

  /// Crea una copia del evento con campos modificados
  VisionEvent copyWith({
    EventType? type,
    EventSeverity? severity,
    DateTime? timestamp,
    double? confidence,
    Map<String, dynamic>? metadata,
  }) {
    return VisionEvent(
      type: type ?? this.type,
      severity: severity ?? this.severity,
      timestamp: timestamp ?? this.timestamp,
      confidence: confidence ?? this.confidence,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [type, severity, timestamp, confidence, metadata];

  @override
  String toString() {
    return 'VisionEvent('
        'type: ${type.displayName}, '
        'severity: ${severity.displayName}, '
        'confidence: ${(confidence * 100).toStringAsFixed(1)}%, '
        'timestamp: $timestamp'
        ')';
  }

  /// Convierte el evento a un mapa para serialización
  Map<String, dynamic> toJson() {
    return {
      'type': type.value,
      'severity': severity.value,
      'timestamp': timestamp.toIso8601String(),
      'confidence': confidence,
      'metadata': metadata,
    };
  }

  /// Crea un VisionEvent desde un mapa JSON
  factory VisionEvent.fromJson(Map<String, dynamic> json) {
    return VisionEvent(
      type: EventType.fromValue(json['type'] as String),
      severity: EventSeverity.fromValue(json['severity'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
      confidence: (json['confidence'] as num).toDouble(),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }
}
