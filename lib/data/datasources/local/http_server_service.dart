import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import '../../models/camera_frame.dart';

/// Servicio que gestiona el servidor HTTP embebido para recibir imágenes del ESP32-CAM
class HttpServerService {
  static const int defaultPort = 8080;
  static const int maxPayloadSize = 500 * 1024; // 500KB
  static const Duration requestTimeout = Duration(seconds: 5);

  HttpServer? _server;
  final _frameController = StreamController<CameraFrame>.broadcast();
  final _esp32ConnectedController = StreamController<String>.broadcast();
  CameraFrame? _lastFrame;
  int _frameCount = 0;
  String? _serverAddress;
  String? _localIp;
  int? _currentPort;

  /// Constructor
  HttpServerService();

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
  Stream<String> get esp32ConnectedStream => _esp32ConnectedController.stream;

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

      // Endpoint POST /handshake para auto-descubrimiento del ESP32
      router.post('/handshake', _handleHandshake);

      // Handler con middleware de logging
      final handler = Pipeline()
          .addMiddleware(logRequests())
          .addMiddleware(_corsMiddleware())
          .addHandler(router);

      // Escuchar en TODAS las interfaces de red (0.0.0.0)
      // Esto es necesario cuando el celular tiene múltiples interfaces activas:
      // - Interfaz de datos móviles (ej: 10.77.173.173)
      // - Interfaz de hotspot WiFi (ej: 10.220.212.167)
      _server = await shelf_io.serve(
        handler,
        InternetAddress.anyIPv4, // 0.0.0.0 - escucha en TODAS las interfaces
        port,
      );

      _currentPort = _server!.port;

      // Obtener IPs de todas las interfaces para mostrar al usuario
      final ips = await _getAllIpAddresses();
      _localIp = ips.isNotEmpty ? ips.first : '0.0.0.0';
      _serverAddress = '0.0.0.0:$_currentPort';

      print('✅ Servidor HTTP iniciado en puerto $_currentPort');
      print('📡 Escuchando en TODAS las interfaces:');
      for (final ip in ips) {
        print('   • http://$ip:$_currentPort');
      }
      print('📡 Esperando conexión del ESP32-CAM (mediante gateway)...');
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

  /// Handler para el endpoint POST /handshake
  /// Permite que el ESP32 se anuncie y detecte el servidor
  Future<Response> _handleHandshake(Request request) async {
    try {
      final bodyString = await request.readAsString();
      final Map<String, dynamic> body = json.decode(bodyString);

      // Extraer información del ESP32
      final String? esp32Type = body['type'] as String?;
      final String? esp32Ip = body['ip'] as String?;
      final String? esp32Mac = body['mac'] as String?;

      if (esp32Type == 'ESP32_HANDSHAKE' && esp32Ip != null) {
        print('🤝 Handshake recibido del ESP32-CAM');
        print('   IP ESP32: $esp32Ip');
        if (esp32Mac != null) {
          print('   MAC: $esp32Mac');
        }

        // Notificar conexión del ESP32
        if (!_esp32ConnectedController.isClosed) {
          _esp32ConnectedController.add(esp32Ip);
        }

        return Response.ok(
          json.encode({
            'status': 'ok',
            'message': 'Handshake exitoso',
            'serverIp': _localIp,
            'serverPort': _currentPort,
            'timestamp': DateTime.now().toIso8601String(),
          }),
          headers: {'Content-Type': 'application/json'},
        );
      } else {
        return Response.badRequest(
          body: json.encode({'error': 'Handshake inválido'}),
          headers: {'Content-Type': 'application/json'},
        );
      }
    } catch (e) {
      print('❌ Error en handshake: $e');
      return Response.internalServerError(
        body: json.encode({'error': 'Error procesando handshake: $e'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
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

  /// Obtiene todas las direcciones IP locales del dispositivo
  Future<List<String>> _getAllIpAddresses() async {
    try {
      final List<String> ipAddresses = [];

      // Obtener todas las interfaces de red
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback) {
            ipAddresses.add(addr.address);
          }
        }
      }

      return ipAddresses;
    } catch (e) {
      print('⚠️ Error obteniendo IPs locales: $e');
      return ['0.0.0.0'];
    }
  }

  /// Libera recursos
  Future<void> dispose() async {
    await stopServer();
    await _frameController.close();
    await _esp32ConnectedController.close();
    _lastFrame = null;
  }
}
