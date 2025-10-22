import 'dart:math';
import 'base_detector.dart';
import '../models/sensor_reading.dart';
import '../models/event_type.dart';
import '../models/event_severity.dart';
import '../models/sensor_statistics.dart';
import '../config/detection_thresholds.dart';

/// Detector de camino irregular (baches)
///
/// Detecta cuando el vehículo pasa por superficie irregular con múltiples impactos verticales.
/// Comportamiento esperado:
/// - Acelerómetro eje Z: Picos verticales repetitivos e irregulares
/// - Acelerómetro X/Y: Variaciones menores
/// - Giroscopio: Pequeñas oscilaciones en pitch (eje X)
class RoughRoadDetector extends BaseDetector {
  final List<_Peak> _detectedPeaks = [];
  DateTime? _windowStart;

  RoughRoadDetector()
      : super(
          detectorName: 'RoughRoadDetector',
          eventType: EventType.roughRoad,
        );

  @override
  bool checkConditions(SensorReading current, SensorStatistics stats) {
    // Inicializar ventana
    _windowStart ??= current.timestamp;

    // Verificar si estamos dentro de la ventana de detección
    final windowDuration = current.timestamp.difference(_windowStart!);
    if (windowDuration > RoughRoadConfig.detectionWindow) {
      // Reiniciar ventana
      _windowStart = current.timestamp;
      _detectedPeaks.clear();
    }

    // Detectar picos en accelZ
    if (recentReadings.length >= 3) {
      final recentZ = recentReadings.takeLast(3).map((r) => r.accelZ).toList();
      final middle = recentZ[1];
      final before = recentZ[0];
      final after = recentZ[2];

      // Verificar si es un máximo local
      if (middle > before && middle > after) {
        final prominence = middle - ((before + after) / 2);
        if (prominence.abs() > RoughRoadConfig.accelZPeakThreshold) {
          _detectedPeaks.add(_Peak(
            timestamp: recentReadings.elementAt(recentReadings.length - 2).timestamp,
            magnitude: prominence,
            sign: prominence > 0 ? 1 : -1,
          ));
        }
      }
    }

    // Limpiar picos antiguos fuera de la ventana
    _detectedPeaks.removeWhere((peak) =>
        current.timestamp.difference(peak.timestamp) > RoughRoadConfig.detectionWindow);

    // Verificar si tenemos suficientes picos
    if (_detectedPeaks.length >= RoughRoadConfig.minPeaksInWindow) {
      // Calcular irregularidad (coeficiente de variación)
      final magnitudes = _detectedPeaks.map((p) => p.magnitude.abs()).toList();
      final mean = magnitudes.reduce((a, b) => a + b) / magnitudes.length;
      final variance = magnitudes.map((m) => pow(m - mean, 2)).reduce((a, b) => a + b) /
                       magnitudes.length;
      final stdDev = sqrt(variance);
      final cv = mean > 0 ? stdDev / mean : 0.0;

      // Debe ser irregular (CV > 30%)
      if (cv > RoughRoadConfig.irregularityThreshold) {
        // Verificar oscilaciones en gyroPitch (gyroX)
        final recentGyroX = recentReadings
            .takeLast(10)
            .map((r) => r.gyroX.abs())
            .where((gx) => gx > RoughRoadConfig.gyroPitchThreshold);

        if (recentGyroX.isNotEmpty) {
          return true;
        }
      }
    }

    return false;
  }

