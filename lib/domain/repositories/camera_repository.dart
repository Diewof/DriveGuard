import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../data/models/camera_frame.dart';

/// Repositorio para gestionar la comunicación con el ESP32-CAM
abstract class CameraRepository {
  /// Inicia el servidor HTTP para recibir frames del ESP32-CAM
  /// Retorna Right(true) si inició correctamente, Left(Failure) si hubo error
  Future<Either<Failure, bool>> startServer();

  /// Detiene el servidor HTTP
  /// Retorna Right(true) si detuvo correctamente, Left(Failure) si hubo error
  Future<Either<Failure, bool>> stopServer();

  /// Stream de frames recibidos desde el ESP32-CAM
  /// Emite un CameraFrame cada vez que se recibe una imagen nueva
  Stream<CameraFrame> get frameStream;

  /// Obtiene el último frame recibido
  /// Retorna Right(CameraFrame) si hay un frame disponible
  /// Retorna Left(Failure) si no hay frames o hubo error
  Either<Failure, CameraFrame?> getLastFrame();

  /// Indica si el servidor está activo
  bool get isServerRunning;

  /// Obtiene la dirección IP y puerto del servidor
  /// Útil para mostrar en la UI de debug
  String? get serverAddress;

  /// Obtiene el contador de frames recibidos
  int get frameCount;

  /// Stream que notifica cuando un ESP32 se conecta (emite la IP del ESP32)
  Stream<String> get esp32ConnectedStream;

  /// Obtiene información del servidor (IP, puerto, estado)
  Map<String, dynamic> getServerInfo();
}
