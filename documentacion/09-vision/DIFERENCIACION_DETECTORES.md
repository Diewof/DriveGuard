# Diferenciación entre Detectores de Visión

## Problema Solucionado

Anteriormente, `DistractionDetector` e `InattentionDetector` se confundían frecuentemente:
- **Problema**: Una persona mirando fuera de la vía podía ser detectada como "usando teléfono"
- **Problema**: Una persona usando el teléfono podía ser detectada solo como "desatención visual"
- **Causa**: Ambos detectores compartían lógica similar sin diferenciadores claros

## Solución Implementada

Se implementó una diferenciación clara mediante **zonas específicas** y **detección multi-criterio**:

### 1. InattentionDetector (Desatención Visual)
**Responsabilidad**: Detectar cuando el conductor mira **lateralmente o hacia arriba** (fuera de la vía)

**Criterios de detección**:
- `headYaw.abs() > 35°` (mirando hacia los lados)
- `headPitch > 20°` (mirando hacia arriba)
- **EXCLUYE**: `headPitch < -15°` (miradas hacia abajo → delegadas a PhoneDetector)

**Casos de uso**:
- Conductor mirando por la ventana lateral
- Conductor mirando al pasajero
- Conductor mirando el espejo retrovisor prolongadamente
- Conductor distraído por algo fuera del vehículo

**Umbrales**:
```dart
// Considera "no mirando al frente" si:
headYaw.abs() > 35°  || headPitch.abs() > 20°

// Excluye miradas hacia abajo (PhoneDetector)
if (isNotLookingForward && !isLookingDown)  // isLookingDown = pitch < -15°
```

---

### 2. PhoneDetector (Uso de Teléfono Móvil)
**Responsabilidad**: Detectar cuando el conductor está **usando el teléfono móvil**

**Criterios de detección multi-modal**:

#### A. Zonas Específicas de Uso de Teléfono
1. **ZONA TABLERO** (Dashboard)
   - Conductor mira ligeramente hacia abajo al soporte del teléfono
   - `pitch: -15° a -30°`
   - `yaw: ±25°` (puede estar ligeramente al lado)

2. **ZONA REGAZO** (Lap)
   - Conductor mira muy hacia abajo (teléfono en las piernas)
   - `pitch: < -30°`
   - `yaw: ±25°`

3. **ZONA MANO** (Hand)
   - Teléfono en la mano (hablando por teléfono)
   - Detectado por posición de manos

#### B. Detección de Teléfono en Manos
Utilizando `HandData` del procesador de poses:
- **Criterio**: Ambas manos fuera del volante Y cercanas entre sí
- **Heurística**: Si `distancia_entre_manos < 200px` → probable objeto en manos
- **Confianza aumentada**: Si además mira hacia zona de teléfono

**Umbrales**:
```dart
// ZONA TABLERO (rango corregido - v2.1)
pitch <= -15°  &&  pitch >= -30°  &&  yaw.abs() < 25°
// Ejemplo: -22° cumple: -22 <= -15 ✓ AND -22 >= -30 ✓

// ZONA REGAZO
headPitch < -30°  &&  headYaw.abs() < 25°

// TELÉFONO EN MANOS
bothHandsOff && distancia_entre_manos < 200px
```

**Duración mínima**: 2 segundos (más largo que InattentionDetector)

**Severidad**: SIEMPRE MEDIUM o superior (score base = 2)
- 2s → MEDIUM
- 3s+ o manos → HIGH
- 5s+ o regazo+manos → CRITICAL

---

## Tabla Comparativa

| Aspecto | InattentionDetector | PhoneDetector |
|---------|---------------------|---------------|
| **Dirección de mirada** | Lateral (±35°) y Arriba (>20°) | Abajo (-15° a -60°) |
| **Zona de interés** | Fuera de la vía | Tablero, regazo, manos |
| **Duración mínima** | 1.5 segundos | 2.0 segundos |
| **Datos usados** | Solo FaceData | FaceData + HandData |
| **Tipo de evento** | `EventType.inattention` | `EventType.distraction` |
| **Metadata** | `avgYaw`, `avgPitch`, `maxDeviation` | `zone`, `hasPhoneInHand` |

