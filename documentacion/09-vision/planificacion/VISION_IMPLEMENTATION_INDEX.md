# Índice de Documentación - Sistema de Detección por Visión

## 📋 Resumen Ejecutivo

Este conjunto de documentos describe la implementación completa de un **sistema de detección de eventos basado en visión** para DriveGuard, utilizando el **ESP32-CAM** para captura de video y **MediaPipe** para procesamiento local en el dispositivo Android.

**Duración total**: 4-6 semanas
**Eventos implementados**: 3 (Distracción, Inattention, Hands Off)
**Arquitectura**: ESP32-CAM → WiFi → Flutter → MediaPipe → Detectores → Alertas

---

## 📚 Documentos del Plan de Implementación

### 1. Plan Principal
**Archivo**: [PLAN_IMPLEMENTACION_VISION.md](PLAN_IMPLEMENTACION_VISION.md)

**Contenido**:
- ✅ Resumen ejecutivo
- ✅ Especificaciones técnicas del ESP32-CAM
- ✅ Definición de los 3 eventos a detectar
- ✅ Arquitectura completa del sistema
- ✅ Requisitos de hardware
- ✅ Timeline y métricas de éxito

**Leer primero**: Este documento para entender la visión general del proyecto.

---

### 2. Fase 1 - Configuración y Preparación
**Archivo**: [PLAN_FASE1_CONFIGURACION.md](PLAN_FASE1_CONFIGURACION.md)

**Duración**: 1 semana

**Contenido**:
- ✅ Instalación de dependencias (google_ml_kit, image)
- ✅ Estructura de directorios (`lib/core/vision/`)
- ✅ Modelos de datos (VisionEvent, FaceData, HandData)
- ✅ Extensión de EventType enum
- ✅ FrameConverter (JPEG → InputImage)
- ✅ FrameSubscriber (conexión con HttpServerService)
- ✅ Tests de verificación

**Tareas principales**:
1. `flutter pub get` para instalar dependencias
2. Crear estructura `lib/core/vision/`
3. Implementar FrameConverter
4. Verificar que frames del ESP32 se convierten correctamente

**Resultado esperado**: Infraestructura base lista para procesamiento MediaPipe.

---

### 3. Fase 2 - Implementación de Detectores
**Archivo**: [PLAN_FASE2_IMPLEMENTACION.md](PLAN_FASE2_IMPLEMENTACION.md)

**Duración**: 2-3 semanas

**Contenido**:
- ✅ **FaceMeshProcessor**: Procesamiento facial con ML Kit Face Detection
- ✅ **HandsProcessor**: Detección de manos con PoseDetector (workaround)
- ✅ **DistractionDetector**: Detecta uso de teléfono (headPitch < -25°)
- ✅ **InattentionDetector**: Detecta mirada fuera de carretera (|headYaw| > 30°)
- ✅ **HandsOffDetector**: Detección híbrida (0 manos + vehículo en movimiento)
- ✅ **VisionProcessor**: Orquestador principal
- ✅ Integración con DashboardBloc

**Código completo incluido**:
- Procesadores MediaPipe con manejo de streams
- Detectores con lógica de umbrales y cooldowns
- Orquestador que conecta todos los componentes
- Modificaciones al DashboardBloc para integrar visión

**Resultado esperado**: Sistema de detección completamente funcional.

---

### 4. Fase 3 - Pruebas, Validación y Mantenimiento
**Archivo**: [PLAN_FASE3_PRUEBAS.md](PLAN_FASE3_PRUEBAS.md)

**Duración**: 1-2 semanas

**Contenido**:
- ✅ **ROICalibrator**: Calibración de región del volante
- ✅ **ROICalibrationWidget**: UI interactiva para calibrar
- ✅ **Tests unitarios**: DistractionDetector, InattentionDetector, HandsOffDetector
- ✅ **Tests de integración**: VisionProcessor
- ✅ **Escenarios de validación**: 3 escenarios reales con criterios de aceptación
- ✅ **Matriz de validación**: Precisión mínima por evento (80%)
- ✅ **Optimización de rendimiento**: Objetivos de FPS, CPU, memoria
- ✅ **Página de debug**: ESP32VisionDebugPage con estadísticas en vivo
- ✅ **Troubleshooting**: Guía de problemas comunes
- ✅ **Mejoras futuras**: Hand Landmarker, Drowsiness, Ajuste dinámico

**Resultado esperado**: Sistema validado, optimizado y listo para producción.

---

## 🎯 Roadmap Visual

