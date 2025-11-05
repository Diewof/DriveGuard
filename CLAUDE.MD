# Directrices de Desarrollo - DriveGuard

> **IMPORTANTE**: Este documento es leído automáticamente por Claude Code en cada sesión.
> Establece los estándares y mejores prácticas para el desarrollo del proyecto DriveGuard.

## 🎯 Objetivo del Proyecto
DriveGuard es una **BETA funcional** - un sistema de monitoreo inteligente de conducción que integra sensores y visión por computadora para detectar comportamientos de riesgo al volante.

**Prioridad**: Funcionalidad simple y práctica sobre perfección técnica.

## Principios de Clean Code

### 1. DRY (Don't Repeat Yourself)
- **Eliminar duplicación**: Si un código se repite más de dos veces, debe extraerse a una función, clase o módulo reutilizable.
- **Centralizar lógica común**: Crear utilidades y servicios compartidos para funcionalidades comunes.
- **Evitar código redundante**: Usar herencia, composición o mixins cuando sea apropiado.

**Ejemplo práctico:**
```dart
// ❌ Mal - Código repetido
if (acceleration > threshold && duration > minDuration && magnitude > minMagnitude) { }
if (acceleration > threshold && duration > minDuration && magnitude > minMagnitude) { }

// ✅ Bien - Extraído a función
bool meetsDetectionCriteria(double acceleration, double duration, double magnitude) {
  return acceleration > threshold && duration > minDuration && magnitude > minMagnitude;
}
```

### 2. KISS (Keep It Simple, Stupid)
- **Simplicidad sobre complejidad**: Preferir soluciones simples y directas.
- **Evitar sobre-ingeniería**: No agregar capas de abstracción innecesarias.
- **Código legible**: El código debe ser fácil de entender a primera vista.
- **Funciones pequeñas**: Cada función debe hacer una sola cosa y hacerla bien.

**Ejemplo práctico:**
```dart
// ❌ Mal - Sobre-ingeniería
class ComplexDetectorFactory {
  AbstractDetectorBuilder createBuilder(DetectorType type) {
    return DetectorBuilderFactory.getInstance()
      .getBuilder(type)
      .withStrategy(new DefaultStrategy());
  }
}

// ✅ Bien - Simple y directo
class DetectorFactory {
  Detector createDetector(DetectorType type) {
    switch (type) {
      case DetectorType.braking: return HarshBrakingDetector();
      case DetectorType.acceleration: return AggressiveAccelerationDetector();
    }
  }
}
```

### 3. YAGNI (You Ain't Gonna Need It)
- **No anticipar necesidades futuras**: Solo implementar lo que se necesita ahora.
- **Evitar características especulativas**: No agregar funcionalidad "por si acaso".
- **Refactorizar cuando sea necesario**: Es mejor agregar funcionalidad cuando realmente se necesite.

**Ejemplo práctico:**
```dart
// ❌ Mal - Funcionalidad innecesaria
class SensorData {
  double x, y, z;
  DateTime timestamp;
  String deviceId;
  Map<String, dynamic> metadata; // ¿Se usa? Probablemente no
  List<String> tags; // ¿Se necesita? No ahora
  int version; // ¿Para qué? Especulación
}

// ✅ Bien - Solo lo necesario
class SensorData {
  final double x;
  final double y;
  final double z;
  final DateTime timestamp;
}
```

## Estándares de Código

### Nombrado
- **Clases**: PascalCase descriptivo (`HarshBrakingDetector`, `SensorDataProcessor`)
- **Funciones/Métodos**: camelCase con verbos (`detectEvent`, `processReading`, `calculateMagnitude`)
- **Variables**: camelCase descriptivo (`accelerationMagnitude`, `detectionThreshold`)
- **Constantes**: UPPER_SNAKE_CASE (`MAX_THRESHOLD`, `DEFAULT_WINDOW_SIZE`)
- **Archivos**: snake_case (`harsh_braking_detector.dart`, `sensor_data_processor.dart`)

