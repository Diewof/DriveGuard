# 📚 ÍNDICE DE DOCUMENTACIÓN - SISTEMA DE VISIÓN

**DriveGuard - Detección por Visión por Computadora**
**Última actualización:** 26 de Octubre de 2025

---

## 🗂️ Documentación de Planificación

### Documento Maestro
- 📄 [PLAN_IMPLEMENTACION_VISION.md](PLAN_IMPLEMENTACION_VISION.md)
  - Resumen ejecutivo completo
  - Especificaciones ESP32-CAM
  - Eventos a implementar
  - Arquitectura general
  - Cronograma y recursos

### Planes por Fase
- 📄 [PLAN_FASE1_CONFIGURACION.md](PLAN_FASE1_CONFIGURACION.md) - **✅ Completada**
  - Instalación de dependencias
  - Estructura de archivos
  - Modelos de datos base
  - Utilidades de conversión

- 📄 [PLAN_FASE2_IMPLEMENTACION.md](PLAN_FASE2_IMPLEMENTACION.md) - **⏭️ Siguiente**
  - Procesadores MediaPipe
  - Detectores de eventos
  - Integración con DashboardBloc

- 📄 [PLAN_FASE3_PRUEBAS.md](PLAN_FASE3_PRUEBAS.md) - **⏸️ Futura**
  - Tests funcionales
  - Calibración ESP32-CAM
  - Optimización de rendimiento

---

## 📋 Documentación de Implementación

### Fase 1 (COMPLETADA)
- 📄 [FASE1_RESUMEN.md](FASE1_RESUMEN.md)
  - Resumen ejecutivo de Fase 1
  - Métricas alcanzadas
  - Componentes implementados
  - Próximos pasos

- 📄 [novedades.md](novedades.md)
  - Documentación técnica detallada
  - Decisiones de diseño
  - Inconsistencias detectadas y solucionadas
  - Lecciones aprendidas

---

## 💻 Código Fuente

### Modelos de Datos
```
lib/core/vision/models/
├── vision_event.dart        Eventos de detección por visión
├── face_data.dart          Datos de detección facial
└── hand_data.dart          Datos de detección de manos
```

**Descripción:**
- `VisionEvent`: Evento base para detecciones de visión (distracción, desatención, manos fuera)
- `FaceData`: Encapsula head pose estimation, estado de ojos, dirección de mirada
- `HandData`: Posiciones de manos con ROI de volante

