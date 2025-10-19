import 'package:equatable/equatable.dart';
import '../../../data/models/camera_frame.dart';

/// Eventos del CameraStreamBloc
abstract class CameraStreamEvent extends Equatable {
  const CameraStreamEvent();

  @override
  List<Object?> get props => [];
}

/// Evento para iniciar el servidor y el stream de cámara
class StartCameraStream extends CameraStreamEvent {
  const StartCameraStream();
}

/// Evento para detener el servidor y el stream de cámara
class StopCameraStream extends CameraStreamEvent {
  const StopCameraStream();
}

/// Evento cuando se recibe un nuevo frame del ESP32-CAM
class NewFrameReceived extends CameraStreamEvent {
  final CameraFrame frame;

  const NewFrameReceived(this.frame);

  @override
  List<Object?> get props => [frame];
}

/// Evento para reconectar el servidor en caso de error
class ReconnectCameraStream extends CameraStreamEvent {
  const ReconnectCameraStream();
}
