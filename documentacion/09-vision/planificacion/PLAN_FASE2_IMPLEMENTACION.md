# FASE 2: Implementación de Detectores

**Duración estimada**: 2-3 semanas
**Objetivo**: Implementar procesadores MediaPipe y los 3 detectores de eventos basados en visión.

---

## 2.1 Procesadores MediaPipe

### 2.1.1 FaceMeshProcessor

**Archivo**: `lib/core/vision/processors/face_mesh_processor.dart`

**Propósito**: Procesar frames con MediaPipe Face Detection para extraer datos faciales (pose de cabeza, ojos, orientación).

```dart
import 'dart:async';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../models/face_data.dart';

/// Procesador de detección facial usando ML Kit Face Detection
class FaceMeshProcessor {
  late final FaceDetector _faceDetector;

  final _faceDataController = StreamController<FaceData?>.broadcast();
  Stream<FaceData?> get faceDataStream => _faceDataController.stream;

  bool _isProcessing = false;
  int _processedFrames = 0;
  int _failedFrames = 0;

  FaceMeshProcessor() {
    _initializeDetector();
  }

  void _initializeDetector() {
    final options = FaceDetectorOptions(
      enableContours: true,        // Habilitar contornos faciales
      enableClassification: true,  // Habilitar clasificación (ojos abiertos/cerrados)
      enableTracking: true,        // Habilitar tracking entre frames
      minFaceSize: 0.15,           // Tamaño mínimo de cara (15% del frame)
      performanceMode: FaceDetectorMode.accurate, // Modo preciso
    );

    _faceDetector = FaceDetector(options: options);
    print('[FaceMeshProcessor] ✅ Detector inicializado');
  }

  /// Procesa un frame y extrae datos faciales
  Future<void> processFrame(InputImage inputImage) async {
    if (_isProcessing) {
      // Evitar procesar múltiples frames simultáneamente
      return;
    }

    _isProcessing = true;

    try {
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        // No se detectó ninguna cara
        _faceDataController.add(null);
        _failedFrames++;

        if (_failedFrames % 10 == 0) {
          print('[FaceMeshProcessor] ⚠️ No se detectó cara en ${_failedFrames} frames');
        }
        return;
      }

      // Tomar la primera cara detectada (asumimos un solo conductor)
      final face = faces.first;

      // Extraer datos de pose de cabeza
      final headYaw = face.headEulerAngleY ?? 0.0;    // Rotación horizontal
      final headPitch = face.headEulerAngleX ?? 0.0;  // Rotación vertical
      final headRoll = face.headEulerAngleZ ?? 0.0;   // Inclinación lateral

      // Extraer estado de ojos
      final leftEyeOpen = (face.leftEyeOpenProbability ?? 0.0) > 0.5;
      final rightEyeOpen = (face.rightEyeOpenProbability ?? 0.0) > 0.5;

      final faceData = FaceData(
        face: face,
        headYaw: headYaw,
        headPitch: headPitch,
        headRoll: headRoll,
        leftEyeOpen: leftEyeOpen,
        rightEyeOpen: rightEyeOpen,
        timestamp: DateTime.now(),
      );

      _faceDataController.add(faceData);
      _processedFrames++;

      // Log cada 30 frames procesados (~6 segundos a 5 FPS)
      if (_processedFrames % 30 == 0) {
        print('[FaceMeshProcessor] 📊 Procesados: $_processedFrames frames, '
            'Fallidos: $_failedFrames');
      }
    } catch (e) {
      print('[FaceMeshProcessor] ❌ Error procesando frame: $e');
      _faceDataController.add(null);
      _failedFrames++;
    } finally {
      _isProcessing = false;
    }
  }

  /// Obtener estadísticas del procesador
  Map<String, int> getStats() {
    return {
      'processedFrames': _processedFrames,
      'failedFrames': _failedFrames,
      'successRate': _processedFrames > 0
          ? ((_processedFrames / (_processedFrames + _failedFrames)) * 100).round()
          : 0,
    };
  }

  void dispose() {
    _faceDetector.close();
    _faceDataController.close();
    print('[FaceMeshProcessor] 🛑 Procesador cerrado');
  }
}
```

