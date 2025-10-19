# Guía de Integración ESP32-CAM → DriveGuard Flutter

## ✅ Implementación Completada - Fase 2.5 (Auto-Discovery)

La comunicación entre el ESP32-CAM y la aplicación Flutter DriveGuard ha sido implementada exitosamente con sistema de auto-descubrimiento UDP.

---

## 📁 Archivos Creados

### 1. **Domain Layer (Entidades y Contratos)**
- `lib/domain/repositories/camera_repository.dart` - Contrato del repositorio de cámara
- `lib/data/models/camera_frame.dart` - Modelo de datos para frames de cámara

### 2. **Data Layer (Implementaciones)**
- `lib/data/datasources/local/http_server_service.dart` - Servidor HTTP embebido
- `lib/data/repositories/camera_repository_impl.dart` - Implementación del repositorio

### 3. **Core Services (Networking)**
- `lib/core/services/network_discovery_service.dart` - Servicio de auto-descubrimiento UDP

### 4. **Presentation Layer (UI y BLoC)**
- `lib/presentation/blocs/camera_stream/camera_stream_bloc.dart` - BLoC de gestión de estado
- `lib/presentation/blocs/camera_stream/camera_stream_event.dart` - Eventos del BLoC
- `lib/presentation/blocs/camera_stream/camera_stream_state.dart` - Estados del BLoC
- `lib/presentation/widgets/esp32/esp32_debug_panel.dart` - Widget de visualización
- `lib/presentation/widgets/esp32/esp32_connection_indicator.dart` - Indicador de conexión ESP32
- `lib/presentation/pages/esp32/esp32_debug_page.dart` - Página de debug completa

### 5. **Archivos Modificados**
- `pubspec.yaml` - Dependencias agregadas (shelf, shelf_router, permission_handler, intl, udp)
- `lib/main.dart` - Integración del CameraStreamBloc
- `lib/presentation/pages/dashboard_page.dart` - Entrada en menú lateral + Indicador de conexión ESP32
- `lib/domain/repositories/camera_repository.dart` - Métodos para obtener info del servidor
- `lib/data/repositories/camera_repository_impl.dart` - Implementación de métodos de servidor
- `android/app/src/main/AndroidManifest.xml` - Permisos de WiFi agregados

---

## 🚀 Características Implementadas

### Sistema de Auto-Discovery UDP
✅ Broadcasting UDP en puerto 8888 cada 2 segundos
✅ Envío automático de IP y puerto del servidor
✅ El ESP32 detecta y se conecta automáticamente
✅ No requiere configuración manual de IP
✅ Detección automática de interfaz WiFi (wlan0)

### Servidor HTTP Embebido
✅ Puerto: 8080 (con fallback automático a 8081, 8082 si está ocupado)
✅ Endpoint: `POST /upload`
✅ Formato aceptado: JSON con Base64
✅ Validación de payload (max 500KB)
✅ Verificación de formato JPEG
✅ Gestión automática de memoria (solo última imagen)
✅ Obtención automática de IP local
✅ CORS habilitado para pruebas

### Interfaz de Usuario
✅ Panel de debug con visualización en tiempo real
✅ Indicador de conexión ESP32 en Dashboard con estados visuales
  - 🟠 Waiting: Esperando conexión del ESP32
  - 🟡 Detected: ESP32 detectado, estableciendo conexión
  - 🟢 Connected: ESP32 conectado y enviando frames
  - 🔴 Error: Error en la conexión
✅ Animación pulsante para estados waiting/detected
✅ Muestra IP del servidor y ESP32
✅ Contador de frames recibidos
✅ Timestamp de última imagen
✅ Animación de fade al cambiar imagen
✅ Botones de iniciar/detener servidor
✅ Reconexión automática en caso de error
✅ Instrucciones de configuración integradas

### Gestión de Estado (BLoC)
✅ Estados: Initial, Loading, Connected, NewFrame, Error, Stopped
✅ Eventos: Start, Stop, NewFrame, Reconnect
✅ Stream reactivo de frames
✅ Manejo de errores robusto
✅ Ciclo de vida limpio (dispose automático)

---

## 📱 Cómo Usar

### Método 1: Auto-Discovery (Recomendado) 🎯