### Estructura de Código
```dart
// 1. Imports (agrupados: dart, flutter, packages, relative)
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/sensor_data.dart';

// 2. Constantes
const double DEFAULT_THRESHOLD = 2.5;

// 3. Clase con documentación
/// Detecta frenazos bruscos basándose en datos del acelerómetro.
///
/// Utiliza un umbral configurable y filtros de ruido para reducir
/// falsos positivos.
class HarshBrakingDetector {
  // 4. Propiedades privadas
  final double _threshold;
  final NoiseFilter _filter;

  // 5. Constructor
  HarshBrakingDetector({
    double threshold = DEFAULT_THRESHOLD,
    NoiseFilter? filter,
  }) : _threshold = threshold,
       _filter = filter ?? NoiseFilter();

  // 6. Métodos públicos
  DetectionEvent? detect(SensorReading reading) {
    // Implementación
  }

  // 7. Métodos privados
  double _calculateMagnitude(SensorReading reading) {
    // Implementación
  }
}
```

## Documentación

### Estructura de la carpeta `documentacion/`

La documentación debe organizarse por categorías temáticas:

```
documentacion/
├── 01-arquitectura/          # Arquitectura general del sistema
├── 02-sensores/              # Sistema de sensores y calibración
├── 03-deteccion/             # Algoritmos de detección
├── 04-vision/                # Sistema de visión por computadora
├── 05-notificaciones/        # Sistema de alertas y notificaciones
├── 06-ui/                    # Interfaz de usuario
├── 07-integraciones/         # Integraciones externas (ESP32-CAM, etc.)
├── 08-testing/               # Estrategias y planes de testing
└── 09-despliegue/            # Configuración y despliegue
```

### Contenido de cada documento

Cada documento de implementación debe incluir:

1. **Título y descripción**: Qué se va a implementar
2. **Contexto**: Por qué es necesario
3. **Objetivos**: Qué se quiere lograr
4. **Diseño técnico**: Cómo se va a implementar
5. **Dependencias**: Qué se necesita
6. **Plan de implementación**: Pasos específicos
7. **Criterios de aceptación**: Cómo saber que está completo
8. **Tests**: Qué tests se deben crear

### Ejemplo de documento
```markdown
# Implementación del Detector de Frenado Brusco

## Contexto
Los frenazos bruscos son uno de los principales indicadores de conducción agresiva...

## Objetivos
- Detectar frenazos con desaceleración > 2.5 m/s²
- Minimizar falsos positivos causados por baches
- Responder en < 100ms

## Diseño Técnico
### Arquitectura
[Descripción de la arquitectura]

### Algoritmo
[Pseudocódigo o descripción del algoritmo]

## Implementación
### Fase 1: Estructura base
- [ ] Crear clase `HarshBrakingDetector`
- [ ] Implementar método `detect()`

### Fase 2: Filtros
- [ ] Agregar filtro de media móvil
- [ ] Implementar reducción de ruido

## Tests
- `test/detectors/harsh_braking_detector_test.dart`
  - Test de detección básica
  - Test de falsos positivos
  - Test de umbrales
```

## Testing

### Principios de Testing
1. **Cobertura mínima**: 80% de cobertura de código
2. **Test unitario por funcionalidad**: Cada detector, filtro y procesador debe tener sus tests
3. **Casos edge**: Probar valores límite y casos extremos
4. **Independencia**: Los tests no deben depender unos de otros
5. **Nomenclatura clara**: `test_deberíaHacerAlgo_cuandoCondicion()`

### Estructura de Tests
```
test/
├── core/
│   ├── detection/
│   │   ├── detectors/
│   │   │   ├── harsh_braking_detector_test.dart
│   │   │   ├── aggressive_acceleration_detector_test.dart
│   │   │   └── sharp_turn_detector_test.dart
│   │   ├── filters/
│   │   │   ├── moving_average_filter_test.dart
│   │   │   └── noise_reduction_filter_test.dart
│   │   └── processors/
│   │       └── sensor_data_processor_test.dart
│   ├── services/
│   │   ├── device_sensor_service_test.dart
│   │   └── notification_service_test.dart
│   └── vision/
│       ├── detectors/
│       │   ├── distraction_detector_test.dart
│       │   └── phone_detector_test.dart
│       └── processors/
│           └── frame_processor_test.dart
└── integration/
    ├── sensor_detection_integration_test.dart
    └── vision_detection_integration_test.dart
```

### Ejemplo de Test Unitario
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:driveguard/core/detection/detectors/harsh_braking_detector.dart';

