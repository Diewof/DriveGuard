import 'package:flutter/material.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/app_typography.dart';
import '../../../core/utils/app_spacing.dart';

class StatusIndicator extends StatelessWidget {
  final String currentAlertType;
  final Animation<double> alertAnimation;

  const StatusIndicator({
    super.key,
    required this.currentAlertType,
    required this.alertAnimation,
  });

  Color _getBackgroundColor() {
    if (currentAlertType == 'NORMAL') {
      return AppColors.success.withValues(alpha: 0.1);
    }
    return AppColors.warning.withValues(
      alpha: 0.1 + (alertAnimation.value * 0.1),
    );
  }

  Color _getBorderColor() {
    return currentAlertType == 'NORMAL' ? AppColors.success : AppColors.warning;
  }

  Color _getIconColor() {
    return currentAlertType == 'NORMAL' ? AppColors.success : AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: alertAnimation,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.all(AppSpacing.paddingCard),
          decoration: BoxDecoration(
            color: _getBackgroundColor(),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            border: Border.all(
              color: _getBorderColor(),
              width: AppSpacing.borderMedium,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: AppSpacing.elevation2,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Estado Actual',
                    style: AppTypography.label.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Icon(
                    currentAlertType == 'NORMAL'
                      ? Icons.check_circle_outlined
                      : Icons.warning_amber_outlined,
                    color: _getIconColor(),
                    size: AppSpacing.iconSmall,
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                currentAlertType,
                style: AppTypography.h4.copyWith(
                  color: _getIconColor(),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}