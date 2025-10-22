class AppConstants {
  // App Info
  static const String appName = 'DriveGuard';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Sistema de Monitoreo Inteligente de Conducción';

  // Configuración sensores
  static const int sensorUpdateIntervalMs = 100; // 10 Hz
  static const int uiUpdateIntervalMs = 300;

  // Configuración de calibración
  static const int calibrationSamples = 30;
  static const int calibrationDurationSeconds = 3;

  // Configuración alertas
  static const int alertTimeoutSeconds = 10;
  static const int emergencyResponseTimeoutSeconds = 30;
  static const int maxRecentAlerts = 10;

  // Configuración sesión
  static const int deviceConnectionDelaySeconds = 2;

  // Rangos de riesgo
  static const double lowRiskThreshold = 30.0;
  static const double mediumRiskThreshold = 60.0;

  // Umbrales de detección ajustados para condiciones reales
  // (valores más sensibles para capturar eventos con teléfono en soporte)

  // Aceleración (m/s²)
  static const double recklessAccelThreshold = 1.5;  // Era 3.0
  static const double crashAccelThreshold = 8.0;     // Era 15.0
  static const double harshBrakingThreshold = 2.0;   // Nuevo
  static const double aggressiveAccelThreshold = 2.0; // Nuevo

  // Giroscopio (grados/segundo)
  static const double recklessGyroThreshold = 25.0;  // Era 45.0
  static const double sharpTurnThreshold = 20.0;     // Nuevo

  // Umbrales de cambio (deltas)
  static const double deltaAccelThreshold = 2.0;     // Cambio brusco en 0.5s
  static const double deltaGyroThreshold = 20.0;     // Cambio de rotación en 0.5s
  static const double deltaDuration = 0.5;           // Ventana de tiempo (segundos)

  // Filtrado de datos
  static const int sensorFilterWindowSize = 2;       // Era 5 (reducido para detectar picos)
  static const bool enablePeakDetection = true;      // Detector paralelo sin filtro

  // Rutas
  static const String splashRoute = '/splash';
  static const String loginRoute = '/login';
  static const String dashboardRoute = '/dashboard';
  static const String notificationSettingsRoute = '/notification-settings';
}