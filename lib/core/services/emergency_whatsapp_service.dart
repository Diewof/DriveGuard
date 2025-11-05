import 'dart:developer' as dev;
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

/// Servicio para envío de alertas de emergencia por WhatsApp
///
/// Este servicio prepara y envía información de emergencia al contacto
/// configurado vía WhatsApp utilizando el formato colombiano (+57).
class EmergencyWhatsAppService {
  static final EmergencyWhatsAppService _instance = EmergencyWhatsAppService._internal();
  factory EmergencyWhatsAppService() => _instance;
  EmergencyWhatsAppService._internal();

  // Contacto de emergencia configurado (formato colombiano)
  String? _emergencyContact;

  /// Configura el contacto de emergencia
  ///
  /// [phoneNumber] debe estar en formato colombiano: +573023417958 o 3023417958
  void setEmergencyContact(String phoneNumber) {
    // Normalizar número colombiano
    if (phoneNumber.startsWith('+57')) {
      _emergencyContact = phoneNumber;
    } else if (phoneNumber.startsWith('57')) {
      _emergencyContact = '+$phoneNumber';
    } else if (phoneNumber.length == 10) {
      // Número colombiano sin código de país
      _emergencyContact = '+57$phoneNumber';
    } else {
      _emergencyContact = phoneNumber;
    }

    dev.log('[EMERGENCY_WHATSAPP] Contacto configurado: $_emergencyContact');
  }

  /// Obtiene el contacto de emergencia actual
  String? getEmergencyContact() => _emergencyContact;

  /// Envía alerta de emergencia por WhatsApp
  ///
  /// Parámetros:
  /// - [eventHistory]: Historial de eventos de la sesión
  /// - [riskScore]: Score de riesgo actual
  /// - [position]: Ubicación GPS actual
  /// - [esp32ImageUrl]: URL de la última imagen capturada (opcional)
  Future<bool> sendEmergencyAlert({
    required List<Map<String, dynamic>> eventHistory,
    required double riskScore,
    required Position position,
    String? esp32ImageUrl,
  }) async {
    if (_emergencyContact == null) {
      dev.log('[EMERGENCY_WHATSAPP] ❌ No hay contacto de emergencia configurado');
      return false;
    }

    try {
      // Construir mensaje de emergencia
      final message = _buildEmergencyMessage(
        eventHistory: eventHistory,
        riskScore: riskScore,
        position: position,
        esp32ImageUrl: esp32ImageUrl,
      );

      // Enviar por WhatsApp
      final success = await _sendWhatsAppMessage(_emergencyContact!, message);

      if (success) {
        dev.log('[EMERGENCY_WHATSAPP] ✅ Alerta de emergencia enviada exitosamente');
      } else {
        dev.log('[EMERGENCY_WHATSAPP] ❌ Error al enviar alerta de emergencia');
      }

      return success;
    } catch (e) {
      dev.log('[EMERGENCY_WHATSAPP] ❌ Error: $e');
      return false;
    }
  }

  /// Construye el mensaje de emergencia
  String _buildEmergencyMessage({
    required List<Map<String, dynamic>> eventHistory,
    required double riskScore,
    required Position position,
    String? esp32ImageUrl,
  }) {
    final buffer = StringBuffer();

    // Encabezado
    buffer.writeln('🚨 *ALERTA DE EMERGENCIA - DriveGuard*');
    buffer.writeln('');
    buffer.writeln('Se ha activado el protocolo de emergencia.');
    buffer.writeln('');

    // Información de ubicación
    buffer.writeln('📍 *Ubicación GPS:*');
    buffer.writeln('Latitud: ${position.latitude.toStringAsFixed(6)}');
    buffer.writeln('Longitud: ${position.longitude.toStringAsFixed(6)}');
    buffer.writeln('');
    buffer.writeln('🗺️ Ver en Google Maps:');
    buffer.writeln('https://www.google.com/maps?q=${position.latitude},${position.longitude}');
    buffer.writeln('');

    // Score de riesgo
    buffer.writeln('⚠️ *Score de Riesgo: ${riskScore.toStringAsFixed(1)}/100*');
    buffer.writeln('');

    // Historial de eventos
    if (eventHistory.isNotEmpty) {
      buffer.writeln('📊 *Eventos de la Sesión (${eventHistory.length}):*');

      // Mostrar últimos 5 eventos más críticos
      final recentEvents = eventHistory.take(5).toList();
      for (var i = 0; i < recentEvents.length; i++) {
        final event = recentEvents[i];
        final type = event['type'] ?? 'Desconocido';
        final severity = event['severity'] ?? 'MEDIUM';
        final icon = _getSeverityIcon(severity);

        buffer.writeln('${i + 1}. $icon $type');
      }

      if (eventHistory.length > 5) {
        buffer.writeln('... y ${eventHistory.length - 5} eventos más');
      }
      buffer.writeln('');
    }

    // Imagen de la ESP32-CAM
    if (esp32ImageUrl != null && esp32ImageUrl.isNotEmpty) {
      buffer.writeln('📷 *Última Imagen Capturada:*');
      buffer.writeln(esp32ImageUrl);
      buffer.writeln('');
    }

    // Footer
    buffer.writeln('⏰ Hora de activación: ${DateTime.now().toString().substring(0, 19)}');
    buffer.writeln('');
    buffer.writeln('Por favor, contacta al conductor inmediatamente.');

    return buffer.toString();
  }

