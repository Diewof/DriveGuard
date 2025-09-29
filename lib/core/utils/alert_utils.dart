import '../services/notification_service.dart';

class AlertUtils {
  static String severityToString(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.low:
        return 'LOW';
      case AlertSeverity.medium:
        return 'MEDIUM';
      case AlertSeverity.high:
        return 'HIGH';
      case AlertSeverity.critical:
        return 'CRITICAL';
    }
  }

  static bool isDistractionAlert(String type) {
    return type.contains('DISTRACCIÓN') ||
           type.contains('CELULAR') ||
           type.contains('MIRADA');
  }

  static bool isRecklessAlert(String type) {
    return type.contains('TEMERARIA') ||
           type.contains('FRENADA');
  }

  static bool isEmergencyAlert(String type, String severity) {
    return type.contains('IMPACTO') ||
           severity == 'CRITICAL';
  }

  static List<Map<String, String>> getRandomEvents() {
    return [
      {'type': 'DISTRACCIÓN', 'severity': 'MEDIUM'},
      {'type': 'MIRADA FUERA', 'severity': 'MEDIUM'},
      {'type': 'USO DE CELULAR', 'severity': 'HIGH'},
      {'type': 'FRENADA BRUSCA', 'severity': 'MEDIUM'},
      {'type': 'CONDUCCIÓN TEMERARIA', 'severity': 'HIGH'},
    ];
  }
}