```
Semana 1: FASE 1 - Configuración
├─ Día 1-2: Instalación de dependencias
├─ Día 3-4: Modelos de datos y estructura
├─ Día 5-6: FrameConverter y FrameSubscriber
└─ Día 7: Verificación y tests

Semana 2-4: FASE 2 - Implementación
├─ Semana 2:
│  ├─ FaceMeshProcessor
│  ├─ HandsProcessor
│  └─ DistractionDetector
├─ Semana 3:
│  ├─ InattentionDetector
│  ├─ HandsOffDetector (híbrido)
│  └─ VisionProcessor
└─ Semana 4:
   └─ Integración con DashboardBloc

Semana 5-6: FASE 3 - Pruebas y Validación
├─ Semana 5:
│  ├─ Calibración de ROI
│  ├─ Tests unitarios
│  └─ Validación en condiciones reales
└─ Semana 6:
   ├─ Optimización de rendimiento
   ├─ Debugging y troubleshooting
   └─ Documentación final
```

---

## 🔧 Dependencias Técnicas

### Nuevas Dependencias
```yaml
dependencies:
  google_mlkit_face_detection: ^0.10.0  # FaceMesh
  google_mlkit_pose_detection: ^0.11.0  # Hands (workaround)
  image: ^4.1.3                          # Conversión JPEG
```

### Infraestructura Existente (No Modificar)
- ✅ HttpServerService (recibe frames del ESP32)
- ✅ CameraFrame (modelo de datos)
- ✅ EventAggregator (procesa eventos)
- ✅ DashboardBloc (coordina app)
- ✅ EventType enum (extender con nuevos eventos)

---

## 📊 Métricas de Éxito

### Precisión de Detección
| Evento | Precisión Objetivo | Falsos Positivos Max |
|--------|-------------------|----------------------|
| Distracción | ≥ 80% | < 10% |
| Inattention | ≥ 75% | < 15% |
| Hands Off | ≥ 80% | < 5% (crítico) |

### Rendimiento
| Métrica | Objetivo | Crítico |
|---------|----------|---------|
| FPS de procesamiento | ≥ 4 FPS | ≥ 3 FPS |
| Latencia frame→evento | ≤ 500ms | ≤ 1000ms |
| Uso de CPU | ≤ 40% | ≤ 60% |
| Memoria adicional | ≤ 150 MB | ≤ 200 MB |
| Consumo de batería | +5-8% | +15% max |

---

## 🚀 Cómo Empezar

### Paso 1: Leer documentación
1. Leer [PLAN_IMPLEMENTACION_VISION.md](PLAN_IMPLEMENTACION_VISION.md) completo
2. Revisar arquitectura y diagramas de flujo
3. Entender especificaciones del ESP32-CAM

### Paso 2: Configuración inicial (Fase 1)
1. Abrir [PLAN_FASE1_CONFIGURACION.md](PLAN_FASE1_CONFIGURACION.md)
2. Ejecutar paso 1.1: Instalación de dependencias
3. Ejecutar paso 1.2: Crear estructura de directorios
4. Implementar paso 1.3-1.5: Modelos y utilidades
5. Verificar paso 1.7: Checklist de Fase 1

### Paso 3: Implementación (Fase 2)
1. Abrir [PLAN_FASE2_IMPLEMENTACION.md](PLAN_FASE2_IMPLEMENTACION.md)
2. Implementar procesadores (2.1)
3. Implementar detectores (2.2)
4. Integrar con DashboardBloc (2.4)
5. Verificar paso 2.5: Checklist de Fase 2

### Paso 4: Validación (Fase 3)
1. Abrir [PLAN_FASE3_PRUEBAS.md](PLAN_FASE3_PRUEBAS.md)
2. Calibrar ROI del volante (3.1)
3. Ejecutar tests unitarios (3.2)
4. Validar en condiciones reales (3.3)
5. Optimizar rendimiento (3.4)
6. Verificar paso 3.6: Checklist Final

---

## 🔍 Arquitectura de Alto Nivel

