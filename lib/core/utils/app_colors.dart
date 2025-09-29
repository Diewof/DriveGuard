import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF1565C0);
  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color secondary = Color(0xFF4CAF50);

  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);

  static Color getRiskColor(double score) {
    if (score < 30) return success;
    if (score < 60) return warning;
    return error;
  }

  static Color getSeverityColor(String severity) {
    switch (severity) {
      case 'LOW':
        return Colors.yellow[700]!;
      case 'MEDIUM':
        return warning;
      case 'HIGH':
        return Colors.deepOrange;
      case 'CRITICAL':
        return error;
      default:
        return Colors.grey;
    }
  }
}