import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/app_spacing.dart';
import '../../../core/utils/app_typography.dart';
import '../../../core/vision/models/face_data.dart';
import '../../../core/vision/processors/face_mesh_processor.dart';
import '../../../core/vision/processors/hands_processor.dart';
import '../../blocs/camera_stream/camera_stream_bloc.dart';
import '../../blocs/camera_stream/camera_stream_state.dart';

/// Widget de verificación de posicionamiento de cámara
///
/// Verifica que:
/// 1. Se detecte el rostro del usuario
/// 2. Se detecten las manos del usuario
/// 3. Los ángulos faciales sean apropiados
///
/// Respuesta binaria: "Cámara bien ubicada" / "Cámara mal ubicada"
class CameraVerificationWidget extends StatefulWidget {
  final Function(bool isWellPositioned) onVerificationComplete;

  const CameraVerificationWidget({
    super.key,
    required this.onVerificationComplete,
  });

  @override
  State<CameraVerificationWidget> createState() =>
      _CameraVerificationWidgetState();
}

class _CameraVerificationWidgetState extends State<CameraVerificationWidget> {
  final FaceMeshProcessor _faceProcessor = FaceMeshProcessor();
  final HandsProcessor _handsProcessor = HandsProcessor();

  bool _isTesting = false;
  bool? _faceDetected;
  bool? _handsDetected;
  bool? _anglesGood;
  FaceData? _lastFaceData;

  // Requerimos 5 frames consecutivos buenos para confirmar
  int _consecutiveGoodFrames = 0;
  static const int _requiredGoodFrames = 5;

  Timer? _verificationTimer;
  StreamSubscription? _faceStreamSubscription;

  @override
  void initState() {
    super.initState();
    _initializeProcessors();
  }

