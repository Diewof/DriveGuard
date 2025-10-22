import 'dart:async';
import '../../domain/entities/sensor_data.dart';
import '../constants/app_constants.dart';
import '../mocks/sensor_simulator.dart';
import 'device_sensor_service.dart';

/// Interfaz común para servicios de sensores
abstract class ISensorService {
  Stream<SensorData> get stream;
  bool get isRunning;
  void start();
  void stop();
  void dispose();
}

/// Adaptador para DeviceSensorService que implementa ISensorService
class DeviceSensorServiceAdapter implements ISensorService {
  final DeviceSensorService _service = DeviceSensorService();

  @override
  Stream<SensorData> get stream => _service.stream;

  @override
  bool get isRunning => _service.isRunning;

  @override
  void start() => _service.startMonitoring();

  @override
  void stop() => _service.stopMonitoring();

  @override
  void dispose() => _service.dispose();
}

/// Adaptador para SensorSimulator que implementa ISensorService
class SensorSimulatorAdapter implements ISensorService {
  final SensorSimulator _simulator = SensorSimulator();

  @override
  Stream<SensorData> get stream => _simulator.stream;

  @override
  bool get isRunning => _simulator.isRunning;

  @override
  void start() => _simulator.startSimulation(SimulationMode.normal);

  @override
  void stop() => _simulator.stopSimulation();

  @override
  void dispose() => _simulator.dispose();
}

/// Factory para crear el servicio de sensores apropiado
class SensorServiceFactory {
  /// Crea una instancia del servicio de sensores según la configuración
  ///
  /// Si [useRealSensors] es true (o no se especifica y AppConstants.useRealSensors es true),
  /// retorna DeviceSensorService que usa sensores reales del dispositivo.
  ///
  /// Si es false, retorna SensorSimulator para testing/desarrollo.
  static ISensorService create({bool? useRealSensors}) {
    final shouldUseRealSensors = useRealSensors ?? AppConstants.useRealSensors;

    if (shouldUseRealSensors) {
      return DeviceSensorServiceAdapter();
    } else {
      return SensorSimulatorAdapter();
    }
  }
}