  @override
  double calculateConfidence(List<SensorReading> eventReadings) {
    if (eventReadings.isEmpty || _detectedPeaks.length < 3) return 0.0;

    double confidence = 0.0;

    // Factor 1: Número de impactos (40%)
    final peakScore = (_detectedPeaks.length / 10.0).clamp(0.0, 1.0);
    confidence += peakScore * 0.4;

    // Factor 2: Irregularidad (30%)
    final magnitudes = _detectedPeaks.map((p) => p.magnitude.abs()).toList();
    final mean = magnitudes.reduce((a, b) => a + b) / magnitudes.length;
    final variance = magnitudes.map((m) => pow(m - mean, 2)).reduce((a, b) => a + b) /
                     magnitudes.length;
    final stdDev = sqrt(variance);
    final cv = mean > 0 ? stdDev / mean : 0.0;
    final irregularityScore = (cv / 0.5).clamp(0.0, 1.0);
    confidence += irregularityScore * 0.3;

    // Factor 3: Correlación con giroscopio (30%)
    final gyroXOscillations = eventReadings
        .where((r) => r.gyroX.abs() > RoughRoadConfig.gyroPitchThreshold)
        .length;
    final gyroScore = (gyroXOscillations / eventReadings.length).clamp(0.0, 1.0);
    confidence += gyroScore * 0.3;

    return confidence.clamp(0.0, 1.0);
  }

  @override
  EventSeverity calculateSeverity(List<SensorReading> eventReadings) {
    final avgMagnitude = _detectedPeaks.isNotEmpty
        ? _detectedPeaks.map((p) => p.magnitude.abs()).reduce((a, b) => a + b) /
          _detectedPeaks.length
        : 0.0;

    if (avgMagnitude > 4.0 || _detectedPeaks.length > 8) {
      return EventSeverity.high;
    } else if (avgMagnitude > 3.0 || _detectedPeaks.length > 5) {
      return EventSeverity.medium;
    } else {
      return EventSeverity.low;
    }
  }

  @override
  Map<String, dynamic> extractMetadata(List<SensorReading> eventReadings) {
    final magnitudes = _detectedPeaks.map((p) => p.magnitude.abs()).toList();
    final avgPeakMagnitude = magnitudes.isNotEmpty
        ? magnitudes.reduce((a, b) => a + b) / magnitudes.length
        : 0.0;

    // Calcular índice de calidad del camino (0-100, 100 = perfecto)
    final roadQualityIndex = (100.0 - (avgPeakMagnitude * 20.0)).clamp(0.0, 100.0);

    // Calcular coeficiente de variación
    final mean = magnitudes.isNotEmpty
        ? magnitudes.reduce((a, b) => a + b) / magnitudes.length
        : 0.0;
    final variance = magnitudes.isNotEmpty
        ? magnitudes.map((m) => pow(m - mean, 2)).reduce((a, b) => a + b) / magnitudes.length
        : 0.0;
    final stdDev = sqrt(variance);
    final irregularityScore = mean > 0 ? stdDev / mean : 0.0;

    return {
      'peakCount': _detectedPeaks.length,
      'avgPeakMagnitude': avgPeakMagnitude,
      'irregularityScore': irregularityScore,
      'roadQualityIndex': roadQualityIndex,
      'readingCount': eventReadings.length,
    };
  }

  @override
  Map<String, double> extractPeakValues(List<SensorReading> eventReadings) {
    final maxPeakMagnitude = _detectedPeaks.isNotEmpty
        ? _detectedPeaks.map((p) => p.magnitude.abs()).reduce(max)
        : 0.0;

    return {
      'accelZ': maxPeakMagnitude,
      'gyroX': eventReadings.map((r) => r.gyroX.abs()).reduce(max),
      'peakCount': _detectedPeaks.length.toDouble(),
    };
  }

  @override
  void reset() {
    super.reset();
    _detectedPeaks.clear();
    _windowStart = null;
  }

  @override
  Duration get cooldownDuration => RoughRoadConfig.cooldownPeriod;

  @override
  Duration get minEventDuration => const Duration(seconds: 2);

  @override
  Duration get maxEventDuration => RoughRoadConfig.detectionWindow;

  @override
  double get minConfidence => RoughRoadConfig.minConfidence;
}

class _Peak {
  final DateTime timestamp;
  final double magnitude;
  final int sign; // +1 o -1

  _Peak({
    required this.timestamp,
    required this.magnitude,
    required this.sign,
  });
}

extension _IterableExtension<T> on Iterable<T> {
  Iterable<T> takeLast(int count) {
    if (length <= count) return this;
    return skip(length - count);
  }
}
