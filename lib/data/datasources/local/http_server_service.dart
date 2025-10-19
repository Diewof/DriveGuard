import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import '../../models/camera_frame.dart';
import '../../../core/services/network_discovery_service.dart';

/// Servicio que gestiona el servidor HTTP embebido para recibir imágenes del ESP32-CAM
class HttpServerService {
  static const int defaultPort = 8080;
  static const int maxPayloadSize = 500 * 1024; // 500KB
  static const Duration requestTimeout = Duration(seconds: 5);

  HttpServer? _server;
  final _frameController = StreamController<CameraFrame>.broadcast();
  final NetworkDiscoveryService _discoveryService;
  CameraFrame? _lastFrame;
  int _frameCount = 0;
  String? _serverAddress;
  String? _localIp;
  int? _currentPort;

  /// Constructor
  HttpServerService({NetworkDiscoveryService? discoveryService})
      : _discoveryService = discoveryService ?? NetworkDiscoveryService();

  /// Stream que emite frames cada vez que llega una imagen nueva
  Stream<CameraFrame> get frameStream => _frameController.stream;

  /// Último frame recibido
  CameraFrame? get lastFrame => _lastFrame;

  /// Contador de frames recibidos
  int get frameCount => _frameCount;

  /// Dirección del servidor (IP:puerto)
  String? get serverAddress => _serverAddress;

  /// Indica si el servidor está activo
  bool get isRunning => _server != null;

  /// Stream que notifica cuando se conecta un ESP32
  Stream<String> get esp32ConnectedStream => _discoveryService.esp32ConnectedStream;

  /// Retorna información actual del servidor
  Map<String, dynamic> getServerInfo() {
    return {
      'ip': _localIp,
      'port': _currentPort,
      'address': _serverAddress,
      'isRunning': isRunning,
    };
  }

  /// Inicia el servidor HTTP en el puerto especificado
  Future<void> startServer({int port = defaultPort}) async {
    if (_server != null) {
      print('⚠️ Servidor ya está corriendo en $_serverAddress');
      return;
    }

    try {
      // Configurar router con Shelf
      final router = Router();

      // Endpoint POST /upload para recibir imágenes
      router.post('/upload', _handleImageUpload);

      // Endpoint GET /status para verificar estado del servidor
      router.get('/status', _handleStatusCheck);

      // Handler con middleware de logging
      final handler = Pipeline()
          .addMiddleware(logRequests())
          .addMiddleware(_corsMiddleware())
          .addHandler(router);

      // Obtener IP local
      final ip = await _getLocalIpAddress();

      // Iniciar servidor
      _server = await shelf_io.serve(
        handler,
        ip,
        port,
      );

      _localIp = _server!.address.address;
      _currentPort = _server!.port;
      _serverAddress = '$_localIp:$_currentPort';

      print('✅ Servidor HTTP iniciado en http://$_serverAddress');
      print('📡 Esperando conexión del ESP32-CAM...');

      // Iniciar broadcasting UDP para auto-descubrimiento
      await _discoveryService.startBroadcasting(
        serverIp: _localIp!,
        serverPort: _currentPort!,
      );
    } catch (e) {
      print('❌ Error al iniciar servidor: $e');

      // Si el puerto está ocupado, intentar con puertos alternativos
      if (e.toString().contains('Address already in use')) {
        print('🔄 Puerto $port ocupado, intentando con puerto alternativo...');
        await startServer(port: port + 1);
      } else {
        rethrow;
      }
    }
  }

  /// Detiene el servidor HTTP
  Future<void> stopServer() async {
    if (_server == null) {
      print('⚠️ Servidor no está corriendo');
      return;
    }

    try {
      // Detener broadcasting UDP
      await _discoveryService.stopBroadcasting();

      await _server!.close(force: true);
      _server = null;
      _serverAddress = null;
      _localIp = null;
      _currentPort = null;
      print('🛑 Servidor HTTP detenido');
    } catch (e) {
      print('❌ Error al detener servidor: $e');
      rethrow;
    }
  }

