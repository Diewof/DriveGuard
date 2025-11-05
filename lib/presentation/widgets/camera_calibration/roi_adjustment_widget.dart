import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/app_spacing.dart';
import '../../../core/utils/app_typography.dart';
import '../../../core/services/camera_roi_config_service.dart';
import '../../blocs/camera_stream/camera_stream_bloc.dart';
import '../../blocs/camera_stream/camera_stream_state.dart';

/// Widget de ajuste visual del ROI (Región de Interés)
///
/// Permite al usuario ajustar visualmente el área del volante
/// que será monitoreada para la detección de manos
class ROIAdjustmentWidget extends StatefulWidget {
  final CameraROIConfigService roiService;
  final VoidCallback onAdjustmentComplete;

  const ROIAdjustmentWidget({
    super.key,
    required this.roiService,
    required this.onAdjustmentComplete,
  });

  @override
  State<ROIAdjustmentWidget> createState() => _ROIAdjustmentWidgetState();
}

class _ROIAdjustmentWidgetState extends State<ROIAdjustmentWidget> {
  late CameraROIConfig _currentROI;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _currentROI = widget.roiService.config;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Título y descripción
        _buildHeader(),
        const SizedBox(height: AppSpacing.xl),

        // Vista de la cámara con ROI ajustable
        _buildCameraWithROI(),
        const SizedBox(height: AppSpacing.xl),

        // Controles de ajuste
        _buildAdjustmentControls(),
        const SizedBox(height: AppSpacing.xl),

        // Botones de acción
        _buildActionButtons(),
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
                  Icons.crop_free,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Ajustar Región del Volante',
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
            'Arrastra el rectángulo para cubrir la zona donde colocas tus manos '
            'sobre el volante. Esta área será monitoreada durante la conducción.',
            style: AppTypography.body.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraWithROI() {
    return BlocBuilder<CameraStreamBloc, CameraStreamState>(
      builder: (context, state) {
        if (state is CameraStreamNewFrame) {
          return Container(
            height: 400,
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final imageWidth = constraints.maxWidth;
                  final imageHeight = constraints.maxHeight;

                  return Stack(
                    children: [
                      // Imagen de la cámara
                      Image.memory(
                        state.frame.imageBytes,
                        fit: BoxFit.cover,
                        width: imageWidth,
                        height: imageHeight,
                      ),
                      // Overlay oscuro fuera del ROI
                      _buildROIOverlay(imageWidth, imageHeight),
                      // ROI ajustable
                      _buildDraggableROI(imageWidth, imageHeight),
                    ],
                  );
                },
              ),
            ),
          );
        }