---

### 2.1.2 HandsProcessor (usando PoseDetector como workaround)

**Archivo**: `lib/core/vision/processors/hands_processor.dart`

**Propósito**: Detectar manos usando PoseDetector (workaround porque ML Kit Flutter no tiene HandLandmarker nativo).

```dart
import 'dart:async';
import 'dart:ui';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../models/hand_data.dart';

/// Procesador de detección de manos usando PoseDetector
///
/// WORKAROUND: ML Kit Flutter no tiene HandLandmarker, así que usamos
/// PoseDetector para detectar muñecas (wrists) como aproximación.
class HandsProcessor {
  late final PoseDetector _poseDetector;

  final _handDataController = StreamController<HandData?>.broadcast();
  Stream<HandData?> get handDataStream => _handDataController.stream;

  bool _isProcessing = false;
  int _processedFrames = 0;
  int _failedFrames = 0;

  // Región de Interés (ROI) para el volante
  // Se calibra en tiempo de ejecución (ver ROICalibrator)
  Rect? _steeringWheelROI;

  HandsProcessor() {
    _initializeDetector();
  }

  void _initializeDetector() {
    final options = PoseDetectorOptions(
      mode: PoseDetectorMode.stream,           // Modo streaming para videos
      model: PoseDetectorModel.accurate,       // Modelo preciso
    );

    _poseDetector = PoseDetector(options: options);
    print('[HandsProcessor] ✅ Detector inicializado (usando PoseDetector)');
  }

  /// Configura la ROI del volante (debe llamarse después de calibración)
  void setSteeringWheelROI(Rect roi) {
    _steeringWheelROI = roi;
    print('[HandsProcessor] 📐 ROI configurada: $roi');
  }

  /// Procesa un frame y detecta manos
  Future<void> processFrame(InputImage inputImage) async {
    if (_isProcessing) {
      return;
    }

    _isProcessing = true;

    try {
      final poses = await _poseDetector.processImage(inputImage);

      if (poses.isEmpty) {
        _handDataController.add(null);
        _failedFrames++;
        return;
      }

      final pose = poses.first;

      // Detectar muñecas (wrists) como aproximación de manos
      final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
      final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

      bool leftHandInROI = false;
      bool rightHandInROI = false;

      // Verificar si las muñecas están dentro de la ROI del volante
      if (_steeringWheelROI != null) {
        if (leftWrist != null) {
          leftHandInROI = _isPointInROI(
            Point(leftWrist.x, leftWrist.y),
            _steeringWheelROI!,
          );
        }

        if (rightWrist != null) {
          rightHandInROI = _isPointInROI(
            Point(rightWrist.x, rightWrist.y),
            _steeringWheelROI!,
          );
        }
      }

      final handData = HandData(
        pose: pose,
        leftHandInROI: leftHandInROI,
        rightHandInROI: rightHandInROI,
        timestamp: DateTime.now(),
      );

      _handDataController.add(handData);
      _processedFrames++;

      if (_processedFrames % 30 == 0) {
        print('[HandsProcessor] 📊 Procesados: $_processedFrames frames, '
            'Manos detectadas: ${handData.handsOnWheel}/2');
      }
    } catch (e) {
      print('[HandsProcessor] ❌ Error procesando frame: $e');
      _handDataController.add(null);
      _failedFrames++;
    } finally {
      _isProcessing = false;
    }
  }

  /// Verifica si un punto está dentro de una región rectangular
  bool _isPointInROI(Point point, Rect roi) {
    return point.x >= roi.left &&
           point.x <= roi.right &&
           point.y >= roi.top &&
           point.y <= roi.bottom;
  }

  Map<String, int> getStats() {
    return {
      'processedFrames': _processedFrames,
      'failedFrames': _failedFrames,
    };
  }

  void dispose() {
    _poseDetector.close();
    _handDataController.close();
    print('[HandsProcessor] 🛑 Procesador cerrado');
  }
}
```

---

