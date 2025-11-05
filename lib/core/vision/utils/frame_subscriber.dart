import 'dart:async';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../../data/datasources/local/http_server_service.dart';
import '../../../data/models/camera_frame.dart';
import 'frame_converter.dart';

/// Suscriptor a frames del ESP32-CAM con conversión automática a InputImage
///
/// Esta clase se encarga de:
/// 1. Suscribirse al stream de frames del HttpServerService
/// 2. Convertir cada frame JPEG a InputImage mediante FrameConverter
/// 3. Emitir InputImages válidos a través de su propio stream
/// 4. Gestionar frames corruptos o inválidos
/// 5. Controlar la tasa de procesamiento para evitar sobrecarga
class FrameSubscriber {
  final HttpServerService _httpServerService;

  StreamSubscription<CameraFrame>? _frameSubscription;
  final _inputImageController = StreamController<InputImage>.broadcast();
  final _frameStatsController = StreamController<FrameStats>.broadcast();

  /// Stream de InputImages procesados y validados
  Stream<InputImage> get inputImageStream => _inputImageController.stream;

  /// Stream de estadísticas de procesamiento de frames
  Stream<FrameStats> get statsStream => _frameStatsController.stream;

  // Estadísticas
  int _totalFramesReceived = 0;
  int _framesConverted = 0;
  int _framesDropped = 0;
  int _framesSkipped = 0;
  DateTime? _lastFrameTime;
  DateTime? _subscriptionStartTime;

  /// Control de flujo: skip frames si el procesamiento está atrasado
  bool _isProcessing = false;

  /// Control de tasa de procesamiento
  DateTime? _lastEmittedFrameTime;
  Duration _minFrameInterval = const Duration(milliseconds: 200); // 5 FPS max

  FrameSubscriber(this._httpServerService);

  /// Inicia la suscripción a frames del ESP32-CAM
  ///
  /// [enableFrameSkipping] si es true, descarta frames si el procesamiento está atrasado
  /// [maxFPS] tasa máxima de frames por segundo (por defecto 5 FPS)
  void start({
    bool enableFrameSkipping = true,
    int maxFPS = 5,
  }) {
    if (_frameSubscription != null) {
      print('[FrameSubscriber] ⚠️ Ya existe una suscripción activa');
      return;
    }

    // Configurar tasa de procesamiento
    final minInterval = (1000 / maxFPS).round();
    _minFrameInterval = Duration(milliseconds: minInterval);

    _subscriptionStartTime = DateTime.now();

    _frameSubscription = _httpServerService.frameStream.listen(
      (frame) => _handleFrame(frame, enableFrameSkipping),
      onError: (error, stackTrace) {
        print('[FrameSubscriber] ❌ Error en stream: $error');
        print('[FrameSubscriber] Stack trace: $stackTrace');
      },
      onDone: () {
        print('[FrameSubscriber] ℹ️ Stream de frames cerrado');
      },
    );

    print('[FrameSubscriber] ✅ Suscripción a frames iniciada (maxFPS: $maxFPS)');
    _emitStats();
  }

  /// Maneja un frame recibido del ESP32-CAM
  void _handleFrame(CameraFrame frame, bool enableFrameSkipping) {
    _totalFramesReceived++;
    _lastFrameTime = DateTime.now();

    // Control de flujo: skip frames si estamos procesando
    if (_isProcessing && enableFrameSkipping) {
      _framesSkipped++;

      // Log solo cada 20 frames skipped para evitar spam
      if (_framesSkipped % 20 == 0) {
        print('[FrameSubscriber] ⏭️ Frame skipped (procesamiento en curso) '
            '[Total skipped: $_framesSkipped]');
      }
      _emitStats();
      return;
    }

    // Control de tasa: skip frames si no ha pasado suficiente tiempo
    if (_lastEmittedFrameTime != null) {
      final timeSinceLastFrame = _lastFrameTime!.difference(_lastEmittedFrameTime!);
      if (timeSinceLastFrame < _minFrameInterval) {
        _framesSkipped++;
        return;
      }
    }

    _isProcessing = true;

    try {
      // Convertir JPEG → InputImage
      final inputImage = FrameConverter.fromJpegBytes(frame.imageBytes);

      if (inputImage != null) {
        // Frame convertido exitosamente
        _framesConverted++;
        _lastEmittedFrameTime = _lastFrameTime;

        if (!_inputImageController.isClosed) {
          _inputImageController.add(inputImage);
        }

        // Log cada 30 frames para no saturar consola (~6s @ 5 FPS)
        if (_framesConverted % 30 == 0) {
          final conversionRate =
              (_framesConverted / _totalFramesReceived * 100).toStringAsFixed(1);
          print('[FrameSubscriber] ✅ Frame #$_framesConverted convertido '
              '(tasa: $conversionRate%, dropped: $_framesDropped, skipped: $_framesSkipped)');
          _emitStats();
        }
      } else {
        // Frame inválido o conversión fallida
        _framesDropped++;

        // Log solo cada 10 frames descartados para evitar spam
        if (_framesDropped % 10 == 0) {
          print('[FrameSubscriber] ⚠️ Frame #$_totalFramesReceived descartado '
              '(conversión fallida) [Total dropped: $_framesDropped]');
        }
        _emitStats();
      }
    } catch (e, stackTrace) {
      _framesDropped++;
      print('[FrameSubscriber] ❌ Error procesando frame: $e');
      print('[FrameSubscriber] Stack trace: $stackTrace');
      _emitStats();
    } finally {
      _isProcessing = false;
    }
  }

