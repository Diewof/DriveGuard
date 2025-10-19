# Ejemplo de Request del ESP32-CAM al Flutter App

## Formato del POST Request

### Headers Requeridos
```http
POST /upload HTTP/1.1
Host: 192.168.1.100:8080
Content-Type: application/json
Content-Length: <tamaño_del_body>
```

### Body (JSON)
```json
{
  "image": "/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/2wBDAQkJCQwLDBgNDRgyIRwhMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjL/wAARCABgAFADASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlbaWmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwD5/ooooA...(más datos Base64)",
  "timestamp": 1729180425123
}
```

### Campos Explicados

#### `image` (string, requerido)
- Imagen JPEG codificada en Base64
- Debe ser un string válido en Base64
- Tamaño máximo: 500KB (después de decodificar)
- El ESP32 debe capturar en formato JPEG y luego convertir a Base64

#### `timestamp` (integer, requerido)
- Timestamp del ESP32 en milisegundos desde el inicio (millis())
- Tipo: entero largo (long)
- Ejemplo: `12345` = 12.345 segundos desde que el ESP32 inició

---

## Código de Ejemplo para ESP32-CAM

### Captura y Envío de Imagen

```cpp
#include <WiFi.h>
#include <HTTPClient.h>
#include "esp_camera.h"
#include "base64.h"

// Configuración WiFi
const char* WIFI_SSID = "DriveGuard";
const char* WIFI_PASSWORD = "driveguard123";

// Configuración Flutter App
const char* FLUTTER_IP = "192.168.1.100";  // ⬅ CAMBIAR ESTA IP
const int FLUTTER_PORT = 8080;
const char* UPLOAD_ENDPOINT = "/upload";

// Construir URL completa
String serverUrl = String("http://") + FLUTTER_IP + ":" + FLUTTER_PORT + UPLOAD_ENDPOINT;

void sendImageToFlutter() {
  // Capturar imagen
  camera_fb_t* fb = esp_camera_fb_get();

  if (!fb) {
    Serial.println("❌ Error capturando imagen");
    return;
  }

  // Convertir a Base64
  String base64Image = base64::encode(fb->buf, fb->len);

  // Obtener timestamp
  unsigned long timestamp = millis();

  // Crear JSON
  String jsonPayload = "{";
  jsonPayload += "\"image\":\"" + base64Image + "\",";
  jsonPayload += "\"timestamp\":" + String(timestamp);
  jsonPayload += "}";

  // Enviar HTTP POST
  HTTPClient http;
  http.begin(serverUrl);
  http.addHeader("Content-Type", "application/json");
  http.setTimeout(2000); // 2 segundos timeout

  int httpCode = http.POST(jsonPayload);

  if (httpCode == HTTP_CODE_OK) {
    String response = http.getString();
    Serial.println("✅ Imagen enviada: " + response);
  } else {
    Serial.printf("❌ Error HTTP: %d\n", httpCode);
  }

  http.end();
  esp_camera_fb_return(fb); // Liberar memoria
}

void loop() {
  sendImageToFlutter();
  delay(500); // Enviar cada 500ms (~2 FPS)
}
```

---

## Respuestas del Servidor Flutter

### Éxito (200 OK)
```json
{
  "status": "success",
  "receivedAt": "2025-10-17T14:23:45.123Z",
  "frameNumber": 127
}
```

### Error: JSON Inválido (400 Bad Request)
```json
{
  "error": "JSON inválido. Se requieren campos: image, timestamp"
}
```

### Error: Base64 Corrupto (400 Bad Request)
```json
{
  "error": "Base64 inválido: Invalid character found"
}
```

### Error: No es JPEG (400 Bad Request)
```json
{
  "error": "No es una imagen JPEG válida"
}
```

### Error: Imagen Muy Grande (413 Payload Too Large)
```json
{
  "error": "Imagen demasiado grande (max 500KB)"
}
```

### Error: Interno (500 Internal Server Error)
```json
{
  "error": "Error interno: <descripción>"
}
```

---

## Verificación del Formato JPEG

El servidor Flutter verifica que los primeros dos bytes de la imagen decodificada sean:
- Byte 0: `0xFF`
- Byte 1: `0xD8`