## 2.2 Detectores de Eventos

### 2.2.1 DistractionDetector (Uso de teléfono)

**Archivo**: `lib/core/vision/detectors/distraction_detector.dart`

**Criterios de detección**:
1. Cara mirando hacia abajo (pitch < -25°)
2. Duración sostenida: 2+ segundos
3. No requiere verificación de movimiento del vehículo

```dart
import 'dart:async';
import '../models/face_data.dart';
import '../models/vision_event.dart';
import '../../detection/models/event_type.dart';
import '../../detection/models/event_severity.dart';

/// Detector de distracción por uso de teléfono móvil
class DistractionDetector {
  // Buffer de datos faciales recientes
  final List<FaceData> _recentFaceData = [];
  static const int _maxBufferSize = 15; // 3 segundos @ 5 FPS

  // Estado del detector
  bool _isDistracted = false;
  DateTime? _distractionStartTime;

  // Umbrales de detección
  static const double _downwardPitchThreshold = -25.0; // Mirando hacia abajo
  static const Duration _minDistractionDuration = Duration(seconds: 2);
  static const Duration _cooldownDuration = Duration(seconds: 5);

  DateTime? _lastEventTime;

  final _eventController = StreamController<VisionEvent>.broadcast();
  Stream<VisionEvent> get eventStream => _eventController.stream;

  /// Procesa datos faciales para detectar distracción
  void processFaceData(FaceData? faceData) {
    // Si no hay datos faciales, resetear
    if (faceData == null) {
      _resetDetection();
      return;
    }

    // Agregar al buffer
    _recentFaceData.add(faceData);
    if (_recentFaceData.length > _maxBufferSize) {
      _recentFaceData.removeAt(0);
    }

    // Verificar cooldown
    if (_lastEventTime != null) {
      final timeSinceLastEvent = DateTime.now().difference(_lastEventTime!);
      if (timeSinceLastEvent < _cooldownDuration) {
        return; // Aún en cooldown
      }
    }

    // Detectar si está mirando hacia abajo (usando teléfono)
    final isLookingDown = faceData.headPitch < _downwardPitchThreshold;

    if (isLookingDown) {
      // Iniciar o continuar detección
      _distractionStartTime ??= DateTime.now();

      final distractionDuration = DateTime.now().difference(_distractionStartTime!);

      if (distractionDuration >= _minDistractionDuration && !_isDistracted) {
        // Detectar evento
        _isDistracted = true;
        _emitDistractionEvent(distractionDuration);
      }
    } else {
      // No está mirando hacia abajo, resetear
      _resetDetection();
    }
  }

  void _emitDistractionEvent(Duration duration) {
    final severity = _calculateSeverity(duration);
    final confidence = _calculateConfidence();

    final event = VisionEvent(
      type: EventType.distraction,
      severity: severity,
      timestamp: DateTime.now(),
      confidence: confidence,
      metadata: {
        'duration': duration.inSeconds,
        'avgPitch': _getAveragePitch(),
        'detectionMethod': 'headPose',
      },
    );

    _eventController.add(event);
    _lastEventTime = DateTime.now();

    print('[DistractionDetector] 🚨 Distracción detectada '
        '(duración: ${duration.inSeconds}s, severidad: ${severity.value})');
  }

  EventSeverity _calculateSeverity(Duration duration) {
    if (duration.inSeconds >= 6) {
      return EventSeverity.critical;
    } else if (duration.inSeconds >= 4) {
      return EventSeverity.high;
    } else if (duration.inSeconds >= 3) {
      return EventSeverity.medium;
    } else {
      return EventSeverity.low;
    }
  }

  double _calculateConfidence() {
    if (_recentFaceData.isEmpty) return 0.0;

    // Contar cuántos frames están mirando hacia abajo
    final lookingDownCount = _recentFaceData
        .where((data) => data.headPitch < _downwardPitchThreshold)
        .length;

    return (lookingDownCount / _recentFaceData.length).clamp(0.0, 1.0);
  }

  double _getAveragePitch() {
    if (_recentFaceData.isEmpty) return 0.0;

    final totalPitch = _recentFaceData
        .map((data) => data.headPitch)
        .reduce((a, b) => a + b);

    return totalPitch / _recentFaceData.length;
  }

  void _resetDetection() {
    _isDistracted = false;
    _distractionStartTime = null;
  }

  void reset() {
    _recentFaceData.clear();
    _resetDetection();
    _lastEventTime = null;
  }

  void dispose() {
    _eventController.close();
  }
}
```

