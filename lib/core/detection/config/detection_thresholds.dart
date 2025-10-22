/// Configuración de umbrales para detección de frenado brusco
/// AJUSTADO PARA PRUEBAS CON TELÉFONO (valores más sensibles)
class HarshBrakingConfig {
  // Umbrales primarios - REDUCIDOS para teléfono
  static const double accelYThreshold = -2.0; // m/s² (era -4.5)
  static const double accelZChangeMin = 0.2;  // m/s² (era 0.5)
  static const double accelZChangeMax = 5.0;  // m/s² (era 2.0, muy aumentado)

  // Umbrales temporales
  static const Duration minEventDuration = Duration(milliseconds: 200); // BETA: Reducido para calibración
  static const Duration maxEventDuration = Duration(milliseconds: 2000); // Aumentado de 1500
  static const Duration cooldownPeriod = Duration(seconds: 2);

  // Umbrales de confianza - MÁS PERMISIVO
  static const double gyroStabilityThreshold = 80.0; // °/s (era 15.0, muy aumentado)
  static const double minConfidence = 0.25; // Reducido de 0.40 para pruebas

  // Umbrales de severidad
  static const double mediumThreshold = -3.5; // Reducido de -6.0
  static const double highThreshold = -5.0;   // Reducido de -8.0
}

/// Configuración de umbrales para detección de aceleración agresiva
/// AJUSTADO PARA PRUEBAS CON TELÉFONO
class AggressiveAccelConfig {
  static const double accelYThreshold = 2.0;  // m/s² (era 3.5)
  static const double accelZChangeMin = -3.0; // m/s² (era -2.5)
  static const double accelZChangeMax = -0.5; // m/s² (era -0.8)

  static const Duration minEventDuration = Duration(milliseconds: 200); // BETA: Reducido para calibración
  static const Duration maxEventDuration = Duration(seconds: 3);
  static const Duration cooldownPeriod = Duration(milliseconds: 1500);

  static const double gyroStabilityThreshold = 60.0; // °/s (era 20.0)
  static const double minConfidence = 0.30; // Reducido de 0.45 para pruebas

  // Umbrales de severidad
  static const double mediumThreshold = 3.5; // Reducido de 5.0
  static const double highThreshold = 5.0;   // Reducido de 7.0
}

/// Configuración de umbrales para detección de giro cerrado
/// AJUSTADO PARA PRUEBAS CON TELÉFONO
class SharpTurnConfig {
  static const double gyroZThreshold = 25.0;      // °/s (era 35.0)
  static const double accelXThreshold = 2.0;      // m/s² (era 3.0)
  static const Duration minTurnDuration = Duration(milliseconds: 200); // BETA: Reducido para calibración
  static const Duration maxTurnDuration = Duration(seconds: 5);

  static const double gyroStdDevThreshold = 15.0;  // Estabilidad (era 8.0)
  static const double minConfidence = 0.25; // Reducido de 0.50 para pruebas
  static const Duration cooldownPeriod = Duration(seconds: 2);

  // Clasificación de curvas
  static const double tightTurnGyroThreshold = 40.0; // Reducido de 50.0
  static const double tightTurnAccelThreshold = 3.5; // Reducido de 4.5
}

/// Configuración de umbrales para detección de zigzagueo
/// AJUSTADO PARA PRUEBAS CON TELÉFONO
class WeavingConfig {
  static const double gyroZOscillationThreshold = 15.0;  // °/s (era 20.0)
  static const double accelXOscillationThreshold = 1.5;  // m/s² (era 2.0)

  static const int minOscillations = 3; // Mantener igual
  static const Duration detectionWindow = Duration(seconds: 8);
  static const Duration cooldownPeriod = Duration(seconds: 5);

  static const double minConfidence = 0.25; // Reducido de 0.40 para pruebas

  // Frecuencias esperadas (Hz)
  static const double minFrequency = 0.5;
  static const double maxFrequency = 2.5; // Aumentado de 2.0
  static const double vibrationFrequency = 4.0; // Aumentado de 3.0
}

/// Configuración de umbrales para detección de camino irregular
/// AJUSTADO PARA PRUEBAS CON TELÉFONO
class RoughRoadConfig {
  static const double accelZPeakThreshold = 1.5;     // m/s² (era 2.5)
  static const int minPeaksInWindow = 3; // Mantener
  static const Duration detectionWindow = Duration(seconds: 5);

  static const double irregularityThreshold = 0.30;   // 30% variación
  static const double gyroPitchThreshold = 20.0;     // °/s (era 15.0)

  static const Duration cooldownPeriod = Duration(seconds: 3);
  static const double minConfidence = 0.30; // Reducido de 0.45 para pruebas

  // Rechazo de falsos positivos
  static const double maxFrequency = 6.0; // Hz (era 5.0)
  static const double regularityThreshold = 0.20; // 20% variación
}

/// Configuración de umbrales para detección de lomos de toro
/// AJUSTADO PARA PRUEBAS CON TELÉFONO
class SpeedBumpConfig {
  static const double firstPeakThreshold = 2.0;   // m/s² (era 3.0)
  static const double secondPeakThreshold = -1.8; // m/s² (era -2.5)

  static const Duration minTimeBetweenPeaks = Duration(milliseconds: 300); // Reducido de 500
  static const Duration maxTimeBetweenPeaks = Duration(milliseconds: 1500);
  static const Duration stabilizationTime = Duration(seconds: 2);

  static const double minConfidence = 0.25; // Reducido de 0.50 para pruebas
  static const Duration cooldownPeriod = Duration(seconds: 3);

  // Velocidad estimada
  static const int fastSpeedThreshold = 700;    // ms
  static const int moderateSpeedThreshold = 1000; // ms
}

/// Niveles de sensibilidad ajustables
enum SensitivityLevel {
  relaxed,   // Principiantes
  normal,    // Default
  strict     // Profesional
}

/// Clase para ajustar umbrales según el nivel de sensibilidad
class SensitivityAdjuster {
  static double adjustThreshold(double baseValue, SensitivityLevel level) {
    switch (level) {
      case SensitivityLevel.relaxed:
        return baseValue * 1.3; // +30%
      case SensitivityLevel.normal:
        return baseValue;
      case SensitivityLevel.strict:
        return baseValue * 0.8; // -20%
    }
  }

  static Duration adjustDuration(Duration baseDuration, SensitivityLevel level) {
    switch (level) {
      case SensitivityLevel.relaxed:
        return baseDuration * 1.5; // +50%
      case SensitivityLevel.normal:
        return baseDuration;
      case SensitivityLevel.strict:
        return baseDuration * 0.7; // -30%
    }
  }

  static double adjustConfidence(double baseConfidence, SensitivityLevel level) {
    switch (level) {
      case SensitivityLevel.relaxed:
        return 0.75;
      case SensitivityLevel.normal:
        return 0.65;
      case SensitivityLevel.strict:
        return 0.55;
    }
  }
}