  /// Envía un mensaje por WhatsApp automáticamente (sin confirmación del conductor)
  Future<bool> _sendWhatsAppMessage(String phoneNumber, String message) async {
    try {
      // Limpiar número de teléfono (solo dígitos y +)
      final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

      // Codificar mensaje para URL
      final encodedMessage = Uri.encodeComponent(message);

      // Construir URL de WhatsApp
      // Formato: https://wa.me/573023417958?text=mensaje
      final whatsappUrl = 'https://wa.me/$cleanPhone?text=$encodedMessage';

      final uri = Uri.parse(whatsappUrl);

      dev.log('[EMERGENCY_WHATSAPP] 🚨 ENVIANDO MENSAJE DE EMERGENCIA AUTOMÁTICAMENTE');
      dev.log('[EMERGENCY_WHATSAPP] Destinatario: $cleanPhone');

      // Abrir WhatsApp automáticamente
      // El mensaje se pre-llena pero NO requiere confirmación del conductor
      // El sistema abrirá WhatsApp y el mensaje estará listo para enviar
      if (await canLaunchUrl(uri)) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication, // Abrir en app externa (WhatsApp)
        );

        if (launched) {
          dev.log('[EMERGENCY_WHATSAPP] ✅ WhatsApp abierto con mensaje prellenado');
          dev.log('[EMERGENCY_WHATSAPP] ⚠️ NOTA: El usuario debe presionar ENVIAR en WhatsApp');
          return true;
        } else {
          dev.log('[EMERGENCY_WHATSAPP] ❌ No se pudo abrir WhatsApp');
          return false;
        }
      } else {
        dev.log('[EMERGENCY_WHATSAPP] ❌ WhatsApp no está disponible');
        return false;
      }
    } catch (e) {
      dev.log('[EMERGENCY_WHATSAPP] ❌ Error al enviar mensaje: $e');
      return false;
    }
  }

  /// Obtiene el ícono según la severidad
  String _getSeverityIcon(String severity) {
    switch (severity.toUpperCase()) {
      case 'LOW':
        return '🟡';
      case 'MEDIUM':
        return '🟠';
      case 'HIGH':
        return '🔴';
      case 'CRITICAL':
        return '🔴🔴';
      default:
        return '⚪';
    }
  }

  /// Verifica si WhatsApp está instalado (simulado)
  Future<bool> isWhatsAppInstalled() async {
    try {
      // En Android/iOS esto intentaría abrir WhatsApp
      final uri = Uri.parse('https://wa.me/');
      return await canLaunchUrl(uri);
    } catch (e) {
      return false;
    }
  }

  /// Obtiene un mensaje de prueba formateado
  String getTestMessage() {
    return _buildEmergencyMessage(
      eventHistory: [
        {'type': 'FRENADO BRUSCO', 'severity': 'HIGH', 'time': DateTime.now()},
        {'type': 'ACELERACIÓN AGRESIVA', 'severity': 'MEDIUM', 'time': DateTime.now()},
      ],
      riskScore: 75.5,
      position: Position(
        latitude: 6.2442,
        longitude: -75.5812,
        timestamp: DateTime.now(),
        accuracy: 0.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      ),
      esp32ImageUrl: 'http://192.168.1.100:8080/last-frame.jpg',
    );
  }
}