        // Placeholder sin conexión
        return Container(
          height: 400,
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

  Widget _buildROIOverlay(double imageWidth, double imageHeight) {
    // Crear overlay oscuro fuera del ROI
    return CustomPaint(
      size: Size(imageWidth, imageHeight),
      painter: _ROIOverlayPainter(
        roi: _currentROI,
        imageSize: Size(imageWidth, imageHeight),
      ),
    );
  }

  Widget _buildDraggableROI(double imageWidth, double imageHeight) {
    // Calcular posición y tamaño del ROI en píxeles
    final roiLeft = _currentROI.left * imageWidth;
    final roiTop = _currentROI.top * imageHeight;
    final roiWidth = _currentROI.width * imageWidth;
    final roiHeight = _currentROI.height * imageHeight;

    return Positioned(
      left: roiLeft,
      top: roiTop,
      child: GestureDetector(
        onPanStart: (_) {
          setState(() {
            _isDragging = true;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            // Calcular nueva posición
            double newLeft = (roiLeft + details.delta.dx) / imageWidth;
            double newTop = (roiTop + details.delta.dy) / imageHeight;

            // Limitar a los bordes de la imagen
            newLeft = newLeft.clamp(0.0, 1.0 - _currentROI.width);
            newTop = newTop.clamp(0.0, 1.0 - _currentROI.height);

            _currentROI = _currentROI.copyWith(
              left: newLeft,
              top: newTop,
            );
          });
        },
        onPanEnd: (_) {
          setState(() {
            _isDragging = false;
          });
        },
        child: Container(
          width: roiWidth,
          height: roiHeight,
          decoration: BoxDecoration(
            border: Border.all(
              color: _isDragging ? AppColors.warning : AppColors.success,
              width: 3,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          ),
          child: Stack(
            children: [
              // Esquinas para indicar que es redimensionable
              _buildCornerHandle(Alignment.topLeft),
              _buildCornerHandle(Alignment.topRight),
              _buildCornerHandle(Alignment.bottomLeft),
              _buildCornerHandle(Alignment.bottomRight),
              // Etiqueta central
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusCircular),
                  ),
                  child: Text(
                    'Área del Volante',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCornerHandle(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: AppColors.success,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    );
  }

  Widget _buildAdjustmentControls() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ajuste Fino',
            style: AppTypography.h4.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildSliderControl(
            label: 'Ancho',
            value: _currentROI.width,
            onChanged: (value) {
              setState(() {
                // Asegurar que no se salga del borde derecho
                final maxWidth = 1.0 - _currentROI.left;
                _currentROI = _currentROI.copyWith(
                  width: value.clamp(0.2, maxWidth),
                );
              });
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _buildSliderControl(
            label: 'Alto',
            value: _currentROI.height,
            onChanged: (value) {
              setState(() {
                // Asegurar que no se salga del borde inferior
                final maxHeight = 1.0 - _currentROI.top;
                _currentROI = _currentROI.copyWith(
                  height: value.clamp(0.1, maxHeight),
                );
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSliderControl({
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: AppTypography.body.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: 0.1,
            max: 1.0,
            activeColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 50,
          child: Text(
            '${(value * 100).toStringAsFixed(0)}%',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // Botón de resetear
        Expanded(
          child: SizedBox(
            height: AppSpacing.buttonHeightLarge,
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _currentROI = CameraROIConfig.defaultConfig();
                });
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: BorderSide(color: AppColors.divider, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.refresh),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Resetear',
                    style: AppTypography.button,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        // Botón de guardar
        Expanded(
          flex: 2,
          child: SizedBox(
            height: AppSpacing.buttonHeightLarge,
            child: ElevatedButton(
              onPressed: _saveROIConfiguration,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                elevation: AppSpacing.elevation3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, size: AppSpacing.iconLarge),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    'Guardar Configuración',
                    style: AppTypography.button.copyWith(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveROIConfiguration() async {
    try {
      // Guardar configuración
      await widget.roiService.saveConfig(_currentROI);

      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Configuración guardada exitosamente'),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );

        // Notificar completitud
        widget.onAdjustmentComplete();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Error al guardar: $e'),
                ),
              ],
            ),
            backgroundColor: AppColors.danger,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

/// Custom painter para dibujar el overlay oscuro fuera del ROI
class _ROIOverlayPainter extends CustomPainter {
  final CameraROIConfig roi;
  final Size imageSize;

  _ROIOverlayPainter({
    required this.roi,
    required this.imageSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    // Calcular rect del ROI
    final roiRect = roi.toRect(imageSize);

    // Dibujar overlay en 4 secciones alrededor del ROI
    // Top
    canvas.drawRect(
      Rect.fromLTWH(0, 0, imageSize.width, roiRect.top),
      paint,
    );

    // Bottom
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        roiRect.bottom,
        imageSize.width,
        imageSize.height - roiRect.bottom,
      ),
      paint,
    );

    // Left
    canvas.drawRect(
      Rect.fromLTWH(0, roiRect.top, roiRect.left, roiRect.height),
      paint,
    );

    // Right
    canvas.drawRect(
      Rect.fromLTWH(
        roiRect.right,
        roiRect.top,
        imageSize.width - roiRect.right,
        roiRect.height,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ROIOverlayPainter oldDelegate) {
    return oldDelegate.roi != roi || oldDelegate.imageSize != imageSize;
  }
}
