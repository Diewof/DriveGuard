import 'package:flutter/material.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/app_typography.dart';
import '../../../core/utils/app_spacing.dart';

class AuthButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? backgroundColor;
  final Color? textColor;

  const AuthButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = backgroundColor ?? AppColors.primary;
    final buttonTextColor = textColor ?? (isOutlined ? primaryColor : Colors.white);

    return SizedBox(
      width: double.infinity,
      height: AppSpacing.buttonHeightLarge,
      child: isOutlined
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: primaryColor,
                  width: AppSpacing.borderMedium,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
                foregroundColor: primaryColor,
                disabledForegroundColor: AppColors.textDisabled,
              ),
              child: _buildButtonContent(buttonTextColor),
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.textDisabled,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
                elevation: AppSpacing.elevation2,
              ),
              child: _buildButtonContent(buttonTextColor),
            ),
    );
  }

  Widget _buildButtonContent(Color textColor) {
    if (isLoading) {
      return SizedBox(
        width: AppSpacing.iconMedium,
        height: AppSpacing.iconMedium,
        child: CircularProgressIndicator(
          strokeWidth: AppSpacing.borderMedium,
          valueColor: AlwaysStoppedAnimation<Color>(
            isOutlined ? textColor : Colors.white,
          ),
        ),
      );
    }

    return Text(
      text,
      style: AppTypography.buttonLarge.copyWith(color: textColor),
    );
  }
}