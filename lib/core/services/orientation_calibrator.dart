import 'dart:math';
import '../../domain/entities/sensor_data.dart';

/// Calibra automáticamente la orientación del dispositivo
/// detectando qué eje recibe la gravedad (9.8 m/s²)
class OrientationCalibrator {
  // Datos recolectados durante calibración
  final List<SensorData> _calibrationSamples = [];

  // Estado de calibración
  bool _isCalibrating = false;
  bool _isCalibrated = false;

  // Configuración de calibración
  final int requiredSamples;
  final Duration calibrationDuration;

  // Resultados de calibración
  late DeviceOrientation _detectedOrientation;
  late Vector3 _gravityBaseline;
  late Vector3 _gyroBaseline;

  // Matriz de rotación para normalizar ejes
  late Matrix3x3 _rotationMatrix;

  OrientationCalibrator({
    this.requiredSamples = 30,
    this.calibrationDuration = const Duration(seconds: 3),
  });

  bool get isCalibrating => _isCalibrating;
  bool get isCalibrated => _isCalibrated;
  DeviceOrientation get orientation => _detectedOrientation;

  /// Inicia el proceso de calibración
  void startCalibration() {
    _isCalibrating = true;
    _isCalibrated = false;
    _calibrationSamples.clear();
    print('📱 [CALIBRACIÓN] Iniciando calibración de orientación...');
  }

  /// Agrega una muestra durante la calibración
  bool addCalibrationSample(SensorData data) {
    if (!_isCalibrating) return false;

    _calibrationSamples.add(data);

    if (_calibrationSamples.length >= requiredSamples) {
      _computeCalibration();
      _isCalibrating = false;
      _isCalibrated = true;
      return true; // Calibración completa
    }

    return false; // Aún calibrando
  }

  /// Calcula la orientación basándose en las muestras recolectadas
  void _computeCalibration() {
    // Promediar todas las muestras para reducir ruido
    double avgAccelX = 0, avgAccelY = 0, avgAccelZ = 0;
    double avgGyroX = 0, avgGyroY = 0, avgGyroZ = 0;

    for (var sample in _calibrationSamples) {
      avgAccelX += sample.accelerationX;
      avgAccelY += sample.accelerationY;
      avgAccelZ += sample.accelerationZ;
      avgGyroX += sample.gyroscopeX;
      avgGyroY += sample.gyroscopeY;
      avgGyroZ += sample.gyroscopeZ;
    }

    final count = _calibrationSamples.length;
    avgAccelX /= count;
    avgAccelY /= count;
    avgAccelZ /= count;
    avgGyroX /= count;
    avgGyroY /= count;
    avgGyroZ /= count;

    // Guardar línea base
    _gravityBaseline = Vector3(avgAccelX, avgAccelY, avgAccelZ);
    _gyroBaseline = Vector3(avgGyroX, avgGyroY, avgGyroZ);

    // Detectar qué eje tiene aproximadamente 9.8 m/s² (gravedad)
    final absX = avgAccelX.abs();
    final absY = avgAccelY.abs();
    final absZ = avgAccelZ.abs();

    print('📊 [CALIBRACIÓN] Aceleración promedio:');
    print('   X: ${avgAccelX.toStringAsFixed(2)} m/s²');
    print('   Y: ${avgAccelY.toStringAsFixed(2)} m/s²');
    print('   Z: ${avgAccelZ.toStringAsFixed(2)} m/s²');

    // Determinar orientación basándose en qué eje tiene mayor magnitud
    if (absX > absY && absX > absZ) {
      _detectedOrientation = avgAccelX > 0
          ? DeviceOrientation.landscapeLeft
          : DeviceOrientation.landscapeRight;
    } else if (absY > absX && absY > absZ) {
      _detectedOrientation = avgAccelY > 0
          ? DeviceOrientation.portraitUpsideDown
          : DeviceOrientation.portrait;
    } else {
      _detectedOrientation = avgAccelZ > 0
          ? DeviceOrientation.faceUp
          : DeviceOrientation.faceDown;
    }

    // Crear matriz de rotación para normalizar datos
    _rotationMatrix = _createRotationMatrix(_detectedOrientation);

    print('✅ [CALIBRACIÓN] Orientación detectada: ${_detectedOrientation.name}');
    print('📐 [CALIBRACIÓN] Línea base gravedad: ${_gravityBaseline.toString()}');
    print('🔄 [CALIBRACIÓN] Línea base giroscopio: ${_gyroBaseline.toString()}');
  }

