import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AlertSeverity { low, medium, high, critical }

enum AudioPlaybackState { idle, playingTone, playingVoice }

enum AlertType {
  distraction,
  recklessDriving,
  impact,
  phoneUsage,
  lookAway,
  harshBraking
}

class NotificationSettings {
  final bool visualEnabled;
  final bool audioEnabled;
  final bool hapticEnabled;
  final double volume;
  final String language;
  final String drivingMode;
  final double sensitivity;
  final int alertCardDuration; // Duración en segundos

  const NotificationSettings({
    this.visualEnabled = true,
    this.audioEnabled = true,
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
      audioEnabled: json['audioEnabled'] ?? true,
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

  AudioPlayer? _audioPlayer;
  SharedPreferences? _prefs;
  Timer? _audioSequenceTimer;

  NotificationSettings _settings = const NotificationSettings();
  final List<AlertNotification> _notificationQueue = [];
  final Map<AlertType, DateTime> _lastNotificationTime = {};
  Timer? _cooldownTimer;
  bool _isProcessingNotification = false;
  bool _silentMode = false;
  bool _isPlayingAudio = false;
  AudioPlaybackState _audioState = AudioPlaybackState.idle;
  bool _isDisposed = false;

  // Límites de cola para optimizar memoria
  static const int maxQueueSize = 10;
  static const int maxHistorySize = 50;

  // Callbacks para UI
  Function(AlertNotification)? onShowOverlay;
  Function()? onHideOverlay;

  Future<void> initialize() async {
    if (_isDisposed) return;

    _prefs = await SharedPreferences.getInstance();
    await _loadSettings();

    // Inicializar AudioPlayer si no existe
    _audioPlayer ??= AudioPlayer();

    // Configurar listener único para el AudioPlayer
    _setupAudioPlayerListener();
  }

  Future<void> _loadSettings() async {
    final settingsJson = _prefs?.getString('notification_settings');
    if (settingsJson != null) {
      try {
        final Map<String, dynamic> settingsMap = {};
        // Simple JSON parsing - en producción usar dart:convert
        _settings = NotificationSettings.fromJson(settingsMap);
      } catch (e) {
        // Usar configuración por defecto
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

  bool get isAudioReady => !_isDisposed && _audioPlayer != null;

  Future<void> showAlert({
    required AlertType type,
    required AlertSeverity severity,
    String? customMessage,
  }) async {

    if (_silentMode) {
      return;
    }

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

    // Añadir con límite de cola
    _addToQueueWithLimit(notification);
    _lastNotificationTime[type] = DateTime.now();

    if (!_isProcessingNotification) {
      await _processNotificationQueue();
    }
  }

  bool _shouldShowAlert(AlertType type, AlertSeverity severity) {
    // Si hay audio reproduciéndose y es una alerta de baja prioridad, omitir
    if (_isPlayingAudio && severity.index < AlertSeverity.high.index) {
      return false;
    }

    // Verificar cooldown por tipo de alerta (mínimo 30 segundos)
    final lastTime = _lastNotificationTime[type];
    if (lastTime != null) {
      final timeDiff = DateTime.now().difference(lastTime);
      if (timeDiff.inSeconds < 30) {
        return false;
      }
    }

    // Solo mostrar alertas MEDIUM o superiores
    return severity.index >= AlertSeverity.medium.index;
  }

  Future<void> _processNotificationQueue() async {
    if (_notificationQueue.isEmpty || _isProcessingNotification) {
      return;
    }

    _isProcessingNotification = true;

    // Ordenar por prioridad (severidad)
    _notificationQueue.sort((a, b) => b.severity.index.compareTo(a.severity.index));

    final notification = _notificationQueue.removeAt(0);

    try {
      await _showNotification(notification);
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }

    _isProcessingNotification = false;

    // Procesar siguiente notificación si existe
    if (_notificationQueue.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 500));
      await _processNotificationQueue();
    }
  }

  Future<void> _showNotification(AlertNotification notification) async {
    // Ejecutar notificaciones de forma no bloqueante para evitar bloquear la UI

    // Notificación visual (no bloqueante)
    if (_settings.visualEnabled) {
      _showVisualNotification(notification);
    }

    // Notificación auditiva (no bloqueante)
    if (_settings.audioEnabled && isAudioReady) {
      _playAudioAlert(notification);
    }

    // Notificación háptica (no bloqueante)
    if (_settings.hapticEnabled) {
      _triggerHapticFeedback(notification.severity);
    }
  }

  void _showVisualNotification(AlertNotification notification) {
    if (onShowOverlay != null) {
      onShowOverlay!(notification);

      // Auto-ocultar después de la duración configurada
      Timer(Duration(seconds: _settings.alertCardDuration), () {
        if (onHideOverlay != null) {
          onHideOverlay!();
        }
      });
    }
  }

  void _playAudioAlert(AlertNotification notification) {
    if (_isDisposed || _audioPlayer == null) {
      return;
    }

    // Si ya hay audio reproduciéndose, detenerlo primero
    if (_isPlayingAudio) {
      _stopCurrentAudio();
    }

    _isPlayingAudio = true;

    // Reproducir audio de forma no bloqueante
    _playAudioSequence(notification).catchError((e) {
      debugPrint('Error playing audio alert: $e');
      _resetAudioState();
    });
  }

  StreamSubscription? _audioCompleteSubscription;

  void _setupAudioPlayerListener() {
    if (_isDisposed || _audioPlayer == null) return;

    _audioCompleteSubscription?.cancel();
    _audioCompleteSubscription = _audioPlayer!.onPlayerComplete.listen((_) async {

      if (_isDisposed || !_isPlayingAudio || _currentNotification == null || _audioPlayer == null) {
        return;
      }

      switch (_audioState) {
        case AudioPlaybackState.playingTone:
          _audioState = AudioPlaybackState.playingVoice;

          // Pausa mínima para evitar artifacts de audio
          await Future.delayed(const Duration(milliseconds: 200));

          if (!_isDisposed && _isPlayingAudio && _currentNotification != null && _audioState == AudioPlaybackState.playingVoice && _audioPlayer != null) {
            try {
              final voiceFile = _getVoiceFile(_currentNotification!.type);
              await _audioPlayer!.play(AssetSource(voiceFile));
            } catch (e) {
              debugPrint('Error playing voice: $e');
              _resetAudioState();
            }
          } else {
            _resetAudioState();
          }
          break;

        case AudioPlaybackState.playingVoice:
          _resetAudioState();
          break;

        case AudioPlaybackState.idle:
          break;
      }
    });
  }

  void _resetAudioState() {
    _audioSequenceTimer?.cancel();
    _isPlayingAudio = false;
    _audioState = AudioPlaybackState.idle;
    _currentNotification = null;
  }

  AlertNotification? _currentNotification;

  Future<void> _playAudioSequence(AlertNotification notification) async {
    if (_isDisposed || _audioPlayer == null) {
      _resetAudioState();
      return;
    }

    try {
      _currentNotification = notification;
      _audioState = AudioPlaybackState.playingTone;

      // Configurar volumen una sola vez
      try {
        if (!_isDisposed && _audioPlayer != null) {
          await _audioPlayer!.setVolume(_settings.volume);
        } else {
          _resetAudioState();
          return;
        }
      } catch (e) {
        debugPrint('Error setting volume: $e');
        _resetAudioState();
        return;
      }

      // Reproducir tono de alerta
      final audioFile = _getAudioFile(notification.severity);
      try {
        if (!_isDisposed && _audioPlayer != null) {
          await _audioPlayer!.play(AssetSource(audioFile));
        } else {
          _resetAudioState();
          return;
        }
      } catch (e) {
        debugPrint('Error playing audio file: $e');
        _resetAudioState();
        return;
      }

      // Programar la reproducción de voz después de 3 segundos (duración aproximada del tono)
      _audioSequenceTimer?.cancel();
      _audioSequenceTimer = Timer(const Duration(seconds: 3), () async {
        if (!_isDisposed) {
          await _playVoiceSequence();
        }
      });

    } catch (e) {
      debugPrint('Error playing audio sequence: $e');
      _resetAudioState();
    }
  }

  Future<void> _playVoiceSequence() async {
    if (_isDisposed || _audioPlayer == null || _currentNotification == null || _audioState != AudioPlaybackState.playingTone) {
      _resetAudioState();
      return;
    }

    try {
      _audioState = AudioPlaybackState.playingVoice;
      final voiceFile = _getVoiceFile(_currentNotification!.type);

      try {
        if (!_isDisposed && _audioPlayer != null) {
          await _audioPlayer!.play(AssetSource(voiceFile));
        } else {
          _resetAudioState();
          return;
        }
      } catch (e) {
        debugPrint('Error playing voice file: $e');
        _resetAudioState();
        return;
      }

      // Programar finalización después de 4 segundos (duración aproximada de la voz)
      _audioSequenceTimer?.cancel();
      _audioSequenceTimer = Timer(const Duration(seconds: 4), () {
        if (!_isDisposed) {
          _resetAudioState();
        }
      });

    } catch (e) {
      debugPrint('Error playing voice: $e');
      _resetAudioState();
    }
  }

  void _stopCurrentAudio() {
    try {
      if (!_isDisposed && _audioPlayer != null) {
        _audioPlayer!.stop();
      }
    } catch (e) {
      debugPrint('Error stopping audio player: $e');
    }
    _resetAudioState();
  }

  void _triggerHapticFeedback(AlertSeverity severity) {
    // Ejecutar vibración de forma no bloqueante
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
        // Fallback para dispositivos sin vibración
        await HapticFeedback.heavyImpact();
      }
    } catch (e) {
      rethrow;
    }
  }

  String _getAudioFile(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.low:
        return 'sounds/alerts/medium_alert.mp3'; // Usar medium para low también
      case AlertSeverity.medium:
        return 'sounds/alerts/medium_alert.mp3';
      case AlertSeverity.high:
        return 'sounds/alerts/high_alert.mp3';
      case AlertSeverity.critical:
        return 'sounds/alerts/critical_alert.mp3';
    }
  }