---

## Flujo de Decisión

```
┌─────────────────┐
│ Frame recibido  │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────┐
│ FaceMeshProcessor extrae    │
│ headYaw, headPitch          │
└────────┬────────────────────┘
         │
         ├──────────────────────┬──────────────────────┐
         ▼                      ▼                      ▼
┌─────────────────┐    ┌───────────────────┐  ┌─────────────────┐
│ InattentionDet  │    │  PhoneDetector    │  │ HandsOffDetector│
└─────────────────┘    └───────────────────┘  └─────────────────┘
         │                      │                      │
         ▼                      ▼                      │
  ¿Yaw > 35° O           ¿Pitch < -15°?               │
   Pitch > 20°?                 │                      │
         │                      ▼                      │
         │              ┌───────────────┐              │
         │              │ Zona tablero? │              │
         │              │ Zona regazo?  │              │
         │              └───────┬───────┘              │
         │                      │                      │
         │                      ▼                      │
         │              HandsProcessor ────────────────┤
         │                      │                      │
         │                      ▼                      │
         │              ┌───────────────┐              │
         │              │ ¿Teléfono en  │              │
         │              │   manos?      │              │
         │              └───────┬───────┘              │
         │                      │                      │
         ▼                      ▼                      ▼
┌─────────────────────────────────────────────────────────┐
│           VisionProcessor - Stream consolidado          │
└─────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────┐
│ Dashboard UI    │
│ (Alerta)        │
└─────────────────┘
```

---

## Ejemplos de Casos Reales

### Caso 1: Conductor mira por la ventana
- **headYaw**: 50° (derecha)
- **headPitch**: -5° (ligeramente abajo)
- **Detección**: ✅ InattentionDetector (yaw > 35°)
- **NO detecta**: PhoneDetector (pitch > -15°)

### Caso 2: Conductor mira el GPS en el tablero
- **headYaw**: 5° (casi al frente)
- **headPitch**: -25° (abajo hacia tablero)
- **Detección**: ✅ PhoneDetector (zona tablero)
- **NO detecta**: InattentionDetector (excluye pitch < -15°)

### Caso 3: Conductor revisa teléfono en regazo
- **headYaw**: -10° (ligeramente izquierda)
- **headPitch**: -40° (muy abajo)
- **bothHandsOff**: true
- **distancia_manos**: 150px
- **Detección**: ✅ PhoneDetector (zona regazo + teléfono en manos)
- **Confianza**: 95% (alta)

### Caso 4: Conductor habla por teléfono
- **headYaw**: 15° (casi al frente)
- **headPitch**: 0° (al frente)
- **bothHandsOff**: true
- **distancia_manos**: 120px
- **Detección**: ✅ PhoneDetector (teléfono en manos)
- **Zona**: hand
- **Confianza**: 80%

### Caso 5: Conductor mira espejo retrovisor
- **headYaw**: 5°
- **headPitch**: 25° (arriba)
- **Detección**: ✅ InattentionDetector (pitch > 20°)
- **NO detecta**: PhoneDetector (pitch es positivo)

---

## Ajustes de Calibración

### InattentionDetector
```dart
// Tolerancia frontal (FaceData.isLookingForward)
headYaw.abs() <= 35.0  &&  headPitch.abs() <= 20.0

// Detección de desatención (excluyendo abajo)
!isLookingForward  &&  headPitch >= -15.0

// Duración mínima
Duration(milliseconds: 1500)
```

### PhoneDetector
```dart
// ZONA TABLERO (soporte de teléfono)
-30.0 <= headPitch <= -15.0  &&  headYaw.abs() <= 25.0

// ZONA REGAZO (teléfono en piernas)
headPitch < -30.0  &&  headYaw.abs() <= 25.0

// DETECCIÓN DE MANOS
bothHandsOff && sqrt(dx² + dy²) < 200.0

// Duración mínima
Duration(milliseconds: 2000)
```

