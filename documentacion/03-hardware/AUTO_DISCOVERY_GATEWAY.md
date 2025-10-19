# Auto-Descubrimiento mediante Gateway

## Resumen

Nueva arquitectura de auto-descubrimiento que **NO requiere hardcodear IPs** y funciona correctamente con hotspots móviles que tienen **AP Isolation** habilitado.

## Problema Anterior

### Broadcasting UDP (método antiguo)

```
ESP32-CAM ←--UDP Broadcast--→ Flutter App
   |                              |
   └──────────────────────────────┘
   (Bloqueado por AP Isolation)
```

**Problemas:**
- AP Isolation en hotspots móviles bloquea comunicación peer-to-peer
- Broadcasting UDP no funciona entre clientes del mismo hotspot
- Requería hardcodear IPs como fallback

---

## Solución: Gateway como Servidor

### Arquitectura

```
┌─────────────────────────────────────────┐
│  Celular (Gateway del Hotspot)          │
│  IP: 192.168.43.1 (obtenida por DHCP)  │
│                                          │
│  ┌────────────────────────────────┐    │
│  │  Servidor HTTP Flutter          │    │
│  │  Puerto: 8080                   │    │
│  │                                  │    │
│  │  Endpoints:                     │    │
│  │  - POST /handshake (discovery)  │    │
│  │  - POST /upload (frames)        │    │
│  │  - GET /status                  │    │
│  └────────────────────────────────┘    │
└─────────────────────────────────────────┘
                    ▲
                    │
         ┌──────────┴──────────┐
         │   ESP32-CAM         │
         │                     │
         │  1. WiFi.begin()    │
         │  2. DHCP → IP       │
         │  3. DHCP → Gateway  │
         │  4. POST Gateway:8080/handshake │
         │  5. POST Gateway:8080/upload    │
         └─────────────────────┘
```

### Flujo de Conexión

#### 1. **ESP32 se conecta al WiFi**
```cpp
WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
// Credenciales: "DriveGuard" / "driveguard123"
```

#### 2. **ESP32 obtiene configuración de red automáticamente (DHCP)**
```cpp
IPAddress localIP = WiFi.localIP();      // Ej: 192.168.43.100
IPAddress gatewayIP = WiFi.gatewayIP();  // Ej: 192.168.43.1 ← Este es el celular!
```

#### 3. **ESP32 intenta handshake con el gateway**
```cpp
String handshakeUrl = "http://" + gatewayIP.toString() + ":8080/handshake";

http.POST({
  "type": "ESP32_HANDSHAKE",
  "ip": "192.168.43.100",
  "mac": "AA:BB:CC:DD:EE:FF"
});
```

#### 4. **Flutter responde al handshake**
```dart
// Endpoint: POST /handshake
Response _handleHandshake(Request request) {
  // Extrae IP del ESP32
  final esp32Ip = body['ip'];

  // Notifica al sistema que el ESP32 está conectado
  _discoveryService.notifyEsp32Connected(esp32Ip);

  return Response.ok({
    'status': 'ok',
    'message': 'Handshake exitoso'
  });
}
```

#### 5. **ESP32 comienza a enviar frames**
```cpp
String url = "http://" + gatewayIP.toString() + ":8080/upload";
http.POST(jsonPayload); // Cada 500ms
```

---

## Ventajas de esta Arquitectura

### ✅ No requiere hardcodear IPs
- ESP32 usa `WiFi.gatewayIP()` automáticamente
- El gateway **siempre** es el dispositivo que creó el hotspot

### ✅ Funciona con AP Isolation
- El gateway (celular) **no** está sujeto a AP Isolation
- Los clientes pueden comunicarse con el gateway libremente

### ✅ Solo requiere credenciales WiFi
```cpp
const char* WIFI_SSID = "DriveGuard";
const char* WIFI_PASSWORD = "driveguard123";
// ¡Eso es todo! No se necesita IP del servidor
```

### ✅ Detección automática bidireccional
- ESP32 detecta al servidor mediante handshake HTTP
- Flutter detecta al ESP32 cuando recibe el handshake

### ✅ Failover graceful
- Si el servidor no está corriendo, el ESP32 sigue intentando
- No hay crashes ni errores fatales

---

## Código Implementado

### ESP32-CAM (main.cpp)

