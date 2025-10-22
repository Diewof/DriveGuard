import 'dart:math';
import 'base_detector.dart';
import '../models/sensor_reading.dart';
import '../models/event_type.dart';
import '../models/event_severity.dart';
import '../models/sensor_statistics.dart';
import '../config/detection_thresholds.dart';

/// Detector de frenado brusco
///
/// Detecta cuando el conductor aplica los frenos de manera repentina y fuerte.
/// Comportamiento esperado:
/// - Acelerómetro eje Y: Pico negativo pronunciado (desaceleración hacia adelante)
/// - Acelerómetro eje Z: Ligero aumento (nariz del vehículo baja)
/// - Giroscopio: Cambios mínimos o nulos (estable)
class HarshBrakingDetector extends BaseDetector {
  HarshBrakingDetector()
      : super(
          detectorName: 'HarshBrakingDetector',
          eventType: EventType.harshBraking,
        );

  @override
  bool checkConditions(SensorReading current, SensorStatistics stats) {
    final gyroTotal = current.gyroX.abs() + current.gyroY.abs() + current.gyroZ.abs();
    final deltaZ = baseline != null ? current.accelZ - baseline!.accelZ : 0.0;

    // Condición primaria: desaceleración fuerte en Y
    if (current.accelY > HarshBrakingConfig.accelYThreshold) {
      return false; // Y debe ser negativo
    }

    // Condición secundaria: cambio en Z (nariz baja)
    if (baseline != null) {
      if (deltaZ < HarshBrakingConfig.accelZChangeMin ||
          deltaZ > HarshBrakingConfig.accelZChangeMax) {
        return false;
      }
    }

    // Verificar estabilidad del giroscopio (sin giros bruscos)
    if (gyroTotal > HarshBrakingConfig.gyroStabilityThreshold) {
      return false;
    }

    return true;
  }

  @override
  double calculateConfidence(List<SensorReading> eventReadings) {
    if (eventReadings.isEmpty) return 0.0;

    double confidence = 0.0;

    // Factor 1: Magnitud del pico de desaceleración (40%)
    final minAccelY = eventReadings.map((r) => r.accelY).reduce(min);
    final peakMagnitude = minAccelY.abs();
    final peakScore = ((peakMagnitude - 4.5) / 10.0).clamp(0.0, 1.0);
    confidence += peakScore * 0.4;

    // Factor 2: Estabilidad del giroscopio (30%)
    final avgGyroMagnitude = eventReadings
        .map((r) => r.gyroX.abs() + r.gyroY.abs() + r.gyroZ.abs())
        .reduce((a, b) => a + b) / eventReadings.length;
    final stabilityScore = (1.0 - (avgGyroMagnitude / HarshBrakingConfig.gyroStabilityThreshold))
        .clamp(0.0, 1.0);
    confidence += stabilityScore * 0.3;

    // Factor 3: Duración dentro del rango esperado (30%)
    if (eventReadings.length >= 2) {
      final duration = eventReadings.last.timestamp
          .difference(eventReadings.first.timestamp);
      final durationMs = duration.inMilliseconds;
      final idealDuration = 900.0; // 900ms es ideal
      final durationScore = 1.0 - ((durationMs - idealDuration).abs() / 1000.0).clamp(0.0, 1.0);
      confidence += durationScore * 0.3;
    }

    return confidence.clamp(0.0, 1.0);
  }

  @override
  EventSeverity calculateSeverity(List<SensorReading> eventReadings) {
    final minAccelY = eventReadings.map((r) => r.accelY).reduce(min);

    if (minAccelY < HarshBrakingConfig.highThreshold) {
      return EventSeverity.high;
    } else if (minAccelY < HarshBrakingConfig.mediumThreshold) {
      return EventSeverity.medium;
    } else {
      return EventSeverity.low;
    }
  }

  @override
  Map<String, dynamic> extractMetadata(List<SensorReading> eventReadings) {
    final minAccelY = eventReadings.map((r) => r.accelY).reduce(min);
    final maxAccelZ = eventReadings.map((r) => r.accelZ).reduce(max);
    final avgGyroMagnitude = eventReadings
        .map((r) => r.gyroX.abs() + r.gyroY.abs() + r.gyroZ.abs())
        .reduce((a, b) => a + b) / eventReadings.length;

    final deltaZ = baseline != null ? maxAccelZ - baseline!.accelZ : 0.0;

    return {
      'peakAccelY': minAccelY,
      'deltaZ': deltaZ,
      'avgGyroMagnitude': avgGyroMagnitude,
      'readingCount': eventReadings.length,
    };
  }

  @override
  Map<String, double> extractPeakValues(List<SensorReading> eventReadings) {
    return {
      'accelY': eventReadings.map((r) => r.accelY).reduce(min),
      'accelZ': eventReadings.map((r) => r.accelZ).reduce(max),
      'gyroMagnitude': eventReadings
          .map((r) => r.gyroX.abs() + r.gyroY.abs() + r.gyroZ.abs())
          .reduce(max),
    };
  }

  @override
  Duration get cooldownDuration => HarshBrakingConfig.cooldownPeriod;

  @override
  Duration get minEventDuration => HarshBrakingConfig.minEventDuration;

  @override
  Duration get maxEventDuration => HarshBrakingConfig.maxEventDuration;

  @override
  double get minConfidence => HarshBrakingConfig.minConfidence;
}
