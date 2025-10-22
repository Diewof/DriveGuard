import 'dart:async';
import 'dart:math';
import '../../domain/entities/sensor_data.dart';
import '../constants/app_constants.dart';

enum SimulationMode { normal, reckless, crash, distracted }

/// Simulador de sensores para testing y desarrollo
///
/// DEPRECATED: Este simulador solo debe usarse para pruebas y desarrollo.
/// En producción, usa DeviceSensorService para obtener datos reales de sensores.
///
/// Para cambiar entre simulador y sensores reales, configura
/// AppConstants.useRealSensors en lib/core/constants/app_constants.dart
@Deprecated('Use DeviceSensorService for real sensor data. This simulator is only for testing.')
class SensorSimulator {
  Timer? _timer;
  final _sensorController = StreamController<SensorData>.broadcast();
  final _random = Random();
  bool _isRunning = false;

  Stream<SensorData> get stream => _sensorController.stream;
  bool get isRunning => _isRunning;

  void startSimulation(SimulationMode mode) {
    if (_isRunning) return;

    _isRunning = true;
    _timer = Timer.periodic(
      const Duration(milliseconds: AppConstants.sensorUpdateIntervalMs),
      (_) => _generateAndEmitData(mode),
    );
  }

  void stopSimulation() {
    _timer?.cancel();
    _isRunning = false;
  }

  void _generateAndEmitData(SimulationMode mode) {
    final data = _generateSensorData(mode);
    _sensorController.add(data);
  }

  SensorData _generateSensorData(SimulationMode mode) {
    switch (mode) {
      case SimulationMode.normal:
        return SensorData(
          id: _generateId(),
          timestamp: DateTime.now(),
          accelerationX: _randomRange(-0.5, 0.5),
          accelerationY: _randomRange(-0.5, 0.5),
          accelerationZ: _randomRange(9.5, 10.5), // Gravedad normal
          gyroscopeX: _randomRange(-10, 10),
          gyroscopeY: _randomRange(-10, 10),
          gyroscopeZ: _randomRange(-10, 10),
          vibrationLevel: _randomRange(0, 0.2),
        );

      case SimulationMode.reckless:
        return SensorData(
          id: _generateId(),
          timestamp: DateTime.now(),
          accelerationX: _randomRange(-4, 4),
          accelerationY: _randomRange(-5, 5),
          accelerationZ: _randomRange(7, 13),
          gyroscopeX: _randomRange(-60, 60),
          gyroscopeY: _randomRange(-70, 70),
          gyroscopeZ: _randomRange(-50, 50),
          vibrationLevel: _randomRange(0.3, 0.8),
        );

      case SimulationMode.crash:
        return SensorData(
          id: _generateId(),
          timestamp: DateTime.now(),
          accelerationX: _randomRange(-20, 20),
          accelerationY: _randomRange(-25, 25),
          accelerationZ: _randomRange(-10, 30),
          gyroscopeX: _randomRange(-180, 180),
          gyroscopeY: _randomRange(-180, 180),
          gyroscopeZ: _randomRange(-180, 180),
          impactDetected: true,
          vibrationLevel: _randomRange(0.8, 1.0),
        );

      case SimulationMode.distracted:
        return SensorData(
          id: _generateId(),
          timestamp: DateTime.now(),
          accelerationX: _randomRange(-1, 1),
          accelerationY: _randomRange(-1.5, 1.5),
          accelerationZ: _randomRange(9, 11),
          gyroscopeX: _randomRange(-20, 20),
          gyroscopeY: _randomRange(-15, 15),
          gyroscopeZ: _randomRange(-25, 25),
          vibrationLevel: _randomRange(0.1, 0.4),
        );
    }
  }

  double _randomRange(double min, double max) {
    return min + _random.nextDouble() * (max - min);
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  void dispose() {
    stopSimulation();
    _sensorController.close();
  }
}