# API del Servidor HTTP - DriveGuard

Documentación completa del servidor HTTP embebido que recibe frames del ESP32-CAM.

---

## 📡 Descripción General

DriveGuard incluye un servidor HTTP ligero construido con **Shelf** (Dart) que corre directamente en el dispositivo móvil. Este servidor recibe imágenes codificadas en Base64 desde el ESP32-CAM para procesamiento y visualización en tiempo real.

### Características

- ✅ Puerto configurable (8080 por defecto con fallback automático)
- ✅ Detección automática de IP local
- ✅ Validación de payload y formato
- ✅ Gestión eficiente de memoria
- ✅ CORS habilitado para testing
- ✅ Endpoints RESTful

---

## 🚀 Inicio del Servidor

### Inicialización

El servidor se inicia desde `HttpServerService`:

```dart
final httpServerService = HttpServerService();
await httpServerService.startServer();
```

**Proceso de Inicio:**
1. Detecta IP local del dispositivo (WiFi prioritario)
2. Intenta iniciar en puerto 8080
3. Si ocupado, prueba 8081, 8082, etc.
4. Configura rutas y middlewares
5. Emite evento de éxito con dirección completa

### Configuración de Puertos

```dart
// Puerto por defecto
static const int DEFAULT_PORT = 8080;

// Fallback automático
int _currentPort = DEFAULT_PORT;
while (_currentPort < DEFAULT_PORT + 10) {
  try {
    await shelf_io.serve(handler, address, _currentPort);
    break;
  } catch (e) {
    _currentPort++;
  }
}
```

---

## 📋 Endpoints

### 1. POST /upload

Recibe imágenes desde ESP32-CAM.

#### Request

**Headers:**
```http
POST /upload HTTP/1.1
Host: <IP_SMARTPHONE>:8080
Content-Type: application/json
Content-Length: <size>
```

**Body (JSON):**
```json
{
  "image": "string (Base64)",  // Imagen JPEG en Base64
  "timestamp": number          // Timestamp del ESP32 en ms
}
```

**Validaciones:**
- `Content-Type` debe ser `application/json`
- Campos `image` y `timestamp` son **requeridos**
- `image` debe ser Base64 válido
- Imagen decodificada debe ser JPEG (magic bytes: `FF D8`)
- Tamaño máximo: **500 KB** (decodificado)

#### Response

**Éxito (200 OK):**
```json
{
  "status": "success",
  "receivedAt": "2025-10-19T14:23:45.123Z",  // ISO 8601
  "frameNumber": 127                          // Contador incremental
}
```

**Errores:**

**400 Bad Request - JSON Inválido:**
```json
{
  "error": "JSON inválido. Se requieren campos: image, timestamp"
}
```

**400 Bad Request - Base64 Corrupto:**
```json
{
  "error": "Base64 inválido: Invalid character found at position 1234"
}
```

**400 Bad Request - No es JPEG:**
```json
{
  "error": "No es una imagen JPEG válida"
}
```

**413 Payload Too Large:**
```json
{
  "error": "Imagen demasiado grande (max 500KB)"
}
```

**500 Internal Server Error:**
```json
{
  "error": "Error interno: <descripción>"
}
```

#### Ejemplo con cURL

```bash
curl -X POST http://192.168.1.100:8080/upload \
  -H "Content-Type: application/json" \
  -d '{
    "image": "/9j/4AAQSkZJRgABAQEASABIAAD...",
    "timestamp": 12345
  }'
```

---

### 2. GET /status

Verifica estado del servidor y estadísticas.

#### Request

```http
GET /status HTTP/1.1
Host: <IP_SMARTPHONE>:8080
```

#### Response

**200 OK:**
```json
{
  "status": "online",
  "serverAddress": "192.168.1.100:8080",
  "framesReceived": 127,
  "lastFrameAt": "2025-10-19T14:23:45.123Z",  // null si no hay frames
  "uptime": 3600,                              // Segundos desde inicio
  "memoryUsage": "45.2 KB"                     // Tamaño del último frame
}
```

