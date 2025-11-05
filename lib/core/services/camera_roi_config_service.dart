import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';

/// Configuración del ROI (Region of Interest) para la detección de manos
///
/// Define el área rectangular del frame donde se debe monitorear
/// la presencia de manos sobre el volante
class CameraROIConfig {
  final double left;   // Posición izquierda (0.0 - 1.0, normalizado)
  final double top;    // Posición superior (0.0 - 1.0, normalizado)
  final double width;  // Ancho (0.0 - 1.0, normalizado)
  final double height; // Alto (0.0 - 1.0, normalizado)

  const CameraROIConfig({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  /// Configuración por defecto (centro del frame, área moderada)
  factory CameraROIConfig.defaultConfig() {
    return const CameraROIConfig(
      left: 0.2,    // 20% desde la izquierda
      top: 0.4,     // 40% desde arriba
      width: 0.6,   // 60% de ancho
      height: 0.3,  // 30% de alto
    );
  }

  /// Crear desde JSON
  factory CameraROIConfig.fromJson(Map<String, dynamic> json) {
    return CameraROIConfig(
      left: json['left'] ?? 0.2,
      top: json['top'] ?? 0.4,
      width: json['width'] ?? 0.6,
      height: json['height'] ?? 0.3,
    );
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'left': left,
      'top': top,
      'width': width,
      'height': height,
    };
  }

  /// Obtener Rect absoluto para un tamaño de imagen dado
  Rect toRect(Size imageSize) {
    return Rect.fromLTWH(
      left * imageSize.width,
      top * imageSize.height,
      width * imageSize.width,
      height * imageSize.height,
    );
  }

  /// Crear copia con valores modificados
  CameraROIConfig copyWith({
    double? left,
    double? top,
    double? width,
    double? height,
  }) {
    return CameraROIConfig(
      left: left ?? this.left,
      top: top ?? this.top,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  /// Validar que los valores estén en el rango correcto
  bool isValid() {
    return left >= 0.0 &&
        left <= 1.0 &&
        top >= 0.0 &&
        top <= 1.0 &&
        width >= 0.1 &&
        width <= 1.0 &&
        height >= 0.1 &&
        height <= 1.0 &&
        (left + width) <= 1.0 &&
        (top + height) <= 1.0;
  }
}

/// Servicio para gestionar la configuración del ROI de la cámara
///
/// Maneja la persistencia local de la configuración del ROI
/// y proporciona acceso singleton a la configuración actual
class CameraROIConfigService {
  static const String _keyROILeft = 'camera_roi_left';
  static const String _keyROITop = 'camera_roi_top';
  static const String _keyROIWidth = 'camera_roi_width';
  static const String _keyROIHeight = 'camera_roi_height';
  static const String _keyIsCalibrated = 'camera_is_calibrated';

  static CameraROIConfigService? _instance;
  late SharedPreferences _prefs;
  CameraROIConfig _currentConfig = CameraROIConfig.defaultConfig();
  bool _isCalibrated = false;

  CameraROIConfigService._();

  /// Obtener instancia singleton
  static Future<CameraROIConfigService> getInstance() async {
    if (_instance == null) {
      _instance = CameraROIConfigService._();
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
    final left = _prefs.getDouble(_keyROILeft);
    final top = _prefs.getDouble(_keyROITop);
    final width = _prefs.getDouble(_keyROIWidth);
    final height = _prefs.getDouble(_keyROIHeight);
    _isCalibrated = _prefs.getBool(_keyIsCalibrated) ?? false;

    // Si existe configuración guardada, cargarla
    if (left != null && top != null && width != null && height != null) {
      final config = CameraROIConfig(
        left: left,
        top: top,
        width: width,
        height: height,
      );

      // Validar configuración antes de usarla
      if (config.isValid()) {
        _currentConfig = config;
      } else {
        // Si la configuración guardada no es válida, resetear
        await reset();
      }
    }
  }

  /// Obtener configuración actual del ROI
  CameraROIConfig get config => _currentConfig;

  /// Verificar si la cámara ya fue calibrada
  bool get isCalibrated => _isCalibrated;

  /// Guardar nueva configuración de ROI
  Future<void> saveConfig(CameraROIConfig config) async {
    if (!config.isValid()) {
      throw ArgumentError('Configuración de ROI inválida');
    }

    await _prefs.setDouble(_keyROILeft, config.left);
    await _prefs.setDouble(_keyROITop, config.top);
    await _prefs.setDouble(_keyROIWidth, config.width);
    await _prefs.setDouble(_keyROIHeight, config.height);
    await _prefs.setBool(_keyIsCalibrated, true);

    _currentConfig = config;
    _isCalibrated = true;

    print('[CameraROIConfigService] ✅ Configuración de ROI guardada: '
        'left=${config.left}, top=${config.top}, '
        'width=${config.width}, height=${config.height}');
  }

  /// Resetear a configuración por defecto
  Future<void> reset() async {
    await _prefs.remove(_keyROILeft);
    await _prefs.remove(_keyROITop);
    await _prefs.remove(_keyROIWidth);
    await _prefs.remove(_keyROIHeight);
    await _prefs.remove(_keyIsCalibrated);

    _currentConfig = CameraROIConfig.defaultConfig();
    _isCalibrated = false;

    print('[CameraROIConfigService] ⚠️ Configuración de ROI reseteada');
  }
}