  /// Transforma datos de sensor a coordenadas normalizadas
  /// donde Z siempre apunta hacia arriba (contra gravedad)
  SensorData transformSensorData(SensorData raw) {
    if (!_isCalibrated) return raw;

    // Restar líneas base para obtener movimiento relativo
    final accelX = raw.accelerationX - _gravityBaseline.x;
    final accelY = raw.accelerationY - _gravityBaseline.y;
    final accelZ = raw.accelerationZ - _gravityBaseline.z;

    final gyroX = raw.gyroscopeX - _gyroBaseline.x;
    final gyroY = raw.gyroscopeY - _gyroBaseline.y;
    final gyroZ = raw.gyroscopeZ - _gyroBaseline.z;

    // Aplicar rotación para normalizar ejes
    final rotatedAccel = _rotationMatrix.transform(Vector3(accelX, accelY, accelZ));
    final rotatedGyro = _rotationMatrix.transform(Vector3(gyroX, gyroY, gyroZ));

    return SensorData(
      id: raw.id,
      timestamp: raw.timestamp,
      accelerationX: rotatedAccel.x,
      accelerationY: rotatedAccel.y,
      accelerationZ: rotatedAccel.z,
      gyroscopeX: rotatedGyro.x,
      gyroscopeY: rotatedGyro.y,
      gyroscopeZ: rotatedGyro.z,
      impactDetected: raw.impactDetected,
      vibrationLevel: raw.vibrationLevel,
    );
  }

  /// Crea matriz de rotación según orientación detectada
  Matrix3x3 _createRotationMatrix(DeviceOrientation orientation) {
    switch (orientation) {
      case DeviceOrientation.portrait: // Teléfono vertical, pantalla hacia usuario
        return Matrix3x3([
          [1, 0, 0],
          [0, 1, 0],
          [0, 0, 1],
        ]);

      case DeviceOrientation.portraitUpsideDown:
        return Matrix3x3([
          [-1, 0, 0],
          [0, -1, 0],
          [0, 0, 1],
        ]);

      case DeviceOrientation.landscapeLeft: // Teléfono horizontal, puerto izquierdo
        return Matrix3x3([
          [0, -1, 0],
          [1, 0, 0],
          [0, 0, 1],
        ]);

      case DeviceOrientation.landscapeRight:
        return Matrix3x3([
          [0, 1, 0],
          [-1, 0, 0],
          [0, 0, 1],
        ]);

      case DeviceOrientation.faceUp: // Teléfono plano, pantalla arriba
        return Matrix3x3([
          [1, 0, 0],
          [0, 1, 0],
          [0, 0, 1],
        ]);

      case DeviceOrientation.faceDown:
        return Matrix3x3([
          [1, 0, 0],
          [0, -1, 0],
          [0, 0, -1],
        ]);
    }
  }

  /// Obtiene información de calibración para diagnóstico
  Map<String, dynamic> getCalibrationInfo() {
    return {
      'isCalibrated': _isCalibrated,
      'orientation': _isCalibrated ? _detectedOrientation.name : 'unknown',
      'gravityBaseline': _isCalibrated ? _gravityBaseline.toMap() : null,
      'gyroBaseline': _isCalibrated ? _gyroBaseline.toMap() : null,
      'sampleCount': _calibrationSamples.length,
    };
  }

  void reset() {
    _isCalibrating = false;
    _isCalibrated = false;
    _calibrationSamples.clear();
  }
}

/// Orientaciones posibles del dispositivo
enum DeviceOrientation {
  portrait,           // Vertical, parte superior arriba
  portraitUpsideDown, // Vertical, parte superior abajo
  landscapeLeft,      // Horizontal, puerto de carga a la izquierda
  landscapeRight,     // Horizontal, puerto de carga a la derecha
  faceUp,            // Plano, pantalla hacia arriba
  faceDown,          // Plano, pantalla hacia abajo
}

extension DeviceOrientationExtension on DeviceOrientation {
  String get name {
    switch (this) {
      case DeviceOrientation.portrait:
        return 'Portrait (Vertical)';
      case DeviceOrientation.portraitUpsideDown:
        return 'Portrait Upside Down';
      case DeviceOrientation.landscapeLeft:
        return 'Landscape Left (Horizontal ←)';
      case DeviceOrientation.landscapeRight:
        return 'Landscape Right (Horizontal →)';
      case DeviceOrientation.faceUp:
        return 'Face Up (Plano ↑)';
      case DeviceOrientation.faceDown:
        return 'Face Down (Plano ↓)';
    }
  }
}

/// Vector 3D simple
class Vector3 {
  final double x, y, z;

  Vector3(this.x, this.y, this.z);

  double get magnitude => sqrt(x * x + y * y + z * z);

  Map<String, double> toMap() => {'x': x, 'y': y, 'z': z};

  @override
  String toString() => '(${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)}, ${z.toStringAsFixed(2)})';
}

/// Matriz 3x3 para rotaciones
class Matrix3x3 {
  final List<List<double>> data;

  Matrix3x3(this.data);

  /// Transforma un vector usando esta matriz
  Vector3 transform(Vector3 v) {
    return Vector3(
      data[0][0] * v.x + data[0][1] * v.y + data[0][2] * v.z,
      data[1][0] * v.x + data[1][1] * v.y + data[1][2] * v.z,
      data[2][0] * v.x + data[2][1] * v.y + data[2][2] * v.z,
    );
  }
}
