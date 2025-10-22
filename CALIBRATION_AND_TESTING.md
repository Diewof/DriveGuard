# 🎯 Sistema de Calibración y Detección Mejorada - DriveGuard

## 📋 Resumen de Cambios Implementados

### ✅ 1. Auto-Calibración de Orientación del Dispositivo

**Archivo creado:** `lib/core/services/orientation_calibrator.dart`

El sistema ahora detecta automáticamente la orientación del teléfono al inicio de cada sesión:

- **Duración de calibración:** 3 segundos (30 muestras a 10 Hz)
- **Detección automática:** Identifica qué eje recibe la gravedad (9.8 m/s²)
- **Orientaciones soportadas:**
  - Portrait (vertical)
  - Landscape Left/Right (horizontal)
  - Face Up/Down (plano)
- **Transformación de coordenadas:** Normaliza todos los datos para que Z siempre apunte hacia arriba

### ✅ 2. Umbrales Ajustados para Condiciones Reales

**Archivo modificado:** `lib/core/constants/app_constants.dart`

#### Valores Anteriores vs Nuevos:

| Métrica | Valor Anterior | Valor Nuevo | Razón |
|---------|----------------|-------------|-------|
| Aceleración temeraria | 3.0 m/s² | **1.5 m/s²** | Más sensible para detectar maniobras bruscas |
| Impacto/Crash | 15.0 m/s² | **8.0 m/s²** | Detectar impactos moderados |
| Giroscopio temerario | 45°/s | **25°/s** | Capturar curvas cerradas |
| Frenado brusco | N/A | **2.0 m/s²** | Nuevo umbral específico |
| Aceleración agresiva | N/A | **2.0 m/s²** | Nuevo umbral específico |
| Curva cerrada | N/A | **20°/s** | Nuevo umbral específico |

### ✅ 3. Detección por Deltas (Cambios Bruscos)

**Archivo modificado:** `lib/core/services/device_sensor_service.dart`

Nueva clase `PeakDetector` que detecta cambios súbitos:

- **Delta de aceleración:** 2.0 m/s² en 0.5s
- **Delta de giroscopio:** 20°/s en 0.5s
- **Detección sin filtro:** Captura picos que el filtrado podría ocultar

### ✅ 4. Filtrado Optimizado

- **Ventana reducida:** De 5 valores a 2 valores
- **Detector paralelo:** PeakDetector trabaja con datos sin filtrar
- **Mejor respuesta:** Eventos críticos se detectan más rápido

### ✅ 5. Pantalla de Diagnóstico Mejorada

**Archivo modificado:** `lib/presentation/pages/sensor_diagnostics_page.dart`

Nuevas características:
- ✅ Estado de calibración en tiempo real
- ✅ Orientación detectada del dispositivo
- ✅ Comparación Raw vs Filtrado
- ✅ Umbrales actualizados con indicadores visuales
- ✅ Línea base de gravedad mostrada

---

## 🧪 Instrucciones de Prueba

### Fase 1: Verificación de Calibración

1. **Abrir la app** y navegar a "Diagnóstico de Sensores"

2. **Verificar calibración automática:**
   - Durante los primeros 3 segundos, debe aparecer "Calibrando..."
   - Mantener el teléfono estable en su soporte
   - Observar qué orientación se detecta (ej: "Landscape Left")

3. **Validar línea base:**
   - Verificar que uno de los ejes X/Y/Z tenga aproximadamente ±9.8 m/s²
   - Los otros ejes deberían estar cerca de 0

### Fase 2: Pruebas de Detección en Condiciones Reales

#### Escenario A: Teléfono en Soporte de Tablero (Horizontal)

**Setup:**
```
Posición: Teléfono montado horizontalmente en el tablero
Orientación esperada: Landscape Left o Landscape Right
```

**Pruebas:**

1. **Frenado Normal**
   - Aplicar freno suavemente
   - Esperado: Cambio de 1.0-2.0 m/s² (sin alerta)
   - Observar valores en pantalla de diagnóstico

2. **Frenado Brusco**
   - Frenar con fuerza (seguro en área controlada)
   - Esperado: Cambio de 2.5-4.0 m/s² (ALERTA)
   - Verificar que se dispare notificación

