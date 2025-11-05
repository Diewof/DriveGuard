import 'dart:async';
import '../../domain/entities/sensor_data.dart';
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

/// Factory para crear el servicio de sensores
class SensorServiceFactory {
  /// Crea una instancia del servicio de sensores reales del dispositivo
  static ISensorService create() {
    return DeviceSensorServiceAdapter();
  }
}