#### Ejemplo con cURL

```bash
curl http://192.168.1.100:8080/status
```

---

### 3. GET /health

Health check simple para monitoreo.

#### Request

```http
GET /health HTTP/1.1
Host: <IP_SMARTPHONE>:8080
```

#### Response

**200 OK:**
```json
{
  "status": "healthy"
}
```

---

## 🔒 Validaciones y Seguridad

### Validación de Formato JPEG

```dart
bool _isValidJpeg(Uint8List bytes) {
  if (bytes.length < 2) return false;

  // Magic bytes JPEG: FF D8
  return bytes[0] == 0xFF && bytes[1] == 0xD8;
}
```

**Bytes de Verificación:**
- **JPEG:** `FF D8 FF ...`
- **PNG:** `89 50 4E 47 ...` (rechazado)
- **BMP:** `42 4D ...` (rechazado)

### Límite de Tamaño

```dart
const int MAX_IMAGE_SIZE = 500 * 1024; // 500 KB

if (decodedBytes.length > MAX_IMAGE_SIZE) {
  return Response(413, body: jsonEncode({
    'error': 'Imagen demasiado grande (max 500KB)'
  }));
}
```

### CORS Headers

```dart
Response _addCorsHeaders(Response response) {
  return response.change(headers: {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
  });
}
```

**Nota:** En producción, reemplazar `*` por dominio específico.

---

## 🔄 Gestión de Memoria

### Estrategia

El servidor mantiene **solo el último frame** en memoria para evitar consumo excesivo.

```dart
class HttpServerService {
  CameraFrame? _lastFrame;  // Solo 1 frame en RAM

  void _handleNewFrame(CameraFrame frame) {
    _lastFrame = frame;  // Reemplaza anterior
    _frameController.add(frame);  // Emite a stream
  }
}
```

**Ventajas:**
- Consumo de memoria constante (~50 KB)
- Sin memory leaks en sesiones largas
- Rendimiento predecible

### Limpieza al Detener

```dart
Future<void> stopServer() async {
  await _server?.close(force: true);
  await _frameController.close();
  _lastFrame = null;  // Libera memoria
  _server = null;
}
```

---

## 📊 Flujo de Datos

### Diagrama de Secuencia

```
ESP32-CAM                 Smartphone (Server)           CameraStreamBloc
    |                            |                             |
    |--- POST /upload ---------->|                             |
    |    {image, timestamp}      |                             |
    |                            |                             |
    |                            |--[1] Validar JSON---------->|
    |                            |<---[OK/Error]---------------|
    |                            |                             |
    |                            |--[2] Decodificar Base64---->|
    |                            |<---[Bytes/Error]------------|
    |                            |                             |
    |                            |--[3] Validar JPEG---------->|
    |                            |<---[OK/Error]---------------|
    |                            |                             |
    |                            |--[4] Validar Tamaño-------->|
    |                            |<---[OK/Error]---------------|
    |                            |                             |
    |                            |--[5] Crear CameraFrame----->|
    |                            |                             |
    |                            |--[6] Emitir a Stream------->|
    |                            |                             |
    |<--- 200 OK ----------------|                             |
    |    {status, receivedAt}    |                             |
    |                            |                             |
    |                            |                        [7] BLoC recibe
    |                            |                        [8] Actualiza estado
    |                            |                        [9] UI se redibuja
```

---

## 🌐 Detección de IP Local

### Algoritmo de Detección

```dart
Future<String> _getLocalIpAddress() async {
  try {
    // Obtener todas las interfaces de red
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLinkLocal: false,
    );

    // Priorizar WiFi sobre datos móviles
    for (var interface in interfaces) {
      if (interface.name.contains('wlan') ||
          interface.name.contains('en0')) {
        for (var addr in interface.addresses) {
          return addr.address;  // Retorna primera IP WiFi
        }
      }
    }

    // Fallback a cualquier interfaz válida
    for (var interface in interfaces) {
      for (var addr in interface.addresses) {
        if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
          return addr.address;
        }
      }
    }

    return '0.0.0.0';  // No se encontró IP
  } catch (e) {
    return '0.0.0.0';
  }
}
```

