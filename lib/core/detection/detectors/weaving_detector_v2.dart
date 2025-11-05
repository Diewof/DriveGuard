import 'dart:math';
import 'base_detector.dart';
import '../models/sensor_reading.dart';
import '../models/event_type.dart';
import '../models/event_severity.dart';
import '../models/sensor_statistics.dart';
import '../config/detection_thresholds.dart';

/// Detector de zigzagueo / cambios de carril bruscos
///
/// Detecta cuando el conductor realiza movimientos laterales rápidos y repetitivos,
/// lo cual puede indicar distracción o somnolencia.
/// Comportamiento esperado:
/// - Giroscopio eje Z: Oscilaciones alternadas (izq-der-izq-der)
/// - Acelerómetro eje X: Cambios laterales repetitivos
/// - Frecuencia: 2-4 cambios en menos de 10 segundos
class WeavingDetector extends BaseDetector {
  final List<DateTime> _zeroCrossings = [];
  DateTime? _windowStart;

  WeavingDetector()
      : super(
          detectorName: 'WeavingDetector',
          eventType: EventType.weaving,
        );

  @override
  bool checkConditions(SensorReading current, SensorStatistics stats) {
    // Inicializar ventana de detección
    _windowStart ??= current.timestamp;

    // Verificar si estamos dentro de la ventana de detección
    final windowDuration = current.timestamp.difference(_windowStart!);
    if (windowDuration > WeavingConfig.detectionWindow) {
      // Reiniciar ventana
      _windowStart = current.timestamp;
      _zeroCrossings.clear();
    }

    // Detectar cruces por cero en gyroZ
    if (recentReadings.length >= 2) {
      final previous = recentReadings.last;
      final currentGyroZ = current.gyroZ;
      final previousGyroZ = previous.gyroZ;

      // Verificar si hay cruce por cero con amplitud suficiente
      if (_hasCrossedZero(previousGyroZ, currentGyroZ)) {
        if (currentGyroZ.abs() > WeavingConfig.gyroZOscillationThreshold) {
          _zeroCrossings.add(current.timestamp);
        }
      }
    }

    // Limpiar cruces antiguos fuera de la ventana
    _zeroCrossings.removeWhere((timestamp) =>
        current.timestamp.difference(timestamp) > WeavingConfig.detectionWindow);

    // MEJORADO: Lógica más robusta para detectar zigzagueo
    // Verificar si tenemos suficientes oscilaciones en gyroZ
    if (_zeroCrossings.length >= WeavingConfig.minOscillations) {
      // Opción A: Hay oscilaciones significativas en accelX (cambios laterales)
      final recentAccelX = recentReadings
          .takeLast(10)
          .map((r) => r.accelX.abs())
          .where((ax) => ax > WeavingConfig.accelXOscillationThreshold);

      if (recentAccelX.length >= 2) {
        return true; // Zigzagueo con fuerza lateral detectada
      }

      // Opción B: Oscilaciones frecuentes y regulares en gyroZ (zigzagueo puro)
      // Calcular frecuencia de oscilaciones
      if (_zeroCrossings.length >= 4) {
        final intervals = <double>[];
        for (int i = 1; i < _zeroCrossings.length; i++) {
          final interval = _zeroCrossings[i]
              .difference(_zeroCrossings[i - 1])
              .inMilliseconds / 1000.0;
          intervals.add(interval);
        }

        // Verificar regularidad (baja varianza indica zigzagueo intencional)
        if (intervals.isNotEmpty) {
          final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
          final frequency = 1.0 / avgInterval;

          // Frecuencia entre 0.5 Hz y 2.5 Hz indica zigzagueo típico
          if (frequency >= WeavingConfig.minFrequency &&
              frequency <= WeavingConfig.maxFrequency) {
            return true; // Zigzagueo por frecuencia característica
          }
        }
      }

      // Opción C: Amplitud sostenida de gyroZ (zigzagueo suave pero sostenido)
      final recentGyroZ = recentReadings
          .takeLast(10)
          .map((r) => r.gyroZ.abs())
          .where((gz) => gz > WeavingConfig.gyroZOscillationThreshold * 0.7);

      if (recentGyroZ.length >= 5) {
        return true; // Zigzagueo sostenido detectado
      }
    }

    return false;
  }

  bool _hasCrossedZero(double previous, double current) {
    return (previous > 0 && current < 0) || (previous < 0 && current > 0);
  }