3. **Aceleración Normal**
   - Acelerar suavemente
   - Esperado: Cambio de 1.0-2.0 m/s² (sin alerta)

4. **Aceleración Agresiva**
   - Acelerar rápidamente
   - Esperado: Cambio de 2.5-4.0 m/s² (ALERTA)

5. **Curva Normal**
   - Girar suavemente a 30-40 km/h
   - Esperado: Rotación de 10-20°/s (sin alerta)

6. **Curva Cerrada**
   - Girar bruscamente
   - Esperado: Rotación de 25-50°/s (ALERTA)

#### Escenario B: Teléfono en Soporte de Parabrisas (Vertical)

**Setup:**
```
Posición: Teléfono montado verticalmente en parabrisas
Orientación esperada: Portrait
```

Repetir las mismas pruebas del Escenario A y validar que:
- La calibración detecte la orientación correcta
- Los valores se normalicen correctamente
- Las alertas se disparen con los mismos umbrales

### Fase 3: Validación de Comparación Raw vs Filtrado

1. **Navegar a Diagnóstico de Sensores**

2. **Observar la sección "Comparación: Raw vs Filtrado"**

3. **Durante conducción:**
   - Valores Raw deben ser más ruidosos (cambios rápidos)
   - Valores Filtrados deben ser más suaves
   - Delta (Δ) debe ser pequeño en reposo (<0.1)
   - Delta debe aumentar durante movimiento

4. **Validar detector de picos:**
   - En eventos bruscos, debería aparecer en logs:
     ```
     ⚡ [PEAK DETECTOR] Pico detectado - ΔAccel: (2.50, 1.20, 0.80) | ΔGyro: (15.5°, 8.2°, 3.1°)
     ```

### Fase 4: Pruebas de Estrés

**Objetivo:** Validar que el sistema no genere falsos positivos

1. **Camino con baches:**
   - Conducir sobre superficie irregular
   - Esperado: Puede detectar "Rough Road" pero NO temeraria

2. **Túnel de lavado de autos:**
   - Dejar el coche en túnel de lavado
   - Esperado: Sin alertas de conducción temeraria

3. **Estacionamiento:**
   - Aparcar en estacionamiento con rampas
   - Esperado: Puede detectar inclinación pero sin alertas críticas

---

## 📊 Valores de Referencia Esperados

### En Reposo (Vehículo Detenido)

```
Aceleración:
  - Eje vertical: ±9.8 m/s² (gravedad)
  - Ejes horizontales: 0 ± 0.5 m/s²

Giroscopio:
  - Todos los ejes: 0 ± 2°/s
```

### Conducción Normal

```
Aceleración:
  - Frenado: -0.5 a -2.0 m/s²
  - Aceleración: +0.5 a +2.0 m/s²
  - Curvas: 0.5 a 1.5 m/s² lateral

Giroscopio:
  - Curvas suaves: 5-15°/s
  - Cambios de carril: 2-8°/s
```

### Conducción Agresiva (Debe Generar Alertas)

```
Aceleración:
  - Frenado brusco: -2.5 a -6.0 m/s²
  - Aceleración fuerte: +2.5 a +5.0 m/s²
  - Curvas cerradas: 2.0 a 4.0 m/s² lateral

Giroscopio:
  - Curvas cerradas: 25-60°/s
  - Maniobras evasivas: 40-80°/s
```

### Eventos Críticos

```
Aceleración:
  - Impacto moderado: 8.0-12.0 m/s²
  - Impacto fuerte: >12.0 m/s²

Giroscopio:
  - Pérdida de control: >80°/s sostenido
```

---

## 🐛 Debugging y Logs

### Activar Logs Detallados

Los siguientes mensajes aparecerán en la consola durante el funcionamiento:

```dart
// Calibración
📱 [CALIBRACIÓN] Iniciando calibración de orientación...
📊 [CALIBRACIÓN] Aceleración promedio: X, Y, Z
✅ [CALIBRACIÓN] Orientación detectada: Landscape Left
📐 [CALIBRACIÓN] Línea base gravedad: (x, y, z)

// Detección de picos
⚡ [PEAK DETECTOR] Pico detectado - ΔAccel: (...) | ΔGyro: (...)

// Sensor Service
✅ [SENSOR SERVICE] Calibración completada
```