void main() {
  group('HarshBrakingDetector', () {
    late HarshBrakingDetector detector;

    setUp(() {
      detector = HarshBrakingDetector(threshold: 2.5);
    });

    test('debería detectar frenado cuando desaceleración excede umbral', () {
      // Arrange
      final reading = SensorReading(
        x: 0.0,
        y: -3.0,  // Desaceleración de 3 m/s²
        z: 0.0,
        timestamp: DateTime.now(),
      );

      // Act
      final event = detector.detect(reading);

      // Assert
      expect(event, isNotNull);
      expect(event!.type, equals(EventType.harshBraking));
      expect(event.magnitude, greaterThan(2.5));
    });

    test('NO debería detectar frenado cuando desaceleración es menor al umbral', () {
      // Arrange
      final reading = SensorReading(
        x: 0.0,
        y: -2.0,  // Desaceleración de 2 m/s²
        z: 0.0,
        timestamp: DateTime.now(),
      );

      // Act
      final event = detector.detect(reading);

      // Assert
      expect(event, isNull);
    });

    test('debería filtrar ruido en lecturas consecutivas', () {
      // Arrange
      final readings = [
        SensorReading(x: 0, y: -1.0, z: 0, timestamp: DateTime.now()),
        SensorReading(x: 0, y: -5.0, z: 0, timestamp: DateTime.now()), // Spike
        SensorReading(x: 0, y: -1.0, z: 0, timestamp: DateTime.now()),
      ];

      // Act
      final events = readings.map((r) => detector.detect(r)).toList();

      // Assert
      expect(events.where((e) => e != null).length, equals(0),
        reason: 'El spike aislado debe ser filtrado como ruido');
    });
  });
}
```

## Workflow de Desarrollo

### Antes de Implementar
1. **Leer documentación existente** en `documentacion/`
2. **Verificar que no existe código similar** (principio DRY)
3. **Planificar en TODO list** los pasos específicos
4. **Crear documento de diseño** si es funcionalidad nueva

### Durante la Implementación
1. **Implementar funcionalidad mínima** (YAGNI)
2. **Mantener funciones simples** (KISS)
3. **Reutilizar código existente** (DRY)
4. **Escribir tests unitarios** en paralelo al código
5. **Documentar decisiones técnicas** en comentarios del código

### Después de Implementar
1. **Ejecutar tests**: `flutter test`
2. **Verificar cobertura**: Usar herramientas de cobertura
3. **Actualizar documentación** si hay cambios arquitectónicos
4. **Refactorizar** si se detecta duplicación o complejidad innecesaria
5. **Commit con mensaje descriptivo**

## Checklist de Pull Request

Antes de considerar una tarea como completa:

- [ ] El código sigue los principios DRY, KISS y YAGNI
- [ ] Existe documentación en `documentacion/` (si aplica)
- [ ] Existen tests unitarios con cobertura > 80%
- [ ] Los tests pasan: `flutter test`
- [ ] El código compila sin warnings: `flutter analyze`
- [ ] Los nombres de variables/funciones/clases son descriptivos
- [ ] No hay código comentado (eliminar, no comentar)
- [ ] No hay console.logs o prints de debug (usar logger apropiado)
- [ ] Las constantes mágicas están definidas como constantes nombradas

## Ejemplo Completo: Agregar Nuevo Detector

### 1. Planificación (TODO)
```
- [ ] Revisar documentación de detección existente
- [ ] Diseñar algoritmo del detector
- [ ] Crear archivo de detector
- [ ] Implementar lógica de detección
- [ ] Crear tests unitarios
- [ ] Integrar con SensorDataProcessor
- [ ] Actualizar documentación
- [ ] Verificar tests y análisis
```

### 2. Documentación (`documentacion/03-deteccion/nuevo_detector.md`)
```markdown
# Detector de [Nombre]

## Objetivo
Detectar [comportamiento] basándose en [señales]...

## Algoritmo
1. Recibir lectura de sensor
2. Aplicar filtro de ruido
3. Calcular magnitud
4. Comparar con umbral
5. Generar evento si excede

## Implementación
Ver: `lib/core/detection/detectors/nuevo_detector.dart`