**Ver:** [Documentación detallada en novedades.md](novedades.md#3-modelos-de-datos)

### Utilidades
```
lib/core/vision/utils/
├── frame_converter.dart    Conversión JPEG → InputImage
└── frame_subscriber.dart   Suscripción a frames con control de flujo
```

**Descripción:**
- `FrameConverter`: Convierte frames JPEG del ESP32-CAM a formato InputImage para MediaPipe
- `FrameSubscriber`: Gestiona suscripción a frames con rate limiting y estadísticas

**Ver:** [Documentación detallada en novedades.md](novedades.md#5-utilidades)

### Procesadores (Fase 2 - Pendiente)
```
lib/core/vision/processors/
├── face_mesh_processor.dart    ⏭️ Por implementar
├── pose_processor.dart          ⏭️ Por implementar
└── vision_processor.dart        ⏭️ Por implementar
```

### Detectores (Fase 2 - Pendiente)
```
lib/core/vision/detectors/
├── distraction_detector.dart    ⏭️ Por implementar
├── inattention_detector.dart    ⏭️ Por implementar
└── hands_off_detector.dart      ⏭️ Por implementar
```

---

## 🧪 Tests

### Tests de Modelos
```
test/core/vision/models/
└── vision_event_test.dart      18 tests ✅
```

**Cobertura:**
- Constructor y validaciones
- Métodos de utilidad (isHighConfidence, isCritical, requiresImmediateAlert)
- Serialización JSON
- Equatable comparisons

### Tests de Utilidades
```
test/core/vision/utils/
└── frame_converter_test.dart   14 tests ✅
```

**Cobertura:**
- Validación de JPEG
- Conversión de frames
- Manejo de errores
- Información de diagnóstico

**Total:** 32/32 tests pasando ✅

---

## 🔧 Componentes Modificados

### Enumeraciones Extendidas
- [lib/core/detection/models/event_type.dart](lib/core/detection/models/event_type.dart)
  - ✅ Agregados: `distraction`, `inattention`, `handsOff`
  - ✅ Nuevas propiedades: `isVisionBased`, `isIMUBased`, `isHybrid`, `icon`
  - ✅ Compatible con código existente

### Dependencias
- [pubspec.yaml](pubspec.yaml)
  - ✅ `google_mlkit_face_detection: ^0.10.0`
  - ✅ `google_mlkit_pose_detection: ^0.11.0`
  - ✅ `image: ^4.1.3`

---

## 📊 Diagramas de Arquitectura

### Flujo de Datos Completo

```
┌─────────────────────────────────────────────────────────────┐
│  HARDWARE                                                    │
├─────────────────────────────────────────────────────────────┤
│  ESP32-CAM (640x480 @ 5 FPS)                                │
│  ↓ WiFi HTTP POST                                           │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  RECEPCIÓN (✅ Fase 1)                                       │
├─────────────────────────────────────────────────────────────┤
│  HttpServerService                                          │
│  → frameStream: Stream<CameraFrame>                         │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  CONVERSIÓN (✅ Fase 1)                                      │
├─────────────────────────────────────────────────────────────┤
│  FrameSubscriber                                            │
│  → FrameConverter.fromJpegBytes()                           │
│  → inputImageStream: Stream<InputImage>                     │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  PROCESAMIENTO ML (⏭️ Fase 2)                                │
├─────────────────────────────────────────────────────────────┤
│  VisionProcessor                                            │
│  ├─ FaceMeshProcessor → FaceData                            │
│  └─ PoseProcessor → HandData                                │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  DETECCIÓN (⏭️ Fase 2)                                       │
├─────────────────────────────────────────────────────────────┤
│  DistractionDetector   → VisionEvent                        │
│  InattentionDetector   → VisionEvent                        │
│  HandsOffDetector      → VisionEvent (híbrido con IMU)      │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  AGREGACIÓN (⏭️ Fase 2)                                      │
├─────────────────────────────────────────────────────────────┤
│  EventAggregator (extendido)                                │
│  → Fusión de eventos IMU + Visión                           │
│  → Deduplicación y throttling                               │
└─────────────────────────────────────────────────────────────┘
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  PRESENTACIÓN (⏭️ Fase 2)                                    │
├─────────────────────────────────────────────────────────────┤
│  DashboardBloc → NotificationService → AlertOverlay         │
└─────────────────────────────────────────────────────────────┘
```

### Jerarquía de Modelos

```
EventType (enum extendido)
├── IMU-based
│   ├── harshBraking
│   ├── aggressiveAcceleration
│   ├── sharpTurn
│   ├── weaving
│   ├── roughRoad
│   └── speedBump
└── Vision-based (✅ Nuevos)
    ├── distraction      (imagen pura)
    ├── inattention      (imagen pura)
    └── handsOff         (híbrido: imagen + IMU)

VisionEvent (✅ Fase 1)
├── type: EventType
├── severity: EventSeverity
├── confidence: double (0.0 - 1.0)
└── metadata: Map<String, dynamic>

FaceData (✅ Fase 1)
├── face: Face (ML Kit)
├── headYaw, headPitch, headRoll
├── leftEyeOpen, rightEyeOpen
└── Methods: isLookingForward, isLookingAway, gazeDirection

HandData (✅ Fase 1)
├── pose: Pose (ML Kit)
├── leftHandInROI, rightHandInROI
├── steeringWheelROI: Rect
└── Methods: handsOnWheel, riskScore, handsStatus
```

---

## 🎯 Estado de Implementación

### Fase 1: Configuración y Preparación
**Estado:** ✅ COMPLETADA (26 Oct 2025)

- [x] Dependencias ML Kit instaladas
- [x] Estructura de directorios creada
- [x] Modelos de datos implementados
- [x] EventType extendido
- [x] FrameConverter implementado
- [x] FrameSubscriber implementado
- [x] Tests unitarios (32/32 ✅)
- [x] Análisis estático limpio
- [x] Documentación completa

### Fase 2: Implementación de Detectores
**Estado:** ⏭️ PENDIENTE (Inicio estimado: Nov 2025)

- [ ] FaceMeshProcessor
- [ ] PoseProcessor
- [ ] DistractionDetector
- [ ] InattentionDetector
- [ ] HandsOffDetector
- [ ] VisionProcessor (orquestador)
- [ ] Integración DashboardBloc
- [ ] Tests de integración

**Duración estimada:** 2-3 semanas

### Fase 3: Pruebas y Validación
**Estado:** ⏸️ FUTURA (Inicio estimado: Dic 2025)

- [ ] Tests funcionales end-to-end
- [ ] Calibración ESP32-CAM
- [ ] Optimización de rendimiento
- [ ] Edge cases
- [ ] Documentación de usuario

**Duración estimada:** 2 semanas

---

## 🔗 Enlaces Rápidos

### Documentación Técnica
- [Decisiones Técnicas](novedades.md#decisiones-técnicas-importantes)
- [Inconsistencias Solucionadas](novedades.md#inconsistencias-detectadas-y-solucionadas)
- [Lecciones Aprendidas](novedades.md#lecciones-aprendidas)

### Código
- [VisionEvent](lib/core/vision/models/vision_event.dart)
- [FaceData](lib/core/vision/models/face_data.dart)
- [HandData](lib/core/vision/models/hand_data.dart)
- [FrameConverter](lib/core/vision/utils/frame_converter.dart)
- [FrameSubscriber](lib/core/vision/utils/frame_subscriber.dart)

### Tests
- [VisionEvent Tests](test/core/vision/models/vision_event_test.dart)
- [FrameConverter Tests](test/core/vision/utils/frame_converter_test.dart)

### Planificación
- [Plan Maestro](PLAN_IMPLEMENTACION_VISION.md)
- [Fase 2 - Siguiente](PLAN_FASE2_IMPLEMENTACION.md)
- [Fase 3 - Futura](PLAN_FASE3_PRUEBAS.md)

---

## 📞 Soporte

**Para preguntas sobre implementación:**
- Revisar [novedades.md](novedades.md) para detalles técnicos
- Revisar [FASE1_RESUMEN.md](FASE1_RESUMEN.md) para overview

**Para comenzar Fase 2:**
- Seguir [PLAN_FASE2_IMPLEMENTACION.md](PLAN_FASE2_IMPLEMENTACION.md)
- Usar código de Fase 1 como base

**Para debugging:**
- Tests unitarios en `test/core/vision/`
- Logs habilitados en FrameConverter y FrameSubscriber

---

**🚀 Sistema de Visión DriveGuard**
**Versión:** 1.0.0-fase1
**Última actualización:** 2025-10-26
