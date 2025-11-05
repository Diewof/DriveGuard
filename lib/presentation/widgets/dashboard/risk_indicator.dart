import 'package:flutter/material.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/app_spacing.dart';
import '../../../core/utils/app_typography.dart';
import '../../../core/widgets/common_card.dart';

/// Indicador de riesgo - Score de conducción
///
/// Aplica sistema semafórico DriveGuard:
/// - Verde (0-30): Seguro
/// - Amarillo (30-60): Advertencia
/// - Rojo (60-100): Peligro
class RiskIndicator extends StatelessWidget {
  final double riskScore;

  const RiskIndicator({
    super.key,
    required this.riskScore,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getRiskColor(riskScore);

    return GestureDetector(
      onTap: () => _showTooltip(context),
      child: CommonCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Score de Riesgo',
                  style: AppTypography.label.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Icon(
                  Icons.analytics_outlined,
                  color: AppColors.textDisabled,
                  size: AppSpacing.iconSmall,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            // Score principal
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  riskScore.toStringAsFixed(0),
                  style: AppTypography.displayMedium.copyWith(
                    color: color,
                    height: 1.0,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4, left: 2),
                  child: Text(
                    '/100',
                    style: AppTypography.h4.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // Barra de progreso
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              child: LinearProgressIndicator(
                value: riskScore / 100,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Etiqueta de estado
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _getRiskLabel(riskScore),
                  style: AppTypography.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getRiskLabel(double score) {
    if (score < 30) return 'Conducción segura';
    if (score < 60) return 'Riesgo moderado';
    return 'Alto riesgo';
  }

  void _showTooltip(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          ),
          title: Text(
            'Score de Riesgo',
            style: AppTypography.h3,
          ),
          content: Text(
            'El Score de Riesgo es una medición en tiempo real (0-100) que evalúa la seguridad de tu conducción basándose en:\n\n'
            '• Aceleración: Detecta frenadas y acelerones bruscos\n'
            '• Rotación: Identifica giros agresivos o maniobras peligrosas\n'
            '• Historial: Considera el patrón de alertas recientes\n\n'
            'Score menor a 30: Conducción segura\n'
            'Score 30-60: Riesgo moderado\n'
            'Score mayor a 60: Alto riesgo',
            style: AppTypography.body,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
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