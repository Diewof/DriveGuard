import 'package:flutter_test/flutter_test.dart';
import 'package:driveguard_app/core/vision/utils/frame_converter.dart';
import 'dart:typed_data';

void main() {
  group('FrameConverter', () {
    group('fromJpegBytes', () {
      test('debe rechazar bytes vacíos', () {
        final result = FrameConverter.fromJpegBytes(Uint8List(0));
        expect(result, isNull);
      });

      test('debe rechazar JPEG inválido (sin SOI marker)', () {
        final invalidJpeg = Uint8List.fromList([0x00, 0x00, 0x00]);
        final result = FrameConverter.fromJpegBytes(invalidJpeg);
        expect(result, isNull);
      });

      test('debe rechazar JPEG incompleto', () {
        // JPEG con solo SOI marker pero sin datos
        final incompleteJpeg = Uint8List.fromList([0xFF, 0xD8]);
        final result = FrameConverter.fromJpegBytes(incompleteJpeg);
        expect(result, isNull);
      });

      test('debe rechazar frame muy pequeño', () {
        // JPEG válido pero muy pequeño (< 10KB)
        final smallJpeg = Uint8List.fromList([
          0xFF, 0xD8, // SOI
          ...List.filled(5000, 0x00), // Datos insuficientes
          0xFF, 0xD9, // EOI
        ]);
        final result = FrameConverter.fromJpegBytes(smallJpeg);
        expect(result, isNull);
      });

      // TODO: Agregar test con JPEG real del ESP32-CAM cuando esté disponible
      // test('debe convertir JPEG válido del ESP32-CAM', () {
      //   final validJpeg = loadTestAsset('test_frame_640x480.jpg');
      //   final result = FrameConverter.fromJpegBytes(validJpeg);
      //   expect(result, isNotNull);
      // });
    });

    group('validateFrameDimensions', () {
      test('debe retornar false para bytes vacíos', () {
        final result = FrameConverter.validateFrameDimensions(Uint8List(0));
        expect(result, isFalse);
      });

      test('debe retornar false para JPEG inválido', () {
        final invalidJpeg = Uint8List.fromList([0x00, 0x00]);
        final result = FrameConverter.validateFrameDimensions(invalidJpeg);
        expect(result, isFalse);
      });
    });

    group('getFrameSize', () {
      test('debe retornar null para bytes vacíos', () {
        final result = FrameConverter.getFrameSize(Uint8List(0));
        expect(result, isNull);
      });

      test('debe retornar null para JPEG inválido', () {
        final invalidJpeg = Uint8List.fromList([0x00, 0x00]);
        final result = FrameConverter.getFrameSize(invalidJpeg);
        expect(result, isNull);
      });
    });

    group('getFrameInfo', () {
      test('debe retornar información básica para bytes vacíos', () {
        final info = FrameConverter.getFrameInfo(Uint8List(0));
        expect(info['sizeBytes'], equals(0));
        expect(info['isValidJpeg'], isFalse);
        expect(info['width'], equals(0));
        expect(info['height'], equals(0));
      });

      test('debe retornar información para JPEG inválido', () {
        final invalidJpeg = Uint8List.fromList([0x00, 0x00]);
        final info = FrameConverter.getFrameInfo(invalidJpeg);
        expect(info['sizeBytes'], equals(2));
        expect(info['isValidJpeg'], isFalse);
      });

      test('debe calcular tamaño en MB correctamente', () {
        final largeData = Uint8List(1024 * 1024); // 1 MB
        final info = FrameConverter.getFrameInfo(largeData);
        expect(info['sizeMB'], equals('1.00'));
      });
    });

    group('Validación de JPEG', () {
      test('debe detectar SOI marker correcto', () {
        final validStart = Uint8List.fromList([0xFF, 0xD8, 0x00]);
        // Esta es una prueba indirecta a través de fromJpegBytes
        // La función _isValidJpeg es privada
        final result = FrameConverter.getFrameInfo(validStart);
        expect(result['isValidJpeg'], isTrue); // SOI marker es válido
      });

      test('debe detectar SOI marker incorrecto', () {
        final invalidStart = Uint8List.fromList([0xFF, 0x00, 0x00]);
        final result = FrameConverter.getFrameInfo(invalidStart);
        expect(result['isValidJpeg'], isFalse);
      });
    });

    group('Constantes', () {
      test('debe tener dimensiones esperadas correctas', () {
        expect(FrameConverter.expectedWidth, equals(640));
        expect(FrameConverter.expectedHeight, equals(480));
      });

      test('debe tener umbrales de tamaño razonables', () {
        expect(FrameConverter.minFrameSizeBytes, equals(10 * 1024));
        expect(FrameConverter.maxFrameSizeBytes, equals(500 * 1024));
        expect(
          FrameConverter.minFrameSizeBytes < FrameConverter.maxFrameSizeBytes,
          isTrue,
        );
      });
    });
  });
}
