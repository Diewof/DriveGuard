import 'dart:math';
import '../../domain/entities/sensor_data.dart';

class RiskCalculator {
  static double calculateRiskScore(SensorData data, List<Map<String, dynamic>> recentAlerts) {
    double score = 0.0;

    // Factor de aceleración
    double accelMagnitude = sqrt(
      pow(data.accelerationX, 2) +
      pow(data.accelerationY, 2) +
      pow((data.accelerationZ - 9.8).abs(), 2)
    );
    score += min(accelMagnitude * 10, 30);

    // Factor de rotación
    double gyroMagnitude = sqrt(
      pow(data.gyroscopeX, 2) +
      pow(data.gyroscopeY, 2) +
      pow(data.gyroscopeZ, 2)
    );
    score += min(gyroMagnitude / 2, 30);

    // Factor de historial reciente
    if (recentAlerts.isNotEmpty) {
      score += min(recentAlerts.length * 5, 40);
    }

    return min(score, 100);
  }
}