## Tests
Ver: `test/core/detection/detectors/nuevo_detector_test.dart`
```

### 3. Implementación
```dart
// lib/core/detection/detectors/nuevo_detector.dart
```

### 4. Tests
```dart
// test/core/detection/detectors/nuevo_detector_test.dart
```

### 5. Verificación
```bash
flutter test test/core/detection/detectors/nuevo_detector_test.dart
flutter analyze
```

## Filosofía de Desarrollo para BETA

### Contexto del Proyecto
DriveGuard es una **beta funcional** que debe priorizar:
1. **Funcionalidad sobre perfección** - Que funcione antes que sea perfecto
2. **Simplicidad sobre sofisticación** - Soluciones directas antes que complejas
3. **Iteración rápida** - Implementar, probar, ajustar

### Prioridades para la BETA

#### ✅ LO QUE SÍ DEBE TENER
1. **Detección básica funcional**: Los detectores principales (frenado, aceleración, giro) deben funcionar de manera confiable
2. **Alertas efectivas**: Notificaciones visuales, sonoras y vibración que realmente alerten
3. **UI simple y clara**: Dashboard intuitivo, sin sobrecarga de información
4. **Integración ESP32-CAM básica**: Captura de frames y envío a la app
5. **Persistencia mínima**: Guardar historial básico en Firestore
6. **Tests críticos**: Solo tests de funcionalidades core

#### ❌ LO QUE NO ES PRIORITARIO AHORA
1. **Optimizaciones prematuras**: No optimizar antes de detectar cuellos de botella reales
2. **Features avanzadas**: Machine learning complejo, análisis predictivo, exportación de datos
3. **UI/UX perfecta**: Animaciones sofisticadas, transiciones elaboradas
4. **Configuración exhaustiva**: Muchas opciones confunden, mantener lo esencial
5. **Tests de integración complejos**: Focus en tests unitarios de lógica crítica
6. **Documentación excesiva**: Documentar lo necesario, no todo

### Reglas de Oro para BETA

#### 1. Regla del 80/20
- El 80% del valor viene del 20% de las features
- Identificar ese 20% crítico y hacerlo excelente
- El resto puede ser básico o incluso no existir

#### 2. Regla de las 3 Preguntas
Antes de implementar cualquier cosa, preguntarse:
1. **¿Es absolutamente necesario para la demo/beta?** - Si no, YAGNI
2. **¿Existe una forma más simple de hacerlo?** - Si sí, KISS
3. **¿Ya existe código que haga esto?** - Si sí, DRY

#### 3. Regla de "Funciona > Bonito > Perfecto"
Orden de prioridades:
1. **Funciona**: Hace lo que debe hacer (70% del esfuerzo)
2. **Bonito**: Se ve bien y es usable (20% del esfuerzo)
3. **Perfecto**: Optimizado y sin edge cases (10% del esfuerzo - BETA lo omite)

### Decisiones Técnicas para BETA

#### Manejo de Errores
```dart
// ❌ Demasiado complejo para BETA
class Result<T, E> {
  final T? value;
  final E? error;
  // ... 50 líneas más
}

// ✅ Suficiente para BETA
DetectionEvent? detect(SensorReading reading) {
  try {
    return _processReading(reading);
  } catch (e) {
    debugPrint('Error en detección: $e');
    return null;
  }
}
```

#### Estado y Persistencia
```dart
// ❌ Innecesario ahora
class CacheManager {
  final LRUCache cache;
  final DiskPersistence disk;
  final MemoryOptimizer optimizer;
}

// ✅ Directo y funcional
class SessionStorage {
  Future<void> saveSession(Session session) async {
    await FirebaseFirestore.instance
      .collection('sessions')
      .add(session.toJson());
  }
}
```

#### Configuración
```dart
// ❌ Sobre-configuración
class DetectorConfig {
  double threshold;
  int windowSize;
  FilterType filterType;
  double noiseThreshold;
  bool adaptiveMode;
  // ... 10 parámetros más
}

// ✅ Configuración esencial
class DetectorConfig {
  final double threshold;  // Lo único que realmente necesitamos ajustar

