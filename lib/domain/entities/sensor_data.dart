import 'package:equatable/equatable.dart';
import '../../core/constants/app_constants.dart';

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
  });

  bool get isRecklessDriving {
    final totalAccel = (accelerationX.abs() + accelerationY.abs()) / 2;
    final totalGyro = (gyroscopeX.abs() + gyroscopeY.abs() + gyroscopeZ.abs()) / 3;

    return totalAccel > AppConstants.recklessAccelThreshold ||
           totalGyro > AppConstants.recklessGyroThreshold;
  }

  bool get isCrashDetected {
    final totalAccel = (accelerationX.abs() + accelerationY.abs() + accelerationZ.abs()) / 3;
    return totalAccel > AppConstants.crashAccelThreshold;
  }

  @override
  List<Object?> get props => [
    id, timestamp, accelerationX, accelerationY, accelerationZ,
    gyroscopeX, gyroscopeY, gyroscopeZ, impactDetected, vibrationLevel
  ];
}