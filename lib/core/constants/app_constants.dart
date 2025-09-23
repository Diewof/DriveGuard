class AppConstants {
  static const String appName = 'DriveGuard';
  static const String appVersion = '1.0.0';

  // Configuración sensores simulados
  static const int sensorUpdateIntervalMs = 100;
  static const int cameraFrameIntervalMs = 500;

  // Umbrales de detección
  static const double recklessAccelThreshold = 3.0; // m/s²
  static const double crashAccelThreshold = 15.0;   // m/s²
  static const double recklessGyroThreshold = 45.0; // °/s

  // Configuración alertas
  static const int alertTimeoutSeconds = 10;
  static const int emergencyResponseTimeoutSeconds = 30;
}

class FirebaseConstants {
  static const String usersCollection = 'users';
  static const String sessionsCollection = 'driving_sessions';
  static const String alertsCollection = 'alerts';
  static const String sensorDataCollection = 'sensor_data';
}