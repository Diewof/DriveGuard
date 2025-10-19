import 'dart:typed_data';
import 'package:equatable/equatable.dart';

/// Modelo que representa un frame de imagen capturado por el ESP32-CAM
class CameraFrame extends Equatable {
  /// Bytes de la imagen decodificada (JPEG)
  final Uint8List imageBytes;

  /// Timestamp de cuando se recibió la imagen en el dispositivo Flutter
  final DateTime receivedAt;

  /// Timestamp del ESP32 cuando capturó la imagen (en milisegundos)
  final int esp32Timestamp;

  const CameraFrame({
    required this.imageBytes,
    required this.receivedAt,
    required this.esp32Timestamp,
  });

  /// Crea un CameraFrame desde JSON recibido del ESP32
  /// Formato esperado: {"image": "base64String", "timestamp": 12345}
  factory CameraFrame.fromJson(Map<String, dynamic> json) {
    return CameraFrame(
      imageBytes: Uint8List(0), // Se decodificará en el servicio
      receivedAt: DateTime.now(),
      esp32Timestamp: json['timestamp'] as int? ?? 0,
    );
  }

  /// Crea un CameraFrame con bytes decodificados
  factory CameraFrame.fromDecodedBytes({
    required Uint8List bytes,
    required int esp32Timestamp,
  }) {
    return CameraFrame(
      imageBytes: bytes,
      receivedAt: DateTime.now(),
      esp32Timestamp: esp32Timestamp,
    );
  }

  /// Convierte el frame a JSON (útil para serialización)
  Map<String, dynamic> toJson() {
    return {
      'receivedAt': receivedAt.toIso8601String(),
      'esp32Timestamp': esp32Timestamp,
      'imageSize': imageBytes.length,
    };
  }

  /// Crea una copia con campos modificados
  CameraFrame copyWith({
    Uint8List? imageBytes,
    DateTime? receivedAt,
    int? esp32Timestamp,
  }) {
    return CameraFrame(
      imageBytes: imageBytes ?? this.imageBytes,
      receivedAt: receivedAt ?? this.receivedAt,
      esp32Timestamp: esp32Timestamp ?? this.esp32Timestamp,
    );
  }

  @override
  List<Object?> get props => [imageBytes, receivedAt, esp32Timestamp];

  @override
  String toString() {
    return 'CameraFrame(size: ${imageBytes.length} bytes, '
        'receivedAt: $receivedAt, esp32Timestamp: $esp32Timestamp)';
  }
}
