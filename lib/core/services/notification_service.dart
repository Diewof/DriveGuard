import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

enum AlertSeverity { low, medium, high, critical }

enum AlertType {
  // IMU-based alerts (sensor detection)
  harshBraking,
  aggressiveAcceleration,
  sharpTurn,
  weaving,
  roughRoad,
  speedBump,

  // Vision-based alerts (camera detection)
  distraction,      // Phone usage - looking down
  inattention,      // Eyes off road - head turned away
  handsOff,         // Hands off steering wheel
  noFaceDetected    // No face detected for extended period
}

class NotificationSettings {
  final bool visualEnabled;
  final bool audioEnabled;
  final bool hapticEnabled;
  final double volume;
  final String language;
  final String drivingMode;
  final double sensitivity;
  final int alertCardDuration;

  const NotificationSettings({
    this.visualEnabled = true,
    this.audioEnabled = true, // Habilitado con sistema de audio
    this.hapticEnabled = true,
    this.volume = 0.8,
    this.language = 'es',
    this.drivingMode = 'ciudad',
    this.sensitivity = 0.7,
    this.alertCardDuration = 5,
  });

  Map<String, dynamic> toJson() {
    return {
      'visualEnabled': visualEnabled,
      'audioEnabled': audioEnabled,
      'hapticEnabled': hapticEnabled,
      'volume': volume,
      'language': language,
      'drivingMode': drivingMode,
      'sensitivity': sensitivity,
      'alertCardDuration': alertCardDuration,
    };
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      visualEnabled: json['visualEnabled'] ?? true,
      audioEnabled: json['audioEnabled'] ?? false,
      hapticEnabled: json['hapticEnabled'] ?? true,
      volume: json['volume'] ?? 0.8,
      language: json['language'] ?? 'es',
      drivingMode: json['drivingMode'] ?? 'ciudad',
      sensitivity: json['sensitivity'] ?? 0.7,
      alertCardDuration: json['alertCardDuration'] ?? 5,
    );
  }
}

class AlertNotification {
  final String id;
  final AlertType type;
  final AlertSeverity severity;
  final String message;
  final DateTime timestamp;
  final bool isActive;

  AlertNotification({
    required this.id,
    required this.type,
    required this.severity,
    required this.message,
    required this.timestamp,
    this.isActive = true,
  });
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  SharedPreferences? _prefs;
  final AudioPlayer _audioPlayer = AudioPlayer();

  NotificationSettings _settings = const NotificationSettings();
  final List<AlertNotification> _notificationQueue = [];
  final Map<AlertType, DateTime> _lastNotificationTime = {};
  bool _isProcessingNotification = false;
  bool _silentMode = false;
  bool _isDisposed = false;
  bool _isAudioInitialized = false;

  static const int maxQueueSize = 10;

  Function(AlertNotification)? onShowOverlay;
  Function()? onHideOverlay;

  Future<void> initialize() async {
    if (_isDisposed) return;
    _prefs = await SharedPreferences.getInstance();
    await _loadSettings();
    await _initializeAudio();
  }