```
┌─────────────────────────────────────────────────────────────┐
│  ESP32-CAM (Hardware)                                       │
│  - Captura: 640x480 @ 5 FPS                                 │
│  - Compresión: JPEG (quality 12)                            │
│  - Transmisión: WiFi HTTP POST                              │
└────────────────┬────────────────────────────────────────────┘
                 │ WiFi (192.168.43.1:8080)
                 ▼
┌─────────────────────────────────────────────────────────────┐
│  Flutter App - Capa de Recepción                            │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ HttpServerService (EXISTENTE)                        │   │
│  │ - Stream<CameraFrame> frameStream                    │   │
│  └──────────────┬───────────────────────────────────────┘   │
│                 │                                            │
│  ┌──────────────▼───────────────────────────────────────┐   │
│  │ FrameSubscriber (NUEVO)                              │   │
│  │ - Convierte CameraFrame → InputImage                 │   │
│  │ - Stream<InputImage> inputImageStream                │   │
│  └──────────────┬───────────────────────────────────────┘   │
└─────────────────┼────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│  Flutter App - Capa de Procesamiento MediaPipe              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ VisionProcessor (NUEVO)                              │   │
│  │                                                       │   │
│  │  ┌────────────────┐       ┌────────────────┐        │   │
│  │  │ FaceMeshProc   │       │ HandsProcessor │        │   │
│  │  │ (Face Detect)  │       │ (PoseDetector) │        │   │
│  │  └───────┬────────┘       └───────┬────────┘        │   │
│  │          │                        │                  │   │
│  │          ▼                        ▼                  │   │
│  │  Stream<FaceData>         Stream<HandData>          │   │
│  └──────────┼──────────────────────────┼────────────────┘   │
└─────────────┼──────────────────────────┼────────────────────┘
              │                          │
              ▼                          ▼
┌─────────────────────────────────────────────────────────────┐
│  Flutter App - Capa de Detección de Eventos                 │
│                                                              │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────┐  │
│  │ Distraction      │  │ Inattention      │  │ HandsOff │  │
│  │ Detector         │  │ Detector         │  │ Detector │  │
│  │                  │  │                  │  │ (Híbrido)│  │
│  │ Threshold:       │  │ Threshold:       │  │          │  │
│  │ headPitch <-25°  │  │ |headYaw| >30°   │  │ Vision + │  │
│  │ Duration: 2s     │  │ Duration: 2s     │  │ IMU      │  │
│  └────────┬─────────┘  └────────┬─────────┘  └────┬─────┘  │
│           │                     │                  │         │
│           └─────────────────────┼──────────────────┘         │
│                                 ▼                            │
│                   Stream<VisionEvent>                        │
└─────────────────────────────┬───────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│  Flutter App - Capa de Agregación (EXISTENTE)               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ EventAggregator                                      │   │
│  │ - Throttling: 15 alerts/min                          │   │
│  │ - Deduplication: 500ms                               │   │
│  └──────────────┬───────────────────────────────────────┘   │
└─────────────────┼────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│  Flutter App - UI (EXISTENTE)                               │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ DashboardBloc                                        │   │
│  │ - Coordina sensores IMU + Visión                     │   │
│  │ - Emite alertas visuales y sonoras                   │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Componentes Clave

### NUEVOS (a implementar)
| Componente | Archivo | Propósito |
|------------|---------|-----------|
| FrameConverter | `lib/core/vision/utils/frame_converter.dart` | JPEG → InputImage |
| FrameSubscriber | `lib/core/vision/utils/frame_subscriber.dart` | Suscripción a frames |
| FaceMeshProcessor | `lib/core/vision/processors/face_mesh_processor.dart` | Procesamiento facial |
| HandsProcessor | `lib/core/vision/processors/hands_processor.dart` | Detección de manos |
| DistractionDetector | `lib/core/vision/detectors/distraction_detector.dart` | Uso de teléfono |
| InattentionDetector | `lib/core/vision/detectors/inattention_detector.dart` | Mirada fuera |
| HandsOffDetector | `lib/core/vision/detectors/hands_off_detector.dart` | Manos fuera (híbrido) |
| VisionProcessor | `lib/core/vision/processors/vision_processor.dart` | Orquestador |
| ROICalibrator | `lib/core/vision/utils/roi_calibrator.dart` | Calibración ROI |

### EXISTENTES (usar sin modificar)
| Componente | Archivo | Uso |
|------------|---------|-----|
| HttpServerService | `lib/data/datasources/local/http_server_service.dart` | Recibir frames |
| CameraFrame | `lib/data/models/camera_frame.dart` | Modelo de frame |
| EventAggregator | `lib/core/detection/processors/event_aggregator.dart` | Procesar eventos |
| DashboardBloc | `lib/presentation/blocs/dashboard/dashboard_bloc.dart` | Coordinación |

---

## 📖 Conceptos Clave

### 1. Detección Pura por Visión
**Eventos**: Distraction, Inattention

**Características**:
- ✅ Solo análisis de imagen (MediaPipe)
- ✅ No requiere sensores IMU
- ✅ Basado en pose de cabeza (FaceMesh)

**Ejemplo**: Distraction
```dart
// Detecta cuando headPitch < -25° (mirando hacia abajo)
// Durante > 2 segundos → Alerta de distracción
```

---

### 2. Detección Híbrida (Visión + IMU)
**Evento**: HandsOff

**Características**:
- ✅ Combina análisis de imagen + sensores IMU
- ✅ Reduce falsos positivos significativamente
- ✅ Solo alerta si AMBAS condiciones se cumplen

**Ejemplo**: HandsOff
```dart
// CONDICIÓN 1: Visión → 0 manos en ROI del volante
// CONDICIÓN 2: IMU → Vehículo en movimiento (accel > 1.5 m/s²)
// Si AMBAS durante > 3 segundos → Alerta
```

---

### 3. Region of Interest (ROI)
**Propósito**: Definir área del frame donde se espera ver el volante.

**Calibración**:
- ✅ Una sola vez por vehículo
- ✅ Usuario dibuja rectángulo sobre volante
- ✅ Guardado en persistencia (SharedPreferences)

**Importancia**: Sin ROI calibrada, HandsOffDetector no funciona correctamente.

---

## ⚠️ Limitaciones Conocidas

### 1. HandLandmarker No Disponible en ML Kit Flutter
**Problema**: ML Kit para Flutter no tiene HandLandmarker nativo.

**Workaround actual**: Usar PoseDetector para detectar muñecas (wrists).

**Precisión esperada**: ~75% (vs ~90% con HandLandmarker real).

**Mejora futura**: Cuando ML Kit agregue HandLandmarker, migrar.

---

### 2. Iluminación Variable
**Problema**: ESP32-CAM es sensible a cambios de luz.

**Mitigación**:
- ✅ MediaPipe es robusto a iluminación (hasta cierto punto)
- ⚠️ Noche completa sin luz puede fallar
- ✅ Recomendación: Luz interior del auto encendida

---

### 3. Posicionamiento del ESP32-CAM
**Problema**: Ángulo de cámara afecta detección.

**Configuración óptima**:
- ✅ Montado en dashboard (tablero)
- ✅ Apuntando al conductor (no al camino)
- ✅ Altura: A nivel del rostro (±20 cm)
- ✅ Distancia: 40-60 cm del conductor

---

## 📞 Soporte y Mantenimiento

### Durante Implementación
- **Fase 1**: Enfocarse en verificar conversión de frames
- **Fase 2**: Probar cada detector individualmente antes de integrar
- **Fase 3**: Calibrar ROI PRIMERO antes de validación

### Post-Implementación
- **Monitoreo**: Trackear métricas de precisión con Firebase Analytics
- **Ajustes**: Afinar umbrales según feedback de usuarios
- **Mejoras**: Ver sección 3.7.2 en PLAN_FASE3_PRUEBAS.md

---

## ✅ Checklist Global

### Antes de Empezar
- [ ] Leer PLAN_IMPLEMENTACION_VISION.md completo
- [ ] Verificar que ESP32-CAM está funcional y enviando frames
- [ ] Verificar que HttpServerService recibe frames correctamente
- [ ] Entender arquitectura de detección IMU existente

### Durante Implementación
- [ ] Completar Fase 1 (Checklist en PLAN_FASE1_CONFIGURACION.md)
- [ ] Completar Fase 2 (Checklist en PLAN_FASE2_IMPLEMENTACION.md)
- [ ] Completar Fase 3 (Checklist en PLAN_FASE3_PRUEBAS.md)

### Antes de Lanzar
- [ ] Precisión ≥ 80% en validación real
- [ ] FPS ≥ 4 en dispositivos de prueba
- [ ] ROI calibrada y guardada
- [ ] Tests unitarios pasan
- [ ] Documentación completa

---

## 🎓 Recursos Adicionales

### Documentación Externa
- [MediaPipe Face Detection](https://developers.google.com/mediapipe/solutions/vision/face_detector)
- [ML Kit Face Detection](https://developers.google.com/ml-kit/vision/face-detection)
- [ML Kit Pose Detection](https://developers.google.com/ml-kit/vision/pose-detection)
- [ESP32-CAM Guide](https://randomnerdtutorials.com/esp32-cam-video-streaming-face-recognition-arduino-ide/)

### Documentación Interna del Proyecto
- [AUTO_DISCOVERY_GATEWAY.md](documentacion/03-hardware/AUTO_DISCOVERY_GATEWAY.md) - Sistema de conexión ESP32-CAM
- [ESP32_INTEGRATION_GUIDE.md](documentacion/03-hardware/ESP32_INTEGRATION_GUIDE.md) - Guía de integración
- [ANALISIS_SISTEMA_DETECCION.md](ANALISIS_SISTEMA_DETECCION.md) - Sistema de detección IMU existente

---

**Versión**: 1.0
**Fecha**: 2025-10-26
**Autor**: Claude Code (Anthropic)
**Proyecto**: DriveGuard - Sistema de Detección por Visión

---

## 🚦 Siguiente Paso

**Acción inmediata**: Abrir [PLAN_FASE1_CONFIGURACION.md](PLAN_FASE1_CONFIGURACION.md) y comenzar con la instalación de dependencias.

¡Éxito con la implementación! 🚀
