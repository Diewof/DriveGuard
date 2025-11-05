import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/utils/app_colors.dart';
import '../../core/utils/app_spacing.dart';
import '../../core/utils/app_typography.dart';
import '../../core/services/camera_roi_config_service.dart';
import '../blocs/camera_stream/camera_stream_bloc.dart';
import '../blocs/camera_stream/camera_stream_event.dart';
import '../blocs/camera_stream/camera_stream_state.dart';
import '../widgets/camera_calibration/camera_verification_widget.dart';
import '../widgets/camera_calibration/roi_adjustment_widget.dart';

/// Página de calibración y detección de cámara
///
/// Permite al usuario:
/// 1. Verificar que la cámara está bien ubicada (detección de rostro y manos)
/// 2. Ajustar el ROI para la detección de "manos fuera del volante"
class CameraCalibrationPage extends StatefulWidget {
  const CameraCalibrationPage({super.key});

  @override
  State<CameraCalibrationPage> createState() => _CameraCalibrationPageState();
}

class _CameraCalibrationPageState extends State<CameraCalibrationPage> {
  int _currentStep = 0; // 0: Verificación, 1: Ajuste ROI
  CameraROIConfigService? _roiService;
  bool _isLoadingService = true;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _ensureCameraStreamStarted();
  }

  Future<void> _initializeServices() async {
    _roiService = await CameraROIConfigService.getInstance();
    if (mounted) {
      setState(() {
        _isLoadingService = false;
      });
    }
  }

  void _ensureCameraStreamStarted() {
    final bloc = context.read<CameraStreamBloc>();
    if (bloc.state is CameraStreamInitial || bloc.state is CameraStreamStopped) {
      bloc.add(const StartCameraStream());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: _buildAppBar(),
      body: _isLoadingService
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Detectar y Calibrar Cámara',
        style: AppTypography.h3.copyWith(color: Colors.white),
      ),
      backgroundColor: AppColors.primaryDark,
      foregroundColor: Colors.white,
      elevation: AppSpacing.elevation2,
      actions: [
        // Indicador de conexión
        BlocBuilder<CameraStreamBloc, CameraStreamState>(
          builder: (context, state) {
            final isConnected = state is CameraStreamConnected ||
                               state is CameraStreamNewFrame;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: isConnected
                        ? AppColors.success.withValues(alpha: 0.15)
                        : AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusCircular),
                    border: Border.all(
                      color: isConnected ? AppColors.success : AppColors.warning,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isConnected ? AppColors.success : AppColors.warning,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        isConnected ? 'Conectado' : 'Esperando...',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Indicador de pasos
            _buildStepIndicator(),
            const SizedBox(height: AppSpacing.xl),

            // Contenido según el paso actual
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _currentStep == 0
                  ? CameraVerificationWidget(
                      key: const ValueKey('verification'),
                      onVerificationComplete: _handleVerificationComplete,
                    )
                  : ROIAdjustmentWidget(
                      key: const ValueKey('roi_adjustment'),
                      roiService: _roiService!,
                      onAdjustmentComplete: _handleAdjustmentComplete,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
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
      child: Row(
        children: [
          _buildStepItem(
            number: 1,
            title: 'Verificar Cámara',
            isActive: _currentStep == 0,
            isCompleted: _currentStep > 0,
          ),
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              color: _currentStep > 0
                  ? AppColors.success
                  : AppColors.divider,
            ),
          ),
          _buildStepItem(
            number: 2,
            title: 'Ajustar Región',
            isActive: _currentStep == 1,
            isCompleted: false,
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required int number,
    required String title,
    required bool isActive,
    required bool isCompleted,
  }) {
    Color color;
    IconData? icon;

    if (isCompleted) {
      color = AppColors.success;
      icon = Icons.check;
    } else if (isActive) {
      color = AppColors.primary;
    } else {
      color = AppColors.textDisabled;
    }

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive
                ? color
                : (isCompleted ? color : Colors.white),
            shape: BoxShape.circle,
            border: Border.all(
              color: color,
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? Icon(icon, color: Colors.white, size: 20)
                : Text(
                    '$number',
                    style: AppTypography.body.copyWith(
                      color: isActive ? Colors.white : color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          title,
          style: AppTypography.caption.copyWith(
            color: color,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  void _handleVerificationComplete(bool isWellPositioned) {
    if (isWellPositioned) {
      // Avanzar al siguiente paso (ajuste de ROI)
      setState(() {
        _currentStep = 1;
      });

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('Cámara bien ubicada. Ahora ajusta la región del volante.'),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      // Mostrar diálogo con recomendaciones
      _showRepositionDialog();
    }
  }

  void _handleAdjustmentComplete() {
    // Mostrar diálogo de éxito y volver al dashboard
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 32,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            const Expanded(
              child: Text('Calibración Completada'),
            ),
          ],
        ),
        content: const Text(
          'Tu cámara ha sido calibrada exitosamente. '
          'El sistema ahora está listo para detectar cuando tus manos '
          'se alejen del volante.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cerrar diálogo
              Navigator.of(context).pop(); // Volver al dashboard
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              ),
            ),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _showRepositionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber,
                color: AppColors.warning,
                size: 32,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            const Expanded(
              child: Text('Cámara Mal Ubicada'),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'La cámara no está detectando correctamente tu rostro y manos.',
              style: TextStyle(fontSize: 15),
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'Recomendaciones:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text('• Asegúrate de que tu rostro esté bien iluminado'),
            Text('• Coloca la cámara frente a ti'),
            Text('• Mantén tus manos visibles sobre el volante'),
            Text('• Verifica que la cámara esté encendida y conectada'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // No detenemos el stream aquí porque puede estar en uso
    super.dispose();
  }
}