  Future<void> _initializeAudio() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      await _audioPlayer.setVolume(_settings.volume);
      _isAudioInitialized = true;
      debugPrint('Audio system initialized successfully');
    } catch (e) {
      debugPrint('Error initializing audio: $e');
      _isAudioInitialized = false;
    }
  }

  Future<void> _loadSettings() async {
    final settingsJson = _prefs?.getString('notification_settings');
    if (settingsJson != null) {
      try {
        _settings = const NotificationSettings();
      } catch (e) {
        _settings = const NotificationSettings();
      }
    }
  }

  Future<void> _saveSettings() async {
    await _prefs?.setString('notification_settings', _settings.toJson().toString());
  }

  void updateSettings(NotificationSettings newSettings) {
    _settings = newSettings;
    _saveSettings();
  }

  NotificationSettings get settings => _settings;

  void setSilentMode(bool silent) {
    _silentMode = silent;
  }

  Future<void> showAlert({
    required AlertType type,
    required AlertSeverity severity,
    String? customMessage,
  }) async {
    if (_silentMode) return;

    if (!_shouldShowAlert(type, severity)) {
      return;
    }

    final notification = AlertNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      severity: severity,
      message: customMessage ?? _getDefaultMessage(type),
      timestamp: DateTime.now(),
    );

    _addToQueueWithLimit(notification);
    _lastNotificationTime[type] = DateTime.now();

    if (!_isProcessingNotification) {
      await _processNotificationQueue();
    }
  }

  bool _shouldShowAlert(AlertType type, AlertSeverity severity) {
    final lastTime = _lastNotificationTime[type];
    if (lastTime != null) {
      final timeDiff = DateTime.now().difference(lastTime);
      if (timeDiff.inSeconds < 30) {
        return false;
      }
    }

    // Permitir alertas informativas como noFaceDetected aunque sean LOW
    if (type == AlertType.noFaceDetected) {
      return true;
    }

    return severity.index >= AlertSeverity.medium.index;
  }

  Future<void> _processNotificationQueue() async {
    if (_notificationQueue.isEmpty || _isProcessingNotification) {
      return;
    }

    _isProcessingNotification = true;
    _notificationQueue.sort((a, b) => b.severity.index.compareTo(a.severity.index));

    final notification = _notificationQueue.removeAt(0);

    try {
      await _showNotification(notification);
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }

    _isProcessingNotification = false;

    if (_notificationQueue.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 500));
      await _processNotificationQueue();
    }
  }

  Future<void> _showNotification(AlertNotification notification) async {
    if (_settings.audioEnabled && _isAudioInitialized) {
      await _playAlertSound(notification.type, notification.severity);
    }

    if (_settings.visualEnabled) {
      _showVisualNotification(notification);
    }

    if (_settings.hapticEnabled) {
      _triggerHapticFeedback(notification.severity);
    }
  }

  Future<void> _playAlertSound(AlertType type, AlertSeverity severity) async {
    try {
      // Detener cualquier sonido previo
      await _audioPlayer.stop();

      // Seleccionar el archivo de sonido apropiado
      final soundPath = _getSoundPath(type, severity);

      // Reproducir el sonido
      await _audioPlayer.play(AssetSource(soundPath));

      debugPrint('Playing alert sound: $soundPath');
    } catch (e) {
      debugPrint('Error playing alert sound: $e');
    }
  }

  String _getSoundPath(AlertType type, AlertSeverity severity) {
    // Primero intentar con sonido específico por tipo
    final specificSound = _getTypeSpecificSound(type);

    // Si no existe, usar sonido genérico por severidad
    if (specificSound.isEmpty) {
      return _getSeveritySound(severity);
    }

    return specificSound;
  }

  String _getTypeSpecificSound(AlertType type) {
    switch (type) {
      // IMU-based alerts
      case AlertType.harshBraking:
        return 'sounds/voice/harsh_braking.mp3';
      case AlertType.aggressiveAcceleration:
        return 'sounds/voice/aggressive_acceleration.mp3';
      case AlertType.sharpTurn:
        return 'sounds/voice/sharp_turn.mp3';
      case AlertType.weaving:
        return 'sounds/voice/weaving.mp3';
      case AlertType.roughRoad:
        return 'sounds/voice/rough_road.mp3';
      case AlertType.speedBump:
        return 'sounds/voice/speed_bump.mp3';

      // Vision-based alerts
      case AlertType.distraction:
        return 'sounds/voice/distraction.mp3';
      case AlertType.inattention:
        return 'sounds/voice/inattention.mp3';
      case AlertType.handsOff:
        return 'sounds/voice/hands_off.mp3';
      case AlertType.noFaceDetected:
        return 'sounds/voice/no_face.mp3';
    }
  }

  String _getSeveritySound(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.low:
        return 'sounds/alerts/alert_low.mp3';
      case AlertSeverity.medium:
        return 'sounds/alerts/alert_medium.mp3';
      case AlertSeverity.high:
        return 'sounds/alerts/alert_high.mp3';
      case AlertSeverity.critical:
        return 'sounds/alerts/alert_critical.mp3';
    }
  }

  void _showVisualNotification(AlertNotification notification) {
    if (onShowOverlay != null) {
      onShowOverlay!(notification);

      Timer(Duration(seconds: _settings.alertCardDuration), () {
        if (onHideOverlay != null) {
          onHideOverlay!();
        }
      });
    }
  }

  void _triggerHapticFeedback(AlertSeverity severity) {
    _performVibration(severity).catchError((e) {
      debugPrint('Error triggering haptic feedback: $e');
    });
  }

  Future<void> _performVibration(AlertSeverity severity) async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        switch (severity) {
          case AlertSeverity.low:
            await Vibration.vibrate(duration: 200);
            break;
          case AlertSeverity.medium:
            await Vibration.vibrate(pattern: [0, 300, 100, 300]);
            break;
          case AlertSeverity.high:
            await Vibration.vibrate(pattern: [0, 500, 200, 500, 200, 500]);
            break;
          case AlertSeverity.critical:
            await Vibration.vibrate(pattern: [0, 1000, 300, 1000, 300, 1000]);
            break;
        }
      } else {
        await HapticFeedback.heavyImpact();
      }
    } catch (e) {
      rethrow;
    }
  }

  String _getDefaultMessage(AlertType type) {
    switch (type) {
      // IMU-based alerts
      case AlertType.harshBraking:
        return 'FRENADO BRUSCO DETECTADO';
      case AlertType.aggressiveAcceleration:
        return 'ACELERACIÓN AGRESIVA';
      case AlertType.sharpTurn:
        return 'GIRO CERRADO A ALTA VELOCIDAD';
      case AlertType.weaving:
        return 'ZIGZAGUEO DETECTADO';
      case AlertType.roughRoad:
        return 'CAMINO IRREGULAR';
      case AlertType.speedBump:
        return 'PASO POR LOMO DE TORO';

      // Vision-based alerts
      case AlertType.distraction:
        return 'DISTRACCIÓN DETECTADA - CELULAR';
      case AlertType.inattention:
        return 'DESATENCIÓN VISUAL - MIRA AL FRENTE';
      case AlertType.handsOff:
        return 'MANOS FUERA DEL VOLANTE';
      case AlertType.noFaceDetected:
        return 'AJUSTA TU POSICIÓN - NO SE DETECTA TU ROSTRO';
    }
  }

  void stopCurrentAlert() {
    _audioPlayer.stop();
    if (onHideOverlay != null) {
      onHideOverlay!();
    }
  }

  void _addToQueueWithLimit(AlertNotification notification) {
    while (_notificationQueue.length >= maxQueueSize) {
      _notificationQueue.removeAt(0);
    }
    _notificationQueue.add(notification);
  }

  void clearNotificationQueue() {
    _notificationQueue.clear();
  }

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _notificationQueue.clear();
    _audioPlayer.dispose();
  }
}
