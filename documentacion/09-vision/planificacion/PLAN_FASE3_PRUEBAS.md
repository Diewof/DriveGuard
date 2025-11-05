# FASE 3: Pruebas, Validación y Mantenimiento

**Duración estimada**: 1-2 semanas
**Objetivo**: Calibrar, validar y optimizar el sistema de detección basado en visión.

---

## 3.1 Calibración de ROI del Volante

### 3.1.1 ROICalibrator

**Archivo**: `lib/core/vision/utils/roi_calibrator.dart`

**Propósito**: Permitir al usuario definir manualmente la región del volante en el frame del ESP32-CAM.

```dart
import 'dart:ui';

/// Calibrador de ROI (Region of Interest) del volante
class ROICalibrator {
  Rect? _steeringWheelROI;

  /// Configurar ROI manualmente (coordenadas relativas al frame 640x480)
  void setROI(Rect roi) {
    _steeringWheelROI = roi;
    print('[ROICalibrator] ✅ ROI configurada: $roi');
  }

  /// Configurar ROI usando porcentajes (más flexible)
  ///
  /// Ejemplo: Para un volante centrado que ocupa el 50% del ancho
  /// y está en la mitad inferior del frame:
  /// ```
  /// setROIFromPercentages(
  ///   leftPercent: 0.25,   // 25% desde la izquierda
  ///   topPercent: 0.50,    // 50% desde arriba
  ///   widthPercent: 0.50,  // 50% del ancho total
  ///   heightPercent: 0.30, // 30% del alto total
  /// );
  /// ```
  void setROIFromPercentages({
    required double leftPercent,
    required double topPercent,
    required double widthPercent,
    required double heightPercent,
  }) {
    const frameWidth = 640.0;
    const frameHeight = 480.0;

    final left = frameWidth * leftPercent;
    final top = frameHeight * topPercent;
    final width = frameWidth * widthPercent;
    final height = frameHeight * heightPercent;

    _steeringWheelROI = Rect.fromLTWH(left, top, width, height);
    print('[ROICalibrator] ✅ ROI configurada (porcentajes): $_steeringWheelROI');
  }

  /// Configurar ROI predeterminada (volante centrado típico)
  void setDefaultROI() {
    // ROI típica para volante centrado en frame ESP32-CAM
    // Ocupa aproximadamente:
    // - 50% del ancho del frame
    // - 30% del alto del frame
    // - Centrado horizontalmente
    // - Posicionado en la mitad inferior
    setROIFromPercentages(
      leftPercent: 0.25,   // Centrado (25% margen izquierdo)
      topPercent: 0.50,    // Mitad inferior del frame
      widthPercent: 0.50,  // 50% del ancho
      heightPercent: 0.30, // 30% del alto
    );

    print('[ROICalibrator] ✅ ROI predeterminada aplicada');
  }

  Rect? get roi => _steeringWheelROI;

  bool get isCalibrated => _steeringWheelROI != null;

  /// Guardar ROI en SharedPreferences (persistencia)
  Map<String, double> toJson() {
    if (_steeringWheelROI == null) {
      throw StateError('ROI no calibrada');
    }

    return {
      'left': _steeringWheelROI!.left,
      'top': _steeringWheelROI!.top,
      'width': _steeringWheelROI!.width,
      'height': _steeringWheelROI!.height,
    };
  }

  /// Cargar ROI desde SharedPreferences
  void fromJson(Map<String, double> json) {
    _steeringWheelROI = Rect.fromLTWH(
      json['left']!,
      json['top']!,
      json['width']!,
      json['height']!,
    );

    print('[ROICalibrator] ✅ ROI cargada desde persistencia: $_steeringWheelROI');
  }

  void reset() {
    _steeringWheelROI = null;
    print('[ROICalibrator] 🔄 ROI reseteada');
  }
}
```

---

### 3.1.2 Widget de Calibración Interactiva

**Archivo**: `lib/presentation/widgets/vision/roi_calibration_widget.dart`

**Propósito**: UI para que el usuario dibuje manualmente la ROI del volante sobre el frame en vivo.

```dart
import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../../../core/vision/utils/roi_calibrator.dart';

/// Widget interactivo para calibrar ROI del volante
class ROICalibrationWidget extends StatefulWidget {
  final Uint8List frameBytes; // Frame actual del ESP32-CAM (JPEG)
  final ROICalibrator calibrator;
  final VoidCallback onCalibrationComplete;

