import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/camera_repository.dart';
import 'camera_stream_event.dart';
import 'camera_stream_state.dart';

/// BLoC para gestionar el stream de cámara del ESP32-CAM
class CameraStreamBloc extends Bloc<CameraStreamEvent, CameraStreamState> {
  final CameraRepository _cameraRepository;
  StreamSubscription? _frameSubscription;

  CameraStreamBloc({
    required CameraRepository cameraRepository,
  })  : _cameraRepository = cameraRepository,
        super(const CameraStreamInitial()) {
    on<StartCameraStream>(_onStartCameraStream);
    on<StopCameraStream>(_onStopCameraStream);
    on<NewFrameReceived>(_onNewFrameReceived);
    on<ReconnectCameraStream>(_onReconnectCameraStream);
  }

  /// Handler para iniciar el servidor y escuchar frames
  Future<void> _onStartCameraStream(
    StartCameraStream event,
    Emitter<CameraStreamState> emit,
  ) async {
    emit(const CameraStreamLoading());

    // Iniciar servidor HTTP
    final result = await _cameraRepository.startServer();

    result.fold(
      (failure) {
        emit(CameraStreamError(failure.message));
      },
      (_) {
        final serverAddress = _cameraRepository.serverAddress ?? 'Desconocido';
        emit(CameraStreamConnected(
          serverAddress: serverAddress,
          frameCount: 0,
        ));

        // Escuchar stream de frames
        _frameSubscription = _cameraRepository.frameStream.listen(
          (frame) {
            add(NewFrameReceived(frame));
          },
          onError: (error) {
            emit(CameraStreamError('Error en stream: $error'));
          },
        );
      },
    );
  }

  /// Handler para detener el servidor
  Future<void> _onStopCameraStream(
    StopCameraStream event,
    Emitter<CameraStreamState> emit,
  ) async {
    // Cancelar suscripción al stream
    await _frameSubscription?.cancel();
    _frameSubscription = null;

    // Detener servidor
    final result = await _cameraRepository.stopServer();

    result.fold(
      (failure) {
        emit(CameraStreamError(failure.message));
      },
      (_) {
        emit(const CameraStreamStopped());
      },
    );
  }

  /// Handler para procesar nuevo frame recibido
  void _onNewFrameReceived(
    NewFrameReceived event,
    Emitter<CameraStreamState> emit,
  ) {
    final serverAddress = _cameraRepository.serverAddress ?? 'Desconocido';
    final frameCount = _cameraRepository.frameCount;

    emit(CameraStreamNewFrame(
      frame: event.frame,
      serverAddress: serverAddress,
      frameCount: frameCount,
    ));
  }

  /// Handler para reconectar en caso de error
  Future<void> _onReconnectCameraStream(
    ReconnectCameraStream event,
    Emitter<CameraStreamState> emit,
  ) async {
    // Detener servidor actual si existe
    if (_cameraRepository.isServerRunning) {
      await _cameraRepository.stopServer();
    }

    // Cancelar suscripción anterior
    await _frameSubscription?.cancel();
    _frameSubscription = null;

    // Reintentar inicio
    add(const StartCameraStream());
  }

  @override
  Future<void> close() async {
    await _frameSubscription?.cancel();
    // No detenemos el servidor aquí para que siga corriendo si el usuario cierra y abre
    return super.close();
  }
}