  @override
  double calculateConfidence(List<SensorReading> eventReadings) {
    if (eventReadings.isEmpty || _zeroCrossings.length < 3) return 0.0;

    double confidence = 0.0;

    // Factor 1: Número de oscilaciones (40%)
    final oscillationScore = (_zeroCrossings.length / 6.0).clamp(0.0, 1.0);
    confidence += oscillationScore * 0.4;

    // Factor 2: Regularidad de las oscilaciones (30%)
    final intervals = _calculateIntervals();
    if (intervals.isNotEmpty) {
      final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
      final variance = intervals.map((i) => pow(i - avgInterval, 2)).reduce((a, b) => a + b) /
                       intervals.length;
      final stdDev = sqrt(variance);
      final regularityScore = (1.0 - (stdDev / avgInterval).abs()).clamp(0.0, 1.0);
      confidence += regularityScore * 0.3;
    }

    // Factor 3: Correlación con accelX (30%)
    final accelXOscillations = eventReadings
        .where((r) => r.accelX.abs() > WeavingConfig.accelXOscillationThreshold)
        .length;
    final correlationScore = (accelXOscillations / eventReadings.length).clamp(0.0, 1.0);
    confidence += correlationScore * 0.3;

    return confidence.clamp(0.0, 1.0);
  }

  List<double> _calculateIntervals() {
    if (_zeroCrossings.length < 2) return [];

    final intervals = <double>[];
    for (int i = 1; i < _zeroCrossings.length; i++) {
      final interval = _zeroCrossings[i]
          .difference(_zeroCrossings[i - 1])
          .inMilliseconds / 1000.0;
      intervals.add(interval);
    }
    return intervals;
  }

  @override
  EventSeverity calculateSeverity(List<SensorReading> eventReadings) {
    final oscillationCount = _zeroCrossings.length;
    final maxGyroZ = eventReadings.map((r) => r.gyroZ.abs()).reduce(max);

    if (oscillationCount > 5 || maxGyroZ > 40.0) {
      return EventSeverity.high;
    } else if (oscillationCount > 3) {
      return EventSeverity.medium;
    } else {
      return EventSeverity.low;
    }
  }

  @override
  Map<String, dynamic> extractMetadata(List<SensorReading> eventReadings) {
    final maxGyroZ = eventReadings.map((r) => r.gyroZ.abs()).reduce(max);
    final avgGyroZ = eventReadings.map((r) => r.gyroZ.abs()).reduce((a, b) => a + b) /
                     eventReadings.length;

    // Calcular frecuencia de oscilación
    final intervals = _calculateIntervals();
    final avgInterval = intervals.isNotEmpty
        ? intervals.reduce((a, b) => a + b) / intervals.length
        : 0.0;
    final frequency = avgInterval > 0 ? 1.0 / avgInterval : 0.0;

    // Clasificar causa probable
    String probableCause = 'UNKNOWN';
    if (frequency >= 0.5 && frequency <= 0.8) {
      probableCause = 'DISTRACTION_DROWSINESS';
    } else if (frequency >= 1.2 && frequency <= 2.0) {
      probableCause = 'ACTIVE_EVASION';
    }

    return {
      'oscillationCount': _zeroCrossings.length,
      'maxGyroZ': maxGyroZ,
      'avgGyroZ': avgGyroZ,
      'frequency': frequency,
      'probableCause': probableCause,
      'readingCount': eventReadings.length,
    };
  }

  @override
  Map<String, double> extractPeakValues(List<SensorReading> eventReadings) {
    return {
      'gyroZ': eventReadings.map((r) => r.gyroZ.abs()).reduce(max),
      'accelX': eventReadings.map((r) => r.accelX.abs()).reduce(max),
      'oscillationCount': _zeroCrossings.length.toDouble(),
    };
  }

  @override
  void reset() {
    super.reset();
    _zeroCrossings.clear();
    _windowStart = null;
  }

  @override
  Duration get cooldownDuration => WeavingConfig.cooldownPeriod;

  @override
  Duration get minEventDuration => const Duration(seconds: 3);

  @override
  Duration get maxEventDuration => WeavingConfig.detectionWindow;

  @override
  double get minConfidence => WeavingConfig.minConfidence;
}

extension _IterableExtension<T> on Iterable<T> {
  Iterable<T> takeLast(int count) {
    if (length <= count) return this;
    return skip(length - count);
  }
}
