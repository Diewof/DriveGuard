import 'package:flutter/material.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/app_spacing.dart';
import '../../../core/utils/app_typography.dart';
import '../../../core/widgets/common_card.dart';

/// Panel de control principal - Monitoreo de sesión
///
/// Aplica diseño DriveGuard:
/// - Gradiente según estado (azul/verde)
/// - Tipografía Montserrat para números
/// - Animación suave en cambios de estado
class ControlPanel extends StatelessWidget {
  final bool isMonitoring;
  final Duration sessionDuration;
  final VoidCallback onToggleMonitoring;

  const ControlPanel({
    super.key,
    required this.isMonitoring,
    required this.sessionDuration,
    required this.onToggleMonitoring,
  });

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      gradientColors: AppColors.getMonitoringGradient(isMonitoring),
      padding: const EdgeInsets.all(AppSpacing.paddingSection),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Estado (overline)
                Text(
                  isMonitoring ? 'MONITOREANDO' : 'EN ESPERA',
                  style: AppTypography.overline.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                // Duración (display)
                Text(
                  _formatDuration(sessionDuration),
                  style: AppTypography.displayMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                // Descripción
                Text(
                  isMonitoring
                      ? 'Sesión activa'
                      : 'Toca para iniciar',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Botón de control
          _buildControlButton(),
        ],
      ),
    );
  }

  Widget _buildControlButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggleMonitoring,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCircular),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Icon(
            isMonitoring ? Icons.stop_rounded : Icons.play_arrow_rounded,
            size: AppSpacing.iconLarge,
            color: isMonitoring ? AppColors.danger : AppColors.success,
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }
}