#### Función de Auto-descubrimiento
```cpp
bool discoverServerViaGateway() {
  // Obtener Gateway IP (el celular)
  IPAddress gatewayIP = WiFi.gatewayIP();

  discoveredServerIP = gatewayIP.toString();
  discoveredServerPort = FLUTTER_APP_PORT;

  // Intentar handshake
  String handshakeUrl = "http://" + discoveredServerIP +
                        ":" + String(discoveredServerPort) + "/handshake";

  String payload = "{\"type\":\"ESP32_HANDSHAKE\",\"ip\":\"" +
                   WiFi.localIP().toString() + "\"}";

  int httpResponseCode = http.POST(payload);

  return (httpResponseCode > 0);
}
```

### Flutter (http_server_service.dart)

#### Endpoint de Handshake
```dart
Future<Response> _handleHandshake(Request request) async {
  final body = json.decode(await request.readAsString());

  if (body['type'] == 'ESP32_HANDSHAKE') {
    final esp32Ip = body['ip'];

    print('🤝 Handshake recibido del ESP32-CAM');
    print('   IP ESP32: $esp32Ip');

    // Notificar al sistema
    _discoveryService.notifyEsp32Connected(esp32Ip);

    return Response.ok({
      'status': 'ok',
      'message': 'Handshake exitoso',
      'serverIp': _localIp,
      'serverPort': _currentPort,
    });
  }
}
```

---

## Uso y Pruebas

### Configuración

#### 1. Crear Hotspot en el Celular
- **Nombre de red**: `DriveGuard`
- **Contraseña**: `driveguard123`

#### 2. Compilar y Subir ESP32-CAM
```bash
cd ESP32-CAM
pio run -t upload
```

#### 3. Iniciar App Flutter
```bash
flutter run
```

#### 4. Abrir Debug de Cámara
En la app Flutter:
- Menu lateral → "Debug Cámara ESP32"
- El servidor HTTP inicia automáticamente

### Logs Esperados

#### ESP32-CAM
```
╔════════════════════════════════════════╗
║     ESP32-CAM DriveGuard v2.0          ║
╚════════════════════════════════════════╝

[WiFi] Conectado
[WiFi] IP: 192.168.43.100

[Gateway] Iniciando auto-descubrimiento...
[DEBUG] Información de red:
  IP ESP32:  192.168.43.100
  Gateway:   192.168.43.1 ← Este es el celular!

[Gateway] Intentando conectar a 192.168.43.1:8080...

╔════════════════════════════════════════╗
║   SERVIDOR FLUTTER DETECTADO! ✓        ║
╚════════════════════════════════════════╝
  IP Gateway:  192.168.43.1
  Puerto:      8080
  HTTP Code:   200
```

#### Flutter App
```
✅ Servidor HTTP iniciado en puerto 8080
📡 Escuchando en TODAS las interfaces:
   • http://10.77.173.173:8080  (datos móviles)
   • http://10.220.212.167:8080 (hotspot WiFi)
📡 Esperando conexión del ESP32-CAM (mediante gateway)...

🤝 Handshake recibido del ESP32-CAM
   IP ESP32: 192.168.43.100

📸 Frame recibido #1 (45678 bytes, timestamp: 12345)
📸 Frame recibido #2 (46123 bytes, timestamp: 12846)
...
```

---

## Troubleshooting

### El ESP32 no se conecta al WiFi

**Causa**: Credenciales incorrectas o fuera de rango

**Solución**:
1. Verificar nombre y contraseña del hotspot
2. Acercar el ESP32 al celular
3. Revisar logs seriales del ESP32

### El handshake falla (HTTP Code: -1)

**Causa**: El servidor Flutter no está corriendo

**Solución**:
1. Abrir la app Flutter
2. Ir a "Debug Cámara ESP32"
3. El servidor inicia automáticamente

**Nota**: El ESP32 sigue intentando, no es un error fatal.

### Error "Connection reset by peer" (errno: 104)

**Causa**: El servidor HTTP estaba escuchando solo en la interfaz de datos móviles, no en la del hotspot

**Solución** (ya implementada):
- El servidor ahora escucha en `0.0.0.0` (todas las interfaces)
- Esto permite recibir conexiones tanto de:
  - Interfaz de datos móviles (ej: `10.77.173.173`)
  - Interfaz de hotspot WiFi (ej: `10.220.212.167`)

**Verificar**:
Los logs de Flutter deben mostrar múltiples IPs:
```
✅ Servidor HTTP iniciado en puerto 8080
📡 Escuchando en TODAS las interfaces:
   • http://10.77.173.173:8080
   • http://10.220.212.167:8080
```

### Las IPs están en diferentes subredes

**Causa**: El ESP32 se conectó a otra red WiFi