**Priorización:**
1. **WiFi** (`wlan0`, `en0`) - Preferido para ESP32
2. **Ethernet** (`eth0`) - Si está disponible
3. **Móvil** (`rmnet_data0`) - Último recurso
4. **Loopback** (`127.0.0.1`) - Ignorado

---

## 📈 Monitoreo y Logs

### Niveles de Log

```dart
enum LogLevel {
  INFO,    // Operaciones normales
  WARNING, // Advertencias no críticas
  ERROR    // Errores que requieren atención
}
```

### Ejemplos de Logs

**Inicio del Servidor:**
```
[INFO] Servidor HTTP iniciado en http://192.168.1.100:8080
[INFO] Esperando conexión del ESP32-CAM...
```

**Frame Recibido:**
```
[INFO] 📸 Frame recibido #127 (45123 bytes, timestamp: 12345)
```

**Errores:**
```
[ERROR] ❌ Base64 inválido: Invalid character found at position 1234
[ERROR] ❌ Imagen demasiado grande: 750 KB (max 500 KB)
[WARNING] ⚠️ Puerto 8080 ocupado, probando 8081...
```

---

## 🔧 Configuración Avanzada

### Cambiar Puerto Predeterminado

```dart
class AppConstants {
  static const int httpServerPort = 9000;  // Cambiar aquí
}
```

### Ajustar Límite de Tamaño

```dart
const int MAX_IMAGE_SIZE = 1024 * 1024; // 1 MB
```

### Deshabilitar CORS (Producción)

```dart
Response _addCorsHeaders(Response response) {
  // Comentar para deshabilitar CORS
  // return response.change(headers: {...});
  return response;
}
```

### Timeout de Requests

```dart
final server = await shelf_io.serve(
  handler,
  address,
  port,
  shared: false,
).timeout(Duration(seconds: 5));  // 5 segundos timeout
```

---

## 🧪 Testing del API

### Test con Postman

**1. Crear Request POST:**
- URL: `http://192.168.1.100:8080/upload`
- Method: POST
- Headers:
  - `Content-Type: application/json`
- Body (raw JSON):
```json
{
  "image": "/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAAEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/2wBDAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/wAARCAACAAIDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwCwAA==",
  "timestamp": 12345
}
```

**2. Verificar Response:**
- Status: 200 OK
- Body contiene `"status": "success"`

### Test con Script Python

```python
import requests
import base64

# Leer imagen local
with open('test_image.jpg', 'rb') as f:
    image_bytes = f.read()
    image_base64 = base64.b64encode(image_bytes).decode('utf-8')

# Construir payload
payload = {
    'image': image_base64,
    'timestamp': 12345
}

# Enviar POST
response = requests.post(
    'http://192.168.1.100:8080/upload',
    json=payload,
    headers={'Content-Type': 'application/json'}
)

print(f"Status: {response.status_code}")
print(f"Body: {response.json()}")
```

### Test con Flutter Integration Test

```dart
test('Server recibe y valida frame correctamente', () async {
  final service = HttpServerService();
  await service.startServer();

  // Crear imagen de prueba
  final testImage = Uint8List.fromList([
    0xFF, 0xD8, 0xFF, 0xE0, // JPEG header
    ...List.filled(100, 0x00), // Datos dummy
  ]);
  final base64Image = base64Encode(testImage);

  // Enviar POST
  final response = await http.post(
    Uri.parse('http://localhost:8080/upload'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'image': base64Image,
      'timestamp': 12345,
    }),
  );

  expect(response.statusCode, 200);
  final body = jsonDecode(response.body);
  expect(body['status'], 'success');

  await service.stopServer();
});
```

---

## 🚨 Troubleshooting

### Problema: "Address already in use"