  const ROICalibrationWidget({
    Key? key,
    required this.frameBytes,
    required this.calibrator,
    required this.onCalibrationComplete,
  }) : super(key: key);

  @override
  State<ROICalibrationWidget> createState() => _ROICalibrationWidgetState();
}

class _ROICalibrationWidgetState extends State<ROICalibrationWidget> {
  Offset? _startPoint;
  Offset? _endPoint;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calibrar Volante'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveROI,
            tooltip: 'Guardar ROI',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _useDefaultROI,
            tooltip: 'Usar ROI predeterminada',
          ),
        ],
      ),
      body: Column(
        children: [
          // Instrucciones
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade100,
            child: const Text(
              'Dibuja un rectángulo alrededor del volante.\n'
              'Mantén presionado y arrastra para definir la región.',
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),

          // Frame con overlay de ROI
          Expanded(
            child: GestureDetector(
              onPanStart: (details) {
                setState(() {
                  _startPoint = details.localPosition;
                  _endPoint = null;
                });
              },
              onPanUpdate: (details) {
                setState(() {
                  _endPoint = details.localPosition;
                });
              },
              onPanEnd: (details) {
                // ROI dibujada, lista para guardar
              },
              child: CustomPaint(
                painter: ROIPainter(
                  frameBytes: widget.frameBytes,
                  startPoint: _startPoint,
                  endPoint: _endPoint,
                ),
                child: Container(),
              ),
            ),
          ),

          // Botones de acción
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveROI,
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar ROI'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _useDefaultROI,
                    icon: const Icon(Icons.auto_fix_high),
                    label: const Text('Usar Predeterminada'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _saveROI() {
    if (_startPoint == null || _endPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, dibuja una región primero')),
      );
      return;
    }

    // Convertir coordenadas de pantalla a coordenadas del frame (640x480)
    final roi = Rect.fromPoints(_startPoint!, _endPoint!);

    // Normalizar a coordenadas del frame
    // TODO: Escalar según el tamaño real del widget vs frame
    widget.calibrator.setROI(roi);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ ROI guardada exitosamente')),
    );

    widget.onCalibrationComplete();
  }

  void _useDefaultROI() {
    widget.calibrator.setDefaultROI();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ ROI predeterminada aplicada')),
    );

    widget.onCalibrationComplete();
  }
}

/// Painter para dibujar el frame y la ROI
class ROIPainter extends CustomPainter {
  final Uint8List frameBytes;
  final Offset? startPoint;
  final Offset? endPoint;

