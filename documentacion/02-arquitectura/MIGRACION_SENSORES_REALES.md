# Migración a Sensores Reales del Dispositivo Android

## Resumen

Se ha completado exitosamente la migración del sistema de sensores simulados a sensores reales del dispositivo Android. La aplicación DriveGuard ahora utiliza el acelerómetro y giroscopio físicos del teléfono para detectar patrones de conducción en tiempo real.

## Estado: ✅ COMPLETADO

**Fecha de migración**: 2025-10-19

## Cambios Implementados

### FASE 1: Dependencias y Permisos ✅

**Archivos modificados:**
- [pubspec.yaml](../../pubspec.yaml) - Línea 40
- [AndroidManifest.xml](../../android/app/src/main/AndroidManifest.xml) - Líneas 18-20

**Cambios realizados:**
- ✅ Agregada dependencia `sensors_plus: ^6.0.1`
- ✅ Agregado permiso `HIGH_SAMPLING_RATE_SENSORS`
- ✅ Declaradas features requeridas: acelerómetro y giroscopio

### FASE 2: Servicio de Sensores Reales ✅

**Archivo nuevo:**
- [device_sensor_service.dart](../../lib/core/services/device_sensor_service.dart)

**Funcionalidad implementada:**
- ✅ Clase `DeviceSensorService` que reemplaza a `SensorSimulator`
- ✅ Fusión de streams de acelerómetro y giroscopio
- ✅ Conversión de rad/s a deg/s para giroscopio
- ✅ Cálculo automático de nivel de vibración
- ✅ Filtro de media móvil (`SensorDataFilter`) con ventana de 5 muestras
- ✅ Manejo de errores en streams de sensores

**Interfaz pública:**
```dart
class DeviceSensorService {
  Stream<SensorData> get stream;
  bool get isRunning;
  void startMonitoring();
  void stopMonitoring();
  void dispose();
}
```

### FASE 3: Integración con DashboardBloc ✅

**Archivo modificado:**
- [dashboard_bloc.dart](../../lib/presentation/blocs/dashboard/dashboard_bloc.dart)

**Cambios realizados:**
- ✅ Línea 7: Import de `sensor_service_factory.dart`
- ✅ Línea 19: Uso de `ISensorService` en lugar de `SensorSimulator`
- ✅ Línea 68: `_sensorService.start()` en lugar de `startSimulation()`
- ✅ Línea 84: `_sensorService.stop()` en lugar de `stopSimulation()`
- ✅ Línea 156: Stream actualizado a `_sensorService.stream`
- ✅ Línea 469: Dispose actualizado

### FASE 4: Filtrado de Ruido y Umbrales ✅

**Archivo modificado:**
- [app_constants.dart](../../lib/core/constants/app_constants.dart) - Línea 37

**Cambios realizados:**
- ✅ Agregado flag `useRealSensors = true`
- ✅ Filtro de media móvil implementado en `DeviceSensorService`
- ✅ Ventana de filtrado de 5 muestras
- ✅ Umbrales existentes validados (pueden requerir calibración en campo)

**Umbrales actuales:**
```dart
static const double recklessAccelThreshold = 3.0;   // m/s²
static const double crashAccelThreshold = 15.0;      // m/s²
static const double recklessGyroThreshold = 45.0;    // deg/s
```

### FASE 5: Factory Pattern ✅

**Archivo nuevo:**
- [sensor_service_factory.dart](../../lib/core/services/sensor_service_factory.dart)

**Funcionalidad implementada:**
- ✅ Interfaz `ISensorService` para abstracción
- ✅ Adaptadores para `DeviceSensorService` y `SensorSimulator`
- ✅ Factory `SensorServiceFactory.create()` con parámetro configurable
- ✅ Selección automática basada en `AppConstants.useRealSensors`

**Uso:**
```dart
// En producción (sensores reales)
final sensorService = SensorServiceFactory.create(); // usa AppConstants.useRealSensors

// Para testing (simulador)
final sensorService = SensorServiceFactory.create(useRealSensors: false);
```

### FASE 6: Pantalla de Diagnóstico ✅

**Archivos nuevos/modificados:**
- [sensor_diagnostics_page.dart](../../lib/presentation/pages/sensor_diagnostics_page.dart) - NUEVO
- [app_router.dart](../../lib/core/routing/app_router.dart) - Líneas 10, 56-59

**Funcionalidad implementada:**
- ✅ Vista en tiempo real de valores de acelerómetro (X, Y, Z)
- ✅ Vista en tiempo real de valores de giroscopio (X, Y, Z)
- ✅ Barras de progreso para umbrales configurados
- ✅ Historial de alertas detectadas (últimas 10)
- ✅ Controles para iniciar/detener monitoreo
- ✅ Indicadores visuales cuando se exceden umbrales

**Acceso:**
- Ruta: `/sensor-diagnostics`
- Nombre de ruta: `sensor-diagnostics`

### FASE 7: Código Legacy Marcado como Deprecated ✅

**Archivo modificado:**
- [sensor_simulator.dart](../../lib/core/mocks/sensor_simulator.dart) - Líneas 8-15

**Cambios realizados:**
- ✅ Anotación `@Deprecated` en clase `SensorSimulator`
- ✅ Documentación clara sobre uso solo para testing
- ✅ Referencia a `DeviceSensorService` como reemplazo

## Arquitectura Final