**Solución**:
1. Verificar credenciales en `main.cpp`
2. Borrar redes guardadas en el ESP32: `WiFi.disconnect(true)`
3. Reiniciar el ESP32

---

## Comparación: Antes vs Ahora

| Aspecto | Método Anterior (UDP) | Método Nuevo (Gateway) |
|---------|----------------------|------------------------|
| **Requiere hardcodear IP** | ❌ Sí (fallback) | ✅ No |
| **Funciona con AP Isolation** | ❌ No | ✅ Sí |
| **Complejidad** | Alta (UDP + Broadcasting) | Baja (HTTP simple) |
| **Confiabilidad** | Media | Alta |
| **Setup requerido** | WiFi + IP fallback | Solo WiFi |
| **Detección bidireccional** | Limitada | ✅ Completa |

---

## Arquitectura Técnica

### Múltiples Interfaces de Red (Hotspot + Datos Móviles)

Cuando el celular usa **hotspot WiFi + datos móviles simultáneamente**, Android crea dos interfaces de red separadas:

```
┌─────────────────────────────────────────────┐
│  Celular Android                            │
│                                             │
│  ┌─────────────────────────────────────┐   │
│  │ Interfaz 1: Datos Móviles (rmnet0)  │   │
│  │ IP: 10.77.173.173                   │   │
│  │ Conectada a torre celular           │   │
│  └─────────────────────────────────────┘   │
│                                             │
│  ┌─────────────────────────────────────┐   │
│  │ Interfaz 2: Hotspot WiFi (wlan0)    │   │
│  │ IP: 10.220.212.167 ← Gateway        │   │
│  │ Provee WiFi a otros dispositivos    │   │
│  └─────────────────────────────────────┘   │
│              │                              │
└──────────────┼──────────────────────────────┘
               │ WiFi
               ▼
       ┌───────────────┐
       │  ESP32-CAM    │
       │ 10.220.212.217│
       └───────────────┘
```

**Problema anterior**:
- El servidor escuchaba solo en `10.77.173.173` (datos móviles)
- El ESP32 intentaba conectarse a `10.220.212.167` (gateway del hotspot)
- Resultado: "Connection reset by peer"

**Solución**:
- El servidor ahora escucha en `0.0.0.0:8080` (todas las interfaces)
- Acepta conexiones en AMBAS IPs:
  - `10.77.173.173:8080` (datos móviles)
  - `10.220.212.167:8080` (hotspot) ← El ESP32 se conecta aquí ✓

### Por qué el Gateway es Alcanzable

En un hotspot móvil:

```
┌─────────────────────────────────────┐
│  Celular (192.168.43.1)             │  ← Gateway
│  - Actúa como router                │
│  - Actúa como servidor DHCP         │
│  - Actúa como servidor DNS          │
│  - Actúa como firewall              │
├─────────────────────────────────────┤
│  AP Isolation:                      │
│  Cliente A ←✗→ Cliente B            │  Bloqueado
│  Cliente A ←✓→ Gateway              │  Permitido
│  Cliente B ←✓→ Gateway              │  Permitido
└─────────────────────────────────────┘
```

**Clave**: El dispositivo que crea el hotspot (gateway) **no** está sujeto a AP Isolation.

### Flujo de Paquetes

```
ESP32 (192.168.43.100)
   │
   │ HTTP POST /handshake
   │ Dst: 192.168.43.1:8080
   ▼
Gateway (192.168.43.1)
   │
   │ Routing interno
   │ Dst: localhost:8080
   ▼
Flutter App (escuchando en 0.0.0.0:8080)
   │
   │ HTTP 200 OK
   │ Src: 192.168.43.1:8080
   ▼
ESP32 (192.168.43.100)
```

---

## Próximos Pasos

### Mejoras Futuras

1. **Múltiples ESP32**
   - Soportar varios ESP32 simultáneamente
   - Identificación por MAC address

2. **Reconexión Automática**
   - Ping periódico para verificar conexión
   - Reintento automático si se pierde el servidor

3. **Compresión de Frames**
   - Reducir tamaño de payload
   - Mejorar velocidad de transmisión

4. **Cifrado**
   - HTTPS para comunicación segura
   - Autenticación por token

---

## Referencias

- Código ESP32: [ESP32-CAM/src/main.cpp](../../ESP32-CAM/src/main.cpp)
- Código Flutter: [lib/data/datasources/local/http_server_service.dart](../../lib/data/datasources/local/http_server_service.dart)
- Guía de Integración: [ESP32_INTEGRATION_GUIDE.md](./ESP32_INTEGRATION_GUIDE.md)
