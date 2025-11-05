import 'dart:math';
import 'base_detector.dart';
import '../models/sensor_reading.dart';
import '../models/event_type.dart';
import '../models/event_severity.dart';
import '../models/sensor_statistics.dart';
import '../config/detection_thresholds.dart';

/// Estados específicos para detección de lomos de toro
enum SpeedBumpState {
  waitingFirstPeak,
  waitingValley,
  waitingSecondPeak,
  confirming,
}

/// Detector de paso por lomo de toro / tope
///
/// Detecta cuando el vehículo pasa sobre un reductor de velocidad elevado.
/// Comportamiento esperado:
/// - Acelerómetro Z: Patrón característico de "M" o "W" (subida-bajada-subida)
/// - Secuencia: Pico positivo → descenso → pico negativo → retorno
/// - Duración corta y concentrada
class SpeedBumpDetector extends BaseDetector {
  SpeedBumpState _bumpState = SpeedBumpState.waitingFirstPeak;
  DateTime? _firstPeakTime;
  double? _firstPeakValue;
  double? _secondPeakValue;
  int? _timeBetweenPeaks;

  SpeedBumpDetector()
      : super(
          detectorName: 'SpeedBumpDetector',
          eventType: EventType.speedBump,
        );

  @override
  bool checkConditions(SensorReading current, SensorStatistics stats) {
    switch (_bumpState) {
      case SpeedBumpState.waitingFirstPeak:
        return _checkFirstPeak(current);

      case SpeedBumpState.waitingValley:
        return _checkValley(current);

      case SpeedBumpState.waitingSecondPeak:
        return _checkSecondPeak(current);

      case SpeedBumpState.confirming:
        return _checkStabilization(current);
    }
  }

  bool _checkFirstPeak(SensorReading current) {
    // Buscar pico positivo en Z
    if (current.accelZ > SpeedBumpConfig.firstPeakThreshold) {
      _bumpState = SpeedBumpState.waitingValley;
      _firstPeakTime = current.timestamp;
      _firstPeakValue = current.accelZ;
      return true; // ✅ CORREGIDO: Iniciar detección
    }
    return false;
  }

  bool _checkValley(SensorReading current) {
    if (_firstPeakTime == null) {
      _resetBumpState();
      return false;
    }

    final timeSinceFirstPeak = current.timestamp.difference(_firstPeakTime!);

    // Timeout si pasa mucho tiempo
    if (timeSinceFirstPeak > SpeedBumpConfig.maxTimeBetweenPeaks) {
      _resetBumpState();
      return false;
    }

    // Buscar descenso (valle)
    if (current.accelZ.abs() <= 2.0 && timeSinceFirstPeak > const Duration(milliseconds: 150)) {
      _bumpState = SpeedBumpState.waitingSecondPeak;
      return true; // ✅ CORREGIDO: Mantener detección activa
    }

    return true; // ✅ CORREGIDO: Continuar detección mientras buscamos valle
  }

  bool _checkSecondPeak(SensorReading current) {
    if (_firstPeakTime == null) {
      _resetBumpState();
      return false;
    }

    final timeSinceFirstPeak = current.timestamp.difference(_firstPeakTime!);

    // Timeout
    if (timeSinceFirstPeak > SpeedBumpConfig.maxTimeBetweenPeaks) {
      _resetBumpState();
      return false;
    }

    // Buscar pico negativo en Z
    if (current.accelZ < SpeedBumpConfig.secondPeakThreshold) {
      if (timeSinceFirstPeak >= SpeedBumpConfig.minTimeBetweenPeaks) {
        _secondPeakValue = current.accelZ;
        _timeBetweenPeaks = timeSinceFirstPeak.inMilliseconds;
        _bumpState = SpeedBumpState.confirming;
        return true; // Patrón completo detectado
      }
    }

    return true; // ✅ CORREGIDO: Continuar detección mientras buscamos segundo pico
  }

  bool _checkStabilization(SensorReading current) {
    // El patrón ya fue detectado (pico+valle+pico), solo mantener brevemente
    // para asegurar que el BaseDetector alcance minEventDuration
    if (_firstPeakTime != null) {
      final timeTotal = current.timestamp.difference(_firstPeakTime!);

      // Terminar después de 500ms desde el inicio del patrón
      // Esto da tiempo suficiente para confirmar el patrón sin esperar demasiado
      if (timeTotal > const Duration(milliseconds: 500)) {
        // NO resetear aquí - el BaseDetector necesita los valores para calculateConfidence()
        // El reset se hará después en el método reset() del BaseDetector
        return false; // Terminar evento
      }
    }
    return true;
  }

