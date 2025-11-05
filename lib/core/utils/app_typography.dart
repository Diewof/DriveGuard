import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Sistema de tipografía DriveGuard
///
/// Tipografía corporativa:
/// - Títulos: Montserrat Bold/SemiBold
/// - Texto base: Inter Regular
/// - Jerarquía clara y legible
class AppTypography {
  // ========== TÍTULOS ==========
  /// H1 - Títulos principales de página
  static const TextStyle h1 = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.2,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  /// H2 - Títulos de sección
  static const TextStyle h2 = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.3,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );

  /// H3 - Subtítulos
  static const TextStyle h3 = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  /// H4 - Encabezados de tarjetas
  static const TextStyle h4 = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  // ========== CUERPO DE TEXTO ==========
  /// Body Large - Texto principal destacado
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  /// Body - Texto principal
  static const TextStyle body = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  /// Body Small - Texto secundario
  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0,
    color: AppColors.textSecondary,
  );

  // ========== ELEMENTOS ESPECIALES ==========
  /// Caption - Etiquetas y textos auxiliares
  static const TextStyle caption = TextStyle(
    fontFamily: 'Inter',
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.3,
    letterSpacing: 0.2,
    color: AppColors.textSecondary,
  );

  /// Button - Texto de botones
  static const TextStyle button = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.5,
  );

  /// Button Large - Texto de botones grandes
  static const TextStyle buttonLarge = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 16,
    fontWeight: FontWeight.bold,
    height: 1.2,
    letterSpacing: 0.5,
  );

  /// Label - Etiquetas de formularios
  static const TextStyle label = TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: 0.1,
    color: AppColors.textPrimary,
  );

  /// Overline - Texto sobre elementos (categorías, etiquetas)
  static const TextStyle overline = TextStyle(
    fontFamily: 'Inter',
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 1.0,
    color: AppColors.textSecondary,
  );

  // ========== VALORES NUMÉRICOS ==========
  /// Display Large - Números grandes (scores, métricas principales)
  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 48,
    fontWeight: FontWeight.bold,
    height: 1.1,
    letterSpacing: -1.0,
  );

  /// Display Medium - Números medianos
  static const TextStyle displayMedium = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 36,
    fontWeight: FontWeight.bold,
    height: 1.1,
    letterSpacing: -0.8,
  );

  /// Display Small - Números pequeños
  static const TextStyle displaySmall = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.2,
    letterSpacing: -0.5,
  );

  // ========== ALERTAS Y NOTIFICACIONES ==========
  /// Alert Title - Título de alertas
  static const TextStyle alertTitle = TextStyle(
    fontFamily: 'Montserrat',
    fontSize: 16,
    fontWeight: FontWeight.bold,
    height: 1.3,
    letterSpacing: 0,
  );

  /// Alert Body - Cuerpo de alertas
  static const TextStyle alertBody = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0,
  );
}
