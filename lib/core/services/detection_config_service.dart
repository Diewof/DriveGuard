import 'package:shared_preferences/shared_preferences.dart';

/// Modos de sensibilidad para el sistema de detección
enum SensitivityMode {
  relaxed,  // Leve - Menos sensible
  normal,   // Moderado - Balanceado (recomendado)
  strict    // Estricto - Muy sensible
}

extension SensitivityModeExtension on SensitivityMode {
  String get displayName {
    switch (this) {
      case SensitivityMode.relaxed:
        return 'Leve';
      case SensitivityMode.normal:
        return 'Moderado';
      case SensitivityMode.strict:
        return 'Estricto';
    }
  }

  String get description {
    switch (this) {
      case SensitivityMode.relaxed:
        return 'Menos alertas, conducción experimentada';
      case SensitivityMode.normal:
        return 'Balance entre precisión y cobertura (Recomendado)';
      case SensitivityMode.strict:
        return 'Máxima seguridad, más alertas';
    }
  }
}

/// Configuración dinámica del sistema de detección
class DetectionConfig {
  final SensitivityMode mode;
  final bool useGimbal;

  // Harsh Braking
  final double harshBrakingAccelY;
  final double harshBrakingMinConfidence;
  final double harshBrakingGyroStability;
  final double harshBrakingDeltaZMin;
  final double harshBrakingDeltaZMax;

  // Aggressive Acceleration
  final double aggressiveAccelAccelY;
  final double aggressiveAccelMinConfidence;
  final double aggressiveAccelGyroStability;

  // Sharp Turn
  final double sharpTurnGyroZ;
  final double sharpTurnAccelX;
  final double sharpTurnMinConfidence;
  final double sharpTurnGyroStability;

  // Weaving
  final double weavingGyroZ;
  final double weavingAccelX;
  final double weavingMinConfidence;

  // Rough Road
  final double roughRoadAccelZ;
  final double roughRoadMinConfidence;

  // Speed Bump
  final double speedBumpFirstPeak;
  final double speedBumpSecondPeak;
  final double speedBumpMinConfidence;

  // Filtros de ruido
  final double noiseFilterMaxAccel;
  final double noiseFilterMaxGyro;

  const DetectionConfig({
    required this.mode,
    required this.useGimbal,
    required this.harshBrakingAccelY,
    required this.harshBrakingMinConfidence,
    required this.harshBrakingGyroStability,
    required this.harshBrakingDeltaZMin,
    required this.harshBrakingDeltaZMax,
    required this.aggressiveAccelAccelY,
    required this.aggressiveAccelMinConfidence,
    required this.aggressiveAccelGyroStability,
    required this.sharpTurnGyroZ,
    required this.sharpTurnAccelX,
    required this.sharpTurnMinConfidence,
    required this.sharpTurnGyroStability,
    required this.weavingGyroZ,
    required this.weavingAccelX,
    required this.weavingMinConfidence,
    required this.roughRoadAccelZ,
    required this.roughRoadMinConfidence,
    required this.speedBumpFirstPeak,
    required this.speedBumpSecondPeak,
    required this.speedBumpMinConfidence,
    required this.noiseFilterMaxAccel,
    required this.noiseFilterMaxGyro,
  });

