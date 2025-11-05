# FASE 1: Configuración y Preparación

**Duración estimada**: 1 semana
**Objetivo**: Preparar el entorno y la infraestructura base para procesamiento de frames del ESP32-CAM con MediaPipe.

---

## 1.1 Instalación de Dependencias

### Paso 1.1.1: Agregar dependencias al `pubspec.yaml`

```yaml
dependencies:
  # Existentes (mantener)
  flutter:
    sdk: flutter
  flutter_bloc: ^8.1.3
  sensors_plus: ^3.0.2
  shelf: ^1.4.0  # Ya existe para HttpServerService

  # NUEVAS - Vision Processing
  google_mlkit_face_detection: ^0.10.0
  google_mlkit_pose_detection: ^0.11.0
  image: ^4.1.3  # Para conversión JPEG → Image

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0
```

**Justificación de dependencias**:
- `google_mlkit_face_detection`: Para FaceMesh (468 landmarks, head pose, iris tracking)
- `google_mlkit_pose_detection`: Para detección de manos (workaround, ya que ML Kit no tiene HandLandmarker nativo en Flutter)
- `image`: Para decodificar JPEG bytes del ESP32-CAM y convertir a formato compatible con InputImage

### Paso 1.1.2: Instalar dependencias

```bash
cd c:\Users\jdgut\Desktop\DriveGuard\android\app
flutter pub get
```

### Paso 1.1.3: Configurar permisos de Android (Opcional)

**NOTA**: Como usamos ESP32-CAM y NO la cámara del celular, NO se requieren permisos de cámara.

Archivo: `android/app/src/main/AndroidManifest.xml`

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:label="DriveGuard"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">

        <!-- IMPORTANTE: NO agregar permisos de cámara -->
        <!-- Solo necesitamos permisos que ya existen: -->
        <!-- - INTERNET (para recibir frames del ESP32) -->
        <!-- - WAKE_LOCK (para mantener pantalla activa) -->

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize"
            android:screenOrientation="portrait">
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"
              />
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>

        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
```

---

## 1.2 Estructura de Archivos

### Paso 1.2.1: Crear estructura de directorios

```bash
# Desde la raíz del proyecto
mkdir lib\core\vision
mkdir lib\core\vision\processors
mkdir lib\core\vision\detectors
mkdir lib\core\vision\models
mkdir lib\core\vision\utils
```

**Estructura resultante**:

```
lib/
├── core/
│   ├── detection/           # Existente (IMU)
│   │   ├── detectors/
│   │   ├── processors/
│   │   └── models/
│   └── vision/              # NUEVO (ESP32-CAM)
│       ├── processors/      # FaceMeshProcessor, HandsProcessor
│       ├── detectors/       # DistractionDetector, InattentionDetector, HandsOffDetector
│       ├── models/          # VisionEvent, FaceData, HandData
│       └── utils/           # FrameConverter, ROICalibrator
```

---

## 1.3 Modelos de Datos Base

### Paso 1.3.1: Crear `VisionEvent` (lib/core/vision/models/vision_event.dart)

```dart
import 'package:equatable/equatable.dart';
import '../../detection/models/event_type.dart';
import '../../detection/models/event_severity.dart';

/// Evento de detección basado en visión (ESP32-CAM)
class VisionEvent extends Equatable {
  final EventType type;
  final EventSeverity severity;
  final DateTime timestamp;
  final double confidence;
  final Map<String, dynamic> metadata;

  const VisionEvent({
    required this.type,
    required this.severity,
    required this.timestamp,
    required this.confidence,
    this.metadata = const {},
  });

  @override
  List<Object?> get props => [type, severity, timestamp, confidence, metadata];

  @override
  String toString() {
    return 'VisionEvent(type: $type, severity: $severity, confidence: ${confidence.toStringAsFixed(2)}, timestamp: $timestamp)';
  }
}
```

### Paso 1.3.2: Crear `FaceData` (lib/core/vision/models/face_data.dart)

```dart
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Datos procesados de detección facial
class FaceData {
  final Face face;
  final double headYaw;        // Rotación horizontal (-90° a 90°)
  final double headPitch;      // Rotación vertical (-90° a 90°)
  final double headRoll;       // Inclinación lateral (-180° a 180°)
  final bool leftEyeOpen;
  final bool rightEyeOpen;
  final DateTime timestamp;

  FaceData({
    required this.face,
    required this.headYaw,
    required this.headPitch,
    required this.headRoll,
    required this.leftEyeOpen,
    required this.rightEyeOpen,
    required this.timestamp,
  });

