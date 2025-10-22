import 'dart:math';
import 'base_detector.dart';
import '../models/sensor_reading.dart';
import '../models/event_type.dart';
import '../models/event_severity.dart';
import '../models/sensor_statistics.dart';
import '../config/detection_thresholds.dart';

/// Detector de giro cerrado a alta velocidad
///
/// Detecta cuando el vehículo toma una curva de manera pronunciada.
/// Comportamiento esperado:
/// - Giroscopio eje Z: Rotación sostenida (>30°/s)
/// - Acelerómetro eje X: Fuerza centrífuga lateral significativa
/// - Acelerómetro Y/Z: Cambios menores por inclinación del vehículo
class SharpTurnDetector extends BaseDetector {
  SharpTurnDetector()
      : super(
          detectorName: 'SharpTurnDetector',
          eventType: EventType.sharpTurn,
        );

  @override
  bool checkConditions(SensorReading current, SensorStatistics stats) {
    // Condición primaria: rotación fuerte en Z
    if (current.gyroZ.abs() < SharpTurnConfig.gyroZThreshold) {
      return false;
    }

    // Condición secundaria: fuerza centrífuga lateral
    if (current.accelX.abs() < SharpTurnConfig.accelXThreshold) {
      return false;
    }

    // Verificar consistencia de dirección (no zigzagueo)
    if (currentState == DetectionState.confirmed || currentState == DetectionState.potential) {
      final recentGyroZ = recentReadings.takeLast(5).map((r) => r.gyroZ);
      if (recentGyroZ.isNotEmpty) {
        // Verificar que todos tienen el mismo signo (giran en la misma dirección)
        final firstSign = recentGyroZ.first.sign;
        final allSameDirection = recentGyroZ.every((gz) => gz.sign == firstSign);
        if (!allSameDirection) {
          return false; // Es zigzagueo, no un giro sostenido
        }
      }
    }

    return true;
  }

  @override
  double calculateConfidence(List<SensorReading> eventReadings) {
    if (eventReadings.isEmpty) return 0.0;

    double confidence = 0.0;

    // Factor 1: Magnitud de la rotación (40%)
    final avgGyroZ = eventReadings.map((r) => r.gyroZ.abs()).reduce((a, b) => a + b) /
                     eventReadings.length;
    final rotationScore = ((avgGyroZ - 35.0) / 30.0).clamp(0.0, 1.0);
    confidence += rotationScore * 0.4;

    // Factor 2: Estabilidad de la rotación (30%)
    final gyroZValues = eventReadings.map((r) => r.gyroZ.abs()).toList();
    final mean = gyroZValues.reduce((a, b) => a + b) / gyroZValues.length;
    final variance = gyroZValues.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) /
                     gyroZValues.length;
    final stdDev = sqrt(variance);
    final stabilityScore = (1.0 - (stdDev / 20.0)).clamp(0.0, 1.0);
    confidence += stabilityScore * 0.3;

    // Factor 3: Fuerza lateral sostenida (30%)
    final avgAccelX = eventReadings.map((r) => r.accelX.abs()).reduce((a, b) => a + b) /
                      eventReadings.length;
    final lateralScore = ((avgAccelX - 3.0) / 3.0).clamp(0.0, 1.0);
    confidence += lateralScore * 0.3;

    return confidence.clamp(0.0, 1.0);
  }

  @override
  EventSeverity calculateSeverity(List<SensorReading> eventReadings) {
    final maxGyroZ = eventReadings.map((r) => r.gyroZ.abs()).reduce(max);
    final maxAccelX = eventReadings.map((r) => r.accelX.abs()).reduce(max);

    // Curva cerrada: gyroZ > 50°/s y accelX > 4.5 m/s²
    if (maxGyroZ > SharpTurnConfig.tightTurnGyroThreshold &&
        maxAccelX > SharpTurnConfig.tightTurnAccelThreshold) {
      return EventSeverity.high;
    } else if (maxGyroZ > 40.0) {
      return EventSeverity.medium;
    } else {
      return EventSeverity.low;
    }
  }

  @override
  Map<String, dynamic> extractMetadata(List<SensorReading> eventReadings) {
    final maxGyroZ = eventReadings.map((r) => r.gyroZ.abs()).reduce(max);
    final maxAccelX = eventReadings.map((r) => r.accelX.abs()).reduce(max);

    // Determinar dirección del giro
    final avgGyroZ = eventReadings.map((r) => r.gyroZ).reduce((a, b) => a + b) /
                     eventReadings.length;
    final turnDirection = avgGyroZ > 0 ? 'LEFT' : 'RIGHT';

    // Calcular ángulo total girado (integración de gyroZ)
    double totalAngle = 0.0;
    for (int i = 1; i < eventReadings.length; i++) {
      final timeDiff = eventReadings[i].timestamp
          .difference(eventReadings[i - 1].timestamp)
          .inMilliseconds / 1000.0;
      totalAngle += eventReadings[i].gyroZ.abs() * timeDiff;
    }

    return {
      'turnDirection': turnDirection,
      'maxAngularVelocity': maxGyroZ,
      'maxLateralForce': maxAccelX,
      'turnAngle': totalAngle,
      'readingCount': eventReadings.length,
    };
  }

  @override
  Map<String, double> extractPeakValues(List<SensorReading> eventReadings) {
    return {
      'gyroZ': eventReadings.map((r) => r.gyroZ.abs()).reduce(max),
      'accelX': eventReadings.map((r) => r.accelX.abs()).reduce(max),
      'accelY': eventReadings.map((r) => r.accelY.abs()).reduce(max),
    };
  }

  @override
  Duration get cooldownDuration => SharpTurnConfig.cooldownPeriod;

  @override
  Duration get minEventDuration => SharpTurnConfig.minTurnDuration;

  @override
  Duration get maxEventDuration => SharpTurnConfig.maxTurnDuration;

  @override
  double get minConfidence => SharpTurnConfig.minConfidence;
}

extension _IterableExtension<T> on Iterable<T> {
  Iterable<T> takeLast(int count) {
    if (length <= count) return this;
    return skip(length - count);
  }
}
