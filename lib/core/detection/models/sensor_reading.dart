import 'dart:math';
import 'package:equatable/equatable.dart';

/// Representa una lectura instantánea de sensores con timestamp
class SensorReading extends Equatable {
  final DateTime timestamp;
  final double accelX; // m/s²
  final double accelY; // m/s²
  final double accelZ; // m/s²
  final double gyroX;  // °/s
  final double gyroY;  // °/s
  final double gyroZ;  // °/s

  const SensorReading({
    required this.timestamp,
    required this.accelX,
    required this.accelY,
    required this.accelZ,
    required this.gyroX,
    required this.gyroY,
    required this.gyroZ,
  });

  /// Calcula la magnitud vectorial total de aceleración
  double get accelMagnitude {
    return sqrt(accelX * accelX + accelY * accelY + accelZ * accelZ);
  }

  /// Calcula la magnitud vectorial total de rotación (giroscopio)
  double get gyroMagnitude {
    return sqrt(gyroX * gyroX + gyroY * gyroY + gyroZ * gyroZ);
  }

  /// Normaliza la aceleración respecto a la gravedad (9.81 m/s²)
  SensorReading normalize() {
    const gravity = 9.81;
    return SensorReading(
      timestamp: timestamp,
      accelX: accelX / gravity,
      accelY: accelY / gravity,
      accelZ: accelZ / gravity,
      gyroX: gyroX,
      gyroY: gyroY,
      gyroZ: gyroZ,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'accelX': accelX,
      'accelY': accelY,
      'accelZ': accelZ,
      'gyroX': gyroX,
      'gyroY': gyroY,
      'gyroZ': gyroZ,
    };
  }

  factory SensorReading.fromJson(Map<String, dynamic> json) {
    return SensorReading(
      timestamp: DateTime.parse(json['timestamp'] as String),
      accelX: (json['accelX'] as num).toDouble(),
      accelY: (json['accelY'] as num).toDouble(),
      accelZ: (json['accelZ'] as num).toDouble(),
      gyroX: (json['gyroX'] as num).toDouble(),
      gyroY: (json['gyroY'] as num).toDouble(),
      gyroZ: (json['gyroZ'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [timestamp, accelX, accelY, accelZ, gyroX, gyroY, gyroZ];
}