  /// Determina si el conductor está mirando al frente
  bool get isLookingForward {
    // Tolerancia: ±20° en yaw (horizontal), ±15° en pitch (vertical)
    return headYaw.abs() < 20.0 && headPitch.abs() < 15.0;
  }

  /// Determina si el conductor tiene los ojos abiertos
  bool get hasEyesOpen {
    return leftEyeOpen && rightEyeOpen;
  }

  @override
  String toString() {
    return 'FaceData(yaw: ${headYaw.toStringAsFixed(1)}°, '
        'pitch: ${headPitch.toStringAsFixed(1)}°, '
        'roll: ${headRoll.toStringAsFixed(1)}°, '
        'eyesOpen: $hasEyesOpen)';
  }
}
```

### Paso 1.3.3: Crear `HandData` (lib/core/vision/models/hand_data.dart)

```dart
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Datos procesados de detección de manos (usando PoseDetector como workaround)
class HandData {
  final Pose pose;
  final bool leftHandInROI;   // Mano izquierda dentro de región del volante
  final bool rightHandInROI;  // Mano derecha dentro de región del volante
  final DateTime timestamp;

  HandData({
    required this.pose,
    required this.leftHandInROI,
    required this.rightHandInROI,
    required this.timestamp,
  });

  /// Cuenta cuántas manos están en el volante
  int get handsOnWheel {
    int count = 0;
    if (leftHandInROI) count++;
    if (rightHandInROI) count++;
    return count;
  }

  /// Determina si al menos una mano está en el volante
  bool get hasHandsOnWheel => handsOnWheel > 0;

  @override
  String toString() {
    return 'HandData(handsOnWheel: $handsOnWheel, '
        'leftInROI: $leftHandInROI, rightInROI: $rightHandInROI)';
  }
}
```

---

## 1.4 Extensión de Enumeraciones

### Paso 1.4.1: Extender `EventType` (lib/core/detection/models/event_type.dart)

**Agregar al enum existente**:

```dart
enum EventType {
  // Eventos IMU existentes
  harshBraking,
  aggressiveAcceleration,
  sharpTurn,
  weaving,
  roughRoad,
  speedBump,

  // NUEVOS - Eventos basados en visión (ESP32-CAM)
  distraction,        // Uso de teléfono móvil
  inattention,        // Mirada fuera de la carretera
  handsOff,           // Ausencia de manos en el volante (híbrido)
}

extension EventTypeExtension on EventType {
  String get displayName {
    switch (this) {
      // Existentes
      case EventType.harshBraking:
        return 'Frenado Brusco';
      case EventType.aggressiveAcceleration:
        return 'Aceleración Agresiva';
      case EventType.sharpTurn:
        return 'Giro Brusco';
      case EventType.weaving:
        return 'Zigzagueo';
      case EventType.roughRoad:
        return 'Camino Irregular';
      case EventType.speedBump:
        return 'Reductor de Velocidad';

      // NUEVOS - Visión
      case EventType.distraction:
        return 'Distracción (Teléfono)';
      case EventType.inattention:
        return 'Desatención Visual';
      case EventType.handsOff:
        return 'Manos Fuera del Volante';
    }
  }

  String get description {
    switch (this) {
      // Existentes (mantener)
      case EventType.harshBraking:
        return 'El conductor frenó bruscamente';
      case EventType.aggressiveAcceleration:
        return 'El conductor aceleró agresivamente';
      case EventType.sharpTurn:
        return 'El conductor realizó un giro brusco';
      case EventType.weaving:
        return 'El vehículo zigzagueó entre carriles';
      case EventType.roughRoad:
        return 'El vehículo pasó por un camino irregular';
      case EventType.speedBump:
        return 'El vehículo pasó por un reductor de velocidad';

      // NUEVOS - Visión
      case EventType.distraction:
        return 'El conductor está usando el teléfono móvil';
      case EventType.inattention:
        return 'El conductor no está mirando la carretera';
      case EventType.handsOff:
        return 'El conductor no tiene las manos en el volante';
    }
  }

  /// NUEVO - Indica si el evento es basado en visión
  bool get isVisionBased {
    return this == EventType.distraction ||
           this == EventType.inattention ||
           this == EventType.handsOff;
  }

