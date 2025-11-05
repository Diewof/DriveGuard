import 'package:equatable/equatable.dart';
import 'event_type.dart';
import 'event_severity.dart';
import 'sensor_reading.dart';

/// Representa un evento de conducción detectado
class DetectionEvent extends Equatable {
  final String id;
  final EventType type;
  final EventSeverity severity;
  final DateTime timestamp;
  final Duration duration;
  final Map<String, double> peakValues;
  final double confidence; // 0.0 - 1.0
  final Map<String, dynamic> metadata;
  final List<SensorReading> readings;

  const DetectionEvent({
    required this.id,
    required this.type,
    required this.severity,
    required this.timestamp,
    required this.duration,
    required this.peakValues,
    required this.confidence,
    this.metadata = const {},
    this.readings = const [],
  });

  /// Calcula puntuación de riesgo (0-100)
  double getRiskScore() {
    double baseScore = severity.priority * 20.0; // 20, 40, 60, 80
    double confidenceBoost = confidence * 20.0; // hasta +20
    return (baseScore + confidenceBoost).clamp(0.0, 100.0);
  }

  /// Convierte el evento a un mensaje de alerta legible
  String toAlertMessage() {
    switch (type) {
      case EventType.harshBraking:
        return 'Frenado brusco detectado';
      case EventType.aggressiveAcceleration:
        return 'Aceleración agresiva detectada';
      case EventType.sharpTurn:
        return 'Giro cerrado a alta velocidad';
      case EventType.weaving:
        return 'Zigzagueo detectado - posible distracción';
      case EventType.roughRoad:
        return 'Camino irregular o con baches';
      case EventType.speedBump:
        return 'Paso por lomo de toro';
      // Eventos de visión (Fase 1 - preparación para Fase 2)
      case EventType.distraction:
        return 'Distracción detectada - uso de teléfono';
      case EventType.inattention:
        return 'Desatención visual detectada';
      case EventType.handsOff:
        return 'Manos fuera del volante detectadas';
      case EventType.noFaceDetected:
        return 'Ajusta tu posición - rostro no detectado';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'severity': severity.value,
      'timestamp': timestamp.toIso8601String(),
      'duration': duration.inMilliseconds,
      'peakValues': peakValues,
      'confidence': confidence,
      'metadata': metadata,
      'riskScore': getRiskScore(),
    };
  }

  factory DetectionEvent.fromJson(Map<String, dynamic> json) {
    return DetectionEvent(
      id: json['id'] as String,
      type: EventType.fromValue(json['type'] as String),
      severity: EventSeverity.fromValue(json['severity'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
      duration: Duration(milliseconds: json['duration'] as int),
      peakValues: Map<String, double>.from(json['peakValues'] as Map),
      confidence: (json['confidence'] as num).toDouble(),
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        severity,
        timestamp,
        duration,
        peakValues,
        confidence,
        metadata,
      ];
}
