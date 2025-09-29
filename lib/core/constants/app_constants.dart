class AppConstants {
  // App Info
  static const String appName = 'DriveGuard';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Sistema de Monitoreo Inteligente de Conducción';

  // Configuración sensores
  static const int sensorUpdateIntervalMs = 100;
  static const int uiUpdateIntervalMs = 300;

  // Umbrales de detección
  static const double recklessAccelThreshold = 3.0;
  static const double crashAccelThreshold = 15.0;
  static const double recklessGyroThreshold = 45.0;

  // Configuración alertas
  static const int alertTimeoutSeconds = 10;
  static const int emergencyResponseTimeoutSeconds = 30;
  static const int maxRecentAlerts = 5;

  // Configuración sesión
  static const int deviceConnectionDelaySeconds = 2;
  static const int randomEventMinInterval = 15;
  static const int randomEventMaxInterval = 30;

  // Rangos de riesgo
  static const double lowRiskThreshold = 30.0;
  static const double mediumRiskThreshold = 60.0;

  // Rutas
  static const String splashRoute = '/splash';
  static const String loginRoute = '/login';
  static const String dashboardRoute = '/dashboard';
  static const String notificationSettingsRoute = '/notification-settings';
}

class AssetConstants {
  static const String _soundsPath = 'assets/sounds';

  // Alertas
  static const String mediumAlertSound = '$_soundsPath/alerts/medium_alert.mp3';
  static const String highAlertSound = '$_soundsPath/alerts/high_alert.mp3';
  static const String criticalAlertSound = '$_soundsPath/alerts/critical_alert.mp3';

  // Voces
  static const String distractionWarning = '$_soundsPath/voices/distraction_warning_es.mp3';
  static const String recklessWarning = '$_soundsPath/voices/reckless_warning_es.mp3';
  static const String impactWarning = '$_soundsPath/voices/impact_warning_es.mp3';
  static const String phoneWarning = '$_soundsPath/voices/phone_warning_es.mp3';
  static const String lookAwayWarning = '$_soundsPath/voices/look_away_warning_es.mp3';
  static const String harshBrakingWarning = '$_soundsPath/voices/harsh_braking_warning_es.mp3';
}