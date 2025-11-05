import 'package:equatable/equatable.dart';
import 'dart:math' as math;

class SensorData extends Equatable {
  final String id;
  final DateTime timestamp;
  final double accelerationX;
  final double accelerationY;
  final double accelerationZ;
  final double gyroscopeX;
  final double gyroscopeY;
  final double gyroscopeZ;
  final bool impactDetected;
  final double vibrationLevel;
  final bool isCalibrated; // Indica si los datos están calibrados (gravedad removida)

  const SensorData({
    required this.id,
    required this.timestamp,
    required this.accelerationX,
    required this.accelerationY,
    required this.accelerationZ,
    required this.gyroscopeX,
    required this.gyroscopeY,
    required this.gyroscopeZ,
    this.impactDetected = false,
    this.vibrationLevel = 0.0,
    this.isCalibrated = false,
  });

  /// Calcula la magnitud de la aceleración (m/s²)
  double get accelerationMagnitude {
    return math.sqrt(
      accelerationX * accelerationX +
      accelerationY * accelerationY +
      accelerationZ * accelerationZ
    );
  }

  /// Calcula la magnitud del giroscopio (°/s)
  double get gyroscopeMagnitude {
    return math.sqrt(
      gyroscopeX * gyroscopeX +
      gyroscopeY * gyroscopeY +
      gyroscopeZ * gyroscopeZ
    );
  }

  @override
  List<Object?> get props => [
    id, timestamp, accelerationX, accelerationY, accelerationZ,
    gyroscopeX, gyroscopeY, gyroscopeZ, impactDetected, vibrationLevel,
    isCalibrated
  ];
}