  /// NUEVO - Indica si el evento es híbrido (visión + IMU)
  bool get isHybrid {
    return this == EventType.handsOff; // Verifica visión + movimiento del vehículo
  }
}
```

---

## 1.5 Utilidades de Conversión de Frames

### Paso 1.5.1: Crear `FrameConverter` (lib/core/vision/utils/frame_converter.dart)

**Propósito**: Convertir los frames JPEG del ESP32-CAM (recibidos como `Uint8List`) a `InputImage` compatible con MediaPipe.

```dart
import 'dart:typed_data';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

/// Convierte frames JPEG del ESP32-CAM a InputImage para MediaPipe
class FrameConverter {
  /// Convierte JPEG bytes a InputImage
  ///
  /// Proceso:
  /// 1. Decodificar JPEG → Image (usando package 'image')
  /// 2. Convertir Image → InputImage (formato compatible con ML Kit)
  static InputImage? fromJpegBytes(Uint8List jpegBytes) {
    try {
      // 1. Decodificar JPEG
      final image = img.decodeJpeg(jpegBytes);
      if (image == null) {
        print('[FrameConverter] ❌ Error al decodificar JPEG');
        return null;
      }

      // 2. Convertir a formato RGB (MediaPipe espera RGB)
      final rgbBytes = _imageToRgbBytes(image);

      // 3. Crear InputImageMetadata
      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotation.rotation0deg, // ESP32-CAM está fijo
        format: InputImageFormat.yuv420,           // Formato compatible
        bytesPerRow: image.width * 3,              // RGB = 3 bytes por pixel
      );

      // 4. Crear InputImage
      final inputImage = InputImage.fromBytes(
        bytes: rgbBytes,
        metadata: metadata,
      );

      return inputImage;
    } catch (e) {
      print('[FrameConverter] ❌ Error en conversión: $e');
      return null;
    }
  }

  /// Convierte Image (package 'image') a bytes RGB
  static Uint8List _imageToRgbBytes(img.Image image) {
    final rgbBytes = <int>[];

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        rgbBytes.add(pixel.r.toInt()); // Red
        rgbBytes.add(pixel.g.toInt()); // Green
        rgbBytes.add(pixel.b.toInt()); // Blue
      }
    }

    return Uint8List.fromList(rgbBytes);
  }

  /// Validar dimensiones del frame
  static bool validateFrameDimensions(Uint8List jpegBytes) {
    try {
      final image = img.decodeJpeg(jpegBytes);
      if (image == null) return false;

      // ESP32-CAM debería enviar 640x480 VGA
      final isValid = image.width == 640 && image.height == 480;

      if (!isValid) {
        print('[FrameConverter] ⚠️ Dimensiones inesperadas: '
            '${image.width}x${image.height} (esperado: 640x480)');
      }

      return isValid;
    } catch (e) {
      print('[FrameConverter] ❌ Error validando dimensiones: $e');
      return false;
    }
  }

  /// Obtener dimensiones del frame sin decodificar completamente
  static Size? getFrameSize(Uint8List jpegBytes) {
    try {
      final image = img.decodeJpeg(jpegBytes);
      if (image == null) return null;

      return Size(image.width.toDouble(), image.height.toDouble());
    } catch (e) {
      print('[FrameConverter] ❌ Error obteniendo tamaño: $e');
      return null;
    }
  }
}
```

**Notas técnicas**:
- **Por qué usar `package:image`**: ML Kit requiere `InputImage`, pero solo acepta formatos específicos. El ESP32 envía JPEG comprimido, así que necesitamos decodificarlo primero.
- **Formato RGB**: MediaPipe espera datos en formato RGB (3 bytes por pixel).
- **Rotación fija**: Como el ESP32-CAM está montado en posición fija, siempre usamos `rotation0deg`.

---

## 1.6 Integración con HttpServerService

### Paso 1.6.1: Verificar que HttpServerService está funcional

**Archivo existente**: `lib/data/datasources/local/http_server_service.dart`

**Verificar que tiene**:
```dart
final _frameController = StreamController<CameraFrame>.broadcast();
Stream<CameraFrame> get frameStream => _frameController.stream;

Future<Response> _handleImageUpload(Request request) async {
  // Recibe frames del ESP32-CAM
  final imageBytes = base64Decode(base64Image);
  final frame = CameraFrame.fromDecodedBytes(...);
  _frameController.add(frame);
}
```

**IMPORTANTE**: No modificar este archivo en Fase 1. Solo verificar que funciona.

### Paso 1.6.2: Crear servicio de suscripción a frames

**Archivo**: `lib/core/vision/utils/frame_subscriber.dart`

```dart
import 'dart:async';
import '../../../data/datasources/local/http_server_service.dart';
import '../../../data/models/camera_frame.dart';
import 'frame_converter.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Suscriptor a frames del ESP32-CAM con conversión automática
class FrameSubscriber {
  final HttpServerService _httpServerService;
  StreamSubscription<CameraFrame>? _frameSubscription;