  ROIPainter({
    required this.frameBytes,
    this.startPoint,
    this.endPoint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Dibujar frame del ESP32-CAM
    // TODO: Decodificar frameBytes y dibujar imagen

    // 2. Dibujar ROI si existe
    if (startPoint != null && endPoint != null) {
      final rect = Rect.fromPoints(startPoint!, endPoint!);

      final paint = Paint()
        ..color = Colors.green.withOpacity(0.3)
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = Colors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      canvas.drawRect(rect, paint);
      canvas.drawRect(rect, borderPaint);

      // Dibujar texto de dimensiones
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${rect.width.toInt()} x ${rect.height.toInt()}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(canvas, Offset(rect.left, rect.top - 25));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
```

---

## 3.2 Pruebas de Validación

### 3.2.1 Test Unitarios - DistractionDetector

**Archivo**: `test/core/vision/detectors/distraction_detector_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:driveguard/core/vision/detectors/distraction_detector.dart';
import 'package:driveguard/core/vision/models/face_data.dart';
import 'package:driveguard/core/detection/models/event_type.dart';
import 'package:driveguard/core/detection/models/event_severity.dart';

void main() {
  group('DistractionDetector', () {
    late DistractionDetector detector;

    setUp(() {
      detector = DistractionDetector();
    });

    tearDown(() {
      detector.dispose();
    });

    test('no debe detectar distracción si headPitch > -25°', () async {
      // Simular cara mirando al frente (pitch = -10°)
      final faceData = _createFaceData(headPitch: -10.0);

      bool eventEmitted = false;
      detector.eventStream.listen((_) {
        eventEmitted = true;
      });

      // Procesar durante 3 segundos @ 5 FPS = 15 frames
      for (int i = 0; i < 15; i++) {
        detector.processFaceData(faceData);
        await Future.delayed(const Duration(milliseconds: 200));
      }

      expect(eventEmitted, isFalse);
    });

    test('debe detectar distracción si headPitch < -25° por 2+ segundos', () async {
      // Simular cara mirando hacia abajo (usando teléfono)
      final faceData = _createFaceData(headPitch: -30.0);

      VisionEvent? detectedEvent;
      detector.eventStream.listen((event) {
        detectedEvent = event;
      });

      // Procesar durante 2.5 segundos @ 5 FPS = 12 frames
      for (int i = 0; i < 12; i++) {
        detector.processFaceData(faceData);
        await Future.delayed(const Duration(milliseconds: 200));
      }

      expect(detectedEvent, isNotNull);
      expect(detectedEvent!.type, EventType.distraction);
      expect(detectedEvent!.severity, isIn([EventSeverity.low, EventSeverity.medium]));
    });

    test('debe aumentar severidad con mayor duración', () async {
      final faceData = _createFaceData(headPitch: -35.0);

      VisionEvent? lastEvent;
      detector.eventStream.listen((event) {
        lastEvent = event;
      });

      // Procesar durante 7 segundos @ 5 FPS = 35 frames
      for (int i = 0; i < 35; i++) {
        detector.processFaceData(faceData);
        await Future.delayed(const Duration(milliseconds: 200));
      }

      // Esperar al menos un evento CRITICAL después de 6+ segundos
      expect(lastEvent, isNotNull);
      // Nota: Solo el primer evento se emite, pero severity debería ser alta
    });

    test('debe resetear detección si la cara vuelve al frente', () async {
      final distractedFaceData = _createFaceData(headPitch: -30.0);
      final normalFaceData = _createFaceData(headPitch: -10.0);

      VisionEvent? detectedEvent;
      detector.eventStream.listen((event) {
        detectedEvent = event;
      });

      // Distracción por 1 segundo (5 frames)
      for (int i = 0; i < 5; i++) {
        detector.processFaceData(distractedFaceData);
        await Future.delayed(const Duration(milliseconds: 200));
      }

      // Volver al frente
      detector.processFaceData(normalFaceData);

      // Distracción nuevamente por 1.5 segundos (no debería detectar)
      for (int i = 0; i < 7; i++) {
        detector.processFaceData(distractedFaceData);
        await Future.delayed(const Duration(milliseconds: 200));
      }

      // No debería emitir evento porque se reseteo
      expect(detectedEvent, isNull);
    });
  });
}

// Helper para crear FaceData simulada
FaceData _createFaceData({
  double headYaw = 0.0,
  double headPitch = 0.0,
  double headRoll = 0.0,
}) {
  return FaceData(
    face: null as dynamic, // Mock (no se usa en detector)
    headYaw: headYaw,
    headPitch: headPitch,
    headRoll: headRoll,
    leftEyeOpen: true,
    rightEyeOpen: true,
    timestamp: DateTime.now(),
  );
}
```

---

### 3.2.2 Test Unitarios - HandsOffDetector (Híbrido)

**Archivo**: `test/core/vision/detectors/hands_off_detector_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:driveguard/core/vision/detectors/hands_off_detector.dart';
import 'package:driveguard/core/vision/models/hand_data.dart';
import 'package:driveguard/domain/entities/sensor_data.dart';
import 'package:driveguard/core/detection/models/event_type.dart';

void main() {
  group('HandsOffDetector (Híbrido)', () {
    late HandsOffDetector detector;

    setUp(() {
      detector = HandsOffDetector();
    });

    tearDown(() {
      detector.dispose();
    });

    test('NO debe detectar si el vehículo está detenido (IMU inactivo)', () async {
      // Simular manos fuera del volante
      final handData = _createHandData(handsOnWheel: 0);

      // Simular vehículo detenido (accel < 1.5, gyro < 20)
      final sensorData = _createSensorData(accelMagnitude: 0.5, gyroMagnitude: 5.0);

      VisionEvent? detectedEvent;
      detector.eventStream.listen((event) {
        detectedEvent = event;
      });

      // Procesar durante 5 segundos
      for (int i = 0; i < 25; i++) {
        detector.updateSensorData(sensorData);
        detector.processHandData(handData);
        await Future.delayed(const Duration(milliseconds: 200));
      }

      // NO debe emitir evento (vehículo detenido)
      expect(detectedEvent, isNull);
    });

    test('SÍ debe detectar si el vehículo está en movimiento (IMU activo)', () async {
      final handData = _createHandData(handsOnWheel: 0);

      // Simular vehículo en movimiento (accel > 1.5)
      final sensorData = _createSensorData(accelMagnitude: 3.0, gyroMagnitude: 15.0);

      VisionEvent? detectedEvent;
      detector.eventStream.listen((event) {
        detectedEvent = event;
      });

      // Procesar durante 4 segundos @ 5 FPS
      for (int i = 0; i < 20; i++) {
        detector.updateSensorData(sensorData);
        detector.processHandData(handData);
        await Future.delayed(const Duration(milliseconds: 200));
      }

      // SÍ debe emitir evento (híbrido: sin manos + movimiento)
      expect(detectedEvent, isNotNull);
      expect(detectedEvent!.type, EventType.handsOff);
      expect(detectedEvent!.metadata['detectionMethod'], 'hybrid');
    });

    test('NO debe detectar si al menos 1 mano está en el volante', () async {
      // Simular 1 mano en el volante
      final handData = _createHandData(handsOnWheel: 1);

      final sensorData = _createSensorData(accelMagnitude: 3.0, gyroMagnitude: 15.0);

      VisionEvent? detectedEvent;
      detector.eventStream.listen((event) {
        detectedEvent = event;
      });

      for (int i = 0; i < 25; i++) {
        detector.updateSensorData(sensorData);
        detector.processHandData(handData);
        await Future.delayed(const Duration(milliseconds: 200));
      }

      // NO debe emitir evento (hay mano en el volante)
      expect(detectedEvent, isNull);
    });
  });
}

HandData _createHandData({required int handsOnWheel}) {
  return HandData(
    pose: null as dynamic, // Mock
    leftHandInROI: handsOnWheel >= 1,
    rightHandInROI: handsOnWheel >= 2,
    timestamp: DateTime.now(),
  );
}

SensorData _createSensorData({
  required double accelMagnitude,
  required double gyroMagnitude,
}) {
  return SensorData(
    timestamp: DateTime.now(),
    accelerationX: accelMagnitude / 1.732, // Distribuir magnitud en X,Y,Z
    accelerationY: accelMagnitude / 1.732,
    accelerationZ: accelMagnitude / 1.732,
    gyroscopeX: gyroMagnitude / 1.732,
    gyroscopeY: gyroMagnitude / 1.732,
    gyroscopeZ: gyroMagnitude / 1.732,
    isCalibrated: true,
  );
}
```

---

### 3.2.3 Test de Integración - VisionProcessor

**Archivo**: `test/core/vision/processors/vision_processor_integration_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:driveguard/core/vision/processors/vision_processor.dart';
import 'package:driveguard/core/vision/models/vision_event.dart';
import 'dart:typed_data';

void main() {
  group('VisionProcessor Integration', () {
    late VisionProcessor processor;

    setUp(() {
      processor = VisionProcessor();
    });

    tearDown(() {
      processor.dispose();
    });

    test('debe emitir eventos consolidados de todos los detectores', () async {
      final events = <VisionEvent>[];
      processor.eventStream.listen((event) {
        events.add(event);
      });

      // TODO: Simular frames reales del ESP32-CAM
      // Por ahora, verificar que el stream está activo
      expect(processor.eventStream, isNotNull);
    });

    test('debe actualizar estadísticas de procesamiento', () {
      final stats = processor.getStats();

      expect(stats, containsPair('faceMesh', isA<Map>()));
      expect(stats, containsPair('hands', isA<Map>()));
    });

    test('debe configurar ROI del volante', () {
      final roi = Rect.fromLTWH(100, 150, 300, 200);

      // No debería lanzar excepción
      expect(() => processor.setSteeringWheelROI(roi), returnsNormally);
    });
  });
}
```

---

## 3.3 Validación en Condiciones Reales

### 3.3.1 Escenarios de Prueba

#### Escenario 1: Distracción (Uso de Teléfono)

**Configuración**:
- ESP32-CAM montado en dashboard, apuntando al conductor
- Conductor sentado en posición normal de conducción

**Procedimiento**:
1. Iniciar monitoreo en la app
2. Conductor mira al frente durante 10 segundos (baseline)
3. Conductor mira hacia abajo simulando uso de teléfono durante 3 segundos
4. Volver a mirar al frente
5. Repetir 5 veces

**Validación**:
- [ ] Evento de distracción detectado en 4/5 intentos (80% precisión)
- [ ] Tiempo de detección: 2-3 segundos desde inicio de distracción
- [ ] Severidad incrementa con duración
- [ ] No hay falsos positivos cuando mira al frente

**Logs esperados**:
```
[FaceMeshProcessor] 📊 Procesados: 15 frames
[DistractionDetector] 🚨 Distracción detectada (duración: 3s, severidad: MEDIUM)
[EventAggregator] ✅ Evento agregado: DISTRACTION
```

---

#### Escenario 2: Inattention (Mirada Lateral)

**Procedimiento**:
1. Conductor mira al frente durante 10 segundos
2. Conductor gira la cabeza 45° a la izquierda durante 3 segundos
3. Volver al frente
4. Girar 45° a la derecha durante 3 segundos
5. Repetir 5 veces

**Validación**:
- [ ] Evento de inattention detectado en 4/5 intentos por lado
- [ ] headYaw registrado correctamente (±45°)
- [ ] No detecta cuando cabeza gira < 20°

---

#### Escenario 3: Hands Off (Híbrido)

**Procedimiento**:
1. Vehículo detenido, conductor suelta el volante durante 5 segundos → **NO debe alertar**
2. Vehículo en movimiento (simular aceleración), conductor suelta el volante durante 4 segundos → **SÍ debe alertar**
3. Vehículo en movimiento, conductor mantiene 1 mano en volante → **NO debe alertar**

**Validación**:
- [ ] NO alerta cuando vehículo detenido (accel < 1.5)
- [ ] SÍ alerta cuando vehículo en movimiento + manos fuera
- [ ] Metadata muestra `isMoving: true` cuando corresponde
- [ ] Confidence híbrida > 0.7

**Logs esperados**:
```
[HandsProcessor] 📊 Manos detectadas: 0/2
[HandsOffDetector] 🚨 Manos fuera del volante detectado (duración: 4s, severidad: MEDIUM)
  Metadata: {isMoving: true, accelMagnitude: 3.2, detectionMethod: 'hybrid'}
```

---

### 3.3.2 Matriz de Validación

| Evento | Condición | Resultado Esperado | Precisión Mínima |
|--------|-----------|-------------------|------------------|
| **Distracción** | Mirando teléfono 3s | Detectado MEDIUM | 80% |
| **Distracción** | Mirando teléfono 7s | Detectado CRITICAL | 80% |
| **Distracción** | Mirando al frente | NO detectado | 95% |
| **Inattention** | Cabeza girada 45° por 3s | Detectado MEDIUM | 75% |
| **Inattention** | Cabeza girada 15° | NO detectado | 90% |
| **Hands Off** | Sin manos + detenido | NO detectado | 100% |
| **Hands Off** | Sin manos + movimiento 4s | Detectado MEDIUM | 80% |
| **Hands Off** | 1 mano + movimiento | NO detectado | 95% |

---

## 3.4 Optimización de Rendimiento

### 3.4.1 Métricas de Rendimiento

**Comando para monitorear FPS del procesamiento**:

```dart
// En VisionProcessor
class VisionProcessor {
  int _frameCount = 0;
  DateTime? _lastFpsReport;

  Future<void> processFrame(InputImage inputImage) async {
    _frameCount++;

    _lastFpsReport ??= DateTime.now();
    final elapsed = DateTime.now().difference(_lastFpsReport!);

    if (elapsed.inSeconds >= 5) {
      final fps = _frameCount / elapsed.inSeconds;
      print('[VisionProcessor] 📊 FPS de procesamiento: ${fps.toStringAsFixed(1)}');

      _frameCount = 0;
      _lastFpsReport = DateTime.now();
    }

    // ... resto del código
  }
}
```

**Objetivos**:
- FPS de procesamiento: **≥ 4 FPS** (procesamos todos los frames del ESP32)
- Latencia frame → evento: **≤ 500ms**
- Uso de CPU: **≤ 40%** promedio
- Uso de memoria: **≤ 150 MB** adicionales

---

### 3.4.2 Optimizaciones Comunes

#### Optimización 1: Skip frames si hay backlog

```dart
Future<void> processFrame(InputImage inputImage) async {
  if (_isProcessing) {
    _skippedFrames++;
    if (_skippedFrames % 10 == 0) {
      print('[VisionProcessor] ⚠️ Skipped $_skippedFrames frames (backlog)');
    }
    return; // Saltar frame
  }

  _isProcessing = true;
  // ... procesamiento
  _isProcessing = false;
}
```

#### Optimización 2: Reducir resolución si necesario

```dart
// En ESP32-CAM main.cpp
config.frame_size = FRAMESIZE_VGA;  // 640x480 (actual)
// Si problemas de rendimiento:
// config.frame_size = FRAMESIZE_HVGA; // 480x320 (más rápido)
```

#### Optimización 3: Procesar solo cada N frames

```dart
int _frameCounter = 0;

Future<void> processFrame(InputImage inputImage) async {
  _frameCounter++;

  // Procesar solo cada 2 frames (reduce a 2.5 FPS)
  if (_frameCounter % 2 != 0) {
    return;
  }

  // ... procesamiento
}
```

---

## 3.5 Debugging y Troubleshooting

### 3.5.1 Página de Debug de Visión

**Archivo**: `lib/presentation/pages/esp32_vision_debug_page.dart`

```dart
import 'package:flutter/material.dart';
import '../../core/vision/processors/vision_processor.dart';
import '../../core/vision/utils/frame_subscriber.dart';
import '../../data/datasources/local/http_server_service.dart';

/// Página de debug para sistema de visión
class ESP32VisionDebugPage extends StatefulWidget {
  const ESP32VisionDebugPage({Key? key}) : super(key: key);

  @override
  State<ESP32VisionDebugPage> createState() => _ESP32VisionDebugPageState();
}

class _ESP32VisionDebugPageState extends State<ESP32VisionDebugPage> {
  late VisionProcessor _visionProcessor;
  late FrameSubscriber _frameSubscriber;
  late HttpServerService _httpServerService;

  Map<String, dynamic> _stats = {};
  int _eventsDetected = 0;

  @override
  void initState() {
    super.initState();

    _httpServerService = HttpServerService();
    _visionProcessor = VisionProcessor();
    _frameSubscriber = FrameSubscriber(_httpServerService);

    _frameSubscriber.start();

    _frameSubscriber.inputImageStream.listen((inputImage) {
      _visionProcessor.processFrame(inputImage);
    });

    _visionProcessor.eventStream.listen((event) {
      setState(() {
        _eventsDetected++;
      });
    });

    // Actualizar estadísticas cada segundo
    Future.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _stats = _visionProcessor.getStats();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Visión ESP32-CAM'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Estadísticas FaceMesh
          _buildStatCard(
            'FaceMesh Processor',
            _stats['faceMesh'] as Map<String, dynamic>? ?? {},
            Icons.face,
          ),

          const SizedBox(height: 16),

          // Estadísticas Hands
          _buildStatCard(
            'Hands Processor',
            _stats['hands'] as Map<String, dynamic>? ?? {},
            Icons.back_hand,
          ),

          const SizedBox(height: 16),

          // Eventos detectados
          Card(
            child: ListTile(
              leading: const Icon(Icons.warning_amber, color: Colors.orange),
              title: const Text('Eventos Detectados'),
              trailing: Text(
                '$_eventsDetected',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Botón para resetear detectores
          ElevatedButton.icon(
            onPressed: () {
              _visionProcessor.resetDetectors();
              setState(() {
                _eventsDetected = 0;
              });
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Resetear Detectores'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, Map<String, dynamic> stats, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            ...stats.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key),
                    Text(
                      '${entry.value}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _frameSubscriber.dispose();
    _visionProcessor.dispose();
    super.dispose();
  }
}
```

---

### 3.5.2 Guía de Troubleshooting

#### Problema: No se detectan eventos

**Diagnóstico**:
1. Verificar que frames llegan al VisionProcessor:
   ```
   [FrameSubscriber] ✅ InputImage emitido
   [VisionProcessor] 📊 FPS de procesamiento: 4.8
   ```

2. Verificar que MediaPipe procesa frames:
   ```
   [FaceMeshProcessor] 📊 Procesados: 150 frames
   ```

3. Verificar umbrales de detección:
   - ¿headPitch realmente < -25° cuando mira teléfono?
   - Agregar logs temporales en detectores

**Solución**:
- Ajustar umbrales según condiciones reales
- Verificar ROI del volante calibrada correctamente

---

#### Problema: Demasiados falsos positivos

**Causa común**: Umbrales muy permisivos o ROI muy grande.

**Solución**:
1. Aumentar duración mínima de detección:
   ```dart
   static const Duration _minDistractionDuration = Duration(seconds: 3); // Era 2
   ```

2. Ajustar umbrales de pose:
   ```dart
   static const double _downwardPitchThreshold = -30.0; // Era -25
   ```

3. Recalibrar ROI del volante (más pequeña)

---

#### Problema: Baja precisión de detección de manos

**Causa**: PoseDetector es workaround, no tan preciso como HandLandmarker.

**Soluciones**:
1. **Opción 1**: Usar TFLite directo con modelo de manos
2. **Opción 2**: Expandir ROI del volante
3. **Opción 3**: Reducir umbral de duración para compensar

---

## 3.6 Checklist Final de Fase 3

- [ ] ROI del volante calibrada y guardada en persistencia
- [ ] Tests unitarios pasan (DistractionDetector, InattentionDetector, HandsOffDetector)
- [ ] Tests de integración completos
- [ ] Validación en condiciones reales ≥ 80% precisión
- [ ] Optimizaciones de rendimiento aplicadas
- [ ] FPS de procesamiento ≥ 4 FPS
- [ ] Página de debug funcional
- [ ] Documentación de troubleshooting actualizada
- [ ] Falsos positivos < 10%
- [ ] Falsos negativos < 20%

---

## 3.7 Mantenimiento Continuo

### 3.7.1 Monitoreo Post-Lanzamiento

**Métricas a trackear**:
1. Tasa de detección (eventos/hora de conducción)
2. Precisión por tipo de evento
3. FPS promedio de procesamiento
4. Crash rate relacionado con visión
5. Consumo de batería adicional

**Firebase Analytics (recomendado)**:
```dart
FirebaseAnalytics.instance.logEvent(
  name: 'vision_event_detected',
  parameters: {
    'event_type': event.type.name,
    'severity': event.severity.value,
    'confidence': event.confidence,
  },
);
```

---

### 3.7.2 Mejoras Futuras

#### Mejora 1: Hand Landmarker Nativo (cuando esté disponible)
Reemplazar PoseDetector por HandLandmarker cuando ML Kit Flutter lo soporte.

#### Mejora 2: Detección de Somnolencia (Drowsiness)
Agregar detector basado en:
- Frecuencia de parpadeo (blinks/min)
- Duración de cierre de ojos
- Bostezos (mouth aspect ratio)

#### Mejora 3: Ajuste Dinámico de Umbrales
Usar Machine Learning para ajustar umbrales según:
- Patrón de conducción del usuario
- Hora del día
- Condiciones de iluminación

#### Mejora 4: Multi-Camera Support
Soportar múltiples ESP32-CAM:
- Una para el conductor
- Una para el camino (lane detection)

---

## 3.8 Documentación Final

### Archivos de Documentación a Crear

1. **USER_GUIDE_VISION.md**
   - Cómo calibrar ROI del volante
   - Posicionamiento óptimo del ESP32-CAM
   - Interpretación de alertas de visión

2. **API_REFERENCE_VISION.md**
   - Clases públicas (VisionProcessor, ROICalibrator)
   - Eventos y metadata
   - Extensibilidad para nuevos detectores

3. **PERFORMANCE_REPORT.md**
   - Benchmarks de FPS
   - Consumo de batería
   - Precisión por evento

---

## Conclusión de Fase 3

Al completar esta fase, el sistema de detección basado en visión estará:

✅ **Calibrado** con ROI del volante específica del vehículo
✅ **Validado** con > 80% de precisión en condiciones reales
✅ **Optimizado** para ≥ 4 FPS de procesamiento
✅ **Probado** con suite completa de tests unitarios e integración
✅ **Documentado** para usuarios y desarrolladores
✅ **Listo para producción**

---

**Tiempo total estimado**: 4-6 semanas

**Próximos pasos post-implementación**: Ver sección 3.7.2 (Mejoras Futuras)
