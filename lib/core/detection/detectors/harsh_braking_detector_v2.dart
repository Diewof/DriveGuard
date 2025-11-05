import 'dart:math';
import 'base_detector.dart';
import '../models/sensor_reading.dart';
import '../models/event_type.dart';
import '../models/event_severity.dart';
import '../models/sensor_statistics.dart';
import '../../services/detection_config_service.dart';

/// Detector de frenado brusco con configuración dinámica
///
/// Detecta cuando el conductor aplica los frenos de manera repentina y fuerte.
/// Comportamiento esperado:
/// - Acelerómetro eje Y: Pico negativo pronunciado (desaceleración hacia adelante)
/// - Acelerómetro eje Z: Ligero aumento (nariz del vehículo baja) - opcional con gimbal
/// - Giroscopio: Cambios mínimos o nulos (estable)
class HarshBrakingDetectorV2 extends BaseDetector {
  final DetectionConfig config;

  HarshBrakingDetectorV2({required this.config})
      : super(
          detectorName: 'HarshBrakingDetector',
          eventType: EventType.harshBraking,
        );

  @override
  bool checkConditions(SensorReading current, SensorStatistics stats) {
    final gyroTotal = current.gyroX.abs() + current.gyroY.abs() + current.gyroZ.abs();

    // Condición primaria: desaceleración fuerte en Y
    if (current.accelY > config.harshBrakingAccelY) {
      return false; // Y debe ser negativo
    }

    // Condición secundaria: cambio en Z (nariz baja)
    // Con gimbal, esto es opcional o muy permisivo
    if (baseline != null && !config.useGimbal) {
      final deltaZ = current.accelZ - baseline!.accelZ;
      if (deltaZ < config.harshBrakingDeltaZMin ||
          deltaZ > config.harshBrakingDeltaZMax) {
        return false;
      }
    }

    // Verificar estabilidad del giroscopio (sin giros bruscos)
    if (gyroTotal > config.harshBrakingGyroStability) {
      return false;
    }

    return true;
  }

  @override
  double calculateConfidence(List<SensorReading> eventReadings) {
    if (eventReadings.isEmpty) return 0.0;

    double confidence = 0.0;

    // Factor 1: Magnitud del pico de desaceleración (50% - aumentado como en V1)
    final minAccelY = eventReadings.map((r) => r.accelY).reduce(min);
    final peakMagnitude = minAccelY.abs();
    final threshold = config.harshBrakingAccelY.abs();
    // CORREGIDO: Escalar dinámicamente en lugar de dividir por 10.0 hardcoded
    final peakScore = ((peakMagnitude - threshold) / (threshold * 2)).clamp(0.0, 1.0);
    confidence += peakScore * 0.5;

    // Factor 2: Estabilidad del giroscopio (30%)
    final avgGyroMagnitude = eventReadings
        .map((r) => r.gyroX.abs() + r.gyroY.abs() + r.gyroZ.abs())
        .reduce((a, b) => a + b) / eventReadings.length;
    final stabilityScore = (1.0 - (avgGyroMagnitude / config.harshBrakingGyroStability))
        .clamp(0.0, 1.0);
    confidence += stabilityScore * 0.3;

    // Factor 3: Duración dentro del rango esperado (20% - reducido como en V1)
    if (eventReadings.length >= 2) {
      final duration = eventReadings.last.timestamp
          .difference(eventReadings.first.timestamp);
      final durationMs = duration.inMilliseconds;
      const idealDuration = 600.0; // 600ms es más realista para eventos cortos
      final durationScore = 1.0 - ((durationMs - idealDuration).abs() / 1000.0).clamp(0.0, 1.0);
      confidence += durationScore * 0.2;
    }

    return confidence.clamp(0.0, 1.0);
  }

  @override
  EventSeverity calculateSeverity(List<SensorReading> eventReadings) {
    final minAccelY = eventReadings.map((r) => r.accelY).reduce(min);

    // Umbrales proporcionales al threshold configurado
    final highThreshold = config.harshBrakingAccelY * 2.5;
    final mediumThreshold = config.harshBrakingAccelY * 1.75;

    if (minAccelY < highThreshold) {
      return EventSeverity.high;
    } else if (minAccelY < mediumThreshold) {
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
      'sensitivityMode': config.mode.name,
      'useGimbal': config.useGimbal,
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
  Duration get cooldownDuration => const Duration(seconds: 2);

  @override
  Duration get minEventDuration => const Duration(milliseconds: 200);

  @override
  Duration get maxEventDuration => const Duration(milliseconds: 2000);

  @override
  double get minConfidence => config.harshBrakingMinConfidence;
}
