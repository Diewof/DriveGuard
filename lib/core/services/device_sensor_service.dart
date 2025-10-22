import 'dart:async';
import 'dart:collection';
import 'package:sensors_plus/sensors_plus.dart';
import '../../domain/entities/sensor_data.dart';

/// Servicio que obtiene datos reales de los sensores del dispositivo Android
/// Combina acelerómetro y giroscopio en un solo stream sincronizado
class DeviceSensorService {
  // Subscripciones a los streams de sensores nativos
  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;

  // Controller para emitir datos combinados
  final _sensorController = StreamController<SensorData>.broadcast();

  // Últimas lecturas de cada sensor
  AccelerometerEvent? _lastAccel;
  GyroscopeEvent? _lastGyro;

  // Filtro de ruido
  final _filter = SensorDataFilter();

  // Estado
  bool _isRunning = false;

  // Getters públicos
  Stream<SensorData> get stream => _sensorController.stream;
  bool get isRunning => _isRunning;

  /// Inicia el monitoreo de sensores reales
  void startMonitoring() {
    if (_isRunning) return;

    _isRunning = true;

    // Suscribirse al acelerómetro
    _accelSubscription = accelerometerEventStream().listen(
      (AccelerometerEvent event) {
        _lastAccel = event;
        _combineAndEmit();
      },
      onError: (error) {
        // TODO: Implementar logging framework
        // ignore: avoid_print
        print('Error en acelerómetro: $error');
      },
    );

    // Suscribirse al giroscopio
    _gyroSubscription = gyroscopeEventStream().listen(
      (GyroscopeEvent event) {
        _lastGyro = event;
        _combineAndEmit();
      },
      onError: (error) {
        // TODO: Implementar logging framework
        // ignore: avoid_print
        print('Error en giroscopio: $error');
      },
    );
  }

  /// Detiene el monitoreo de sensores
  void stopMonitoring() {
    _accelSubscription?.cancel();
    _gyroSubscription?.cancel();
    _isRunning = false;
  }

  /// Combina las lecturas de ambos sensores y emite un SensorData completo
  void _combineAndEmit() {
    // Solo emitir cuando tengamos ambos valores
    if (_lastAccel == null || _lastGyro == null) return;

    // Crear dato crudo
    final rawData = SensorData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      accelerationX: _lastAccel!.x,
      accelerationY: _lastAccel!.y,
      accelerationZ: _lastAccel!.z,
      gyroscopeX: _lastGyro!.x * 57.2958, // Convertir rad/s a deg/s
      gyroscopeY: _lastGyro!.y * 57.2958,
      gyroscopeZ: _lastGyro!.z * 57.2958,
      vibrationLevel: _calculateVibration(_lastAccel!),
    );

    // Aplicar filtro de ruido
    final filteredData = _filter.filter(rawData);

    // Emitir dato filtrado
    _sensorController.add(filteredData);
  }

  /// Calcula el nivel de vibración basado en aceleración
  double _calculateVibration(AccelerometerEvent event) {
    // Calcular magnitud del vector de aceleración (sin gravedad)
    const gravity = 9.81;
    final totalAccel = event.x * event.x + event.y * event.y + event.z * event.z;
    final magnitude = totalAccel - (gravity * gravity);

    // Normalizar a rango 0-1
    return (magnitude.abs() / 100).clamp(0.0, 1.0);
  }

  /// Libera recursos
  void dispose() {
    stopMonitoring();
    _sensorController.close();
  }
}

/// Filtro de media móvil para reducir ruido de sensores
class SensorDataFilter {
  final int _windowSize = 5;
  final Queue<SensorData> _buffer = Queue();

  /// Aplica filtro de media móvil sobre los últimos N valores
  SensorData filter(SensorData raw) {
    _buffer.add(raw);

    // Mantener solo los últimos N valores
    if (_buffer.length > _windowSize) {
      _buffer.removeFirst();
    }

    // Si aún no tenemos suficientes datos, retornar el valor crudo
    if (_buffer.length < 3) {
      return raw;
    }

    // Calcular promedio de todas las lecturas en el buffer
    return _calculateAverage(_buffer, raw);
  }

  /// Calcula el promedio de todos los SensorData en el buffer
  SensorData _calculateAverage(Queue<SensorData> buffer, SensorData latest) {
    double sumAccelX = 0, sumAccelY = 0, sumAccelZ = 0;
    double sumGyroX = 0, sumGyroY = 0, sumGyroZ = 0;
    double sumVibration = 0;

    for (var data in buffer) {
      sumAccelX += data.accelerationX;
      sumAccelY += data.accelerationY;
      sumAccelZ += data.accelerationZ;
      sumGyroX += data.gyroscopeX;
      sumGyroY += data.gyroscopeY;
      sumGyroZ += data.gyroscopeZ;
      sumVibration += data.vibrationLevel;
    }

    final count = buffer.length;

    return SensorData(
      id: latest.id,
      timestamp: latest.timestamp,
      accelerationX: sumAccelX / count,
      accelerationY: sumAccelY / count,
      accelerationZ: sumAccelZ / count,
      gyroscopeX: sumGyroX / count,
      gyroscopeY: sumGyroY / count,
      gyroscopeZ: sumGyroZ / count,
      vibrationLevel: sumVibration / count,
      impactDetected: latest.isCrashDetected, // Usar detección del último valor
    );
  }
}
