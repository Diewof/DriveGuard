# Guía de Integración ESP32-CAM → DriveGuard Flutter

## ✅ Implementación Completada - Fase 2

La comunicación entre el ESP32-CAM y la aplicación Flutter DriveGuard ha sido implementada exitosamente.

---

## 📁 Archivos Creados

### 1. **Domain Layer (Entidades y Contratos)**
- `lib/domain/repositories/camera_repository.dart` - Contrato del repositorio de cámara
- `lib/data/models/camera_frame.dart` - Modelo de datos para frames de cámara

### 2. **Data Layer (Implementaciones)**
- `lib/data/datasources/local/http_server_service.dart` - Servidor HTTP embebido
- `lib/data/repositories/camera_repository_impl.dart` - Implementación del repositorio

### 3. **Presentation Layer (UI y BLoC)**
- `lib/presentation/blocs/camera_stream/camera_stream_bloc.dart` - BLoC de gestión de estado
- `lib/presentation/blocs/camera_stream/camera_stream_event.dart` - Eventos del BLoC
- `lib/presentation/blocs/camera_stream/camera_stream_state.dart` - Estados del BLoC
- `lib/presentation/widgets/esp32/esp32_debug_panel.dart` - Widget de visualización
- `lib/presentation/pages/esp32/esp32_debug_page.dart` - Página de debug completa

### 4. **Archivos Modificados**
- `pubspec.yaml` - Dependencias agregadas (shelf, shelf_router, permission_handler, intl)
- `lib/main.dart` - Integración del CameraStreamBloc
- `lib/presentation/pages/dashboard_page.dart` - Entrada en menú lateral
- `android/app/src/main/AndroidManifest.xml` - Permisos de WiFi agregados

---

## 🚀 Características Implementadas

### Servidor HTTP Embebido
✅ Puerto: 8080 (con fallback automático a 8081, 8082 si está ocupado)
✅ Endpoint: `POST /upload`
✅ Formato aceptado: JSON con Base64
✅ Validación de payload (max 500KB)
✅ Verificación de formato JPEG
✅ Gestión automática de memoria (solo última imagen)
✅ CORS habilitado para pruebas

### Interfaz de Usuario
✅ Panel de debug con visualización en tiempo real
✅ Indicador de estado de conexión (conectado/desconectado/error)
✅ Muestra IP del servidor para configurar ESP32
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

### Paso 1: Ejecutar la Aplicación Flutter
```bash
flutter run
```

### Paso 2: Acceder al Panel de Debug
1. Abrir la aplicación DriveGuard
2. Abrir el menú lateral (hamburger menu)
3. Seleccionar **"ESP32-CAM Debug"**
4. Presionar el botón verde **"Iniciar"**

### Paso 3: Obtener la IP del Servidor
En el panel de debug aparecerá algo como:
```
📡 Dirección del servidor:
http://192.168.1.100:8080/upload
```

### Paso 4: Configurar el ESP32-CAM
Actualiza el código del ESP32-CAM con la IP obtenida:

```cpp
// En tu archivo main.cpp del ESP32
const char* FLUTTER_IP = "192.168.1.100";  // ⬅ Cambiar esta IP
const int FLUTTER_PORT = 8080;
const char* UPLOAD_ENDPOINT = "/upload";
```

### Paso 5: Reiniciar el ESP32-CAM
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

### Request del ESP32 → Flutter
```http
POST /upload HTTP/1.1
Host: <IP_FLUTTER>:8080
Content-Type: application/json

{
  "image": "<base64_encoded_jpeg>",
  "timestamp": 12345
}
```

### Response Flutter → ESP32
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
📡 Esperando conexión del ESP32-CAM...
📸 Frame recibido #1 (45123 bytes, timestamp: 12345)
📸 Frame recibido #2 (44987 bytes, timestamp: 12845)
...
```

### Logs del ESP32 (Serial Monitor)
```
✅ WiFi conectado
📡 IP asignada: 192.168.4.2
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
- Autodescubrimiento vía mDNS/Bonjour
- Modo offline con cache local

---

## 📞 Soporte

Si encuentras problemas:
1. Revisar logs de Flutter: `flutter logs`
2. Revisar Serial Monitor del ESP32
3. Verificar conectividad de red
4. Consultar este documento

---

## ✅ Criterios de Aceptación Cumplidos

✅ Servidor HTTP inicia correctamente al abrir app
✅ ESP32 puede enviar imágenes sin errores 4xx/5xx
✅ Flutter recibe y decodifica imágenes Base64 correctamente
✅ Widget de debug muestra última imagen en tiempo real
✅ No hay memory leaks al recibir 100+ imágenes consecutivas
✅ Servidor se detiene limpiamente al cerrar app
✅ Logs descriptivos en consola para debugging

---

**Desarrollado siguiendo Clean Architecture + BLoC Pattern**
**Compatible con Flutter 3.16.0+ y Android API 30+**
