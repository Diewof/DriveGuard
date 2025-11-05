import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:ui';

/// Datos procesados de detección de manos mediante MediaPipe Pose
///
/// NOTA: ML Kit Flutter no tiene HandLandmarker nativo, por lo que
/// usamos PoseDetector como workaround para detectar posición de manos
/// mediante los landmarks de muñecas (wrists).
class HandData {
  /// Objeto Pose detectado por ML Kit
  final Pose pose;

  /// Indica si la mano izquierda está dentro de la región de interés (volante)
  final bool leftHandInROI;

  /// Indica si la mano derecha está dentro de la región de interés (volante)
  final bool rightHandInROI;

  /// Posición de la mano izquierda (puede ser null si no se detecta)
  final Offset? leftHandPosition;

  /// Posición de la mano derecha (puede ser null si no se detecta)
  final Offset? rightHandPosition;

  /// Región de interés del volante (calibrada por usuario)
  final Rect steeringWheelROI;

  /// Momento de la detección
  final DateTime timestamp;

  /// Nivel de confianza de la detección (0.0 - 1.0)
  final double confidence;

  HandData({
    required this.pose,
    required this.leftHandInROI,
    required this.rightHandInROI,
    this.leftHandPosition,
    this.rightHandPosition,
    required this.steeringWheelROI,
    required this.timestamp,
    this.confidence = 1.0,
  });

  /// Cuenta cuántas manos están en el volante
  int get handsOnWheel {
    int count = 0;
    if (leftHandInROI) count++;
    if (rightHandInROI) count++;
    return count;
  }

  /// Determina si al menos una mano está en el volante
  bool get hasHandsOnWheel => handsOnWheel > 0;

  /// Determina si ambas manos están fuera del volante
  bool get bothHandsOff => handsOnWheel == 0;

  /// Determina si solo una mano está en el volante (riesgoso)
  bool get onlyOneHandOnWheel => handsOnWheel == 1;

  /// Determina si ambas manos están en el volante (seguro)
  bool get bothHandsOnWheel => handsOnWheel == 2;

  /// Calcula el nivel de riesgo (0.0 - 1.0) basado en las manos en el volante
  ///
  /// - 0.0: Ambas manos en el volante (seguro)
  /// - 0.5: Una mano en el volante (riesgo moderado)
  /// - 1.0: Ninguna mano en el volante (riesgo crítico)
  double get riskScore {
    switch (handsOnWheel) {
      case 2:
        return 0.0; // Seguro
      case 1:
        return 0.5; // Moderado
      case 0:
        return 1.0; // Crítico
      default:
        return 1.0;
    }
  }

  /// Obtiene descripción textual del estado de las manos
  String get handsStatus {
    if (bothHandsOnWheel) return 'Ambas manos en volante';
    if (onlyOneHandOnWheel) {
      if (leftHandInROI) return 'Solo mano izquierda en volante';
      if (rightHandInROI) return 'Solo mano derecha en volante';
    }
    if (bothHandsOff) return 'Sin manos en volante';
    return 'Estado indeterminado';
  }

  /// Verifica si alguna mano está cerca de la zona facial (posible uso de teléfono)
  bool isHandNearFace() {
    // Esta función requiere landmarks faciales para comparar
    // Se implementará en el detector que tiene acceso a FaceData
    // Por ahora retornamos false
    return false;
  }

  @override
  String toString() {
    return 'HandData('
        'handsOnWheel: $handsOnWheel, '
        'leftInROI: $leftHandInROI, '
        'rightInROI: $rightHandInROI, '
        'status: $handsStatus, '
        'riskScore: ${(riskScore * 100).toStringAsFixed(0)}%, '
        'confidence: ${(confidence * 100).toStringAsFixed(1)}%'
        ')';
  }

  /// Crea una copia con campos modificados
  HandData copyWith({
    Pose? pose,
    bool? leftHandInROI,
    bool? rightHandInROI,
    Offset? leftHandPosition,
    Offset? rightHandPosition,
    Rect? steeringWheelROI,
    DateTime? timestamp,
    double? confidence,
  }) {
    return HandData(
      pose: pose ?? this.pose,
      leftHandInROI: leftHandInROI ?? this.leftHandInROI,
      rightHandInROI: rightHandInROI ?? this.rightHandInROI,
      leftHandPosition: leftHandPosition ?? this.leftHandPosition,
      rightHandPosition: rightHandPosition ?? this.rightHandPosition,
      steeringWheelROI: steeringWheelROI ?? this.steeringWheelROI,
      timestamp: timestamp ?? this.timestamp,
      confidence: confidence ?? this.confidence,
    );
  }

  /// Crea HandData con ROI por defecto (centro de la imagen)
  factory HandData.withDefaultROI({
    required Pose pose,
    required bool leftHandInROI,
    required bool rightHandInROI,
    Offset? leftHandPosition,
    Offset? rightHandPosition,
    DateTime? timestamp,
    double confidence = 1.0,
  }) {
    // ROI por defecto: centro de una imagen 640x480
    // Asumimos que el volante está en el tercio inferior central
    final defaultROI = Rect.fromLTWH(
      160, // x: inicia en 1/4 del ancho
      280, // y: inicia en el tercio inferior
      320, // width: mitad del ancho
      150, // height: altura del volante típico
    );

    return HandData(
      pose: pose,
      leftHandInROI: leftHandInROI,
      rightHandInROI: rightHandInROI,
      leftHandPosition: leftHandPosition,
      rightHandPosition: rightHandPosition,
      steeringWheelROI: defaultROI,
      timestamp: timestamp ?? DateTime.now(),
      confidence: confidence,
    );
  }
}