  const DetectorConfig({this.threshold = 2.5});
}
```

### Arquitectura Simplificada para BETA

#### Estructura Recomendada
```
lib/
├── core/
│   ├── detection/          # Sistema de detección (CORE)
│   │   ├── detectors/      # Detectores individuales
│   │   ├── models/         # Modelos de datos
│   │   └── processors/     # Procesador principal
│   ├── services/           # Servicios esenciales (CORE)
│   │   ├── device_sensor_service.dart
│   │   ├── notification_service.dart
│   │   └── sensor_service_factory.dart
│   └── vision/             # Sistema de visión (BETA SIMPLE)
│       └── detectors/      # Detectores de visión básicos
├── presentation/           # UI (MANTENER SIMPLE)
│   ├── blocs/             # Estado con BLoC
│   ├── pages/             # Páginas principales
│   └── widgets/           # Widgets reutilizables
└── main.dart
```

#### Capas Opcionales para BETA
- **UseCases**: Solo si la lógica de negocio es muy compleja
- **Repositories abstractos**: Solo si necesitas múltiples fuentes de datos
- **Mappers**: Solo si el mapeo es complejo, sino usar `.fromJson()` directo

### Testing para BETA

#### Estrategia Minimalista
1. **Tests unitarios de detectores**: CRÍTICO
2. **Tests de servicios core**: IMPORTANTE
3. **Tests de BLoCs**: OPCIONAL (solo los más críticos)
4. **Tests de widgets**: NO PRIORITARIO
5. **Tests de integración**: NO EN BETA

#### Ejemplo de Test Mínimo Viable
```dart
void main() {
  group('HarshBrakingDetector - Tests Esenciales', () {
    test('detecta frenado fuerte', () {
      final detector = HarshBrakingDetector();
      final event = detector.detect(
        SensorReading(x: 0, y: -3.0, z: 0, timestamp: DateTime.now())
      );
      expect(event, isNotNull);
    });

    test('ignora frenado suave', () {
      final detector = HarshBrakingDetector();
      final event = detector.detect(
        SensorReading(x: 0, y: -1.0, z: 0, timestamp: DateTime.now())
      );
      expect(event, isNull);
    });
  });
}
```

### Debugging y Logging para BETA

#### Approach Pragmático
```dart
// ✅ Simple y efectivo para BETA
class Logger {
  static void debug(String message) {
    if (kDebugMode) {
      print('[DEBUG] $message');
    }
  }

  static void error(String message, [dynamic error]) {
    debugPrint('[ERROR] $message: $error');
  }
}

// Uso
Logger.debug('Detector iniciado');
Logger.error('Fallo en lectura de sensor', e);
```

### Integración ESP32-CAM para BETA

#### Versión Mínima Funcional
```dart
// Solo lo esencial: recibir frames y procesarlos
class ESP32Service {
  Future<void> startServer() async {
    final handler = Pipeline()
      .addMiddleware(logRequests())
      .addHandler(_router);

    await serve(handler, InternetAddress.anyIPv4, 8080);
  }

  Future<Response> _handleFrame(Request request) async {
    final bytes = await request.read().toBytes();
    // Procesar frame (básico)
    _processFrame(bytes);
    return Response.ok('OK');
  }
}
```

### Detección por Visión para BETA

#### Implementación Minimalista
```dart
// ❌ Demasiado ambicioso para BETA
class AIVisionProcessor {
  TensorFlowModel model;
  PreProcessor preprocessor;
  PostProcessor postprocessor;
  FeatureExtractor extractor;
  // ... modelo complejo de ML
}

// ✅ Versión BETA: Usar ML Kit de Google (pre-entrenado)
class SimpleVisionDetector {
  final FaceDetector _faceDetector = FaceDetector();

