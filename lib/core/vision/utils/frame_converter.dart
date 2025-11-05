import 'dart:typed_data';
import 'dart:ui';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

/// Convierte frames JPEG del ESP32-CAM a InputImage para MediaPipe
///
/// Esta clase se encarga de transformar los frames JPEG recibidos del ESP32-CAM
/// (vía HTTP como Uint8List) al formato InputImage requerido por ML Kit.
///
/// Proceso de conversión:
/// 1. Validar que los bytes sean un JPEG válido
/// 2. Decodificar JPEG → Image (usando package 'image')
/// 3. Convertir Image → formato RGB/NV21
/// 4. Crear InputImage con metadata correcta
class FrameConverter {
  /// Dimensiones esperadas del ESP32-CAM (VGA)
  static const int expectedWidth = 640;
  static const int expectedHeight = 480;

  /// Umbral mínimo de tamaño para considerar válido un frame (en bytes)
  /// Un JPEG de 640x480 con calidad 12 debería tener ~30-60 KB
  static const int minFrameSizeBytes = 10 * 1024; // 10 KB

  /// Umbral máximo de tamaño para considerar válido un frame (en bytes)
  static const int maxFrameSizeBytes = 500 * 1024; // 500 KB

  /// Convierte JPEG bytes a InputImage
  ///
  /// Retorna null si:
  /// - Los bytes están vacíos o corruptos
  /// - La decodificación falla
  /// - Las dimensiones no son las esperadas (con warning)
  static InputImage? fromJpegBytes(Uint8List jpegBytes) {
    try {
      // 1. Validación básica
      if (!_isValidJpeg(jpegBytes)) {
        print('[FrameConverter] ❌ JPEG inválido o corrupto');
        return null;
      }

      // 2. Validar tamaño
      if (jpegBytes.length < minFrameSizeBytes) {
        print('[FrameConverter] ⚠️ Frame muy pequeño: ${jpegBytes.length} bytes '
            '(esperado: >$minFrameSizeBytes bytes)');
        return null;
      }

      if (jpegBytes.length > maxFrameSizeBytes) {
        print('[FrameConverter] ⚠️ Frame muy grande: ${jpegBytes.length} bytes '
            '(esperado: <$maxFrameSizeBytes bytes)');
        return null;
      }

      // 3. Decodificar JPEG
      final image = img.decodeImage(jpegBytes);
      if (image == null) {
        print('[FrameConverter] ❌ Error al decodificar JPEG');
        return null;
      }

      // 4. Validar dimensiones (con warning, no bloqueante)
      if (image.width != expectedWidth || image.height != expectedHeight) {
        print('[FrameConverter] ⚠️ Dimensiones inesperadas: '
            '${image.width}x${image.height} (esperado: ${expectedWidth}x$expectedHeight)');
        // No bloqueamos, MediaPipe puede trabajar con otras resoluciones
      }

      // 5. Convertir a NV21 (YUV420) para ML Kit
      // ML Kit requiere formato raw (NV21), no acepta JPEG comprimido en fromBytes
      final nv21Bytes = _imageToNv21Bytes(image);

      final inputImage = InputImage.fromBytes(
        bytes: nv21Bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation0deg, // ESP32-CAM está fijo
          format: InputImageFormat.nv21, // Formato NV21 (YUV420)
          bytesPerRow: image.width, // Para NV21, bytesPerRow = width
        ),
      );

      return inputImage;
    } catch (e, stackTrace) {
      print('[FrameConverter] ❌ Error en conversión: $e');
      print('[FrameConverter] Stack trace: $stackTrace');
      return null;
    }
  }

  /// Valida si los bytes representan un JPEG válido
  ///
  /// Un JPEG válido debe:
  /// - Tener al menos 2 bytes
  /// - Comenzar con SOI marker (0xFF 0xD8)
  /// - Terminar con EOI marker (0xFF 0xD9)
  static bool _isValidJpeg(Uint8List bytes) {
    if (bytes.isEmpty) {
      return false;
    }

    // Verificar tamaño mínimo
    if (bytes.length < 2) {
      return false;
    }

    // Verificar SOI marker (Start of Image)
    if (bytes[0] != 0xFF || bytes[1] != 0xD8) {
      print('[FrameConverter] ❌ JPEG sin SOI marker válido '
          '(encontrado: 0x${bytes[0].toRadixString(16)} 0x${bytes[1].toRadixString(16)})');
      return false;
    }

    // Verificar EOI marker (End of Image)
    if (bytes.length >= 2) {
      final lastTwo = bytes.length - 2;
      if (bytes[lastTwo] != 0xFF || bytes[lastTwo + 1] != 0xD9) {
        print('[FrameConverter] ⚠️ JPEG sin EOI marker válido '
            '(puede estar incompleto)');
        // No bloqueamos, algunos encoders no agregan EOI
      }
    }

    return true;
  }

  /// Validar dimensiones del frame sin decodificar completamente
  ///
  /// Retorna true si las dimensiones coinciden con las esperadas
  static bool validateFrameDimensions(Uint8List jpegBytes) {
    try {
      final size = getFrameSize(jpegBytes);
      if (size == null) return false;

      final isValid =
          size.width == expectedWidth && size.height == expectedHeight;

      if (!isValid) {
        print('[FrameConverter] ⚠️ Dimensiones inesperadas: '
            '${size.width.toInt()}x${size.height.toInt()} '
            '(esperado: ${expectedWidth}x$expectedHeight)');
      }

      return isValid;
    } catch (e) {
      print('[FrameConverter] ❌ Error validando dimensiones: $e');
      return false;
    }
  }

  /// Obtener dimensiones del frame sin decodificar completamente
  ///
  /// Retorna null si el JPEG es inválido
  static Size? getFrameSize(Uint8List jpegBytes) {
    try {
      if (!_isValidJpeg(jpegBytes)) {
        return null;
      }

      final image = img.decodeImage(jpegBytes);
      if (image == null) return null;

      return Size(image.width.toDouble(), image.height.toDouble());
    } catch (e) {
      print('[FrameConverter] ❌ Error obteniendo tamaño: $e');
      return null;
    }
  }

  /// Obtiene información de diagnóstico del frame
  ///
  /// Útil para debugging y monitoreo
  static Map<String, dynamic> getFrameInfo(Uint8List jpegBytes) {
    final size = getFrameSize(jpegBytes);
    final isValid = _isValidJpeg(jpegBytes);

    return {
      'sizeBytes': jpegBytes.length,
      'sizeMB': (jpegBytes.length / (1024 * 1024)).toStringAsFixed(2),
      'width': size?.width.toInt() ?? 0,
      'height': size?.height.toInt() ?? 0,
      'isValidJpeg': isValid,
      'hasExpectedDimensions': size != null
          ? (size.width == expectedWidth && size.height == expectedHeight)
          : false,
      'aspectRatio':
          size != null ? (size.width / size.height).toStringAsFixed(2) : '0',
    };
  }

  /// Convierte Image (package 'image') a bytes NV21 para MediaPipe
  ///
  /// NOTA: Esta función no se usa actualmente porque ML Kit acepta JPEG directamente,
  /// pero se mantiene para compatibilidad futura si se necesita conversión explícita
  static Uint8List _imageToNv21Bytes(img.Image image) {
    final width = image.width;
    final height = image.height;
    final ySize = width * height;
    final uvSize = width * height ~/ 2;
    final nv21 = Uint8List(ySize + uvSize);

    int yIndex = 0;
    int uvIndex = ySize;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();

        // Conversión RGB → YUV
        final yValue = ((66 * r + 129 * g + 25 * b + 128) >> 8) + 16;
        nv21[yIndex++] = yValue.clamp(0, 255);

        // UV interleaved (solo en posiciones pares)
        if (y % 2 == 0 && x % 2 == 0) {
          final uValue = ((-38 * r - 74 * g + 112 * b + 128) >> 8) + 128;
          final vValue = ((112 * r - 94 * g - 18 * b + 128) >> 8) + 128;
          nv21[uvIndex++] = vValue.clamp(0, 255);
          nv21[uvIndex++] = uValue.clamp(0, 255);
        }
      }
    }

    return nv21;
  }
}
