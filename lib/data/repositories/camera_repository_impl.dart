import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../domain/repositories/camera_repository.dart';
import '../datasources/local/http_server_service.dart';
import '../models/camera_frame.dart';

/// Implementación del repositorio de cámara usando HttpServerService
class CameraRepositoryImpl implements CameraRepository {
  final HttpServerService _httpServerService;

  CameraRepositoryImpl({
    required HttpServerService httpServerService,
  }) : _httpServerService = httpServerService;

  @override
  Future<Either<Failure, bool>> startServer() async {
    try {
      await _httpServerService.startServer();
      return const Right(true);
    } catch (e) {
      return Left(ServerFailure('Error al iniciar servidor: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> stopServer() async {
    try {
      await _httpServerService.stopServer();
      return const Right(true);
    } catch (e) {
      return Left(ServerFailure('Error al detener servidor: $e'));
    }
  }

  @override
  Stream<CameraFrame> get frameStream => _httpServerService.frameStream;

  @override
  Either<Failure, CameraFrame?> getLastFrame() {
    try {
      final frame = _httpServerService.lastFrame;
      return Right(frame);
    } catch (e) {
      return Left(CacheFailure('Error al obtener último frame: $e'));
    }
  }

  @override
  bool get isServerRunning => _httpServerService.isRunning;

  @override
  String? get serverAddress => _httpServerService.serverAddress;

  @override
  int get frameCount => _httpServerService.frameCount;

  @override
  Stream<String> get esp32ConnectedStream => _httpServerService.esp32ConnectedStream;

  @override
  Map<String, dynamic> getServerInfo() => _httpServerService.getServerInfo();
}