#### Paso 1: Ejecutar la Aplicación Flutter
```bash
flutter run
```

#### Paso 2: Iniciar el Servidor
1. Abrir la aplicación DriveGuard
2. Abrir el menú lateral (hamburger menu)
3. Seleccionar **"ESP32-CAM Debug"**
4. Presionar el botón verde **"Iniciar"**

El servidor comenzará a enviar broadcasts UDP automáticamente.

#### Paso 3: Configurar el ESP32-CAM para Auto-Discovery
```cpp
#include <WiFiUdp.h>
#include <ArduinoJson.h>

WiFiUDP udp;
const int UDP_PORT = 8888;

void discoverServer() {
  udp.begin(UDP_PORT);

  while (true) {
    int packetSize = udp.parsePacket();
    if (packetSize) {
      char buffer[256];
      udp.read(buffer, 256);

      StaticJsonDocument<200> doc;
      deserializeJson(doc, buffer);

      const char* type = doc["type"];
      if (strcmp(type, "DRIVEGUARD_SERVER") == 0) {
        const char* serverIp = doc["ip"];
        int serverPort = doc["port"];

        Serial.printf("✅ Servidor encontrado: %s:%d\n", serverIp, serverPort);

        // Guardar IP y puerto para enviar frames
        // ... continuar con el envío de imágenes
        break;
      }
    }
    delay(100);
  }
  udp.stop();
}
```

#### Paso 4: Reiniciar el ESP32-CAM
El ESP32 se conectará automáticamente sin necesidad de configurar la IP manualmente.

---

### Método 2: Configuración Manual (Alternativa)

Si prefieres configurar la IP manualmente:

#### Paso 3 (Manual): Obtener la IP del Servidor
En el panel de debug o en el indicador del Dashboard aparecerá:
```
📡 Servidor escuchando en 192.168.1.100:8080
```

#### Paso 4 (Manual): Configurar el ESP32-CAM
```cpp
// En tu archivo main.cpp del ESP32
const char* FLUTTER_IP = "192.168.1.100";  // ⬅ Cambiar esta IP
const int FLUTTER_PORT = 8080;
const char* UPLOAD_ENDPOINT = "/upload";
```

#### Paso 5 (Manual): Reiniciar el ESP32-CAM
Las imágenes comenzarán a llegar automáticamente cada 500ms (~2 FPS).

---

## 🔧 Configuración de Red

### Requisitos
- ✅ ESP32-CAM y smartphone en la **misma red WiFi**
- ✅ Red local debe permitir comunicación entre dispositivos
- ✅ Puerto 8080 no debe estar ocupado en el smartphone

### Verificar Conectividad
Puedes probar el servidor con `curl`:
```bash
curl -X GET http://<IP_SMARTPHONE>:8080/status
```

Respuesta esperada:
```json
{
  "status": "online",
  "serverAddress": "192.168.1.100:8080",
  "framesReceived": 0,
  "lastFrameAt": null
}
```

---

## 📡 Formato de Comunicación

### 1. UDP Broadcast (Flutter → ESP32) - Auto-Discovery

Flutter envía broadcasts UDP cada 2 segundos en puerto 8888:

```json
{
  "type": "DRIVEGUARD_SERVER",
  "ip": "192.168.1.100",
  "port": 8080,
  "timestamp": 1697562225123
}
```

### 2. HTTP Request (ESP32 → Flutter) - Envío de Frames

```http
POST /upload HTTP/1.1
Host: <IP_FLUTTER>:8080
Content-Type: application/json

{
  "image": "<base64_encoded_jpeg>",
  "timestamp": 12345
}
```

### 3. HTTP Response (Flutter → ESP32)

```json
{
  "status": "success",
  "receivedAt": "2025-10-17T14:23:45.123Z",
  "frameNumber": 127
}
```

### Códigos de Error Manejados
- `400 Bad Request` - JSON inválido o Base64 corrupto
- `413 Payload Too Large` - Imagen > 500KB
- `500 Internal Server Error` - Error de procesamiento

---

## 🐛 Solución de Problemas

### El servidor no inicia
**Problema**: Puerto 8080 ocupado
**Solución**: El servidor intentará automáticamente puertos 8081, 8082, etc.

