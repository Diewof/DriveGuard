import 'package:flutter/material.dart';

/// Sistema de diseño DriveGuard - Design Tokens
///
/// Identidad visual: protección, tecnología, confianza y prevención
/// Paleta cromática basada en el escudo geométrico y sistema semafórico
class AppColors {
  // ========== COLORES PRINCIPALES (Identidad de marca) ==========
  /// Azul principal #1E40AF - Confianza y seguridad tecnológica
  static const Color primary = Color(0xFF1E40AF);

  /// Azul oscuro #0F172A - Solidez y autoridad
  static const Color primaryDark = Color(0xFF0F172A);

  /// Azul claro para estados hover y fondos secundarios
  static const Color primaryLight = Color(0xFF3B82F6);

  // ========== SISTEMA SEMAFÓRICO (Estados de riesgo) ==========
  /// Verde #10B981 - Estado seguro, conducción normal
  static const Color success = Color(0xFF10B981);

  /// Amarillo #F59E0B - Advertencia, atención requerida
  static const Color warning = Color(0xFFF59E0B);

  /// Rojo #EF4444 - Peligro, acción inmediata necesaria
  static const Color danger = Color(0xFFEF4444);

  /// Naranja #F97316 - Riesgo moderado
  static const Color moderate = Color(0xFFF97316);

  // ========== COLORES DE FONDO ==========
  /// Fondo principal de la app (gris muy claro)
  static const Color backgroundLight = Color(0xFFF8FAFC);

  /// Fondo de tarjetas y elementos elevados
  static const Color cardBackground = Color(0xFFFFFFFF);

  /// Fondo para overlays y modales
  static const Color overlay = Color(0x66000000);

  // ========== COLORES DE TEXTO ==========
  /// Texto principal (gris oscuro, casi negro)
  static const Color textPrimary = Color(0xFF1E293B);

  /// Texto secundario (gris medio)
  static const Color textSecondary = Color(0xFF64748B);

  /// Texto terciario / deshabilitado (gris claro)
  static const Color textDisabled = Color(0xFF94A3B8);

  // ========== COLORES DE BORDES Y DIVISORES ==========
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFCBD5E1);

  // ========== COLORES AUXILIARES ==========
  /// Información (azul info)
  static const Color info = Color(0xFF0EA5E9);

  /// Color de error (deprecado, usar danger en su lugar)
  @Deprecated('Use danger instead')
  static const Color error = danger;

  // ========== GRADIENTES ==========
  /// Gradiente azul principal (para headers y elementos destacados)
  static const List<Color> gradientPrimary = [
    primaryDark,
    primary,
  ];

  /// Gradiente de éxito (monitoreo activo)
  static const List<Color> gradientSuccess = [
    Color(0xFF059669), // green-700
    success,
  ];

  /// Gradiente de advertencia
  static const List<Color> gradientWarning = [
    Color(0xFFD97706), // amber-700
    warning,
  ];

  // ========== FUNCIONES AUXILIARES ==========

  /// Obtiene el color según el score de riesgo (0-100)
  /// - 0-30: Verde (seguro)
  /// - 30-60: Amarillo (advertencia)
  /// - 60-100: Rojo (peligro)
  static Color getRiskColor(double score) {
    if (score < 30) return success;
    if (score < 60) return warning;
    return danger;
  }

  /// Obtiene el color según la severidad de la alerta
  static Color getSeverityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'LOW':
        return warning;
      case 'MEDIUM':
        return moderate;
      case 'HIGH':
        return danger;
      case 'CRITICAL':
        return const Color(0xFFDC2626); // red-700 (más oscuro para máxima severidad)
      default:
        return textSecondary;
    }
  }

  /// Obtiene el color de fondo suave según severidad
  static Color getSeverityBackgroundColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'LOW':
        return const Color(0xFFFEF3C7); // amber-100
      case 'MEDIUM':
        return const Color(0xFFFFEDD5); // orange-100
      case 'HIGH':
        return const Color(0xFFFEE2E2); // red-100
      case 'CRITICAL':
        return const Color(0xFFFECACA); // red-200
      default:
        return const Color(0xFFF1F5F9); // slate-100
    }
  }

  /// Obtiene gradiente según estado de monitoreo
  static List<Color> getMonitoringGradient(bool isMonitoring) {
    return isMonitoring ? gradientSuccess : gradientPrimary;
  }
}