  String _getVoiceFile(AlertType type) {
    switch (type) {
      case AlertType.distraction:
        return 'sounds/voices/distraction_warning_es.mp3';
      case AlertType.recklessDriving:
        return 'sounds/voices/reckless_warning_es.mp3';
      case AlertType.impact:
        return 'sounds/voices/impact_warning_es.mp3';
      case AlertType.phoneUsage:
        return 'sounds/voices/phone_warning_es.mp3';
      case AlertType.lookAway:
        return 'sounds/voices/look_away_warning_es.mp3';
      case AlertType.harshBraking:
        return 'sounds/voices/harsh_braking_warning_es.mp3';
    }
  }

  String _getDefaultMessage(AlertType type) {
    switch (type) {
      case AlertType.distraction:
        return 'DISTRACCIÓN DETECTADA';
      case AlertType.recklessDriving:
        return 'CONDUCCIÓN TEMERARIA';
      case AlertType.impact:
        return 'IMPACTO DETECTADO';
      case AlertType.phoneUsage:
        return 'USO DE CELULAR';
      case AlertType.lookAway:
        return 'MIRADA FUERA DEL CAMINO';
      case AlertType.harshBraking:
        return 'FRENADA BRUSCA';
    }
  }

  void stopCurrentAlert() {
    _stopCurrentAudio();
    if (onHideOverlay != null) {
      onHideOverlay!();
    }
  }

  void _addToQueueWithLimit(AlertNotification notification) {
    // Remover elementos más antiguos si se excede el límite
    while (_notificationQueue.length >= maxQueueSize) {
      _notificationQueue.removeAt(0);
    }
    _notificationQueue.add(notification);
  }

  void clearNotificationQueue() {
    _notificationQueue.clear();
  }

  List<AlertNotification> getNotificationHistory() {
    // Limitar el historial retornado
    if (_notificationQueue.length > maxHistorySize) {
      return _notificationQueue.sublist(_notificationQueue.length - maxHistorySize);
    }
    return List<AlertNotification>.from(_notificationQueue);
  }

  void dispose() {
    if (_isDisposed) return;

    _isDisposed = true;
    _stopCurrentAudio();
    _audioCompleteSubscription?.cancel();
    _audioCompleteSubscription = null;

    try {
      _audioPlayer?.dispose();
    } catch (e) {
      debugPrint('Error disposing audio player: $e');
    }
    _audioPlayer = null;

    _cooldownTimer?.cancel();
    _cooldownTimer = null;
    _audioSequenceTimer?.cancel();
    _audioSequenceTimer = null;

    _notificationQueue.clear();
    _currentNotification = null;
  }
}