import 'dart:async';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../models/face_data.dart';

/// Procesador de detección facial usando ML Kit Face Detection
///
/// Procesa frames del ESP32-CAM con MediaPipe para extraer datos faciales
/// incluyendo orientación de la cabeza (head pose) y estado de los ojos.
class FaceMeshProcessor {
  late final FaceDetector _faceDetector;

  final _faceDataController = StreamController<FaceData?>.broadcast();
  Stream<FaceData?> get faceDataStream => _faceDataController.stream;

  bool _isProcessing = false;
  int _processedFrames = 0;
  int _failedFrames = 0;
  int _noFaceDetectedFrames = 0;

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
        _noFaceDetectedFrames++;

        if (_noFaceDetectedFrames % 10 == 0) {
          print('[FaceMeshProcessor] ⚠️ No se detectó cara en $_noFaceDetectedFrames frames consecutivos');
        }
        return;
      }

      // Resetear contador de frames sin cara
      _noFaceDetectedFrames = 0;

      // Tomar la primera cara detectada (asumimos un solo conductor)
      final face = faces.first;

      // Extraer datos de pose de cabeza
      final headYaw = face.headEulerAngleY ?? 0.0;    // Rotación horizontal
      final headPitch = face.headEulerAngleX ?? 0.0;  // Rotación vertical
      final headRoll = face.headEulerAngleZ ?? 0.0;   // Inclinación lateral

      // Extraer estado de ojos
      final leftEyeOpen = (face.leftEyeOpenProbability ?? 0.0) > 0.5;
      final rightEyeOpen = (face.rightEyeOpenProbability ?? 0.0) > 0.5;

      // Calcular confidence basado en tracking ID y probabilidades
      final confidence = _calculateConfidence(face);

      final faceData = FaceData(
        face: face,
        headYaw: headYaw,
        headPitch: headPitch,
        headRoll: headRoll,
        leftEyeOpen: leftEyeOpen,
        rightEyeOpen: rightEyeOpen,
        timestamp: DateTime.now(),
        confidence: confidence,
      );

      _faceDataController.add(faceData);
      _processedFrames++;

      // Log cada 30 frames procesados (~6 segundos a 5 FPS)
      if (_processedFrames % 30 == 0) {
        print('[FaceMeshProcessor] 📊 Procesados: $_processedFrames frames, '
            'Fallidos: $_failedFrames, '
            'Sin cara: $_noFaceDetectedFrames frames');
      }
    } catch (e) {
      print('[FaceMeshProcessor] ❌ Error procesando frame: $e');
      _faceDataController.add(null);
      _failedFrames++;
    } finally {
      _isProcessing = false;
    }
  }

  /// Calcula el nivel de confianza de la detección facial
  double _calculateConfidence(Face face) {
    // Usar probabilidad de ojos como proxy de confidence
    // Si no hay datos de probabilidad, usar 1.0
    final leftEyeProb = face.leftEyeOpenProbability ?? 1.0;
    final rightEyeProb = face.rightEyeOpenProbability ?? 1.0;

    // Promedio de probabilidades como confidence
    return ((leftEyeProb + rightEyeProb) / 2.0).clamp(0.5, 1.0);
  }

  /// Obtener estadísticas del procesador
  Map<String, int> getStats() {
    final totalFrames = _processedFrames + _failedFrames + _noFaceDetectedFrames;
    return {
      'processedFrames': _processedFrames,
      'failedFrames': _failedFrames,
      'noFaceDetectedFrames': _noFaceDetectedFrames,
      'successRate': totalFrames > 0
          ? ((_processedFrames / totalFrames) * 100).round()
          : 0,
    };
  }

  void dispose() {
    _faceDetector.close();
    _faceDataController.close();
    print('[FaceMeshProcessor] 🛑 Procesador cerrado');
  }
}