```
┌─────────────────────────────────────────────────────────┐
│                    DashboardBloc                        │
│  (usa ISensorService a través de Factory)              │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│              SensorServiceFactory                       │
│  - create(useRealSensors: bool)                         │
└──────────────────┬─────────────────┬────────────────────┘
                   │                 │
        ┌──────────▼────────┐   ┌───▼─────────────────┐
        │ DeviceSensorService│   │ SensorSimulator     │
        │  (PRODUCCIÓN)      │   │ (TESTING/DEV)       │
        │                    │   │  @Deprecated        │
        └──────────┬─────────┘   └─────────────────────┘
                   │
        ┌──────────▼────────┐
        │  sensors_plus     │
        │  - acelerómetro   │
        │  - giroscopio     │
        └───────────────────┘
```

## Compatibilidad

### ✅ Retrocompatibilidad Mantenida
- `SensorData` no requirió cambios
- Umbrales de detección conservados
- Métodos `isRecklessDriving` y `isCrashDetected` funcionan igual
- Posible alternar entre simulador y sensores reales con un flag

### ⚠️ Consideraciones
- Los umbrales pueden necesitar calibración después de pruebas en campo
- El filtro de ruido está optimizado para datos a ~100ms de intervalo
- Requiere dispositivos Android con acelerómetro y giroscopio

## Pruebas Recomendadas

### Pruebas en Desarrollo
1. Usar la pantalla de diagnóstico `/sensor-diagnostics`
2. Validar que ambos sensores emiten datos
3. Probar diferentes movimientos del dispositivo
4. Verificar que los umbrales se activan correctamente

### Pruebas en Campo (Vehículo Real)
1. **Conducción Normal**
   - Verificar que no hay falsas alarmas
   - Validar que el riesgo se mantiene bajo

2. **Frenada Brusca**
   - Confirmar detección de aceleración lateral/frontal
   - Validar alerta de "CONDUCCIÓN TEMERARIA"

3. **Giro Cerrado**
   - Confirmar detección de giroscopio elevado
   - Validar alerta apropiada

4. **Baches y Vibraciones**
   - Verificar que el filtro reduce falsos positivos
   - Ajustar ventana de filtrado si es necesario

5. **Simulación de Impacto** (con precaución)
   - Validar detección de impacto a >15 m/s²
   - Confirmar alerta "IMPACTO DETECTADO"

## Calibración de Umbrales

Si se detectan demasiados falsos positivos o falsos negativos, ajustar en [app_constants.dart](../../lib/core/constants/app_constants.dart):

```dart
// Valores conservadores (menos alertas)
static const double recklessAccelThreshold = 4.0;   // Aumentar
static const double crashAccelThreshold = 20.0;      // Aumentar
static const double recklessGyroThreshold = 60.0;    // Aumentar

// Valores sensibles (más alertas)
static const double recklessAccelThreshold = 2.0;   // Reducir
static const double crashAccelThreshold = 12.0;      // Reducir
static const double recklessGyroThreshold = 30.0;    // Reducir
```

## Configuración de Modo de Desarrollo

Para usar el simulador durante desarrollo:

**Opción 1: Flag global** (en [app_constants.dart](../../lib/core/constants/app_constants.dart))
```dart
static const bool useRealSensors = false; // Usar simulador
```

**Opción 2: Instancia directa** (en código)
```dart
final sensorService = SensorServiceFactory.create(useRealSensors: false);
```

## Build y Deployment

### Build Exitoso ✅
```bash
flutter build apk --debug
# Resultado: √ Built build\app\outputs\flutter-apk\app-debug.apk (140.6s)
```

### Análisis de Código
```bash
flutter analyze
# Resultado: 72 info (warnings menores de linting, no errors)
```

## Próximos Pasos Recomendados

1. **Calibración en Campo** - Probar con diferentes vehículos y estilos de conducción
2. **Logging Mejorado** - Reemplazar `print()` con framework de logging profesional
3. **Telemetría** - Enviar datos de sensores a Firebase para análisis
4. **Machine Learning** - Entrenar modelo con datos reales de conducción
5. **Ajuste Dinámico** - Permitir al usuario ajustar sensibilidad de alertas

## Archivos Creados

1. `lib/core/services/device_sensor_service.dart` - Servicio de sensores reales
2. `lib/core/services/sensor_service_factory.dart` - Factory pattern
3. `lib/presentation/pages/sensor_diagnostics_page.dart` - Pantalla de diagnóstico
4. `documentacion/02-arquitectura/MIGRACION_SENSORES_REALES.md` - Este documento

## Archivos Modificados

1. `pubspec.yaml` - Dependencia sensors_plus
2. `android/app/src/main/AndroidManifest.xml` - Permisos de sensores
3. `lib/core/constants/app_constants.dart` - Flag useRealSensors
4. `lib/presentation/blocs/dashboard/dashboard_bloc.dart` - Integración con servicio real
5. `lib/core/routing/app_router.dart` - Ruta de diagnóstico
6. `lib/core/mocks/sensor_simulator.dart` - Marcado como deprecated

## Conclusión

✅ La migración a sensores reales se completó exitosamente sin romper funcionalidad existente.

✅ La aplicación ahora puede detectar patrones de conducción reales usando hardware del dispositivo.

✅ Se mantiene compatibilidad con simulador para desarrollo y testing.

✅ Build compila correctamente sin errores.

---

**Migración completada por**: Claude Code
**Fecha**: 2025-10-19
**Versión de la app**: 1.0.0+1