  /// Configuración para modo LEVE (Relaxed) - Para conductores experimentados
  /// Valores calibrados explícitamente - Menos alertas, umbrales más altos
  factory DetectionConfig.relaxed({bool useGimbal = false}) {
    return DetectionConfig(
      mode: SensitivityMode.relaxed,
      useGimbal: useGimbal,
      // Harsh Braking - Menos sensible (solo frenados muy fuertes)
      // AJUSTADO: Reducido 15% para mayor sensibilidad (-2.5 → -2.125)
      harshBrakingAccelY: -2.125,  // Más permisivo que normal (-1.275)
      harshBrakingMinConfidence: 0.25,
      harshBrakingGyroStability: 100.0,  // Muy permisivo
      harshBrakingDeltaZMin: 0.2,
      harshBrakingDeltaZMax: 5.0,
      // Aggressive Acceleration - Menos sensible
      // AJUSTADO: Reducido 15% para mayor sensibilidad (4.5 → 3.825)
      aggressiveAccelAccelY: 3.825,  // Más alto que normal (2.975)
      aggressiveAccelMinConfidence: 0.30,
      aggressiveAccelGyroStability: 60.0,
      // Sharp Turn - Menos sensible (solo giros cerrados)
      sharpTurnGyroZ: 40.0,  // Más alto que normal (30.0)
      sharpTurnAccelX: 3.0,  // Más alto que normal (2.2)
      sharpTurnMinConfidence: 0.30,
      sharpTurnGyroStability: 25.0,
      // Weaving - Menos sensible
      weavingGyroZ: 20.0,
      weavingAccelX: 2.0,
      weavingMinConfidence: 0.35,
      // Rough Road - Menos sensible
      roughRoadAccelZ: 2.0,
      roughRoadMinConfidence: 0.40,
      // Speed Bump - Menos sensible
      speedBumpFirstPeak: 3.5,  // Más alto que normal (2.5)
      speedBumpSecondPeak: -3.0,  // Más estricto que normal (-2.2)
      speedBumpMinConfidence: 0.30,
      // Filtros de ruido - Muy permisivos
      noiseFilterMaxAccel: 25.0,
      noiseFilterMaxGyro: 250.0,
    );
  }

  /// Configuración para modo MODERADO (Normal) - RECOMENDADO
  /// Valores calibrados cuidadosamente - Balance óptimo entre precisión y cobertura
  /// ESTOS SON LOS VALORES BASE DE detection_thresholds.dart
  factory DetectionConfig.normal({bool useGimbal = false}) {
    return DetectionConfig(
      mode: SensitivityMode.normal,
      useGimbal: useGimbal,
      // Harsh Braking - Balance calibrado
      // AJUSTADO: Reducido 15% para mayor sensibilidad (-1.5 → -1.275)
      harshBrakingAccelY: -1.275,  // Valor calibrado de detection_thresholds.dart
      harshBrakingMinConfidence: 0.18,
      harshBrakingGyroStability: 80.0,
      harshBrakingDeltaZMin: 0.2,
      harshBrakingDeltaZMax: 5.0,
      // Aggressive Acceleration - Balance calibrado v2.1
      // AJUSTADO: Reducido 15% para mayor sensibilidad (3.5 → 2.975)
      aggressiveAccelAccelY: 2.975,  // Valor calibrado v2.1 (anti-lomos mejorado)
      aggressiveAccelMinConfidence: 0.25,
      aggressiveAccelGyroStability: 45.0,
      // Sharp Turn - Balance calibrado v2.1 (punto medio)
      sharpTurnGyroZ: 30.0,  // Valor calibrado v2.1 (punto medio 15→45)
      sharpTurnAccelX: 2.2,
      sharpTurnMinConfidence: 0.20,
      sharpTurnGyroStability: 20.0,
      // Weaving - Balance calibrado
      weavingGyroZ: 15.0,
      weavingAccelX: 1.5,
      weavingMinConfidence: 0.25,
      // Rough Road - Balance calibrado
      roughRoadAccelZ: 1.5,
      roughRoadMinConfidence: 0.30,
      // Speed Bump - Balance calibrado
      speedBumpFirstPeak: 2.5,  // Valor calibrado de detection_thresholds.dart
      speedBumpSecondPeak: -2.2,
      speedBumpMinConfidence: 0.22,
      // Filtros de ruido - Balance
      noiseFilterMaxAccel: 20.0,
      noiseFilterMaxGyro: 200.0,
    );
  }

