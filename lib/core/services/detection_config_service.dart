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

  /// Configuración para modo LEVE (Relaxed)
  factory DetectionConfig.relaxed({bool useGimbal = false}) {
    return DetectionConfig(
      mode: SensitivityMode.relaxed,
      useGimbal: useGimbal,
      // Harsh Braking - Menos sensible (-35%)
      harshBrakingAccelY: -1.95,  // -3.0 * 0.65
      harshBrakingMinConfidence: 0.23,  // 0.35 * 0.65
      harshBrakingGyroStability: useGimbal ? 38.5 : 123.0,  // * 1.54 (inverso para estabilidad)
      harshBrakingDeltaZMin: useGimbal ? 0.065 : 0.13,  // * 0.65
      harshBrakingDeltaZMax: useGimbal ? 15.4 : 7.7,  // * 1.54 (inverso)
      // Aggressive Acceleration (-35%)
      aggressiveAccelAccelY: 1.95,  // 3.0 * 0.65
      aggressiveAccelMinConfidence: 0.26,  // 0.40 * 0.65
      aggressiveAccelGyroStability: useGimbal ? 77.0 : 108.0,  // * 1.54
      // Sharp Turn (-35%)
      sharpTurnGyroZ: 26.0,  // 40.0 * 0.65
      sharpTurnAccelX: 1.95,  // 3.0 * 0.65
      sharpTurnMinConfidence: 0.23,  // 0.35 * 0.65
      sharpTurnGyroStability: useGimbal ? 38.5 : 23.0,  // * 1.54
      // Weaving (-35%)
      weavingGyroZ: 13.0,  // 20.0 * 0.65
      weavingAccelX: 1.3,  // 2.0 * 0.65
      weavingMinConfidence: 0.23,  // 0.35 * 0.65
      // Rough Road (-35%)
      roughRoadAccelZ: 1.3,  // 2.0 * 0.65
      roughRoadMinConfidence: 0.26,  // 0.40 * 0.65
      // Speed Bump (-35%)
      speedBumpFirstPeak: 1.63,  // 2.5 * 0.65
      speedBumpSecondPeak: -1.43,  // -2.2 * 0.65
      speedBumpMinConfidence: 0.23,  // 0.35 * 0.65
      // Filtros de ruido - Menos estrictos (aumentados)
      noiseFilterMaxAccel: useGimbal ? 54.0 : 77.0,  // * 1.54
      noiseFilterMaxGyro: useGimbal ? 462.0 : 770.0,  // * 1.54
    );
  }

  /// Configuración para modo MODERADO (Normal) - RECOMENDADO
  factory DetectionConfig.normal({bool useGimbal = false}) {
    return DetectionConfig(
      mode: SensitivityMode.normal,
      useGimbal: useGimbal,
      // Harsh Braking - Balance (-35%)
      harshBrakingAccelY: -1.3,  // -2.0 * 0.65
      harshBrakingMinConfidence: 0.20,  // 0.30 * 0.65 (redondeado a 0.20)
      harshBrakingGyroStability: useGimbal ? 46.2 : 123.0,  // * 1.54
      harshBrakingDeltaZMin: useGimbal ? 0.065 : 0.13,  // * 0.65
      harshBrakingDeltaZMax: useGimbal ? 15.4 : 7.7,  // * 1.54
      // Aggressive Acceleration (-35%)
      aggressiveAccelAccelY: 1.3,  // 2.0 * 0.65
      aggressiveAccelMinConfidence: 0.20,  // 0.30 * 0.65
      aggressiveAccelGyroStability: useGimbal ? 77.0 : 92.4,  // * 1.54
      // Sharp Turn (-35%)
      sharpTurnGyroZ: 19.5,  // 30.0 * 0.65
      sharpTurnAccelX: 1.63,  // 2.5 * 0.65
      sharpTurnMinConfidence: 0.20,  // 0.30 * 0.65
      sharpTurnGyroStability: useGimbal ? 30.8 : 23.0,  // * 1.54
      // Weaving (-35%)
      weavingGyroZ: 9.75,  // 15.0 * 0.65
      weavingAccelX: 0.98,  // 1.5 * 0.65
      weavingMinConfidence: 0.20,  // 0.30 * 0.65
      // Rough Road (-35%)
      roughRoadAccelZ: 0.98,  // 1.5 * 0.65
      roughRoadMinConfidence: 0.23,  // 0.35 * 0.65
      // Speed Bump (-35%)
      speedBumpFirstPeak: 1.3,  // 2.0 * 0.65
      speedBumpSecondPeak: -1.17,  // -1.8 * 0.65
      speedBumpMinConfidence: 0.20,  // 0.30 * 0.65
      // Filtros de ruido - Menos estrictos (aumentados)
      noiseFilterMaxAccel: useGimbal ? 61.6 : 92.4,  // * 1.54
      noiseFilterMaxGyro: useGimbal ? 539.0 : 924.0,  // * 1.54
    );
  }

  /// Configuración para modo ESTRICTO (Strict)
  factory DetectionConfig.strict({bool useGimbal = false}) {
    return DetectionConfig(
      mode: SensitivityMode.strict,
      useGimbal: useGimbal,
      // Harsh Braking - Muy sensible (-35%)
      harshBrakingAccelY: -0.78,  // -1.2 * 0.65
      harshBrakingMinConfidence: 0.13,  // 0.20 * 0.65
      harshBrakingGyroStability: useGimbal ? 61.6 : 138.6,  // * 1.54
      harshBrakingDeltaZMin: useGimbal ? 0.065 : 0.098,  // * 0.65
      harshBrakingDeltaZMax: useGimbal ? 18.5 : 9.24,  // * 1.54
      // Aggressive Acceleration (-35%)
      aggressiveAccelAccelY: 0.98,  // 1.5 * 0.65
      aggressiveAccelMinConfidence: 0.16,  // 0.25 * 0.65
      aggressiveAccelGyroStability: useGimbal ? 92.4 : 108.0,  // * 1.54
      // Sharp Turn (-35%)
      sharpTurnGyroZ: 13.0,  // 20.0 * 0.65
      sharpTurnAccelX: 1.17,  // 1.8 * 0.65
      sharpTurnMinConfidence: 0.13,  // 0.20 * 0.65
      sharpTurnGyroStability: useGimbal ? 38.5 : 27.7,  // * 1.54
      // Weaving (-35%)
      weavingGyroZ: 7.8,  // 12.0 * 0.65
      weavingAccelX: 0.78,  // 1.2 * 0.65
      weavingMinConfidence: 0.16,  // 0.25 * 0.65
      // Rough Road (-35%)
      roughRoadAccelZ: 0.78,  // 1.2 * 0.65
      roughRoadMinConfidence: 0.20,  // 0.30 * 0.65 (redondeado)
      // Speed Bump (-35%)
      speedBumpFirstPeak: 0.98,  // 1.5 * 0.65
      speedBumpSecondPeak: -0.98,  // -1.5 * 0.65
      speedBumpMinConfidence: 0.16,  // 0.25 * 0.65
      // Filtros de ruido - Menos estrictos (aumentados)
      noiseFilterMaxAccel: useGimbal ? 77.0 : 108.0,  // * 1.54
      noiseFilterMaxGyro: useGimbal ? 616.0 : 1078.0,  // * 1.54
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
