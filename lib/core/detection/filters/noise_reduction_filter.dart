import '../models/sensor_reading.dart';

/// Filtro para rechazar lecturas con ruido extremo
class NoiseReductionFilter {
  // Umbrales configurables
  double maxAccelMagnitude;
  double maxGyroMagnitude;

  NoiseReductionFilter({
    this.maxAccelMagnitude = 20.0,
    this.maxGyroMagnitude = 200.0,
  });

  /// Actualizar umbrales dinámicamente
  void updateThresholds({
    required double maxAccel,
    required double maxGyro,
  }) {
    maxAccelMagnitude = maxAccel;
    maxGyroMagnitude = maxGyro;
  }

  /// Verifica si una lectura es válida o tiene ruido extremo
  bool isValid(SensorReading reading) {
    // Verificar magnitud de aceleración
    if (reading.accelMagnitude > maxAccelMagnitude) {
      return false;
    }

    // Verificar magnitud de giroscopio
    if (reading.gyroMagnitude > maxGyroMagnitude) {
      return false;
    }

    // Verificar valores individuales para NaN o infinito
    if (_hasInvalidValues(reading)) {
      return false;
    }

    return true;
  }

  bool _hasInvalidValues(SensorReading reading) {
    return reading.accelX.isNaN || reading.accelX.isInfinite ||
           reading.accelY.isNaN || reading.accelY.isInfinite ||
           reading.accelZ.isNaN || reading.accelZ.isInfinite ||
           reading.gyroX.isNaN || reading.gyroX.isInfinite ||
           reading.gyroY.isNaN || reading.gyroY.isInfinite ||
           reading.gyroZ.isNaN || reading.gyroZ.isInfinite;
  }

  /// Filtra y limpia una lectura, retornando null si es inválida
  SensorReading? filter(SensorReading reading) {
    return isValid(reading) ? reading : null;
  }
}