  void _initializeProcessors() {
    // Escuchar el stream de detección facial
    _faceStreamSubscription = _faceProcessor.faceDataStream.listen((faceData) {
      if (mounted && _isTesting) {
        setState(() {
          _lastFaceData = faceData;
          _faceDetected = faceData != null;

          if (faceData != null) {
            // Verificar que los ángulos sean razonables
            // (no extremos que indiquen mala posición)
            _anglesGood = faceData.headYaw.abs() < 45.0 &&
                         faceData.headPitch.abs() < 30.0;
          } else {
            _anglesGood = false;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _verificationTimer?.cancel();
    _faceStreamSubscription?.cancel();
    _faceProcessor.dispose();
    _handsProcessor.dispose();
    super.dispose();
  }

  void _startVerification() {
    setState(() {
      _isTesting = true;
      _faceDetected = null;
      _handsDetected = null;
      _anglesGood = null;
      _consecutiveGoodFrames = 0;
    });

    // Temporizador para evaluar frames continuamente
    _verificationTimer?.cancel();
    _verificationTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _checkVerificationStatus(),
    );

    // Auto-detener después de 30 segundos si no se completa
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted && _isTesting) {
        _stopVerification(success: false);
      }
    });
  }

  void _checkVerificationStatus() {
    if (!mounted || !_isTesting) return;

    // Verificar si todos los criterios se cumplen
    final allGood = _faceDetected == true &&
                    _handsDetected == true &&
                    _anglesGood == true;

    if (allGood) {
      _consecutiveGoodFrames++;

      if (_consecutiveGoodFrames >= _requiredGoodFrames) {
        // ¡Verificación exitosa!
        _stopVerification(success: true);
      }
    } else {
      _consecutiveGoodFrames = 0;
    }
  }

  void _stopVerification({required bool success}) {
    _verificationTimer?.cancel();

    if (mounted) {
      setState(() {
        _isTesting = false;
      });

      widget.onVerificationComplete(success);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Título y descripción
        _buildHeader(),
        const SizedBox(height: AppSpacing.xl),

        // Vista de la cámara
        _buildCameraPreview(),
        const SizedBox(height: AppSpacing.xl),

        // Indicadores de verificación
        if (_isTesting) ...[
          _buildVerificationIndicators(),
          const SizedBox(height: AppSpacing.xl),
        ],

        // Botón de acción
        _buildActionButton(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Verificar Posición de Cámara',
                  style: AppTypography.h3.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Asegúrate de que el video se vea claro y que tu rostro y manos '
            'sean visibles. El sistema verificará que todo esté correcto.',
            style: AppTypography.body.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    return BlocBuilder<CameraStreamBloc, CameraStreamState>(
      builder: (context, state) {
        if (state is CameraStreamNewFrame) {
          // Procesar frame para detección
          if (_isTesting) {
            _processFrame(state.frame.imageBytes);
          }

          return Container(
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(
                    state.frame.imageBytes,
                    fit: BoxFit.cover,
                  ),
                  // Overlay de detección
                  if (_isTesting) _buildDetectionOverlay(),
                ],
              ),
            ),
          );
        }

        // Placeholder sin conexión
        return Container(
          height: 300,
          decoration: BoxDecoration(
            color: AppColors.divider,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                state is CameraStreamLoading
                    ? Icons.sync
                    : Icons.videocam_off,
                size: 64,
                color: AppColors.textDisabled,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                state is CameraStreamLoading
                    ? 'Conectando con cámara...'
                    : 'Esperando conexión de cámara',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetectionOverlay() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: _getOverlayColor(),
          width: 4,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(AppSpacing.radiusCircular),
          ),
          child: Text(
            'Analizando... $_consecutiveGoodFrames/$_requiredGoodFrames',
            style: AppTypography.body.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Color _getOverlayColor() {
    if (_faceDetected == true && _handsDetected == true && _anglesGood == true) {
      return AppColors.success;
    } else if (_faceDetected == false || _handsDetected == false) {
      return AppColors.danger;
    } else {
      return AppColors.warning;
    }
  }

  Widget _buildVerificationIndicators() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildIndicatorItem(
            icon: Icons.face,
            label: 'Rostro detectado',
            status: _faceDetected,
          ),
          const Divider(height: AppSpacing.xl),
          _buildIndicatorItem(
            icon: Icons.back_hand,
            label: 'Manos detectadas',
            status: _handsDetected,
          ),
          const Divider(height: AppSpacing.xl),
          _buildIndicatorItem(
            icon: Icons.rotate_90_degrees_cw,
            label: 'Ángulos correctos',
            status: _anglesGood,
            subtitle: _lastFaceData != null
                ? 'Horizontal: ${_lastFaceData!.headYaw.toStringAsFixed(1)}°, '
                  'Vertical: ${_lastFaceData!.headPitch.toStringAsFixed(1)}°'
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorItem({
    required IconData icon,
    required String label,
    required bool? status,
    String? subtitle,
  }) {
    IconData statusIcon;
    Color statusColor;

    if (status == null) {
      statusIcon = Icons.pending;
      statusColor = AppColors.textDisabled;
    } else if (status) {
      statusIcon = Icons.check_circle;
      statusColor = AppColors.success;
    } else {
      statusIcon = Icons.cancel;
      statusColor = AppColors.danger;
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          ),
          child: Icon(icon, color: statusColor, size: 28),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        Icon(statusIcon, color: statusColor, size: 24),
      ],
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      height: AppSpacing.buttonHeightLarge,
      child: ElevatedButton(
        onPressed: _isTesting ? null : _startVerification,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.textDisabled,
          elevation: AppSpacing.elevation3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusCircular),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isTesting ? Icons.sync : Icons.check_circle_outline,
              size: AppSpacing.iconLarge,
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              _isTesting ? 'Verificando...' : 'Iniciar Verificación',
              style: AppTypography.button.copyWith(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processFrame(List<int> imageBytes) async {
    if (!_isTesting) return; // Solo procesar durante verificación activa

    try {
      // 1. Decodificar JPEG a imagen raw
      final decodedImage = img.decodeJpg(Uint8List.fromList(imageBytes));
      if (decodedImage == null) {
        debugPrint('[CameraVerification] No se pudo decodificar JPEG');
        return;
      }

      // 2. Convertir a formato que ML Kit entiende (NV21)
      final nv21Data = _convertImageToNV21(decodedImage);

      // 3. Crear InputImage con metadata correcta
      final inputImage = InputImage.fromBytes(
        bytes: nv21Data,
        metadata: InputImageMetadata(
          size: Size(decodedImage.width.toDouble(), decodedImage.height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow: decodedImage.width,
        ),
      );

      // 4. Procesar con FaceDetector
      await _faceProcessor.processFrame(inputImage);

      // 5. Procesar con HandsProcessor (PoseDetector)
      await _handsProcessor.processFrame(inputImage);

      // 6. Actualizar estado con resultados
      if (mounted && _isTesting) {
        // El stream de _faceProcessor ya actualiza _lastFaceData

        // Para manos, necesitamos verificar el último dato
        _handsProcessor.handDataStream.first.timeout(
          const Duration(seconds: 1),
          onTimeout: () => null,
        ).then((handData) {
          if (mounted && _isTesting) {
            setState(() {
              _handsDetected = handData != null &&
                  (handData.leftHandPosition != null ||
                   handData.rightHandPosition != null);
            });
          }
        });
      }
    } catch (e) {
      debugPrint('[CameraVerification] Error procesando frame: $e');
    }
  }

  /// Convierte imagen decodificada a formato NV21 para ML Kit
  Uint8List _convertImageToNV21(img.Image image) {
    final width = image.width;
    final height = image.height;
    final ySize = width * height;
    final uvSize = width * height ~/ 2;

    final nv21 = Uint8List(ySize + uvSize);

    int yIndex = 0;
    int uvIndex = ySize;

    for (int j = 0; j < height; j++) {
      for (int i = 0; i < width; i++) {
        final pixel = image.getPixel(i, j);

        // Extraer componentes RGB
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();

        // Convertir RGB a YUV
        final y = ((66 * r + 129 * g + 25 * b + 128) >> 8) + 16;
        nv21[yIndex++] = y.clamp(0, 255);

        // Solo cada 2 píxeles para UV
        if (j % 2 == 0 && i % 2 == 0) {
          final u = ((-38 * r - 74 * g + 112 * b + 128) >> 8) + 128;
          final v = ((112 * r - 94 * g - 18 * b + 128) >> 8) + 128;

          nv21[uvIndex++] = v.clamp(0, 255);
          nv21[uvIndex++] = u.clamp(0, 255);
        }
      }
    }

    return nv21;
  }
}