**Causa:** Puerto 8080 ocupado por otra aplicación.

**Solución:**
```bash
# Android (con adb)
adb shell netstat -tulnp | grep 8080

# iOS (con ifconfig)
lsof -i :8080

# Cerrar proceso o usar fallback automático (8081, 8082...)
```

### Problema: ESP32 no puede conectarse

**Verificar:**
1. Misma red WiFi:
   ```bash
   # En Android
   adb shell ip addr show wlan0

   # En ESP32 (Serial Monitor)
   Serial.println(WiFi.localIP());
   ```

2. Ping desde ESP32:
   ```cpp
   WiFiClient client;
   if (client.connect(FLUTTER_IP, FLUTTER_PORT)) {
     Serial.println("Conexión OK");
   } else {
     Serial.println("No se puede conectar");
   }
   ```

3. Firewall:
   - Verificar que el firewall del smartphone no bloquee puerto 8080

### Problema: Imágenes no se muestran

**Verificar:**
1. Base64 válido:
   ```dart
   try {
     base64Decode(imageString);
   } catch (e) {
     print('Base64 inválido: $e');
   }
   ```

2. Magic bytes JPEG:
   ```dart
   final bytes = base64Decode(imageString);
   print('First bytes: ${bytes.sublist(0, 4)}');
   // Debe mostrar: [255, 216, 255, ...]
   ```

3. Logs de Flutter:
   ```bash
   flutter logs | grep "📸"
   ```

---

## 📞 Integración con BLoC

### CameraStreamBloc

```dart
class CameraStreamBloc extends Bloc<CameraStreamEvent, CameraStreamState> {
  final HttpServerService _httpServerService;
  StreamSubscription? _frameSubscription;

  CameraStreamBloc(this._httpServerService) : super(CameraStreamInitial()) {
    on<CameraStreamStart>(_onStart);
    on<CameraStreamNewFrame>(_onNewFrame);
    on<CameraStreamStop>(_onStop);
  }

  Future<void> _onStart(
    CameraStreamStart event,
    Emitter<CameraStreamState> emit,
  ) async {
    try {
      emit(CameraStreamLoading());

      await _httpServerService.startServer();
      final address = _httpServerService.serverAddress;

      // Escuchar frames
      _frameSubscription = _httpServerService.frameStream.listen(
        (frame) => add(CameraStreamNewFrame(frame)),
      );

      emit(CameraStreamConnected(serverAddress: address));
    } catch (e) {
      emit(CameraStreamError(e.toString()));
    }
  }

  void _onNewFrame(
    CameraStreamNewFrame event,
    Emitter<CameraStreamState> emit,
  ) {
    final currentState = state;
    if (currentState is CameraStreamConnected) {
      emit(currentState.copyWith(
        lastFrame: event.frame,
        frameCount: currentState.frameCount + 1,
      ));
    }
  }
}
```

---

## 🔮 Futuras Mejoras

### Autenticación

```dart
// Agregar token de autenticación
final token = 'secret_token_123';

// En ESP32
http.addHeader('Authorization', 'Bearer $token');

// En servidor
if (request.headers['authorization'] != 'Bearer $token') {
  return Response.unauthorized('Token inválido');
}
```

### Compresión

```dart
import 'package:archive/archive.dart';

// Comprimir antes de enviar (ESP32)
final compressed = ZLibEncoder().encode(imageBytes);

// Descomprimir en servidor
final decompressed = ZLibDecoder().decode(compressed);
```

### Rate Limiting

```dart
final _requestCounts = <String, int>{};

bool _checkRateLimit(String ip) {
  final count = _requestCounts[ip] ?? 0;
  if (count > 100) {  // Max 100 requests por minuto
    return false;
  }
  _requestCounts[ip] = count + 1;
  return true;
}
```

---

**API Lista para Integración!** 🚀

Para integrar con ESP32-CAM, consulta [ESP32_INTEGRATION_GUIDE.md](../../03-hardware/ESP32_INTEGRATION_GUIDE.md).