  Future<bool> isDriverDistracted(Uint8List imageBytes) async {
    final faces = await _faceDetector.processImage(
      InputImage.fromBytes(bytes: imageBytes)
    );

    // Lógica simple: si no hay cara o está muy rotada
    if (faces.isEmpty) return true;
    if (faces.first.headEulerAngleY?.abs() ?? 0 > 30) return true;

    return false;
  }
}
```

### Métricas de Éxito para BETA

#### KPIs Funcionales
1. **Tasa de detección**: > 80% de eventos reales detectados
2. **Falsos positivos**: < 20% de las alertas
3. **Latencia**: < 200ms desde sensor hasta alerta
4. **Estabilidad**: App no crashea en uso normal de 30 minutos

#### KPIs NO Prioritarios (ignorar por ahora)
- Optimización de batería
- Uso de memoria
- Tamaño del APK
- Tiempo de startup
- Cobertura de tests > 50%

### Checklist de Tarea BETA

Para considerar una tarea completa en BETA:

- [ ] **Funciona correctamente** en caso de uso principal
- [ ] **Código simple** y fácil de entender
- [ ] **No rompe** funcionalidad existente
- [ ] **Tests básicos** si es lógica crítica (detección)
- [ ] **Sin warnings** de Flutter Analyze

NO es necesario:
- [ ] ~~Documentación exhaustiva~~
- [ ] ~~Tests de edge cases~~
- [ ] ~~Manejo de todos los errores posibles~~
- [ ] ~~Optimización de performance~~
- [ ] ~~UI perfecta~~

### Gestión de Deuda Técnica

#### Es Aceptable en BETA
1. **Código duplicado** si es en 2-3 lugares (no en 10)
2. **TODOs estratégicos** marcando mejoras futuras
3. **Hardcoded values** si no hay necesidad clara de configuración
4. **Manejo básico de errores** (try-catch + log)
5. **UI sin pulir** si es funcional

#### NO es Aceptable ni en BETA
1. **Crashes frecuentes**
2. **Pérdida de datos del usuario**
3. **Funcionalidad core que no funciona**
4. **Código completamente ilegible**
5. **Violaciones graves de seguridad** (tokens hardcodeados, etc.)

### Dependencias y Paquetes

#### Filosofía: Usar lo que Existe
- **ML Kit de Google** > Entrenar modelo custom
- **Audioplayers** > Implementar reproductor desde cero
- **Firebase** > Backend custom
- **Sensors Plus** > Implementar acceso a sensores

#### Evitar en BETA
- Paquetes experimentales (< 100 likes en pub.dev)
- Múltiples paquetes que hacen lo mismo
- Dependencias muy pesadas para features no-core

### Comunicación con el Usuario

#### Durante Desarrollo
```dart
// ✅ Para BETA está bien
showDialog(
  context: context,
  builder: (_) => AlertDialog(
    title: Text('Error'),
    content: Text('No se pudo conectar con ESP32-CAM'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('OK'),
      ),
    ],
  ),
);
```

No necesitamos todavía:
- Sistema de notificaciones complejo
- Internacionalización (i18n)
- Accesibilidad avanzada
- Soporte para temas custom

### Plan de Iteración

#### Sprint 1: Funcionalidad Core (AHORA)
- Detección de sensores funcionando
- Alertas básicas operativas
- Dashboard mostrando datos en tiempo real
- Historial básico

#### Sprint 2: Visión Básica (SIGUIENTE)
- ESP32-CAM enviando frames
- Detección simple de rostro/distracción
- Integración con sistema de alertas

#### Sprint 3: Refinamiento (DESPUÉS)
- Mejorar precisión de detectores
- Ajustar umbrales basado en testing real
- Pulir UI según feedback

#### Post-BETA (FUTURO)
- Optimizaciones de performance
- Tests comprehensivos
- Features avanzadas
- Refactoring de deuda técnica

## Recursos Adicionales

- **Flutter Testing**: https://docs.flutter.dev/testing
- **Clean Code**: Robert C. Martin
- **Effective Dart**: https://dart.dev/guides/language/effective-dart
- **ML Kit**: https://developers.google.com/ml-kit
- **Firebase**: https://firebase.google.com/docs/flutter/setup

## Comandos Útiles

```bash
# Verificar que todo compila sin warnings
flutter analyze

# Correr tests (solo los que tengas)
flutter test

# Limpiar build (si algo no funciona)
flutter clean && flutter pub get

# Ver logs en tiempo real
flutter logs

# Instalar en dispositivo físico
flutter run --release
```

## Preguntas Frecuentes - Desarrollo BETA

**Q: ¿Debo crear tests para todo?**
A: No. Solo tests para detectores y lógica crítica. UI tests pueden esperar.

**Q: ¿Cuándo refactorizar código duplicado?**
A: Si se repite > 3 veces Y es probable que cambie junto. Sino, déjalo.

**Q: ¿Debo usar UseCases/Repository pattern?**
A: Si la lógica es simple, no. BLoC puede llamar al servicio directo.

**Q: ¿Manejar todos los edge cases?**
A: No en BETA. Maneja el 80% de casos comunes bien.

**Q: ¿Optimizar rendimiento ahora?**
A: Solo si hay un problema evidente. No optimizar "por si acaso".

**Q: ¿Documentar cada función?**
A: Solo las no obvias o con lógica compleja. El código debe ser auto-documentado.

---

**Última actualización**: 2025-10-28
**Mantenido por**: Claude AI Assistant
**Versión**: BETA Focus Edition