### ESP32 no puede conectarse
**Problema**: Dispositivos en redes diferentes
**Solución**: Verificar que ambos están en la misma WiFi con:
```bash
# En Android (con adb)
adb shell ip addr show wlan0

# En ESP32 (Serial Monitor)
Serial.println(WiFi.localIP());
```

### Imágenes no se muestran
**Problema**: Base64 corrupto o formato incorrecto
**Solución**: Verificar en logs de Flutter:
```bash
flutter logs | grep "📸"
```

### Error "Address already in use"
**Problema**: App anterior no cerró el servidor correctamente
**Solución**: Reiniciar la aplicación Flutter

---

## 📊 Monitoreo y Logs

### Logs del Servidor HTTP (Flutter)
```
✅ Servidor HTTP iniciado en http://192.168.1.100:8080
✅ Broadcasting UDP iniciado en puerto 8888
📡 Enviando broadcasts cada 2s con IP: 192.168.1.100:8080
📤 Broadcast enviado: {"type":"DRIVEGUARD_SERVER","ip":"192.168.1.100","port":8080,"timestamp":1697562225123}
📸 Frame recibido #1 (45123 bytes, timestamp: 12345)
📸 Frame recibido #2 (44987 bytes, timestamp: 12845)
...
```

### Logs del ESP32 (Serial Monitor) - Con Auto-Discovery
```
✅ WiFi conectado
📡 IP asignada: 192.168.4.2
🔍 Buscando servidor DriveGuard...
📡 Broadcast recibido desde 192.168.1.100
✅ Servidor encontrado: 192.168.1.100:8080
📸 Capturando imagen...
➡️ Enviando a http://192.168.1.100:8080/upload
✅ Respuesta: 200 OK
```

---

## 🔒 Seguridad

### Implementado
✅ Validación de Content-Type
✅ Límite de tamaño de payload (500KB)
✅ Verificación de formato JPEG
✅ Timeout de requests (5 segundos)
✅ Gestión de memoria (1 frame en RAM)

### Consideraciones Futuras
⚠️ Agregar autenticación (token/API key)
⚠️ Encriptar comunicación (HTTPS/TLS)
⚠️ Rate limiting para evitar flooding

---

## 🎯 Próximos Pasos (Fases Futuras)

### Fase 3: Análisis de IA (Pendiente)
- Integrar modelo de detección de objetos
- Procesar frames en tiempo real
- Detectar distracciones del conductor
- Generar alertas automáticas

### Fase 4: Optimizaciones
- Compresión de imágenes en ESP32
- Transmisión adaptativa (ajustar FPS según latencia)
- ✅ Autodescubrimiento vía UDP Broadcasting (COMPLETADO)
- Modo offline con cache local
- mDNS/Bonjour como alternativa a UDP

---

## 📞 Soporte

Si encuentras problemas:
1. Revisar logs de Flutter: `flutter logs`
2. Revisar Serial Monitor del ESP32
3. Verificar conectividad de red
4. Consultar este documento

---

## ✅ Criterios de Aceptación Cumplidos

### Fase 2: Servidor HTTP
✅ Servidor HTTP inicia correctamente al abrir app
✅ ESP32 puede enviar imágenes sin errores 4xx/5xx
✅ Flutter recibe y decodifica imágenes Base64 correctamente
✅ Widget de debug muestra última imagen en tiempo real
✅ No hay memory leaks al recibir 100+ imágenes consecutivas
✅ Servidor se detiene limpiamente al cerrar app
✅ Logs descriptivos en consola para debugging

### Fase 2.5: Auto-Discovery UDP
✅ Broadcasting UDP iniciado automáticamente con el servidor
✅ Mensajes UDP contienen IP y puerto correctos
✅ Broadcasts enviados cada 2 segundos de manera consistente
✅ Detección automática de interfaz WiFi (prioriza wlan0)
✅ NetworkDiscoveryService integrado en HttpServerService
✅ Indicador visual de conexión ESP32 en Dashboard
✅ Estados visuales claros (waiting, detected, connected, error)
✅ Animaciones pulsantes para estados de espera
✅ Stream de eventos de conexión ESP32
✅ Información del servidor disponible vía CameraRepository

---

**Desarrollado siguiendo Clean Architecture + BLoC Pattern**
**Compatible con Flutter 3.16.0+ y Android API 30+**
