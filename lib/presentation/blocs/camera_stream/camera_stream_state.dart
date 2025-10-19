import 'package:equatable/equatable.dart';
import '../../../data/models/camera_frame.dart';

/// Estados del CameraStreamBloc
abstract class CameraStreamState extends Equatable {
  const CameraStreamState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial antes de iniciar el servidor
class CameraStreamInitial extends CameraStreamState {
  const CameraStreamInitial();
}

/// Estado mientras se está iniciando el servidor
class CameraStreamLoading extends CameraStreamState {
  const CameraStreamLoading();
}

/// Estado cuando el servidor está activo y esperando frames
class CameraStreamConnected extends CameraStreamState {
  final String serverAddress;
  final int frameCount;

  const CameraStreamConnected({
    required this.serverAddress,
    required this.frameCount,
  });

  @override
  List<Object?> get props => [serverAddress, frameCount];
}

/// Estado cuando se recibe un nuevo frame
class CameraStreamNewFrame extends CameraStreamState {
  final CameraFrame frame;
  final String serverAddress;
  final int frameCount;

  const CameraStreamNewFrame({
    required this.frame,
    required this.serverAddress,
    required this.frameCount,
  });

  @override
  List<Object?> get props => [frame, serverAddress, frameCount];
}

/// Estado de error
class CameraStreamError extends CameraStreamState {
  final String message;

  const CameraStreamError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Estado cuando el servidor está detenido
class CameraStreamStopped extends CameraStreamState {
  const CameraStreamStopped();
}
