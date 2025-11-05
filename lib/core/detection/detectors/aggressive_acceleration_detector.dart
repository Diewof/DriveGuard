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

    // CRÍTICO: Rechazar si hay componente vertical fuerte (indica lomo de toro, no aceleración)
    // Los lomos causan picos en Z, la aceleración real es principalmente en Y
    if (current.accelZ.abs() > AggressiveAccelConfig.verticalComponentThreshold) {
      return false; // Es un lomo de toro, no aceleración agresiva
    }

    // MEJORADO: Rechazar si el ratio Z/Y es alto (indica lomo más que aceleración)
    // En aceleración real: Y >> Z
    // En lomo de toro: Y ≈ Z (ambos suben juntos)
    final ratioZY = current.accelZ.abs() / (current.accelY.abs() + 0.1); // +0.1 evita división por 0
    if (ratioZY > 0.6) {
      // Si Z es más del 60% de Y, probablemente es un lomo
      return false;
    }

    // Rechazar si hay giro fuerte (es una curva, no aceleración recta)
    if (current.gyroZ.abs() > AggressiveAccelConfig.gyroStabilityThreshold) {
      return false;
    }

    // Verificar que el evento se sostenga (no sea un pico instantáneo de lomo)
    if (currentState == DetectionState.potential || currentState == DetectionState.confirmed) {
      // Contar cuántas lecturas recientes tienen accelY alto Y accelZ bajo
      final recentHighY = recentReadings
          .takeLast(5)
          .where((r) =>
            r.accelY >= AggressiveAccelConfig.accelYThreshold &&
            r.accelZ.abs() < AggressiveAccelConfig.verticalComponentThreshold)
          .length;

      // Si menos de 3 de las últimas 5 lecturas cumplen, probablemente es ruido/lomo
      if (recentHighY < 3) {
        return false;
      }
    }

    return true;
  }

  @override
  double calculateConfidence(List<SensorReading> eventReadings) {
    if (eventReadings.isEmpty) return 0.0;

    double confidence = 0.0;

    // Factor 1: Magnitud sostenida de aceleración (50% - aumentado)
    // AJUSTADO: Usar umbral actual (1.0) en lugar de hardcoded 3.5
    final avgAccelY = eventReadings.map((r) => r.accelY).reduce((a, b) => a + b) /
                      eventReadings.length;
    final threshold = AggressiveAccelConfig.accelYThreshold;
    // Si supera el umbral, dar confianza. Escalar hasta 3x el umbral
    final peakScore = ((avgAccelY - threshold) / (threshold * 2)).clamp(0.0, 1.0);
    confidence += peakScore * 0.5;

    // Factor 2: Estabilidad lateral (30%)
    final avgGyroZ = eventReadings.map((r) => r.gyroZ.abs()).reduce((a, b) => a + b) /
                     eventReadings.length;
    final stabilityScore = (1.0 - (avgGyroZ / AggressiveAccelConfig.gyroStabilityThreshold))
        .clamp(0.0, 1.0);
    confidence += stabilityScore * 0.3;

    // Factor 3: Duración sostenida (20% - reducido)
    if (eventReadings.length >= 2) {
      final duration = eventReadings.last.timestamp
          .difference(eventReadings.first.timestamp);
      final durationSec = duration.inMilliseconds / 1000.0;
      const idealDuration = 1.0; // 1 segundo es más realista para eventos cortos
      final durationScore = 1.0 - ((durationSec - idealDuration).abs() / 1.5).clamp(0.0, 1.0);
      confidence += durationScore * 0.2;
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

extension _IterableExtension<T> on Iterable<T> {
  Iterable<T> takeLast(int count) {
    if (length <= count) return this;
    return skip(length - count);
  }
}