  void _resetBumpState() {
    _bumpState = SpeedBumpState.waitingFirstPeak;
    _firstPeakTime = null;
    _firstPeakValue = null;
    _secondPeakValue = null;
    _timeBetweenPeaks = null;
  }

  @override
  double calculateConfidence(List<SensorReading> eventReadings) {
    if (_firstPeakValue == null || _secondPeakValue == null || _timeBetweenPeaks == null) {
      return 0.0;
    }

    double confidence = 0.0;

    // Factor 1: Simetría del patrón (40%)
    final symmetry = 1.0 - ((_firstPeakValue!.abs() - _secondPeakValue!.abs()).abs() /
                            max(_firstPeakValue!.abs(), _secondPeakValue!.abs()));
    confidence += symmetry.clamp(0.0, 1.0) * 0.4;

    // Factor 2: Ratio de amplitudes (30%)
    final ratio = min(_firstPeakValue!.abs(), _secondPeakValue!.abs()) /
                  max(_firstPeakValue!.abs(), _secondPeakValue!.abs());
    confidence += ratio * 0.3;

    // Factor 3: Timing ideal (30%)
    const idealTiming = 1000.0; // 1 segundo es ideal
    final timingScore = 1.0 - ((_timeBetweenPeaks! - idealTiming).abs() / 1000.0).clamp(0.0, 1.0);
    confidence += timingScore * 0.3;

    return confidence.clamp(0.0, 1.0);
  }

  @override
  EventSeverity calculateSeverity(List<SensorReading> eventReadings) {
    if (_timeBetweenPeaks == null) return EventSeverity.low;

    // Basado en velocidad estimada
    if (_timeBetweenPeaks! < SpeedBumpConfig.fastSpeedThreshold) {
      return EventSeverity.high; // Velocidad excesiva
    } else if (_timeBetweenPeaks! < SpeedBumpConfig.moderateSpeedThreshold) {
      return EventSeverity.medium; // Velocidad moderada
    } else {
      return EventSeverity.low; // Velocidad apropiada
    }
  }

  @override
  Map<String, dynamic> extractMetadata(List<SensorReading> eventReadings) {
    String speedEstimate = 'UNKNOWN';
    if (_timeBetweenPeaks != null) {
      if (_timeBetweenPeaks! < SpeedBumpConfig.fastSpeedThreshold) {
        speedEstimate = 'FAST';
      } else if (_timeBetweenPeaks! < SpeedBumpConfig.moderateSpeedThreshold) {
        speedEstimate = 'MODERATE';
      } else {
        speedEstimate = 'SLOW';
      }
    }

    final symmetry = (_firstPeakValue != null && _secondPeakValue != null)
        ? 1.0 - ((_firstPeakValue!.abs() - _secondPeakValue!.abs()).abs() /
                max(_firstPeakValue!.abs(), _secondPeakValue!.abs()))
        : 0.0;

    return {
      'speedEstimate': speedEstimate,
      'patternSymmetry': symmetry,
      'timeBetweenPeaks': _timeBetweenPeaks ?? 0,
      'firstPeakMagnitude': _firstPeakValue ?? 0.0,
      'secondPeakMagnitude': _secondPeakValue ?? 0.0,
      'readingCount': eventReadings.length,
    };
  }

  @override
  Map<String, double> extractPeakValues(List<SensorReading> eventReadings) {
    return {
      'firstPeak': _firstPeakValue ?? 0.0,
      'secondPeak': _secondPeakValue?.abs() ?? 0.0,
      'timeBetweenMs': _timeBetweenPeaks?.toDouble() ?? 0.0,
    };
  }

  @override
  void reset() {
    super.reset();
    _resetBumpState();
    // ignore: avoid_print
    print('[$detectorName] 🔄 Estado reseteado - listo para nueva detección');
  }

  @override
  Duration get cooldownDuration => SpeedBumpConfig.cooldownPeriod;

  @override
  Duration get minEventDuration => SpeedBumpConfig.minTimeBetweenPeaks;

  @override
  Duration get maxEventDuration => const Duration(milliseconds: 500);

  @override
  double get minConfidence => SpeedBumpConfig.minConfidence;
}