  /// Configuración para modo ESTRICTO (Strict) - Máxima seguridad
  /// Valores calibrados explícitamente - Más alertas, umbrales más bajos
  factory DetectionConfig.strict({bool useGimbal = false}) {
    return DetectionConfig(
      mode: SensitivityMode.strict,
      useGimbal: useGimbal,
      // Harsh Braking - Muy sensible (detecta frenados moderados)
      // AJUSTADO: Reducido 15% para mayor sensibilidad (-1.0 → -0.85)
      harshBrakingAccelY: -0.85,  // Más sensible que normal (-1.275)
      harshBrakingMinConfidence: 0.15,
      harshBrakingGyroStability: 60.0,  // Menos permisivo
      harshBrakingDeltaZMin: 0.2,
      harshBrakingDeltaZMax: 5.0,
      // Aggressive Acceleration - Muy sensible
      // AJUSTADO: Reducido 15% para mayor sensibilidad (2.5 → 2.125)
      aggressiveAccelAccelY: 2.125,  // Más bajo que normal (2.975)
      aggressiveAccelMinConfidence: 0.18,
      aggressiveAccelGyroStability: 35.0,
      // Sharp Turn - Muy sensible (detecta giros moderados)
      sharpTurnGyroZ: 25.0,  // Más bajo que normal (30.0)
      sharpTurnAccelX: 1.8,  // Más bajo que normal (2.2)
      sharpTurnMinConfidence: 0.18,
      sharpTurnGyroStability: 18.0,
      // Weaving - Muy sensible
      weavingGyroZ: 12.0,
      weavingAccelX: 1.2,
      weavingMinConfidence: 0.20,
      // Rough Road - Muy sensible
      roughRoadAccelZ: 1.2,
      roughRoadMinConfidence: 0.25,
      // Speed Bump - Muy sensible
      speedBumpFirstPeak: 2.0,  // Más bajo que normal (2.5)
      speedBumpSecondPeak: -1.8,  // Menos estricto que normal (-2.2)
      speedBumpMinConfidence: 0.18,
      // Filtros de ruido - Más permisivos para no perder eventos
      noiseFilterMaxAccel: 25.0,
      noiseFilterMaxGyro: 250.0,
    );
  }

  /// Crear configuración desde modo y gimbal
  factory DetectionConfig.fromMode(SensitivityMode mode, {bool useGimbal = false}) {
    switch (mode) {
      case SensitivityMode.relaxed:
        return DetectionConfig.relaxed(useGimbal: useGimbal);
      case SensitivityMode.normal:
        return DetectionConfig.normal(useGimbal: useGimbal);
      case SensitivityMode.strict:
        return DetectionConfig.strict(useGimbal: useGimbal);
    }
  }
}

/// Servicio para gestionar la configuración de detección
class DetectionConfigService {
  static const String _keyMode = 'detection_sensitivity_mode';
  static const String _keyUseGimbal = 'detection_use_gimbal';

  static DetectionConfigService? _instance;
  late SharedPreferences _prefs;
  DetectionConfig _currentConfig = DetectionConfig.normal();

  DetectionConfigService._();

  /// Obtener instancia singleton
  static Future<DetectionConfigService> getInstance() async {
    if (_instance == null) {
      _instance = DetectionConfigService._();
      await _instance!._init();
    }
    return _instance!;
  }

  /// Inicializar servicio y cargar configuración guardada
  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadConfig();
  }

  /// Cargar configuración desde SharedPreferences
  Future<void> _loadConfig() async {
    final modeStr = _prefs.getString(_keyMode) ?? 'normal';
    final useGimbal = _prefs.getBool(_keyUseGimbal) ?? false;

    final mode = SensitivityMode.values.firstWhere(
      (m) => m.name == modeStr,
      orElse: () => SensitivityMode.normal,
    );

    _currentConfig = DetectionConfig.fromMode(mode, useGimbal: useGimbal);
  }

  /// Obtener configuración actual
  DetectionConfig get config => _currentConfig;

  /// Cambiar modo de sensibilidad
  Future<void> setMode(SensitivityMode mode) async {
    await _prefs.setString(_keyMode, mode.name);
    _currentConfig = DetectionConfig.fromMode(mode, useGimbal: _currentConfig.useGimbal);
  }

  /// Activar/desactivar uso de gimbal
  Future<void> setUseGimbal(bool useGimbal) async {
    await _prefs.setBool(_keyUseGimbal, useGimbal);
    _currentConfig = DetectionConfig.fromMode(_currentConfig.mode, useGimbal: useGimbal);
  }

  /// Cambiar modo y gimbal simultáneamente
  Future<void> setConfig(SensitivityMode mode, bool useGimbal) async {
    await _prefs.setString(_keyMode, mode.name);
    await _prefs.setBool(_keyUseGimbal, useGimbal);
    _currentConfig = DetectionConfig.fromMode(mode, useGimbal: useGimbal);
  }

  /// Resetear a configuración por defecto
  Future<void> reset() async {
    await _prefs.remove(_keyMode);
    await _prefs.remove(_keyUseGimbal);
    _currentConfig = DetectionConfig.normal();
  }
}
