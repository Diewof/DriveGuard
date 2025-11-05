import 'dart:math';
import 'base_detector.dart';
import '../models/sensor_reading.dart';
import '../models/event_type.dart';
import '../models/event_severity.dart';
import '../models/sensor_statistics.dart';
import '../../services/detection_config_service.dart';

/// Detector de giro cerrado a alta velocidad con configuración dinámica (V2)
///
/// Detecta cuando el vehículo toma una curva de manera pronunciada.
/// Comportamiento esperado:
/// - Giroscopio eje Z: Rotación sostenida
/// - Acelerómetro eje X: Fuerza centrífuga lateral significativa
/// - Acelerómetro Y/Z: Cambios menores por inclinación del vehículo
class SharpTurnDetectorV2 extends BaseDetector {
  final DetectionConfig config;

  SharpTurnDetectorV2({required this.config})
      : super(
          detectorName: 'SharpTurnDetector',
          eventType: EventType.sharpTurn,
        );

  @override
  bool checkConditions(SensorReading current, SensorStatistics stats) {
    final absGyroZ = current.gyroZ.abs();
    final absAccelX = current.accelX.abs();

    // Condición primaria: rotación significativa en Z
    if (absGyroZ < config.sharpTurnGyroZ) {
      return false;
    }

    // Condición secundaria: fuerza centrífuga lateral (más permisivo)
    // AJUSTADO: Reducir umbral base en 20% para mayor sensibilidad
    final adjustedAccelXThreshold = config.sharpTurnAccelX * 0.8;
    if (absAccelX < adjustedAccelXThreshold) {
      return false;
    }

    // AJUSTADO: Verificar que aceleración en Y no sea extrema (no frenado/aceleración muy fuerte)
    // Aumentado de 3.0 a 4.5 para ser más permisivo
    if (current.accelY.abs() > 4.5) {
      return false; // Es aceleración o frenado muy fuerte, no giro
    }

    // Verificar consistencia de dirección (no zigzagueo) - solo si ya estamos en detección
    if (currentState == DetectionState.confirmed || currentState == DetectionState.potential) {
      final recentGyroZ = recentReadings.takeLast(5).map((r) => r.gyroZ);
      if (recentGyroZ.length >= 3) {
        // AJUSTADO: Permitir 1 cambio de dirección (más permisivo)
        final firstSign = recentGyroZ.first.sign;
        final sameDirectionCount = recentGyroZ.where((gz) => gz.sign == firstSign).length;
        // Al menos el 60% debe ir en la misma dirección
        if (sameDirectionCount < (recentGyroZ.length * 0.6)) {
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
    final rotationScore = ((avgGyroZ - config.sharpTurnGyroZ) / 40.0).clamp(0.0, 1.0);
    confidence += rotationScore * 0.35;

    // Factor 2: Correlación gyro-accel (25%)
    final avgRatio = avgAccelX / (avgGyroZ + 1.0);
    final correlationScore = ((avgRatio - 0.05) / 0.5).clamp(0.0, 1.0);
    confidence += correlationScore * 0.25;

    // Factor 3: Estabilidad de la rotación (20%)
    final gyroZValues = eventReadings.map((r) => r.gyroZ.abs()).toList();
    final mean = gyroZValues.reduce((a, b) => a + b) / gyroZValues.length;
    final variance = gyroZValues.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) /
                     gyroZValues.length;
    final stdDev = sqrt(variance);
    final stabilityScore = (1.0 - (stdDev / config.sharpTurnGyroStability)).clamp(0.0, 1.0);
    confidence += stabilityScore * 0.2;

    // Factor 4: Fuerza lateral sostenida (20%)
    final lateralScore = ((avgAccelX - config.sharpTurnAccelX) / 3.0).clamp(0.0, 1.0);
    confidence += lateralScore * 0.2;

    return confidence.clamp(0.0, 1.0);
  }

  @override
  EventSeverity calculateSeverity(List<SensorReading> eventReadings) {
    final maxGyroZ = eventReadings.map((r) => r.gyroZ.abs()).reduce(max);
    final maxAccelX = eventReadings.map((r) => r.accelX.abs()).reduce(max);

    // Umbrales dinámicos basados en el threshold configurado
    final tightTurnGyroThreshold = config.sharpTurnGyroZ * 1.67; // ~50 para normal (30*1.67)
    final tightTurnAccelThreshold = config.sharpTurnAccelX * 1.59; // ~3.5 para normal (2.2*1.59)

    if (maxGyroZ > tightTurnGyroThreshold &&
        maxAccelX > tightTurnAccelThreshold) {
      return EventSeverity.high;
    } else if (maxGyroZ > config.sharpTurnGyroZ * 1.33) { // ~40 para normal
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
      'sensitivityMode': config.mode.name,
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
  Duration get cooldownDuration => const Duration(seconds: 2);

  @override
  Duration get minEventDuration => const Duration(milliseconds: 300);

  @override
  Duration get maxEventDuration => const Duration(seconds: 5);

  @override
  double get minConfidence => config.sharpTurnMinConfidence;
}

extension _IterableExtension<T> on Iterable<T> {
  Iterable<T> takeLast(int count) {
    if (length <= count) return this;
    return skip(length - count);
  }
}
