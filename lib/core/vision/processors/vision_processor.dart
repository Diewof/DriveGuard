import 'dart:async';
import 'dart:ui';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../models/vision_event.dart';
import '../models/face_data.dart';
import '../models/hand_data.dart';
import '../../../domain/entities/sensor_data.dart';
import 'face_mesh_processor.dart';
import 'hands_processor.dart';
import '../detectors/phone_detector.dart';
import '../detectors/inattention_detector.dart';
import '../detectors/hands_off_detector.dart';
import '../detectors/no_face_detector.dart';

/// Orquestador principal de procesamiento de visión
///
/// Coordina todos los procesadores MediaPipe y detectores de eventos,
/// consolidando los resultados en un stream unificado de eventos de visión.
class VisionProcessor {
  // Procesadores MediaPipe
  late final FaceMeshProcessor _faceMeshProcessor;
  late final HandsProcessor _handsProcessor;

  // Detectores de eventos
  late final PhoneDetector _phoneDetector;
  late final InattentionDetector _inattentionDetector;
  late final HandsOffDetector _handsOffDetector;
  late final NoFaceDetector _noFaceDetector;

  // Suscripciones a streams
  StreamSubscription<FaceData?>? _faceDataSubscription;
  StreamSubscription<HandData?>? _handDataSubscription;
  StreamSubscription<VisionEvent>? _phoneEventSubscription;
  StreamSubscription<VisionEvent>? _inattentionEventSubscription;
  StreamSubscription<VisionEvent>? _handsOffEventSubscription;
  StreamSubscription<VisionEvent>? _noFaceEventSubscription;

  // Caché de últimos datos para PhoneDetector
  FaceData? _lastFaceData;
  HandData? _lastHandData;

  // Stream consolidado de eventos
  final _eventController = StreamController<VisionEvent>.broadcast();
  Stream<VisionEvent> get eventStream => _eventController.stream;

  bool _isInitialized = false;
  int _framesProcessed = 0;

  VisionProcessor() {
    _initialize();
  }

  void _initialize() {
    // Inicializar procesadores
    _faceMeshProcessor = FaceMeshProcessor();
    _handsProcessor = HandsProcessor();

    // Inicializar detectores
    _phoneDetector = PhoneDetector();
    _inattentionDetector = InattentionDetector();
    _handsOffDetector = HandsOffDetector();
    _noFaceDetector = NoFaceDetector();

    // Conectar streams
    _connectStreams();

    _isInitialized = true;
    print('[VisionProcessor] ✅ Inicializado');
  }

  void _connectStreams() {
    // Conectar FaceMeshProcessor → Caché + Detectores
    _faceDataSubscription = _faceMeshProcessor.faceDataStream.listen((faceData) {
      _lastFaceData = faceData;

      // PhoneDetector necesita ambos: face + hand data
      _phoneDetector.processData(faceData, _lastHandData);

      // InattentionDetector solo necesita face data
      _inattentionDetector.processFaceData(faceData);

      // NoFaceDetector solo necesita face data (o null)
      _noFaceDetector.processFaceData(faceData);
    });

    // Conectar HandsProcessor → Caché + Detectores
    _handDataSubscription = _handsProcessor.handDataStream.listen((handData) {
      _lastHandData = handData;

      // PhoneDetector necesita datos actualizados de manos
      _phoneDetector.processData(_lastFaceData, handData);

      // HandsOffDetector solo necesita hand data
      _handsOffDetector.processHandData(handData);
    });

    // Consolidar eventos de todos los detectores
    _phoneEventSubscription = _phoneDetector.eventStream.listen((event) {
      _eventController.add(event);
    });

    _inattentionEventSubscription = _inattentionDetector.eventStream.listen((event) {
      _eventController.add(event);
    });

    _handsOffEventSubscription = _handsOffDetector.eventStream.listen((event) {
      _eventController.add(event);
    });

    _noFaceEventSubscription = _noFaceDetector.eventStream.listen((event) {
      _eventController.add(event);
    });

    print('[VisionProcessor] 🔗 Streams conectados (PhoneDetector + InattentionDetector + HandsOffDetector + NoFaceDetector)');
  }

  /// Procesa un frame del ESP32-CAM
  Future<void> processFrame(InputImage inputImage) async {
    if (!_isInitialized) {
      print('[VisionProcessor] ⚠️ No inicializado');
      return;
    }

    // Procesar en paralelo (no esperar resultados)
    // Los procesadores emitirán datos a sus streams cuando terminen
    _faceMeshProcessor.processFrame(inputImage);
    _handsProcessor.processFrame(inputImage);

    _framesProcessed++;

    // Log cada 60 frames (~12 segundos a 5 FPS)
    if (_framesProcessed % 60 == 0) {
      final stats = getStats();
      print('[VisionProcessor] 📊 Frames procesados: $_framesProcessed');
      print('  - Face: ${stats['faceMesh']?['processedFrames']} frames, '
          '${stats['faceMesh']?['successRate']}% éxito');
      print('  - Hands: ${stats['hands']?['processedFrames']} frames, '
          '${stats['hands']?['successRate']}% éxito');
    }
  }

  /// Actualizar datos del IMU (para detector híbrido)
  void updateSensorData(SensorData sensorData) {
    _handsOffDetector.updateSensorData(sensorData);
  }

  /// Configurar ROI del volante (después de calibración)
  void setSteeringWheelROI(Rect roi) {
    _handsProcessor.setSteeringWheelROI(roi);
    print('[VisionProcessor] 📐 ROI del volante configurada');
  }

  /// Resetear todos los detectores
  void resetDetectors() {
    _phoneDetector.reset();
    _inattentionDetector.reset();
    _handsOffDetector.reset();
    _noFaceDetector.reset();
    _lastFaceData = null;
    _lastHandData = null;
    print('[VisionProcessor] 🔄 Detectores reseteados');
  }

  /// Obtener estadísticas de procesamiento
  Map<String, dynamic> getStats() {
    return {
      'framesProcessed': _framesProcessed,
      'faceMesh': _faceMeshProcessor.getStats(),
      'hands': _handsProcessor.getStats(),
    };
  }

  void dispose() {
    // Cancelar suscripciones
    _faceDataSubscription?.cancel();
    _handDataSubscription?.cancel();
    _phoneEventSubscription?.cancel();
    _inattentionEventSubscription?.cancel();
    _handsOffEventSubscription?.cancel();
    _noFaceEventSubscription?.cancel();

    // Cerrar procesadores y detectores
    _faceMeshProcessor.dispose();
    _handsProcessor.dispose();
    _phoneDetector.dispose();
    _inattentionDetector.dispose();
    _handsOffDetector.dispose();
    _noFaceDetector.dispose();

    _eventController.close();
    print('[VisionProcessor] 🛑 Cerrado');
  }
}