  /// Handler para el endpoint POST /upload
  Future<Response> _handleImageUpload(Request request) async {
    try {
      // Verificar Content-Type
      final contentType = request.headers['content-type'];
      if (contentType == null || !contentType.contains('application/json')) {
        return Response.badRequest(
          body: json.encode({'error': 'Content-Type debe ser application/json'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Leer y parsear JSON
      final bodyString = await request.readAsString();

      // Validar tamaño del payload
      if (bodyString.length > maxPayloadSize) {
        return Response(
          413, // Payload Too Large
          body: json.encode({'error': 'Imagen demasiado grande (max ${maxPayloadSize / 1024}KB)'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      final Map<String, dynamic> body = json.decode(bodyString);

      // Validar estructura del JSON
      if (!body.containsKey('image') || !body.containsKey('timestamp')) {
        return Response.badRequest(
          body: json.encode({'error': 'JSON inválido. Se requieren campos: image, timestamp'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Decodificar imagen Base64
      final String base64Image = body['image'] as String;
      final int timestamp = body['timestamp'] as int;

      Uint8List imageBytes;
      try {
        imageBytes = base64Decode(base64Image);
      } catch (e) {
        return Response.badRequest(
          body: json.encode({'error': 'Base64 inválido: $e'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Validar que los bytes decodificados correspondan a una imagen JPEG
      if (imageBytes.length < 2 ||
          imageBytes[0] != 0xFF ||
          imageBytes[1] != 0xD8) {
        return Response.badRequest(
          body: json.encode({'error': 'No es una imagen JPEG válida'}),
          headers: {'Content-Type': 'application/json'},
        );
      }

      // Crear CameraFrame
      final frame = CameraFrame.fromDecodedBytes(
        bytes: imageBytes,
        esp32Timestamp: timestamp,
      );

      // Liberar frame anterior (gestión de memoria)
      _lastFrame = null;

      // Guardar nuevo frame
      _lastFrame = frame;
      _frameCount++;

      // Emitir frame al stream
      if (!_frameController.isClosed) {
        _frameController.add(frame);
      }

      print('📸 Frame recibido #$_frameCount (${imageBytes.length} bytes, timestamp: $timestamp)');

      // Responder al ESP32
      return Response.ok(
        json.encode({
          'status': 'success',
          'receivedAt': DateTime.now().toIso8601String(),
          'frameNumber': _frameCount,
        }),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e, stackTrace) {
      print('❌ Error procesando imagen: $e');
      print('Stack trace: $stackTrace');

      return Response.internalServerError(
        body: json.encode({'error': 'Error interno: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  /// Handler para el endpoint GET /status
  Response _handleStatusCheck(Request request) {
    return Response.ok(
      json.encode({
        'status': 'online',
        'serverAddress': _serverAddress,
        'framesReceived': _frameCount,
        'lastFrameAt': _lastFrame?.receivedAt.toIso8601String(),
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// Middleware CORS para permitir peticiones desde cualquier origen
  Middleware _corsMiddleware() {
    return (handler) {
      return (request) async {
        // Manejar preflight OPTIONS
        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: _corsHeaders);
        }

        // Agregar headers CORS a todas las respuestas
        final response = await handler(request);
        return response.change(headers: _corsHeaders);
      };
    };
  }

  /// Headers CORS
  Map<String, String> get _corsHeaders => {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type',
      };

  /// Obtiene la dirección IP local del dispositivo
  Future<String> _getLocalIpAddress() async {
    try {
      // Obtener todas las interfaces de red
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      // Buscar interfaz WiFi o la primera disponible
      for (final interface in interfaces) {
        // Priorizar WiFi (wlan0 en Android)
        if (interface.name.toLowerCase().contains('wlan') ||
            interface.name.toLowerCase().contains('wifi')) {
          for (final addr in interface.addresses) {
            if (!addr.isLoopback) {
              return addr.address;
            }
          }
        }
      }

      // Si no hay WiFi, usar la primera interfaz no-loopback
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback) {
            return addr.address;
          }
        }
      }

      // Fallback a localhost
      return InternetAddress.anyIPv4.address;
    } catch (e) {
      print('⚠️ Error obteniendo IP local: $e');
      return InternetAddress.anyIPv4.address;
    }
  }

  /// Libera recursos
  Future<void> dispose() async {
    await stopServer();
    await _discoveryService.dispose();
    await _frameController.close();
    _lastFrame = null;
  }
}
