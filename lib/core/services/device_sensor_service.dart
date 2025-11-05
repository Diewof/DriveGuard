import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';
import '../../domain/entities/sensor_data.dart';
import '../constants/app_constants.dart';
import 'orientation_calibrator.dart';

/// Servicio que obtiene datos reales de los sensores del dispositivo Android
/// Combina acelerómetro y giroscopio en un solo stream sincronizado
class DeviceSensorService {
  // Subscripciones a los streams de sensores nativos
  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;

  // Controller para emitir datos combinados
  final _sensorController = StreamController<SensorData>.broadcast();
  final _rawDataController = StreamController<SensorData>.broadcast();

  // Últimas lecturas de cada sensor
  AccelerometerEvent? _lastAccel;
  GyroscopeEvent? _lastGyro;

  // Calibrador de orientación
  final _calibrator = OrientationCalibrator(
    requiredSamples: AppConstants.calibrationSamples,
    calibrationDuration: Duration(seconds: AppConstants.calibrationDurationSeconds),
  );

  // Detector de picos paralelo (sin filtro)
  final _peakDetector = PeakDetector();

  // Estado
  bool _isRunning = false;

  // Getters públicos
  Stream<SensorData> get stream => _sensorController.stream;
  Stream<SensorData> get rawStream => _rawDataController.stream;
  bool get isRunning => _isRunning;
  bool get isCalibrating => _calibrator.isCalibrating;
  bool get isCalibrated => _calibrator.isCalibrated;
  OrientationCalibrator get calibrator => _calibrator;

  /// Inicia el monitoreo de sensores reales
  void startMonitoring() {
    if (_isRunning) return;

    _isRunning = true;

    // Iniciar calibración automática
    _calibrator.startCalibration();

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

    // Crear dato crudo (no calibrado)
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
      isCalibrated: false, // Dato crudo sin calibrar
    );

    // Emitir dato crudo para diagnóstico
    _rawDataController.add(rawData);

    // Si estamos calibrando, alimentar el calibrador
    if (_calibrator.isCalibrating) {
      final calibrationComplete = _calibrator.addCalibrationSample(rawData);
      if (calibrationComplete) {
        // ignore: avoid_print
        print('✅ [SENSOR SERVICE] Calibración completada');
      }
      return; // No emitir datos durante calibración
    }

    // Aplicar calibración de orientación si está disponible
    // IMPORTANTE: NO filtramos aquí para evitar doble/triple filtrado
    // El procesador V2 aplicará los filtros necesarios
    final calibratedData = _calibrator.isCalibrated
        ? _calibrator.transformSensorData(rawData)
        : rawData;

    // Detectar picos sin filtro (para eventos críticos)
    _peakDetector.analyze(calibratedData);

    // Emitir dato calibrado SIN filtrar al procesador
    _sensorController.add(calibratedData);
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
    _rawDataController.close();
  }
}

/// Detector de picos que trabaja en paralelo sin filtro
/// para capturar eventos críticos que podrían perderse con el filtrado
class PeakDetector {
  SensorData? _lastData;
  final List<SensorData> _recentPeaks = [];
  DateTime? _lastPeakTime;

  /// Analiza datos sin filtro buscando cambios bruscos
  void analyze(SensorData current) {
    if (_lastData == null) {
      _lastData = current;
      return;
    }

    // Calcular deltas (cambios entre lecturas)
    final deltaAccelX = (current.accelerationX - _lastData!.accelerationX).abs();
    final deltaAccelY = (current.accelerationY - _lastData!.accelerationY).abs();
    final deltaAccelZ = (current.accelerationZ - _lastData!.accelerationZ).abs();

    final deltaGyroX = (current.gyroscopeX - _lastData!.gyroscopeX).abs();
    final deltaGyroY = (current.gyroscopeY - _lastData!.gyroscopeY).abs();
    final deltaGyroZ = (current.gyroscopeZ - _lastData!.gyroscopeZ).abs();

    // Detectar picos significativos
    final hasAccelPeak = deltaAccelX > AppConstants.deltaAccelThreshold ||
                        deltaAccelY > AppConstants.deltaAccelThreshold ||
                        deltaAccelZ > AppConstants.deltaAccelThreshold;

    final hasGyroPeak = deltaGyroX > AppConstants.deltaGyroThreshold ||
                       deltaGyroY > AppConstants.deltaGyroThreshold ||
                       deltaGyroZ > AppConstants.deltaGyroThreshold;

    if (hasAccelPeak || hasGyroPeak) {
      final now = DateTime.now();

      // Evitar múltiples detecciones del mismo pico
      if (_lastPeakTime == null ||
          now.difference(_lastPeakTime!).inMilliseconds > 500) {

        _recentPeaks.add(current);
        _lastPeakTime = now;

        // Mantener solo los últimos 10 picos
        if (_recentPeaks.length > 10) {
          _recentPeaks.removeAt(0);
        }

        // ignore: avoid_print
        print('⚡ [PEAK DETECTOR] Pico detectado - '
            'ΔAccel: (${deltaAccelX.toStringAsFixed(2)}, '
            '${deltaAccelY.toStringAsFixed(2)}, '
            '${deltaAccelZ.toStringAsFixed(2)}) | '
            'ΔGyro: (${deltaGyroX.toStringAsFixed(1)}°, '
            '${deltaGyroY.toStringAsFixed(1)}°, '
            '${deltaGyroZ.toStringAsFixed(1)}°)');
      }
    }

    _lastData = current;
  }

  /// Obtiene información de picos recientes para diagnóstico
  List<Map<String, dynamic>> getRecentPeaks() {
    return _recentPeaks.map((peak) => {
      'timestamp': peak.timestamp,
      'accelX': peak.accelerationX,
      'accelY': peak.accelerationY,
      'accelZ': peak.accelerationZ,
      'gyroX': peak.gyroscopeX,
      'gyroY': peak.gyroscopeY,
      'gyroZ': peak.gyroscopeZ,
    }).toList();
  }

  void reset() {
    _lastData = null;
    _recentPeaks.clear();
    _lastPeakTime = null;
  }
}
