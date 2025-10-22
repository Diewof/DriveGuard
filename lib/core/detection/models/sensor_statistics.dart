import 'dart:collection';
import 'dart:math';
import 'sensor_reading.dart';

/// Mantiene estadísticas de ventanas temporales para detección de patrones
class SensorStatistics {
  final Duration windowSize;
  final Queue<SensorReading> _readings = Queue();
  int maxReadings;

  Map<String, double> mean = {};
  Map<String, double> stdDev = {};
  Map<String, double> min = {};
  Map<String, double> max = {};

  SensorStatistics({
    this.windowSize = const Duration(seconds: 5),
    this.maxReadings = 50,
  });

  /// Agrega nueva lectura y actualiza estadísticas
  void addReading(SensorReading reading) {
    _readings.add(reading);

    // Mantener solo las lecturas dentro de la ventana de tiempo
    final cutoffTime = DateTime.now().subtract(windowSize);
    while (_readings.isNotEmpty && _readings.first.timestamp.isBefore(cutoffTime)) {
      _readings.removeFirst();
    }

    // También limitar por cantidad máxima
    while (_readings.length > maxReadings) {
      _readings.removeFirst();
    }

    _updateStatistics();
  }

  void _updateStatistics() {
    if (_readings.isEmpty) return;

    final axes = ['accelX', 'accelY', 'accelZ', 'gyroX', 'gyroY', 'gyroZ'];

    for (final axis in axes) {
      final values = _readings.map((r) => _getValue(r, axis)).toList();

      // Media
      final sum = values.reduce((a, b) => a + b);
      mean[axis] = sum / values.length;

      // Min/Max
      min[axis] = values.reduce((a, b) => a < b ? a : b);
      max[axis] = values.reduce((a, b) => a > b ? a : b);

      // Desviación estándar
      final variance = values
          .map((v) => pow(v - mean[axis]!, 2))
          .reduce((a, b) => a + b) / values.length;
      stdDev[axis] = sqrt(variance);
    }
  }

  double _getValue(SensorReading reading, String axis) {
    switch (axis) {
      case 'accelX':
        return reading.accelX;
      case 'accelY':
        return reading.accelY;
      case 'accelZ':
        return reading.accelZ;
      case 'gyroX':
        return reading.gyroX;
      case 'gyroY':
        return reading.gyroY;
      case 'gyroZ':
        return reading.gyroZ;
      default:
        return 0.0;
    }
  }

  /// Identifica valores anómalos (outliers) - más de 2 desviaciones estándar
  bool isOutlier(SensorReading reading, String axis) {
    if (!mean.containsKey(axis) || !stdDev.containsKey(axis)) {
      return false;
    }

    final value = _getValue(reading, axis);
    final deviation = (value - mean[axis]!).abs();
    return deviation > (2 * stdDev[axis]!);
  }

  /// Calcula la derivada (jerk) - cambio por unidad de tiempo
  double getDerivative(String axis) {
    if (_readings.length < 2) return 0.0;

    final latest = _readings.last;
    final previous = _readings.elementAt(_readings.length - 2);

    final valueDiff = _getValue(latest, axis) - _getValue(previous, axis);
    final timeDiff = latest.timestamp.difference(previous.timestamp).inMilliseconds / 1000.0;

    return timeDiff > 0 ? valueDiff / timeDiff : 0.0;
  }

  /// Obtiene las últimas N lecturas
  List<SensorReading> getRecentReadings(int count) {
    if (_readings.length <= count) {
      return List.from(_readings);
    }
    return _readings.toList().sublist(_readings.length - count);
  }

  /// Limpia el buffer
  void clear() {
    _readings.clear();
    mean.clear();
    stdDev.clear();
    min.clear();
    max.clear();
  }

  int get readingCount => _readings.length;
}
