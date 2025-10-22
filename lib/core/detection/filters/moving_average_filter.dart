import 'dart:collection';
import '../models/sensor_reading.dart';

/// Filtro de media móvil para suavizar ruido de alta frecuencia
class MovingAverageFilter {
  final int windowSize;
  final Queue<SensorReading> _buffer = Queue();

  MovingAverageFilter({this.windowSize = 5});

  /// Aplica el filtro y retorna la lectura suavizada
  SensorReading filter(SensorReading raw) {
    _buffer.add(raw);

    // Mantener solo las últimas N lecturas
    if (_buffer.length > windowSize) {
      _buffer.removeFirst();
    }

    // Si aún no tenemos suficientes datos, retornar el valor crudo
    if (_buffer.length < 3) {
      return raw;
    }

    // Calcular promedio de todas las lecturas en el buffer
    return _calculateAverage(_buffer, raw);
  }

  SensorReading _calculateAverage(Queue<SensorReading> buffer, SensorReading latest) {
    double sumAccelX = 0, sumAccelY = 0, sumAccelZ = 0;
    double sumGyroX = 0, sumGyroY = 0, sumGyroZ = 0;

    for (var reading in buffer) {
      sumAccelX += reading.accelX;
      sumAccelY += reading.accelY;
      sumAccelZ += reading.accelZ;
      sumGyroX += reading.gyroX;
      sumGyroY += reading.gyroY;
      sumGyroZ += reading.gyroZ;
    }

    final count = buffer.length;

    return SensorReading(
      timestamp: latest.timestamp,
      accelX: sumAccelX / count,
      accelY: sumAccelY / count,
      accelZ: sumAccelZ / count,
      gyroX: sumGyroX / count,
      gyroY: sumGyroY / count,
      gyroZ: sumGyroZ / count,
    );
  }

  void clear() {
    _buffer.clear();
  }
}