  final _inputImageController = StreamController<InputImage>.broadcast();
  Stream<InputImage> get inputImageStream => _inputImageController.stream;

  FrameSubscriber(this._httpServerService);

  /// Inicia la suscripción a frames del ESP32-CAM
  void start() {
    _frameSubscription = _httpServerService.frameStream.listen((frame) {
      // Convertir JPEG → InputImage
      final inputImage = FrameConverter.fromJpegBytes(frame.imageBytes);

      if (inputImage != null) {
        _inputImageController.add(inputImage);
      } else {
        print('[FrameSubscriber] ⚠️ Frame descartado (conversión fallida)');
      }
    });

    print('[FrameSubscriber] ✅ Suscripción a frames iniciada');
  }

  /// Detiene la suscripción
  void stop() {
    _frameSubscription?.cancel();
    print('[FrameSubscriber] 🛑 Suscripción a frames detenida');
  }

  void dispose() {
    stop();
    _inputImageController.close();
  }
}
```

---

## 1.7 Pruebas de Verificación

### Paso 1.7.1: Test de conversión de frames

**Archivo**: `test/core/vision/utils/frame_converter_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:driveguard/core/vision/utils/frame_converter.dart';
import 'dart:typed_data';

void main() {
  group('FrameConverter', () {
    test('debe rechazar bytes vacíos', () {
      final result = FrameConverter.fromJpegBytes(Uint8List(0));
      expect(result, isNull);
    });

    test('debe rechazar JPEG inválido', () {
      final invalidJpeg = Uint8List.fromList([0xFF, 0xD8, 0x00]); // JPEG incompleto
      final result = FrameConverter.fromJpegBytes(invalidJpeg);
      expect(result, isNull);
    });

    // TODO: Agregar test con JPEG real del ESP32-CAM
  });
}
```

### Paso 1.7.2: Test de integración con HttpServerService

**Verificación manual**:

1. Asegurarse de que el ESP32-CAM esté conectado y enviando frames
2. Abrir la app en modo debug
3. Ir a "Debug Cámara ESP32"
4. Verificar logs:

```
✅ Servidor HTTP iniciado en puerto 8080
📡 Esperando conexión del ESP32-CAM...
🤝 Handshake recibido del ESP32-CAM
   IP ESP32: 192.168.43.100
📸 Frame recibido #1 (45678 bytes)
[FrameConverter] ✅ Frame convertido: 640x480
[FrameSubscriber] ✅ InputImage emitido
```

---

## 1.8 Checklist de Fase 1

Al finalizar esta fase, verificar:

- [ ] Dependencias instaladas (`flutter pub get` exitoso)
- [ ] Estructura de directorios creada (`lib/core/vision/`)
- [ ] Modelos creados (`VisionEvent`, `FaceData`, `HandData`)
- [ ] `EventType` extendido con eventos de visión
- [ ] `FrameConverter` implementado y probado
- [ ] `FrameSubscriber` implementado
- [ ] HttpServerService verificado funcional
- [ ] Tests unitarios escritos
- [ ] ESP32-CAM enviando frames exitosamente
- [ ] Frames siendo convertidos a `InputImage` sin errores

---

## 1.9 Problemas Comunes y Soluciones

### Problema: "MissingPluginException" al usar ML Kit

**Causa**: Plugins nativos no compilados.

**Solución**:
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### Problema: "Failed to decode JPEG"

**Causa**: Frame corrupto o incompleto del ESP32-CAM.

**Solución**:
1. Verificar calidad JPEG en ESP32 (debería ser 10-12)
2. Verificar que WiFi tenga buena señal
3. Agregar retry logic en FrameConverter

### Problema: Frames no llegan a FrameSubscriber

**Causa**: HttpServerService no está corriendo.

**Solución**:
1. Asegurarse de abrir "Debug Cámara ESP32" en la app
2. Verificar que el servidor inicie en puerto 8080
3. Verificar que ESP32 haga handshake exitoso

---

## Siguiente Fase

**FASE 2**: Implementación de procesadores MediaPipe y detectores de eventos.

Ver: `PLAN_FASE2_IMPLEMENTACION.md`
