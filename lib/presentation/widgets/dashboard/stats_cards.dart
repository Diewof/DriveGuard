import 'package:flutter/material.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/app_spacing.dart';
import '../../../core/utils/app_typography.dart';
import '../../../core/widgets/common_card.dart';

/// Tarjetas de estadísticas - Contador de eventos
///
/// Aplica sistema semafórico y tipografía DriveGuard
class StatsCards extends StatelessWidget {
  final int distractionCount;
  final int recklessCount;
  final int emergencyCount;

  const StatsCards({
    super.key,
    required this.distractionCount,
    required this.recklessCount,
    required this.emergencyCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context: context,
            title: 'Distracciones',
            value: distractionCount,
            icon: Icons.visibility_off_outlined,
            color: AppColors.warning,
            onTap: () => _showDistractionTooltip(context),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildStatCard(
            context: context,
            title: 'Conducta Temeraria',
            value: recklessCount,
            icon: Icons.speed,
            color: AppColors.moderate,
            onTap: () => _showRecklessTooltip(context),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildStatCard(
            context: context,
            title: 'Emergencias',
            value: emergencyCount,
            icon: Icons.emergency_outlined,
            color: AppColors.danger,
            onTap: () => _showEmergencyTooltip(context),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required int value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: CommonCard(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.sm,
        ),
        child: Column(
          children: [
            // Icono con fondo de color
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: AppSpacing.iconMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Valor numérico
            Text(
              value.toString(),
              style: AppTypography.displaySmall.copyWith(
                color: color,
                height: 1.0,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            // Título
            Text(
              title,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showDistractionTooltip(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          ),
          title: Row(
            children: [
              Icon(
                Icons.visibility_off_outlined,
                color: AppColors.warning,
                size: AppSpacing.iconMedium,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Distracciones',
                style: AppTypography.h4.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          content: Text(
            'Las distracciones detectadas incluyen:\n\n'
            '• Uso del teléfono móvil mientras conduces\n'
            '• Miradas prolongadas fuera de la carretera\n'
            '• Patrones de conducción errática que sugieren distracción\n\n'
            'Este contador muestra el número total de distracciones detectadas durante la sesión actual de monitoreo.',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
              ),
              child: Text(
                'Entendido',
                style: AppTypography.button.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showRecklessTooltip(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          ),
          title: Row(
            children: [
              Icon(
                Icons.speed_outlined,
                color: AppColors.moderate,
                size: AppSpacing.iconMedium,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Conducta Temeraria',
                style: AppTypography.h4.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          content: Text(
            'La conducta temeraria se identifica por:\n\n'
            '• Aceleraciones bruscas o excesivas\n'
            '• Frenadas súbitas y agresivas\n'
            '• Giros bruscos o maniobras peligrosas\n'
            '• Cambios repentinos de velocidad\n\n'
            'Este contador registra episodios de conducción que pueden comprometer tu seguridad y la de otros.',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
              ),
              child: Text(
                'Entendido',
                style: AppTypography.button.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEmergencyTooltip(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          ),
          title: Row(
            children: [
              Icon(
                Icons.emergency_outlined,
                color: AppColors.danger,
                size: AppSpacing.iconMedium,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Emergencias',
                style: AppTypography.h4.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          content: Text(
            'Las emergencias detectadas incluyen:\n\n'
            '• Posibles impactos o colisiones\n'
            '• Frenadas de emergencia extremas\n'
            '• Movimientos bruscos que sugieren accidentes\n'
            '• Situaciones de riesgo crítico\n\n'
            'Cuando se detecta una emergencia, se activa automáticamente el protocolo de respuesta de emergencia.',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
              ),
              child: Text(
                'Entendido',
                style: AppTypography.button.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}