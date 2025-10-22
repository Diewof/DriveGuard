import 'dart:math';
import 'base_detector.dart';
import '../models/sensor_reading.dart';
import '../models/event_type.dart';
import '../models/event_severity.dart';
import '../models/sensor_statistics.dart';
import '../config/detection_thresholds.dart';

/// Detector de aceleración agresiva
///
/// Detecta cuando el conductor acelera de forma brusca desde parada o baja velocidad.
/// Comportamiento esperado:
/// - Acelerómetro eje Y: Pico positivo sostenido (aceleración hacia atrás)
/// - Acelerómetro eje Z: Disminución (parte trasera del vehículo baja)
/// - Giroscopio: Estable (sin giros)
class AggressiveAccelerationDetector extends BaseDetector {
  AggressiveAccelerationDetector()
      : super(
          detectorName: 'AggressiveAccelerationDetector',
          eventType: EventType.aggressiveAcceleration,
        );

  @override
  bool checkConditions(SensorReading current, SensorStatistics stats) {
    // Condición primaria: aceleración fuerte en Y (positiva)
    if (current.accelY < AggressiveAccelConfig.accelYThreshold) {
      return false;
    }

    // Verificar que se mantiene por encima de 2.5 m/s² (sostenida)
    if (currentState == DetectionState.confirmed && current.accelY < 2.5) {
      return false;
    }

    // Condición secundaria: descenso en Z
    if (baseline != null) {
      final deltaZ = current.accelZ - baseline!.accelZ;
      if (deltaZ > AggressiveAccelConfig.accelZChangeMax ||
          deltaZ < AggressiveAccelConfig.accelZChangeMin) {
        return false;
      }
    }

    // Rechazar si hay giro lateral (posible curva, no aceleración recta)
    if (current.gyroZ.abs() > AggressiveAccelConfig.gyroStabilityThreshold) {
      return false;
    }

    // Rechazar si hay cambio lateral brusco
    if (current.accelX.abs() > 2.0) {
      return false;
    }

    return true;
  }

  @override
  double calculateConfidence(List<SensorReading> eventReadings) {
    if (eventReadings.isEmpty) return 0.0;

    double confidence = 0.0;

    // Factor 1: Magnitud sostenida de aceleración (40%)
    final avgAccelY = eventReadings.map((r) => r.accelY).reduce((a, b) => a + b) /
                      eventReadings.length;
    final peakScore = ((avgAccelY - 3.5) / 5.0).clamp(0.0, 1.0);
    confidence += peakScore * 0.4;

    // Factor 2: Estabilidad lateral (30%)
    final avgGyroZ = eventReadings.map((r) => r.gyroZ.abs()).reduce((a, b) => a + b) /
                     eventReadings.length;
    final stabilityScore = (1.0 - (avgGyroZ / AggressiveAccelConfig.gyroStabilityThreshold))
        .clamp(0.0, 1.0);
    confidence += stabilityScore * 0.3;

    // Factor 3: Duración sostenida (30%)
    if (eventReadings.length >= 2) {
      final duration = eventReadings.last.timestamp
          .difference(eventReadings.first.timestamp);
      final durationSec = duration.inMilliseconds / 1000.0;
      const idealDuration = 2.0; // 2 segundos es ideal
      final durationScore = 1.0 - ((durationSec - idealDuration).abs() / 2.0).clamp(0.0, 1.0);
      confidence += durationScore * 0.3;
    }

    return confidence.clamp(0.0, 1.0);
  }

  @override
  EventSeverity calculateSeverity(List<SensorReading> eventReadings) {
    final maxAccelY = eventReadings.map((r) => r.accelY).reduce(max);

    if (maxAccelY > AggressiveAccelConfig.highThreshold) {
      return EventSeverity.high;
    } else if (maxAccelY > AggressiveAccelConfig.mediumThreshold) {
      return EventSeverity.medium;
    } else {
      return EventSeverity.low;
    }
  }

  @override
  Map<String, dynamic> extractMetadata(List<SensorReading> eventReadings) {
    final maxAccelY = eventReadings.map((r) => r.accelY).reduce(max);
    final avgAccelY = eventReadings.map((r) => r.accelY).reduce((a, b) => a + b) /
                      eventReadings.length;
    final minAccelZ = eventReadings.map((r) => r.accelZ).reduce(min);

    final deltaZ = baseline != null ? minAccelZ - baseline!.accelZ : 0.0;

    // Calcular jerk (cambio de aceleración)
    double totalJerk = 0.0;
    for (int i = 1; i < eventReadings.length; i++) {
      final timeDiff = eventReadings[i].timestamp
          .difference(eventReadings[i - 1].timestamp)
          .inMilliseconds / 1000.0;
      if (timeDiff > 0) {
        final accelDiff = eventReadings[i].accelY - eventReadings[i - 1].accelY;
        totalJerk += (accelDiff / timeDiff).abs();
      }
    }
    final avgJerk = eventReadings.length > 1 ? totalJerk / (eventReadings.length - 1) : 0.0;

    return {
      'peakAccelY': maxAccelY,
      'avgAccelY': avgAccelY,
      'deltaZ': deltaZ,
      'avgJerk': avgJerk,
      'readingCount': eventReadings.length,
    };
  }

  @override
  Map<String, double> extractPeakValues(List<SensorReading> eventReadings) {
    return {
      'accelY': eventReadings.map((r) => r.accelY).reduce(max),
      'accelZ': eventReadings.map((r) => r.accelZ).reduce(min),
      'gyroZ': eventReadings.map((r) => r.gyroZ.abs()).reduce(max),
    };
  }

  @override
  Duration get cooldownDuration => AggressiveAccelConfig.cooldownPeriod;

  @override
  Duration get minEventDuration => AggressiveAccelConfig.minEventDuration;

  @override
  Duration get maxEventDuration => AggressiveAccelConfig.maxEventDuration;

  @override
  double get minConfidence => AggressiveAccelConfig.minConfidence;
}
