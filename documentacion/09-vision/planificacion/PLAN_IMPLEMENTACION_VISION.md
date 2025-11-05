# 📋 PLAN DE IMPLEMENTACIÓN: SISTEMA DE DETECCIÓN POR VISIÓN (ESP32-CAM)

**Proyecto:** DriveGuard - Sistema de Detección por Visión por Computadora
**Versión:** 2.0.0 - ESP32-CAM Edition
**Fecha:** Octubre 2025
**Hardware:** ESP32-CAM exclusivamente (no cámara del celular)
**Procesamiento:** 100% Local en dispositivo móvil (MediaPipe)

---

## 📑 TABLA DE CONTENIDOS

- [Resumen Ejecutivo](#resumen-ejecutivo)
- [Especificaciones ESP32-CAM](#especificaciones-esp32-cam)
- [Eventos a Implementar](#eventos-a-implementar)
- [Arquitectura General](#arquitectura-general)
- [FASE 1: Configuración y Preparación](#fase-1-configuración-y-preparación)
- [FASE 2: Implementación de Detectores](#fase-2-implementación-de-detectores)
- [FASE 3: Pruebas y Validación](#fase-3-pruebas-validación-y-mantenimiento)
- [Especificaciones de Hardware](#especificaciones-de-hardware)
- [Cronograma y Recursos](#cronograma-y-recursos)

---

## 🎯 RESUMEN EJECUTIVO

### Objetivo
Integrar capacidades de detección por visión por computadora al sistema DriveGuard existente, procesando frames del **ESP32-CAM** (ya integrado) con MediaPipe en el dispositivo móvil.

### Alcance
- **Detección de distracción** (uso de celular) - Análisis puro de imagen
- **Detección de desatención visual** (mirada fuera de la carretera) - Análisis puro de imagen
- **Detección de ausencia de manos en volante** - Análisis híbrido (imagen + IMU)

### Ventaja Clave
✅ **La infraestructura ESP32-CAM ya está implementada y funcionando**
- HttpServerService recibe frames vía HTTP
- Stream de CameraFrame disponible
- Sistema de gateway configurado
- Solo falta integrar MediaPipe para analizar los frames

### Tecnología
- **Hardware:** ESP32-CAM (OV2640) - ya integrado
- **Transmisión:** HTTP/WiFi (gateway 192.168.43.1:8080) - ya funcionando
- **Framework ML:** MediaPipe Solutions (Google)
- **Integración:** Flutter + google_ml_kit package
- **Procesamiento:** 100% local en el celular

### Tiempo Estimado
- **Total:** 4-6 semanas (reducido vs plan original)
- **Fase 1:** 1 semana (infraestructura ESP32 ya existe)
- **Fase 2:** 2-3 semanas
- **Fase 3:** 2 semanas

---

## 📷 ESPECIFICACIONES ESP32-CAM

### Hardware ESP32-CAM

```yaml
Microcontrolador:
  - Chip: ESP32-S (Dual-core Xtensa 32-bit)
  - Frecuencia: 160 MHz
  - RAM: 520 KB SRAM
  - Flash: 4 MB (externo)

Cámara OV2640:
  - Sensor: 2 Megapixeles (1600x1200)
  - Formatos: JPEG, RGB565, YUV422
  - Lente: Gran angular (~66° FOV)
  - Tamaño frame: Ajustable (160x120 a 1600x1200)

WiFi:
  - Estándar: 802.11 b/g/n
  - Frecuencia: 2.4 GHz
  - Alcance: ~50 metros (sin obstáculos)
  - Velocidad: Hasta 150 Mbps
```

### Capacidades Actuales (Ya Implementadas)

```yaml
Transmisión:
  - Protocolo: HTTP POST
  - Endpoint: http://GATEWAY_IP:8080/upload
  - Formato payload: JSON {"image": "base64", "timestamp": 12345}
  - Compresión: JPEG (calidad ajustable)
  - Frecuencia: Configurable (actualmente ~2 FPS)

Resolución Actual:
  - 640x480 (VGA) @ ~2 FPS
  - Balance óptimo: calidad vs velocidad de transmisión
  - Tamaño promedio: 30-60 KB por frame (JPEG comprimido)

Limitaciones:
  - Memoria limitada: 520 KB RAM (no permite ML on-board)
  - CPU limitado: No puede ejecutar MediaPipe
  - Solo captura y transmite: Processing en celular
```

### Optimizaciones para Visión por Computadora

**Configuración Recomendada ESP32-CAM:**

```cpp
// Configuración óptima para detección de conductor
camera_config_t config;
config.frame_size = FRAMESIZE_VGA;      // 640x480 - balance perfecto
config.pixel_format = PIXFORMAT_JPEG;   // Compresión eficiente
config.jpeg_quality = 12;               // 10-15 (menor = mejor calidad)
config.fb_count = 2;                    // Double buffering

// FPS objetivo
const int TARGET_FPS = 5;  // Aumentar de 2 a 5 FPS
const int FRAME_DELAY_MS = 200;  // 200ms entre frames
```

**Ventajas de VGA (640x480):**
- ✅ Suficiente resolución para detección facial
- ✅ MediaPipe Face Mesh funciona bien con 640x480
- ✅ Tamaño de payload manejable (~40-50 KB)
- ✅ 5 FPS es óptimo para detección en tiempo real
- ✅ No satura WiFi ni sobrecarga celular

---

## 📸 EVENTOS A IMPLEMENTAR

### 1. Distracción del Conductor (Uso de Celular)
**Tipo:** Análisis puro de imagen
**Prioridad:** CRÍTICA
**Modelo:** MediaPipe Hands + Face Mesh
**Frame source:** ESP32-CAM

**Criterios de detección:**
```yaml
CONDICIONES:
  - Mano detectada en zona facial (cerca de oreja/mejilla)
  - Duración sostenida: > 2 segundos
  - Confianza de MediaPipe: > 0.7

SEVERIDAD:
  LOW: Mano se acerca a zona de riesgo (1-2s)
  MEDIUM: Mano sostenida cerca de cara (2-4s)
  HIGH: Gesto activo confirmado (4-6s)
  CRITICAL: Uso continuo >6 segundos

DESAFÍOS ESP32-CAM:
  - Posición fija de cámara (calibrar ángulo)
  - Iluminación variable del vehículo
  - Vibración durante conducción
```

### 2. Desatención Visual (Mirada Fuera de la Carretera)
**Tipo:** Análisis puro de imagen
**Prioridad:** MUY ALTA
**Modelo:** MediaPipe Face Mesh (Head Pose + Iris Tracking)
**Frame source:** ESP32-CAM

**Criterios de detección:**
```yaml
ZONA_SEGURA:
  yaw: -30° a +30° (rotación horizontal)
  pitch: -15° a +10° (inclinación vertical)

DESATENCION_DETECTADA_SI:
  - yaw > 45° (mirando ventana/pasajero) por >2s
  - pitch < -20° (mirando regazo/consola) por >3s
  - pitch > 25° (mirando techo) por >4s

SEVERIDAD:
  LOW: Mirada fuera 2-4s
  MEDIUM: Mirada fuera 4-6s
  HIGH: Mirada fuera 6-8s
  CRITICAL: Mirada fuera >8s

VENTAJAS ESP32-CAM:
  - Posición estable para calibración de head pose
  - Enfoque directo al conductor
  - No se mueve como cámara del celular
```

### 3. Ausencia de Manos en Volante (Híbrido)
**Tipo:** Análisis híbrido (imagen + sensores IMU)
**Prioridad:** ALTA
**Modelo:** MediaPipe Hands + Acelerómetro
**Frame source:** ESP32-CAM

**Criterios de detección:**
```yaml
CONDICIONES_IMAGEN:
  - ROI definido para volante (calibrado por usuario)
  - Cero manos detectadas en ROI
  - Confianza MediaPipe: > 0.6

CONDICIONES_IMU:
  - Vehículo en movimiento: accelMagnitude > 1.5 m/s²
  - O velocidad GPS > 5 km/h

DETECCION_VALIDA_SI:
  (manos_fuera_de_ROI == true) AND (vehiculo_en_movimiento == true)

SEVERIDAD:
  LOW: 1 mano fuera por 3-5s (velocidad <30 km/h)
  MEDIUM: Ambas manos fuera 3-5s
  HIGH: Ambas manos fuera 5-8s
  CRITICAL: Sin manos >8s + velocidad alta

CONSIDERACIONES ESP32-CAM:
  - Ángulo de cámara crítico (debe ver volante y conductor)
  - Posición de montaje: tablero o parabrisas
  - Calibración inicial de ROI obligatoria
```

---

## 🏗️ ARQUITECTURA GENERAL

### Flujo de Datos Completo

```
┌────────────────────────────────────────────────────────────┐
│  CAPA DE CAPTURA (Hardware)                                │
├────────────────────────────────────────────────────────────┤
│  ESP32-CAM (OV2640)           │  Sensores IMU (Celular)    │
│  - Captura frames @ 5 FPS     │  - Acelerómetro 100 Hz     │
│  - Compresión JPEG            │  - Giroscopio 100 Hz       │
│  - Resolución: 640x480        │  - GPS (opcional)          │
│  - Tamaño: ~40-50 KB/frame    │                            │
└────────────────────────────────────────────────────────────┘
                    ↓                           ↓
┌────────────────────────────────────────────────────────────┐
│  CAPA DE TRANSMISIÓN                                       │
├────────────────────────────────────────────────────────────┤
│  WiFi Hotspot (Gateway)       │  Sensores locales          │
│  - SSID: "DriveGuard"         │  - API nativa Android/iOS  │
│  - Gateway: 192.168.43.1      │  - Stream continuo         │
│  - HTTP POST /upload          │                            │
│  - Payload: Base64 JPEG       │                            │
└────────────────────────────────────────────────────────────┘
                    ↓                           ↓
┌────────────────────────────────────────────────────────────┐
│  CAPA DE RECEPCIÓN (Flutter App)                           │
├────────────────────────────────────────────────────────────┤
│  HttpServerService (YA EXISTE) │  SensorDataProcessorV2    │
│  - Recibe frames vía HTTP      │  (YA EXISTE)              │
│  - Decodifica Base64 → JPEG    │  - Filtra datos IMU       │
│  - Stream<CameraFrame>         │  - Calibración            │
│  - Validación de payload       │  - Estadísticas           │
└────────────────────────────────────────────────────────────┘
                    ↓                           ↓
┌────────────────────────────────────────────────────────────┐
│  CAPA DE PREPROCESAMIENTO (NUEVO)                          │
├────────────────────────────────────────────────────────────┤
│  FrameConverter                │  (IMU sin cambios)         │
│  - JPEG bytes → InputImage     │                            │
│  - Validación de frame         │                            │
│  - Skip frames si lag          │                            │
└────────────────────────────────────────────────────────────┘
                    ↓                           ↓
┌────────────────────────────────────────────────────────────┐
│  CAPA DE PROCESAMIENTO ML (NUEVO)                          │
├────────────────────────────────────────────────────────────┤
│  VisionProcessor              │  IMU Detectors (existente) │
│  ┌──────────────────────┐    │  - HarshBrakingDetectorV2  │
│  │ MediaPipe Models     │    │  - AggressiveAccelDetectorV2│
│  ├──────────────────────┤    │  - SharpTurnDetectorV2     │
│  │ • Face Mesh          │    │  - WeavingDetector         │
│  │ • Hands              │    │  - RoughRoadDetector       │
│  │ • Pose (opcional)    │    │  - SpeedBumpDetector       │
│  └──────────────────────┘    │                            │
│           ↓                   │           ↓                │
│  ┌──────────────────────┐    │                            │
│  │ Vision Detectors     │    │                            │
│  ├──────────────────────┤    │                            │
│  │ • DistractionDetector│    │                            │
│  │ • InattentionDetector│    │                            │
│  │ • HandsOffDetector   │←───┼─ (híbrido: usa IMU)       │
│  └──────────────────────┘    │                            │
└────────────────────────────────────────────────────────────┘
                    ↓                           ↓
┌────────────────────────────────────────────────────────────┐
│  CAPA DE AGREGACIÓN (YA EXISTE - Modificar)               │
├────────────────────────────────────────────────────────────┤
│  EventAggregator                                           │
│  - Fusión de eventos IMU + Vision                          │
│  - Deduplicación (500ms)                                   │
│  - Throttling (15 alertas/min)                             │
│  - Priorización por severidad                              │
└────────────────────────────────────────────────────────────┘
                             ↓
┌────────────────────────────────────────────────────────────┐
│  CAPA DE PRESENTACIÓN (YA EXISTE)                          │
├────────────────────────────────────────────────────────────┤
│  DashboardBloc → NotificationService → AlertOverlay        │
│  - Alertas visuales                                        │
│  - Alertas de audio                                        │
│  - Alertas hápticas                                        │
└────────────────────────────────────────────────────────────┘
```

### Integración con Sistema Existente

```dart
// ANTES (Solo IMU)
HttpServerService (idle) ───────────────────┐
SensorService → SensorDataProcessorV2 ──────┤
                                            ├─→ EventAggregator → DashboardBloc
                                            │
// DESPUÉS (IMU + Vision desde ESP32-CAM)   │
HttpServerService → VisionProcessor ────────┤
SensorService → SensorDataProcessorV2 ──────┘
```

### Ventajas de usar ESP32-CAM vs Cámara del Celular

| Aspecto | ESP32-CAM | Cámara Celular |
|---------|-----------|----------------|
| **Posición** | ✅ Fija (tablero/parabrisas) | ❌ Se mueve con celular |
| **Ángulo** | ✅ Optimizado para conductor | ❌ Variable |
| **Calibración** | ✅ Una vez | ❌ Cada vez |
| **Estabilidad** | ✅ Sin vibración relativa | ❌ Vibra con soporte |
| **Batería celular** | ✅ Sin impacto en captura | ❌ Consume 15-20% |
| **Procesamiento** | ⚠️ Requiere WiFi activo | ✅ Siempre disponible |
| **ROI volante** | ✅ Consistente | ❌ Cambia con posición |
| **Iluminación** | ⚠️ Puede variar | ⚠️ Puede variar |

---

## 📱 ESPECIFICACIONES DE HARDWARE

### ESP32-CAM (Ya tienes)
```yaml
Hardware:
  - ESP32-S (dual-core 160 MHz)
  - OV2640 (2 MP)
  - RAM: 520 KB
  - Flash: 4 MB

Configuración Actual:
  - Resolución: 640x480 (VGA)
  - FPS: ~5 (ajustable)
  - Formato: JPEG
  - Transmisión: WiFi HTTP
```

### Celular (Para Procesamiento ML)

**Mínimas:**
```yaml
Procesador: Snapdragon 695 / Dimensity 700 / Apple A12
RAM: 4 GB
Android: 9.0+ (API 28+)
iOS: 13+
WiFi: 802.11n (2.4 GHz)
```

**Recomendadas:**
```yaml
Procesador: Snapdragon 730G+ / Dimensity 800+ / Apple A13+
RAM: 6 GB
Android: 10+ (API 29+)
iOS: 14+
WiFi: 802.11ac (5 GHz)
NPU: Dedicado (Hexagon, APU, Neural Engine)
```

**Nota:** Como no usamos cámara del celular, los requisitos de procesamiento son ligeramente menores que con cámara local.

---

## 📅 CRONOGRAMA Y RECURSOS

### Timeline Detallado (Actualizado)

```
Semana 1: FASE 1 (Reducida)
├─ Día 1-2: Dependencias y modelos ML
├─ Día 3-4: FrameConverter y estructura
├─ Día 5: Verificar HttpServerService
└─ Día 6-7: Configurar ESP32-CAM a 5 FPS

Semana 2-4: FASE 2
├─ Día 1-3: Procesadores MediaPipe
├─ Día 4-6: Detectores de visión
├─ Día 7-9: VisionProcessor orquestador
├─ Día 10-12: Integración con DashboardBloc
└─ Día 13-14: Testing básico

Semana 5-6: FASE 3
├─ Día 1-3: Tests funcionales
├─ Día 4-5: Calibración ESP32-CAM
├─ Día 6-7: Optimización rendimiento
├─ Día 8-9: Edge cases
└─ Día 10-12: Documentación

TOTAL: 4-6 semanas
```

### Recursos Necesarios

**Humanos:**
- 1 Desarrollador Flutter (full-time)
- 1 Tester (part-time, semanas 2-6)

**Hardware:**
- 1 ESP32-CAM (✅ ya tienes)
- 3 dispositivos móviles de prueba (gama baja, media, alta)
- Soporte para ESP32-CAM (tablero/parabrisas)
- Router WiFi o hotspot móvil

**Software:**
- Android Studio / VS Code
- Flutter SDK 3.16+
- Firebase (ya configurado)
- Git para control de versiones
- Monitor Serial para ESP32-CAM

---

## 🎯 MÉTRICAS DE ÉXITO

### KPIs Técnicos (ESP32-CAM)
```yaml
Precisión:
  - Tasa de detección: >80% (vs >85% con cámara móvil)
  - Falsos positivos: <20% (vs <15%)
  - Nota: Ligeramente menor debido a posición fija

Rendimiento:
  - FPS ESP32-CAM: 4.5-5.5
  - Latencia end-to-end: <500ms
  - Procesamiento MediaPipe: <150ms

Estabilidad:
  - Conexión WiFi: >95% uptime
  - Frames corruptos: <1%
  - Reconexión automática: <10s

Batería Celular:
  - Consumo adicional vs solo IMU: ~5-8%/hora
  - (No procesa cámara local, solo WiFi + ML)
```

### KPIs de Negocio
```yaml
Adopción:
  - % usuarios que activan visión ESP32-CAM: >40%
  - Retención después de 1 semana: >65%

Satisfacción:
  - Rating app store: >4.0/5.0
  - % usuarios que reportan alertas útiles: >70%
```

---

**Continuará en FASE 1...**

> **Nota:** Este es el documento principal. Las fases detalladas se encuentran en archivos separados para mejor organización.