### Acceder a Información de Calibración Programáticamente

```dart
final calibrationInfo = sensorService.calibrator.getCalibrationInfo();
print('Is calibrated: ${calibrationInfo['isCalibrated']}');
print('Orientation: ${calibrationInfo['orientation']}');
print('Gravity baseline: ${calibrationInfo['gravityBaseline']}');
```

---

## ⚙️ Configuración Avanzada

### Ajustar Umbrales en Tiempo Real

Editar `lib/core/constants/app_constants.dart`:

```dart
// Hacer más sensible (más alertas)
static const double recklessAccelThreshold = 1.0;  // De 1.5
static const double recklessGyroThreshold = 20.0;  // De 25.0

// Hacer menos sensible (menos alertas)
static const double recklessAccelThreshold = 2.5;  // De 1.5
static const double recklessGyroThreshold = 35.0;  // De 25.0
```

### Cambiar Duración de Calibración

```dart
static const int calibrationSamples = 50;          // De 30 (más largo)
static const int calibrationDurationSeconds = 5;   // De 3 (más tiempo)
```

### Ajustar Ventana de Filtrado

```dart
static const int sensorFilterWindowSize = 3;  // De 2 (más suavizado)
```

---

## 📝 Checklist de Validación

### Pre-Lanzamiento

- [ ] Calibración detecta correctamente orientación en soporte de tablero
- [ ] Calibración detecta correctamente orientación en soporte de parabrisas
- [ ] Frenados bruscos generan alertas consistentemente
- [ ] Aceleraciones agresivas generan alertas
- [ ] Curvas cerradas generan alertas
- [ ] Conducción normal NO genera falsos positivos
- [ ] Caminos con baches NO generan alertas de conducción temeraria
- [ ] Comparación Raw vs Filtrado muestra datos coherentes
- [ ] Umbrales visuales en diagnóstico reflejan valores correctos

### Testing Beta

- [ ] Probar en al menos 3 modelos de teléfono diferentes
- [ ] Probar en al menos 2 tipos de soporte diferentes
- [ ] Recopilar feedback sobre sensibilidad de alertas
- [ ] Validar que no hay crashes durante calibración
- [ ] Confirmar que batería no se drena excesivamente

---

## 🔧 Solución de Problemas

### Problema: Calibración no se completa

**Síntomas:** Se queda en "Calibrando..." por más de 5 segundos

**Soluciones:**
1. Verificar que el teléfono tiene sensores funcionando
2. Asegurar que el teléfono está estable (no en movimiento)
3. Revisar logs para errores de sensores

### Problema: Demasiadas alertas (falsos positivos)

**Síntomas:** Alertas constantes durante conducción normal

**Soluciones:**
1. Aumentar umbrales en `app_constants.dart`
2. Verificar que calibración detectó orientación correcta
3. Revisar que el teléfono está bien sujeto al soporte

### Problema: No se generan alertas

**Síntomas:** Conducción agresiva no dispara notificaciones

**Soluciones:**
1. Reducir umbrales en `app_constants.dart`
2. Verificar que el monitoreo está activo
3. Comprobar logs del detector de picos
4. Validar que notificaciones están habilitadas

### Problema: Valores raw y filtrados son idénticos

**Síntomas:** Delta siempre es 0.00 en comparación

**Soluciones:**
1. Verificar que `sensorFilterWindowSize` no es 1
2. Asegurar que hay movimiento del dispositivo
3. Revisar que ambos streams están activos

---

## 📞 Soporte

Para reportar problemas o sugerir mejoras:
- Incluir logs completos de la sesión
- Especificar modelo de teléfono y versión de Android
- Describir tipo de soporte usado
- Adjuntar captura de pantalla de diagnóstico

---

**Última actualización:** 2025-10-22
**Versión del sistema:** 1.1.0
**Autor:** DriveGuard Development Team