---

### 2.2.2 InattentionDetector (Mirada fuera de la carretera)

**Archivo**: `lib/core/vision/detectors/inattention_detector.dart`

**Criterios de detección**:
1. Cabeza girada > 30° (yaw absoluto)
2. O mirando muy arriba/abajo (pitch > 20° absoluto)
3. Duración sostenida: 2+ segundos

```dart
import 'dart:async';
import '../models/face_data.dart';
import '../models/vision_event.dart';
import '../../detection/models/event_type.dart';
import '../../detection/models/event_severity.dart';

/// Detector de desatención visual (mirada fuera de la carretera)
class InattentionDetector {
  final List<FaceData> _recentFaceData = [];
  static const int _maxBufferSize = 15; // 3 segundos @ 5 FPS

  bool _isInattentive = false;
  DateTime? _inattentionStartTime;

  // Umbrales de detección
  static const double _maxYawDeviation = 30.0;    // Máximo giro horizontal
  static const double _maxPitchDeviation = 20.0;  // Máximo giro vertical
  static const Duration _minInattentionDuration = Duration(seconds: 2);
  static const Duration _cooldownDuration = Duration(seconds: 5);

  DateTime? _lastEventTime;

  final _eventController = StreamController<VisionEvent>.broadcast();
  Stream<VisionEvent> get eventStream => _eventController.stream;

  void processFaceData(FaceData? faceData) {
    if (faceData == null) {
      _resetDetection();
      return;
    }

    _recentFaceData.add(faceData);
    if (_recentFaceData.length > _maxBufferSize) {
      _recentFaceData.removeAt(0);
    }

    // Verificar cooldown
    if (_lastEventTime != null) {
      final timeSinceLastEvent = DateTime.now().difference(_lastEventTime!);
      if (timeSinceLastEvent < _cooldownDuration) {
        return;
      }
    }

    // Detectar desatención: NO está mirando al frente
    final isNotLookingForward = !faceData.isLookingForward;

    if (isNotLookingForward) {
      _inattentionStartTime ??= DateTime.now();

      final inattentionDuration = DateTime.now().difference(_inattentionStartTime!);

      if (inattentionDuration >= _minInattentionDuration && !_isInattentive) {
        _isInattentive = true;
        _emitInattentionEvent(inattentionDuration);
      }
    } else {
      _resetDetection();
    }
  }

  void _emitInattentionEvent(Duration duration) {
    final severity = _calculateSeverity(duration);
    final confidence = _calculateConfidence();

    final event = VisionEvent(
      type: EventType.inattention,
      severity: severity,
      timestamp: DateTime.now(),
      confidence: confidence,
      metadata: {
        'duration': duration.inSeconds,
        'avgYaw': _getAverageYaw(),
        'avgPitch': _getAveragePitch(),
        'maxDeviation': _getMaxDeviation(),
      },
    );

    _eventController.add(event);
    _lastEventTime = DateTime.now();

    print('[InattentionDetector] 🚨 Desatención detectada '
        '(duración: ${duration.inSeconds}s, severidad: ${severity.value})');
  }

  EventSeverity _calculateSeverity(Duration duration) {
    final maxDeviation = _getMaxDeviation();

    // Severidad basada en duración + desviación
    if (duration.inSeconds >= 5 || maxDeviation > 60.0) {
      return EventSeverity.critical;
    } else if (duration.inSeconds >= 4 || maxDeviation > 45.0) {
      return EventSeverity.high;
    } else if (duration.inSeconds >= 3 || maxDeviation > 35.0) {
      return EventSeverity.medium;
    } else {
      return EventSeverity.low;
    }
  }

  double _calculateConfidence() {
    if (_recentFaceData.isEmpty) return 0.0;

    final notLookingForwardCount = _recentFaceData
        .where((data) => !data.isLookingForward)
        .length;

    return (notLookingForwardCount / _recentFaceData.length).clamp(0.0, 1.0);
  }

  double _getAverageYaw() {
    if (_recentFaceData.isEmpty) return 0.0;
    return _recentFaceData.map((d) => d.headYaw).reduce((a, b) => a + b) /
        _recentFaceData.length;
  }

  double _getAveragePitch() {
    if (_recentFaceData.isEmpty) return 0.0;
    return _recentFaceData.map((d) => d.headPitch).reduce((a, b) => a + b) /
        _recentFaceData.length;
  }

  double _getMaxDeviation() {
    if (_recentFaceData.isEmpty) return 0.0;

    return _recentFaceData
        .map((data) => [data.headYaw.abs(), data.headPitch.abs()].reduce((a, b) => a > b ? a : b))
        .reduce((a, b) => a > b ? a : b);
  }

  void _resetDetection() {
    _isInattentive = false;
    _inattentionStartTime = null;
  }

  void reset() {
    _recentFaceData.clear();
    _resetDetection();
    _lastEventTime = null;
  }

  void dispose() {
    _eventController.close();
  }
}
```

