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
    final absGyroZ = current.gyroZ.abs();
    final absAccelX = current.accelX.abs();

    // CRÍTICO: Rechazar explícitamente si la rotación es demasiado baja (línea recta)
    if (absGyroZ < SharpTurnConfig.straightLineGyroMax) {
      return false; // Línea recta o curva muy suave, no es giro cerrado
    }

    // Condición primaria: rotación fuerte en Z
    if (absGyroZ < SharpTurnConfig.gyroZThreshold) {
      return false;
    }

    // Condición secundaria: fuerza centrífuga lateral significativa
    if (absAccelX < SharpTurnConfig.accelXThreshold) {
      return false;
    }

    // NUEVO: Verificar correlación entre rotación y fuerza lateral
    // En un giro real, debe haber fuerza lateral proporcional a la rotación
    // Ratio bajo indica movimiento del teléfono sin giro real del vehículo
    final gyroAccelRatio = absAccelX / (absGyroZ + 1.0); // +1 para evitar división por 0
    if (gyroAccelRatio < SharpTurnConfig.minGyroAccelRatio) {
      return false; // Rotación sin suficiente fuerza lateral = movimiento del teléfono
    }

    // Verificar que aceleración en Y sea baja (no es aceleración/frenado)
    if (current.accelY.abs() > 3.0) {
      return false; // Es aceleración o frenado, no giro
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

    final avgGyroZ = eventReadings.map((r) => r.gyroZ.abs()).reduce((a, b) => a + b) /
                     eventReadings.length;
    final avgAccelX = eventReadings.map((r) => r.accelX.abs()).reduce((a, b) => a + b) /
                      eventReadings.length;

    // Factor 1: Magnitud de la rotación (35%)
    // Ajustado para umbrales nuevos: 45°/s es el mínimo
    final rotationScore = ((avgGyroZ - SharpTurnConfig.gyroZThreshold) / 40.0).clamp(0.0, 1.0);
    confidence += rotationScore * 0.35;

    // Factor 2: Correlación gyro-accel (25%)
    // En un giro real debe haber buena correlación
    final avgRatio = avgAccelX / (avgGyroZ + 1.0);
    final correlationScore = ((avgRatio - SharpTurnConfig.minGyroAccelRatio) / 0.5).clamp(0.0, 1.0);
    confidence += correlationScore * 0.25;

    // Factor 3: Estabilidad de la rotación (20%)
    final gyroZValues = eventReadings.map((r) => r.gyroZ.abs()).toList();
    final mean = gyroZValues.reduce((a, b) => a + b) / gyroZValues.length;
    final variance = gyroZValues.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) /
                     gyroZValues.length;
    final stdDev = sqrt(variance);
    final stabilityScore = (1.0 - (stdDev / SharpTurnConfig.gyroStdDevThreshold)).clamp(0.0, 1.0);
    confidence += stabilityScore * 0.2;

    // Factor 4: Fuerza lateral sostenida (20%)
    final lateralScore = ((avgAccelX - SharpTurnConfig.accelXThreshold) / 3.0).clamp(0.0, 1.0);
    confidence += lateralScore * 0.2;

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