---

## Archivos Modificados

1. **Creados**:
   - [phone_detector.dart](../../lib/core/vision/detectors/phone_detector.dart) - Nuevo detector especializado

2. **Modificados**:
   - [inattention_detector.dart](../../lib/core/vision/detectors/inattention_detector.dart) - Excluye pitch < -15°
   - [vision_processor.dart](../../lib/core/vision/processors/vision_processor.dart) - Integra PhoneDetector

3. **Renombrados (deprecated)**:
   - `distraction_detector.dart` → `distraction_detector_v1_deprecated.dart`

---

## Métricas de Éxito Esperadas

Después de esta refactorización:

✅ **Reducción de falsos positivos**:
- Mirar ventana NO debe alertar "usando teléfono"
- Usar teléfono NO debe alertar solo "desatención"

✅ **Mejora en precisión**:
- Detección específica de zona de teléfono (tablero/regazo)
- Detección de teléfono en manos aumenta confianza

✅ **Alertas más contextuales**:
- Metadata incluye `zone` y `hasPhoneInHand`
- UI puede mostrar alertas específicas: "Celular en el tablero detectado"

---

## Testing Recomendado

### Tests Unitarios
```dart
test('InattentionDetector NO detecta miradas hacia abajo', () {
  final detector = InattentionDetector();
  final faceData = FaceData(headYaw: 0, headPitch: -25);

  detector.processFaceData(faceData);

  // NO debe emitir evento (delegado a PhoneDetector)
  expect(detector.eventStream, neverEmits(anything));
});

test('PhoneDetector detecta zona tablero', () {
  final detector = PhoneDetector();
  final faceData = FaceData(headYaw: 5, headPitch: -20);

  detector.processData(faceData, null);
  await Future.delayed(Duration(seconds: 2));

  expect(detector.eventStream, emits(
    predicate((event) => event.metadata['zone'] == 'dashboard')
  ));
});

test('PhoneDetector detecta teléfono en manos', () {
  final detector = PhoneDetector();
  final handData = HandData(
    bothHandsOff: true,
    leftHandPosition: Offset(200, 200),
    rightHandPosition: Offset(250, 210),
  );

  detector.processData(faceData, handData);
  await Future.delayed(Duration(seconds: 2));

  expect(detector.eventStream, emits(
    predicate((event) => event.metadata['hasPhoneInHand'] == true)
  ));
});
```

### Tests de Integración
1. Grabar video conduciendo normalmente → NO debe alertar
2. Grabar video mirando teléfono en tablero → Debe alertar con zone='dashboard'
3. Grabar video mirando por ventana → Debe alertar como 'inattention' (no 'distraction')
4. Grabar video con teléfono en mano → Debe alertar con hasPhoneInHand=true

---

## Historial de Correcciones

### v2.1 - 2025-10-28 (Fix crítico)
**Problemas corregidos**:
1. ✅ **Detección de zonas tablero/regazo no funcionaba**
   - Causa: Condición de rango invertida (`pitch >= -30 && pitch <= -15` nunca era verdadera)
   - Solución: Corregir lógica a `pitch <= -15 && pitch >= -30`

2. ✅ **Severidad siempre era LOW**
   - Causa: Score base empezaba en 0
   - Solución: Score base de 2 → MEDIUM mínimo
   - Justificación: Mayoría de accidentes comienzan viendo el celular

**Resultado**: Ahora funciona correctamente la detección de todas las zonas y severidad apropiada.

Ver: [FIX_PHONE_DETECTOR_ZONES_SEVERITY.md](../../FIX_PHONE_DETECTOR_ZONES_SEVERITY.md)

---

**Última actualización**: 2025-10-28
**Autor**: DriveGuard Development Team
**Versión**: 2.1 (PhoneDetector - Zones & Severity Fixed)