---

### 2.2.3 HandsOffDetector (Híbrido: Visión + IMU)

**Archivo**: `lib/core/vision/detectors/hands_off_detector.dart`

**Criterios de detección** (HÍBRIDO):
1. **Visión**: 0 manos detectadas en ROI del volante
2. **IMU**: Vehículo en movimiento (accel > 1.5 m/s² O gyro > 20°/s)
3. Duración sostenida: 3+ segundos

```dart
import 'dart:async';
import '../models/hand_data.dart';
import '../models/vision_event.dart';
import '../../detection/models/event_type.dart';
import '../../detection/models/event_severity.dart';
import '../../../domain/entities/sensor_data.dart';

/// Detector híbrido: manos fuera del volante (visión + IMU)
class HandsOffDetector {
  final List<HandData> _recentHandData = [];
  static const int _maxBufferSize = 15; // 3 segundos @ 5 FPS

  bool _isHandsOff = false;
  DateTime? _handsOffStartTime;

  // Umbrales de detección
  static const Duration _minHandsOffDuration = Duration(seconds: 3);
  static const Duration _cooldownDuration = Duration(seconds: 8);

  // Umbrales IMU para detectar movimiento
  static const double _minAccelMagnitude = 1.5;  // m/s²
  static const double _minGyroMagnitude = 20.0;  // °/s

  DateTime? _lastEventTime;
  SensorData? _latestSensorData;

  final _eventController = StreamController<VisionEvent>.broadcast();
  Stream<VisionEvent> get eventStream => _eventController.stream;

  /// Actualizar datos del IMU (llamado desde SensorDataProcessor)
  void updateSensorData(SensorData sensorData) {
    _latestSensorData = sensorData;
  }

  void processHandData(HandData? handData) {
    if (handData == null) {
      _resetDetection();
      return;
    }

    _recentHandData.add(handData);
    if (_recentHandData.length > _maxBufferSize) {
      _recentHandData.removeAt(0);
    }

    // Verificar cooldown
    if (_lastEventTime != null) {
      final timeSinceLastEvent = DateTime.now().difference(_lastEventTime!);
      if (timeSinceLastEvent < _cooldownDuration) {
        return;
      }
    }

    // CONDICIÓN 1 (Visión): Sin manos en volante
    final hasHandsOff = handData.handsOnWheel == 0;

    // CONDICIÓN 2 (IMU): Vehículo en movimiento
    final isMoving = _isVehicleMoving();

    // DETECCIÓN HÍBRIDA: Ambas condiciones deben cumplirse
    if (hasHandsOff && isMoving) {
      _handsOffStartTime ??= DateTime.now();

      final handsOffDuration = DateTime.now().difference(_handsOffStartTime!);

      if (handsOffDuration >= _minHandsOffDuration && !_isHandsOff) {
        _isHandsOff = true;
        _emitHandsOffEvent(handsOffDuration);
      }
    } else {
      _resetDetection();
    }
  }

  bool _isVehicleMoving() {
    if (_latestSensorData == null) return false;

    final accelMagnitude = _latestSensorData!.accelerationMagnitude;
    final gyroMagnitude = _latestSensorData!.gyroscopeMagnitude;

    // Vehículo se considera en movimiento si hay aceleración o rotación significativa
    return accelMagnitude > _minAccelMagnitude || gyroMagnitude > _minGyroMagnitude;
  }

  void _emitHandsOffEvent(Duration duration) {
    final severity = _calculateSeverity(duration);
    final confidence = _calculateConfidence();

    final event = VisionEvent(
      type: EventType.handsOff,
      severity: severity,
      timestamp: DateTime.now(),
      confidence: confidence,
      metadata: {
        'duration': duration.inSeconds,
        'isMoving': _isVehicleMoving(),
        'accelMagnitude': _latestSensorData?.accelerationMagnitude ?? 0.0,
        'gyroMagnitude': _latestSensorData?.gyroscopeMagnitude ?? 0.0,
        'detectionMethod': 'hybrid',
      },
    );

    _eventController.add(event);
    _lastEventTime = DateTime.now();

    print('[HandsOffDetector] 🚨 Manos fuera del volante detectado '
        '(duración: ${duration.inSeconds}s, severidad: ${severity.value})');
  }

  EventSeverity _calculateSeverity(Duration duration) {
    if (duration.inSeconds >= 8) {
      return EventSeverity.critical;
    } else if (duration.inSeconds >= 6) {
      return EventSeverity.high;
    } else if (duration.inSeconds >= 4) {
      return EventSeverity.medium;
    } else {
      return EventSeverity.low;
    }
  }

  double _calculateConfidence() {
    if (_recentHandData.isEmpty) return 0.0;

    final handsOffCount = _recentHandData
        .where((data) => data.handsOnWheel == 0)
        .length;

    final visionConfidence = (handsOffCount / _recentHandData.length).clamp(0.0, 1.0);

    // Confidence híbrida: 70% visión + 30% IMU
    final imuConfidence = _isVehicleMoving() ? 1.0 : 0.0;

    return (visionConfidence * 0.7 + imuConfidence * 0.3).clamp(0.0, 1.0);
  }

  void _resetDetection() {
    _isHandsOff = false;
    _handsOffStartTime = null;
  }

  void reset() {
    _recentHandData.clear();
    _resetDetection();
    _lastEventTime = null;
  }

  void dispose() {
    _eventController.close();
  }
}
```

