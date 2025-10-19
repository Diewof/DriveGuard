import 'dart:async';
import 'dart:convert';
import 'package:udp/udp.dart';

/// Servicio para auto-descubrimiento del ESP32-CAM mediante broadcasts UDP
class NetworkDiscoveryService {
  static const int broadcastPort = 8888;
  static const Duration broadcastInterval = Duration(seconds: 2);

  UDP? _sender;
  Timer? _broadcastTimer;
  final _esp32ConnectedController = StreamController<String>.broadcast();
  bool _isActive = false;
  String? _currentServerIp;
  int? _currentServerPort;

  /// Stream que notifica cuando se detecta un ESP32 conectado (emite la IP del ESP32)
  Stream<String> get esp32ConnectedStream => _esp32ConnectedController.stream;

  /// Indica si el broadcast está activo
  bool get isActive => _isActive;

  /// IP actual del servidor
  String? get serverIp => _currentServerIp;

  /// Puerto actual del servidor
  int? get serverPort => _currentServerPort;

  /// Inicia el broadcasting UDP
  ///
  /// [serverIp] - IP local del servidor HTTP de la app
  /// [serverPort] - Puerto del servidor HTTP de la app (típicamente 8080)
  Future<void> startBroadcasting({
    required String serverIp,
    required int serverPort,
  }) async {
    if (_isActive) {
      print('⚠️ Broadcasting ya está activo');
      return;
    }

    try {
      _currentServerIp = serverIp;
      _currentServerPort = serverPort;

      // Crear emisor UDP
      _sender = await UDP.bind(Endpoint.any(port: const Port(0)));

      _isActive = true;
      print('✅ Broadcasting UDP iniciado en puerto $broadcastPort');
      print('📡 Enviando broadcasts cada ${broadcastInterval.inSeconds}s con IP: $serverIp:$serverPort');

      // Iniciar timer para broadcasts periódicos
      _broadcastTimer = Timer.periodic(broadcastInterval, (_) async {
        await _sendBroadcast();
      });

      // Enviar primer broadcast inmediatamente
      await _sendBroadcast();
    } catch (e) {
      print('❌ Error iniciando broadcasting: $e');
      _isActive = false;
      rethrow;
    }
  }

  /// Detiene el broadcasting UDP
  Future<void> stopBroadcasting() async {
    if (!_isActive) {
      print('⚠️ Broadcasting no está activo');
      return;
    }

    try {
      _broadcastTimer?.cancel();
      _broadcastTimer = null;

      _sender?.close();
      _sender = null;

      _isActive = false;
      _currentServerIp = null;
      _currentServerPort = null;

      print('🛑 Broadcasting UDP detenido');
    } catch (e) {
      print('❌ Error deteniendo broadcasting: $e');
      rethrow;
    }
  }

  /// Envía un broadcast UDP con la información del servidor
  Future<void> _sendBroadcast() async {
    if (!_isActive || _sender == null) return;

    try {
      final message = json.encode({
        'type': 'DRIVEGUARD_SERVER',
        'ip': _currentServerIp,
        'port': _currentServerPort,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      final bytes = utf8.encode(message);

      // Enviar a dirección de broadcast
      await _sender!.send(
        bytes,
        Endpoint.broadcast(port: Port(broadcastPort)),
      );

      print('📤 Broadcast enviado: $message');
    } catch (e) {
      print('⚠️ Error enviando broadcast: $e');
    }
  }

  /// Notifica que un ESP32 se ha conectado (opcional)
  ///
  /// Este método puede ser llamado externamente cuando se detecta
  /// que el ESP32 ha empezado a enviar frames
  void notifyEsp32Connected(String esp32Ip) {
    if (!_esp32ConnectedController.isClosed) {
      _esp32ConnectedController.add(esp32Ip);
      print('🔗 ESP32 conectado desde: $esp32Ip');
    }
  }

  /// Libera recursos
  Future<void> dispose() async {
    await stopBroadcasting();
    await _esp32ConnectedController.close();
  }
}
