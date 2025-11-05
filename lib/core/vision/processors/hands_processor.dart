import 'dart:async';
import 'dart:ui';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../models/hand_data.dart';
import '../../services/camera_roi_config_service.dart';

/// Procesador de detección de manos usando PoseDetector
///
/// WORKAROUND: ML Kit Flutter no tiene HandLandmarker nativo, así que usamos
/// PoseDetector para detectar muñecas (wrists) como aproximación de la posición
/// de las manos.
class HandsProcessor {
  late final PoseDetector _poseDetector;

  final _handDataController = StreamController<HandData?>.broadcast();
  Stream<HandData?> get handDataStream => _handDataController.stream;

  bool _isProcessing = false;
  int _processedFrames = 0;
  int _failedFrames = 0;
  int _noPoseDetectedFrames = 0;

  // Región de Interés (ROI) para el volante
  // Se calibra en tiempo de ejecución (ver ROICalibrator en Fase 3)
  Rect? _steeringWheelROI;

  HandsProcessor() {
    _initializeDetector();
    _loadROIConfig();
  }

  void _initializeDetector() {
    // Inicializar con opciones por defecto
    // La API de google_mlkit_pose_detection usa PoseDetectorOptions()
    final options = PoseDetectorOptions();

    _poseDetector = PoseDetector(options: options);
    print('[HandsProcessor] ✅ Detector inicializado (usando PoseDetector como workaround)');
  }

  /// Carga la configuración del ROI desde el servicio
  Future<void> _loadROIConfig() async {
    try {
      final service = await CameraROIConfigService.getInstance();
      final config = service.config;

      // Convertir ROI normalizado a píxeles absolutos (asumiendo 640x480)
      final roi = config.toRect(const Size(640, 480));
      setSteeringWheelROI(roi);

      print('[HandsProcessor] 📐 ROI cargada desde configuración guardada');
    } catch (e) {
      print('[HandsProcessor] ⚠️ Error cargando ROI, usando valor por defecto: $e');
    }
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
        _noPoseDetectedFrames++;

        if (_noPoseDetectedFrames % 10 == 0) {
          print('[HandsProcessor] ⚠️ No se detectó pose en $_noPoseDetectedFrames frames consecutivos');
        }
        return;
      }

      // Resetear contador
      _noPoseDetectedFrames = 0;

      final pose = poses.first;

      // Detectar muñecas (wrists) como aproximación de manos
      final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
      final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];

      Offset? leftHandPosition;
      Offset? rightHandPosition;
      bool leftHandInROI = false;
      bool rightHandInROI = false;

      // Usar ROI por defecto si no está calibrada
      final roi = _steeringWheelROI ?? _getDefaultROI();

      // Verificar si las muñecas están dentro de la ROI del volante
      if (leftWrist != null) {
        leftHandPosition = Offset(leftWrist.x, leftWrist.y);
        leftHandInROI = _isPointInROI(leftHandPosition, roi);
      }

      if (rightWrist != null) {
        rightHandPosition = Offset(rightWrist.x, rightWrist.y);
        rightHandInROI = _isPointInROI(rightHandPosition, roi);
      }

      // Calcular confidence basado en la certeza de los landmarks
      final confidence = _calculateConfidence(leftWrist, rightWrist);

      final handData = HandData(
        pose: pose,
        leftHandInROI: leftHandInROI,
        rightHandInROI: rightHandInROI,
        leftHandPosition: leftHandPosition,
        rightHandPosition: rightHandPosition,
        steeringWheelROI: roi,
        timestamp: DateTime.now(),
        confidence: confidence,
      );

      _handDataController.add(handData);
      _processedFrames++;

      if (_processedFrames % 30 == 0) {
        print('[HandsProcessor] 📊 Procesados: $_processedFrames frames, '
            'Manos detectadas: ${handData.handsOnWheel}/2, '
            'ROI calibrada: ${_steeringWheelROI != null}');
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
  bool _isPointInROI(Offset point, Rect roi) {
    return point.dx >= roi.left &&
           point.dx <= roi.right &&
           point.dy >= roi.top &&
           point.dy <= roi.bottom;
  }

  /// Obtiene ROI por defecto (centro inferior de la imagen)
  Rect _getDefaultROI() {
    // Asumimos imagen de 640x480 del ESP32-CAM
    // Volante típicamente en el tercio inferior central
    return const Rect.fromLTWH(
      160,  // x: inicia en 1/4 del ancho
      280,  // y: inicia en el tercio inferior
      320,  // width: mitad del ancho
      150,  // height: altura del volante típico
    );
  }

  /// Calcula el nivel de confianza basado en la certeza de los landmarks
  double _calculateConfidence(PoseLandmark? leftWrist, PoseLandmark? rightWrist) {
    double totalConfidence = 0.0;
    int landmarksDetected = 0;

    if (leftWrist != null && leftWrist.likelihood > 0.0) {
      totalConfidence += leftWrist.likelihood;
      landmarksDetected++;
    }

    if (rightWrist != null && rightWrist.likelihood > 0.0) {
      totalConfidence += rightWrist.likelihood;
      landmarksDetected++;
    }

    if (landmarksDetected == 0) return 0.5; // Confidence por defecto

    return (totalConfidence / landmarksDetected).clamp(0.5, 1.0);
  }

  Map<String, int> getStats() {
    final totalFrames = _processedFrames + _failedFrames + _noPoseDetectedFrames;
    return {
      'processedFrames': _processedFrames,
      'failedFrames': _failedFrames,
      'noPoseDetectedFrames': _noPoseDetectedFrames,
      'successRate': totalFrames > 0
          ? ((_processedFrames / totalFrames) * 100).round()
          : 0,
    };
  }

  void dispose() {
    _poseDetector.close();
    _handDataController.close();
    print('[HandsProcessor] 🛑 Procesador cerrado');
  }
}