---

## 2.3 Orquestador de Visión

### 2.3.1 VisionProcessor

**Archivo**: `lib/core/vision/processors/vision_processor.dart`

**Propósito**: Coordinar todos los procesadores y detectores, conectar streams.

```dart
import 'dart:async';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../models/vision_event.dart';
import '../../../domain/entities/sensor_data.dart';
import 'face_mesh_processor.dart';
import 'hands_processor.dart';
import '../detectors/distraction_detector.dart';
import '../detectors/inattention_detector.dart';
import '../detectors/hands_off_detector.dart';

/// Orquestador principal de procesamiento de visión
class VisionProcessor {
  // Procesadores MediaPipe
  late final FaceMeshProcessor _faceMeshProcessor;
  late final HandsProcessor _handsProcessor;

  // Detectores de eventos
  late final DistractionDetector _distractionDetector;
  late final InattentionDetector _inattentionDetector;
  late final HandsOffDetector _handsOffDetector;

  // Suscripciones
  StreamSubscription<FaceData?>? _faceDataSubscription;
  StreamSubscription<HandData?>? _handDataSubscription;
  StreamSubscription<VisionEvent>? _distractionEventSubscription;
  StreamSubscription<VisionEvent>? _inattentionEventSubscription;
  StreamSubscription<VisionEvent>? _handsOffEventSubscription;

  // Stream consolidado de eventos
  final _eventController = StreamController<VisionEvent>.broadcast();
  Stream<VisionEvent> get eventStream => _eventController.stream;

  bool _isInitialized = false;

  VisionProcessor() {
    _initialize();
  }

  void _initialize() {
    // Inicializar procesadores
    _faceMeshProcessor = FaceMeshProcessor();
    _handsProcessor = HandsProcessor();

    // Inicializar detectores
    _distractionDetector = DistractionDetector();
    _inattentionDetector = InattentionDetector();
    _handsOffDetector = HandsOffDetector();

    // Conectar streams
    _connectStreams();

    _isInitialized = true;
    print('[VisionProcessor] ✅ Inicializado');
  }

  void _connectStreams() {
    // Conectar FaceMeshProcessor → Detectores
    _faceDataSubscription = _faceMeshProcessor.faceDataStream.listen((faceData) {
      _distractionDetector.processFaceData(faceData);
      _inattentionDetector.processFaceData(faceData);
    });

    // Conectar HandsProcessor → HandsOffDetector
    _handDataSubscription = _handsProcessor.handDataStream.listen((handData) {
      _handsOffDetector.processHandData(handData);
    });

    // Consolidar eventos de todos los detectores
    _distractionEventSubscription = _distractionDetector.eventStream.listen((event) {
      _eventController.add(event);
    });

    _inattentionEventSubscription = _inattentionDetector.eventStream.listen((event) {
      _eventController.add(event);
    });

    _handsOffEventSubscription = _handsOffDetector.eventStream.listen((event) {
      _eventController.add(event);
    });
  }

  /// Procesa un frame del ESP32-CAM
  Future<void> processFrame(InputImage inputImage) async {
    if (!_isInitialized) {
      print('[VisionProcessor] ⚠️ No inicializado');
      return;
    }

    // Procesar en paralelo (no esperar resultados)
    _faceMeshProcessor.processFrame(inputImage);
    _handsProcessor.processFrame(inputImage);
  }

  /// Actualizar datos del IMU (para detector híbrido)
  void updateSensorData(SensorData sensorData) {
    _handsOffDetector.updateSensorData(sensorData);
  }

  /// Configurar ROI del volante (después de calibración)
  void setSteeringWheelROI(Rect roi) {
    _handsProcessor.setSteeringWheelROI(roi);
  }

  /// Resetear todos los detectores
  void resetDetectors() {
    _distractionDetector.reset();
    _inattentionDetector.reset();
    _handsOffDetector.reset();
  }

  /// Obtener estadísticas de procesamiento
  Map<String, dynamic> getStats() {
    return {
      'faceMesh': _faceMeshProcessor.getStats(),
      'hands': _handsProcessor.getStats(),
    };
  }

  void dispose() {
    // Cancelar suscripciones
    _faceDataSubscription?.cancel();
    _handDataSubscription?.cancel();
    _distractionEventSubscription?.cancel();
    _inattentionEventSubscription?.cancel();
    _handsOffEventSubscription?.cancel();

    // Cerrar procesadores y detectores
    _faceMeshProcessor.dispose();
    _handsProcessor.dispose();
    _distractionDetector.dispose();
    _inattentionDetector.dispose();
    _handsOffDetector.dispose();

    _eventController.close();
    print('[VisionProcessor] 🛑 Cerrado');
  }
}
```

