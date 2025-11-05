import 'dart:async';
import '../../../domain/entities/sensor_data.dart';
import '../models/sensor_reading.dart';
import '../models/sensor_statistics.dart';
import '../models/detection_event.dart';
import '../filters/moving_average_filter.dart';
import '../filters/noise_reduction_filter.dart';
import '../detectors/base_detector.dart';
import '../detectors/harsh_braking_detector_v2.dart';
import '../detectors/aggressive_acceleration_detector_v2.dart';
import '../detectors/sharp_turn_detector_v2.dart';
import '../detectors/weaving_detector.dart';
import '../detectors/rough_road_detector.dart';
import '../detectors/speed_bump_detector.dart';
import '../../services/detection_config_service.dart';

/// Procesa datos de sensores con configuración dinámica
class SensorDataProcessorV2 {
  final _eventController = StreamController<DetectionEvent>.broadcast();
  final _rawDataController = StreamController<SensorReading>.broadcast();

  // Filtros
  final _movingAverageFilter = MovingAverageFilter(windowSize: 5);
  late NoiseReductionFilter _noiseFilter;

  // Estadísticas
  final _statistics = SensorStatistics(
    windowSize: const Duration(seconds: 5),
    maxReadings: 50,
  );

  // Detectores
  List<BaseDetector> _detectors = [];

  // Configuración actual
  DetectionConfig _currentConfig;

  SensorDataProcessorV2({DetectionConfig? initialConfig})
      : _currentConfig = initialConfig ?? DetectionConfig.normal() {
    _initializeFilters();
    _initializeDetectors();
  }

  void _initializeFilters() {
    _noiseFilter = NoiseReductionFilter(
      maxAccelMagnitude: _currentConfig.noiseFilterMaxAccel,
      maxGyroMagnitude: _currentConfig.noiseFilterMaxGyro,
    );
  }

  void _initializeDetectors() {
    _detectors = [
      HarshBrakingDetectorV2(config: _currentConfig),
      AggressiveAccelerationDetectorV2(config: _currentConfig), // ✅ MIGRADO A V2
      SharpTurnDetectorV2(config: _currentConfig),              // ✅ MIGRADO A V2
      WeavingDetector(),        // TODO: Migrar a V2
      RoughRoadDetector(),      // TODO: Migrar a V2
      SpeedBumpDetector(),      // TODO: Migrar a V2
    ];
  }

  Stream<DetectionEvent> get eventStream => _eventController.stream;
  Stream<SensorReading> get rawDataStream => _rawDataController.stream;

  /// Actualizar configuración en tiempo real
  void updateConfiguration(DetectionConfig newConfig) {
    _currentConfig = newConfig;

    // Actualizar filtros
    _noiseFilter.updateThresholds(
      maxAccel: newConfig.noiseFilterMaxAccel,
      maxGyro: newConfig.noiseFilterMaxGyro,
    );

    // Reinicializar detectores con nueva configuración
    _initializeDetectors();

    // ignore: avoid_print
    print('[PROCESSOR_V2] 📝 Configuración actualizada: '
        'Modo=${newConfig.mode.displayName}, Gimbal=${newConfig.useGimbal}');
  }

  /// Procesa una nueva lectura de sensor desde SensorData
  void processSensorData(SensorData data) {
    // Convertir SensorData a SensorReading, propagando el flag de calibración
    final reading = SensorReading(
      timestamp: data.timestamp,
      accelX: data.accelerationX,
      accelY: data.accelerationY,
      accelZ: data.accelerationZ,
      gyroX: data.gyroscopeX,
      gyroY: data.gyroscopeY,
      gyroZ: data.gyroscopeZ,
      isCalibrated: data.isCalibrated, // Propagar flag de calibración
    );

    processReading(reading);
  }

  /// Procesa una nueva lectura de sensor
  void processReading(SensorReading raw) {
    // 1. Filtrar ruido
    final validReading = _noiseFilter.filter(raw);
    if (validReading == null) {
      // ignore: avoid_print
      print('[PROCESSOR_V2] ❌ Lectura rechazada por filtro de ruido: '
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
        print('[PROCESSOR_V2] 🚨 EVENTO DETECTADO: ${result!.event!.type.displayName} '
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