Estos son los magic bytes de archivos JPEG. Si no coinciden, la imagen es rechazada.

---

## Optimizaciones Recomendadas

### 1. Comprimir Imagen en ESP32
```cpp
// Configurar calidad JPEG (0-63, menor = mejor compresión)
camera_config_t config;
config.jpeg_quality = 12; // Ajustar según necesidad
```

### 2. Reducir Resolución
```cpp
config.frame_size = FRAMESIZE_QVGA; // 320x240
// Opciones: QVGA, VGA, SVGA, HD, etc.
```

### 3. Enviar Solo Cuando Hay Movimiento
```cpp
bool detectMotion() {
  // Implementar detección básica de movimiento
  // Comparar frame actual vs anterior
}

void loop() {
  if (detectMotion()) {
    sendImageToFlutter();
  }
  delay(100);
}
```

### 4. Manejo de Errores con Reintentos
```cpp
void sendImageWithRetry(int maxRetries = 3) {
  for (int i = 0; i < maxRetries; i++) {
    int httpCode = sendImageToFlutter();

    if (httpCode == HTTP_CODE_OK) {
      return; // Éxito
    }

    Serial.printf("⚠️ Reintento %d/%d\n", i + 1, maxRetries);
    delay(1000);
  }

  Serial.println("❌ Falló después de todos los reintentos");
}
```

---

## Testing con cURL

### Enviar Imagen de Prueba
```bash
# Crear JSON con imagen pequeña
echo '{
  "image": "/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAAEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/2wBDAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQH/wAARCAACAAIDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwCwAA==",
  "timestamp": 12345
}' > test_request.json

# Enviar POST
curl -X POST \
  -H "Content-Type: application/json" \
  -d @test_request.json \
  http://192.168.1.100:8080/upload
```

### Verificar Estado del Servidor
```bash
curl http://192.168.1.100:8080/status
```

---

## Depuración

### Logs del ESP32 (Serial Monitor)
```
Conectando a WiFi: DriveGuard
✅ WiFi conectado
📡 IP asignada: 192.168.4.2
🎯 Servidor Flutter: http://192.168.1.100:8080/upload

📸 Capturando imagen...
📊 Tamaño JPEG: 45123 bytes
🔄 Convirtiendo a Base64...
📊 Tamaño Base64: 60164 bytes
➡️ Enviando POST...
✅ Respuesta HTTP: 200
📄 Body: {"status":"success","receivedAt":"2025-10-17T14:23:45.123Z","frameNumber":1}
```

### Logs de Flutter (Console)
```bash
flutter logs | grep -E "📸|❌|✅"
```

Salida esperada:
```
I/flutter (12345): ✅ Servidor HTTP iniciado en http://192.168.1.100:8080
I/flutter (12345): 📡 Esperando conexión del ESP32-CAM...
I/flutter (12345): 📸 Frame recibido #1 (45123 bytes, timestamp: 12345)
I/flutter (12345): 📸 Frame recibido #2 (44987 bytes, timestamp: 12845)
```

---

## Checklist de Integración

### Pre-requisitos
- [ ] ESP32-CAM configurado con firmware actualizado
- [ ] WiFi "DriveGuard" disponible (o ajustar SSID en ESP32)
- [ ] Flutter app corriendo en smartphone
- [ ] Smartphone y ESP32 en la misma red WiFi

### Configuración
- [ ] Obtener IP del servidor desde panel de debug en Flutter
- [ ] Actualizar `FLUTTER_IP` en código ESP32
- [ ] Compilar y subir código al ESP32-CAM
- [ ] Verificar conexión WiFi del ESP32 (Serial Monitor)

### Testing
- [ ] Verificar estado del servidor con `/status`
- [ ] Enviar imagen de prueba con cURL
- [ ] Verificar que el panel de debug muestre la imagen
- [ ] Confirmar que el contador de frames incremente

### Validación
- [ ] Enviar 10 imágenes consecutivas sin errores
- [ ] Verificar latencia < 2 segundos
- [ ] Confirmar que no hay memory leaks en Flutter
- [ ] Probar reconexión después de detener/iniciar servidor

---

**¡Listo para integrar!** 🚀