---

## 2.4 Integración con DashboardBloc

### Paso 2.4.1: Modificar DashboardBloc

**Archivo**: `lib/presentation/blocs/dashboard/dashboard_bloc.dart`

**Agregar**:

```dart
import '../../core/vision/processors/vision_processor.dart';
import '../../core/vision/utils/frame_subscriber.dart';
import '../../data/datasources/local/http_server_service.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  // Existentes
  final SensorService _sensorService;
  final EventAggregator _eventAggregator;

  // NUEVOS - Visión
  late final VisionProcessor _visionProcessor;
  late final FrameSubscriber _frameSubscriber;
  final HttpServerService _httpServerService;

  StreamSubscription<VisionEvent>? _visionEventSubscription;
  StreamSubscription<InputImage>? _frameSubscription;
  StreamSubscription<SensorData>? _sensorSubscription; // Para actualizar HandsOffDetector

  DashboardBloc({
    required SensorService sensorService,
    required EventAggregator eventAggregator,
    required HttpServerService httpServerService, // NUEVO
  })  : _sensorService = sensorService,
        _eventAggregator = eventAggregator,
        _httpServerService = httpServerService,
        super(DashboardInitial()) {

    // Inicializar procesador de visión
    _visionProcessor = VisionProcessor();
    _frameSubscriber = FrameSubscriber(_httpServerService);

    on<DashboardStartMonitoring>(_onStartMonitoring);
    on<DashboardStopMonitoring>(_onStopMonitoring);
    // ... otros eventos
  }

  Future<void> _onStartMonitoring(
    DashboardStartMonitoring event,
    Emitter<DashboardState> emit,
  ) async {
    // Iniciar sensores IMU (existente)
    _sensorService.start();
    _listenToSensorData();
    _listenToDetectionEvents();

    // NUEVO - Iniciar procesamiento de visión
    _startVisionProcessing();

    emit(DashboardMonitoring());
  }

  void _startVisionProcessing() {
    // Suscribirse a frames del ESP32-CAM
    _frameSubscriber.start();

    _frameSubscription = _frameSubscriber.inputImageStream.listen((inputImage) {
      // Procesar frame con MediaPipe
      _visionProcessor.processFrame(inputImage);
    });

    // Suscribirse a eventos de visión
    _visionEventSubscription = _visionProcessor.eventStream.listen((visionEvent) {
      // Convertir VisionEvent → DetectionEvent
      final detectionEvent = DetectionEvent(
        type: visionEvent.type,
        severity: visionEvent.severity,
        timestamp: visionEvent.timestamp,
        confidence: visionEvent.confidence,
        metadata: visionEvent.metadata,
        peakValues: {},
      );

      // Enviar al EventAggregator (existente)
      _eventAggregator.addEvent(detectionEvent);
    });

    // Actualizar HandsOffDetector con datos del IMU
    _sensorSubscription = _sensorService.sensorDataStream.listen((sensorData) {
      _visionProcessor.updateSensorData(sensorData);
    });

    print('[DashboardBloc] ✅ Procesamiento de visión iniciado');
  }

  Future<void> _onStopMonitoring(
    DashboardStopMonitoring event,
    Emitter<DashboardState> emit,
  ) async {
    // Detener sensores IMU (existente)
    _sensorService.stop();

    // NUEVO - Detener procesamiento de visión
    _stopVisionProcessing();

    emit(DashboardIdle());
  }

  void _stopVisionProcessing() {
    _frameSubscription?.cancel();
    _visionEventSubscription?.cancel();
    _sensorSubscription?.cancel();
    _frameSubscriber.stop();
    _visionProcessor.resetDetectors();

    print('[DashboardBloc] 🛑 Procesamiento de visión detenido');
  }

  @override
  Future<void> close() {
    _stopVisionProcessing();
    _visionProcessor.dispose();
    _frameSubscriber.dispose();
    return super.close();
  }
}
```

---

## 2.5 Checklist de Fase 2

- [ ] FaceMeshProcessor implementado y probado
- [ ] HandsProcessor implementado y probado
- [ ] DistractionDetector implementado con umbrales correctos
- [ ] InattentionDetector implementado con umbrales correctos
- [ ] HandsOffDetector implementado con lógica híbrida (visión + IMU)
- [ ] VisionProcessor orquesta todos los componentes
- [ ] DashboardBloc integrado con VisionProcessor
- [ ] Eventos de visión llegan al EventAggregator
- [ ] ROI del volante calibrada (ver Fase 3)
- [ ] Logs muestran detecciones exitosas

---

## Siguiente Fase

**FASE 3**: Pruebas, calibración de ROI, validación y mantenimiento.

Ver: `PLAN_FASE3_PRUEBAS.md`
