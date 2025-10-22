import 'dart:async';
import '../../../domain/entities/sensor_data.dart';
import '../models/sensor_reading.dart';
import '../models/sensor_statistics.dart';
import '../models/detection_event.dart';
import '../filters/moving_average_filter.dart';
import '../filters/noise_reduction_filter.dart';
import '../detectors/base_detector.dart';
import '../detectors/harsh_braking_detector.dart';
import '../detectors/aggressive_acceleration_detector.dart';
import '../detectors/sharp_turn_detector.dart';
import '../detectors/weaving_detector.dart';
import '../detectors/rough_road_detector.dart';
import '../detectors/speed_bump_detector.dart';

/// Procesa datos de sensores y coordina todos los detectores
class SensorDataProcessor {
  final _eventController = StreamController<DetectionEvent>.broadcast();
  final _rawDataController = StreamController<SensorReading>.broadcast();

  // Filtros
  final _movingAverageFilter = MovingAverageFilter(windowSize: 5);
  final _noiseFilter = NoiseReductionFilter();

  // Estadísticas
  final _statistics = SensorStatistics(
    windowSize: const Duration(seconds: 5),
    maxReadings: 50,
  );

  // Detectores
  final List<BaseDetector> _detectors = [];

  SensorDataProcessor() {
    _initializeDetectors();
  }

  void _initializeDetectors() {
    _detectors.addAll([
      HarshBrakingDetector(),
      AggressiveAccelerationDetector(),
      SharpTurnDetector(),
      WeavingDetector(),
      RoughRoadDetector(),
      SpeedBumpDetector(),
    ]);
  }

  Stream<DetectionEvent> get eventStream => _eventController.stream;
  Stream<SensorReading> get rawDataStream => _rawDataController.stream;

  /// Procesa una nueva lectura de sensor desde SensorData
  void processSensorData(SensorData data) {
    // Convertir SensorData a SensorReading
    final reading = SensorReading(
      timestamp: data.timestamp,
      accelX: data.accelerationX,
      accelY: data.accelerationY,
      accelZ: data.accelerationZ,
      gyroX: data.gyroscopeX,
      gyroY: data.gyroscopeY,
      gyroZ: data.gyroscopeZ,
    );

    processReading(reading);
  }

  /// Procesa una nueva lectura de sensor
  void processReading(SensorReading raw) {
    // 1. Filtrar ruido
    final validReading = _noiseFilter.filter(raw);
    if (validReading == null) {
      // ignore: avoid_print
      print('[PROCESSOR] ❌ Lectura rechazada por filtro de ruido: '
          'accelMag=${raw.accelMagnitude.toStringAsFixed(2)}, '
          'gyroMag=${raw.gyroMagnitude.toStringAsFixed(2)}');
      return;
    }

    // 2. Aplicar filtro de media móvil
    final filteredReading = _movingAverageFilter.filter(validReading);

    // 3. Actualizar estadísticas
    _statistics.addReading(filteredReading);

    // 4. Emitir dato procesado
    _rawDataController.add(filteredReading);

    // 5. Ejecutar todos los detectores
    for (final detector in _detectors) {
      final result = detector.process(filteredReading, _statistics);

      if (result?.event != null) {
        // ignore: avoid_print
        print('[PROCESSOR] 🚨 EVENTO DETECTADO: ${result!.event!.type.displayName} '
            '(severity=${result.event!.severity.value}, '
            'confidence=${result.event!.confidence.toStringAsFixed(2)})');
        _eventController.add(result.event!);
      }
    }
  }

  /// Reinicia todos los detectores
  void resetDetectors() {
    for (final detector in _detectors) {
      detector.reset();
    }
    _statistics.clear();
  }

  void dispose() {
    _eventController.close();
    _rawDataController.close();
  }
}