  /// Emite estadísticas actuales de procesamiento
  void _emitStats() {
    if (_frameStatsController.isClosed) return;

    final stats = FrameStats(
      totalFramesReceived: _totalFramesReceived,
      framesConverted: _framesConverted,
      framesDropped: _framesDropped,
      framesSkipped: _framesSkipped,
      conversionRate: _totalFramesReceived > 0
          ? (_framesConverted / _totalFramesReceived)
          : 0.0,
      lastFrameTime: _lastFrameTime,
      subscriptionDuration: _subscriptionStartTime != null
          ? DateTime.now().difference(_subscriptionStartTime!)
          : Duration.zero,
    );

    _frameStatsController.add(stats);
  }

  /// Detiene la suscripción
  void stop() {
    _frameSubscription?.cancel();
    _frameSubscription = null;
    print('[FrameSubscriber] 🛑 Suscripción a frames detenida');
    _emitFinalStats();
  }

  /// Emite estadísticas finales al detener
  void _emitFinalStats() {
    _emitStats();
    print('[FrameSubscriber] 📊 Estadísticas finales:');
    print('  • Total recibidos: $_totalFramesReceived');
    print('  • Convertidos: $_framesConverted');
    print('  • Descartados: $_framesDropped');
    print('  • Saltados: $_framesSkipped');
    if (_totalFramesReceived > 0) {
      final rate = (_framesConverted / _totalFramesReceived * 100).toStringAsFixed(1);
      print('  • Tasa de conversión: $rate%');
    }
  }

  /// Obtiene estadísticas actuales
  FrameStats getStats() {
    return FrameStats(
      totalFramesReceived: _totalFramesReceived,
      framesConverted: _framesConverted,
      framesDropped: _framesDropped,
      framesSkipped: _framesSkipped,
      conversionRate: _totalFramesReceived > 0
          ? (_framesConverted / _totalFramesReceived)
          : 0.0,
      lastFrameTime: _lastFrameTime,
      subscriptionDuration: _subscriptionStartTime != null
          ? DateTime.now().difference(_subscriptionStartTime!)
          : Duration.zero,
    );
  }

  /// Resetea estadísticas
  void resetStats() {
    _totalFramesReceived = 0;
    _framesConverted = 0;
    _framesDropped = 0;
    _framesSkipped = 0;
    _lastFrameTime = null;
    _subscriptionStartTime = DateTime.now();
    print('[FrameSubscriber] 🔄 Estadísticas reseteadas');
  }

  /// Libera recursos
  void dispose() {
    stop();
    _inputImageController.close();
    _frameStatsController.close();
    print('[FrameSubscriber] 🗑️ Recursos liberados');
  }
}

/// Estadísticas de procesamiento de frames
class FrameStats {
  final int totalFramesReceived;
  final int framesConverted;
  final int framesDropped;
  final int framesSkipped;
  final double conversionRate;
  final DateTime? lastFrameTime;
  final Duration subscriptionDuration;

  const FrameStats({
    required this.totalFramesReceived,
    required this.framesConverted,
    required this.framesDropped,
    required this.framesSkipped,
    required this.conversionRate,
    this.lastFrameTime,
    required this.subscriptionDuration,
  });

  /// Calcula FPS promedio
  double get averageFPS {
    if (subscriptionDuration.inSeconds == 0) return 0.0;
    return framesConverted / subscriptionDuration.inSeconds;
  }

  @override
  String toString() {
    return 'FrameStats('
        'received: $totalFramesReceived, '
        'converted: $framesConverted, '
        'dropped: $framesDropped, '
        'skipped: $framesSkipped, '
        'rate: ${(conversionRate * 100).toStringAsFixed(1)}%, '
        'avgFPS: ${averageFPS.toStringAsFixed(2)}'
        ')';
  }

  Map<String, dynamic> toJson() {
    return {
      'totalFramesReceived': totalFramesReceived,
      'framesConverted': framesConverted,
      'framesDropped': framesDropped,
      'framesSkipped': framesSkipped,
      'conversionRate': conversionRate,
      'lastFrameTime': lastFrameTime?.toIso8601String(),
      'subscriptionDurationSeconds': subscriptionDuration.inSeconds,
      'averageFPS': averageFPS,
    };
  }
}
