import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../data/models/camera_frame.dart';
import '../../blocs/camera_stream/camera_stream_bloc.dart';
import '../../blocs/camera_stream/camera_stream_state.dart';

/// Widget que muestra el panel de debug del ESP32-CAM
class ESP32DebugPanel extends StatelessWidget {
  const ESP32DebugPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CameraStreamBloc, CameraStreamState>(
      builder: (context, state) {
        return Card(
          margin: const EdgeInsets.all(16),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(
                      Icons.camera_alt,
                      size: 28,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'ESP32-CAM Debug',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Estado de conexión
                _buildConnectionStatus(state),
                const SizedBox(height: 16),

                // Información del servidor
                if (state is CameraStreamConnected ||
                    state is CameraStreamNewFrame)
                  _buildServerInfo(state),

                const SizedBox(height: 16),

                // Imagen del ESP32-CAM
                _buildImagePreview(state),

                const SizedBox(height: 16),

                // Estadísticas
                if (state is CameraStreamConnected ||
                    state is CameraStreamNewFrame)
                  _buildStats(state),

                // Mensaje de error
                if (state is CameraStreamError) _buildErrorMessage(state),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Widget de estado de conexión
  Widget _buildConnectionStatus(CameraStreamState state) {
    IconData icon;
    Color color;
    String text;

    if (state is CameraStreamLoading) {
      icon = Icons.sync;
      color = Colors.orange;
      text = 'Iniciando servidor...';
    } else if (state is CameraStreamConnected) {
      icon = Icons.check_circle;
      color = Colors.green;
      text = 'Servidor activo - Esperando frames';
    } else if (state is CameraStreamNewFrame) {
      icon = Icons.check_circle;
      color = Colors.green;
      text = 'Conectado - Recibiendo frames';
    } else if (state is CameraStreamError) {
      icon = Icons.error;
      color = Colors.red;
      text = 'Error de conexión';
    } else if (state is CameraStreamStopped) {
      icon = Icons.cancel;
      color = Colors.grey;
      text = 'Servidor detenido';
    } else {
      icon = Icons.circle_outlined;
      color = Colors.grey;
      text = 'Desconectado';
    }

    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          'Estado: ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  /// Widget con información del servidor
  Widget _buildServerInfo(CameraStreamState state) {
    String serverAddress = '';

    if (state is CameraStreamConnected) {
      serverAddress = state.serverAddress;
    } else if (state is CameraStreamNewFrame) {
      serverAddress = state.serverAddress;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.network_wifi, size: 18, color: Colors.blue),
              const SizedBox(width: 8),
              const Text(
                'Dirección del servidor:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SelectableText(
            'http://$serverAddress/upload',
            style: TextStyle(
              fontFamily: 'monospace',
              color: Colors.blue.shade900,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '💡 Configura esta URL en tu ESP32-CAM',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  /// Widget con preview de la imagen
  Widget _buildImagePreview(CameraStreamState state) {
    if (state is CameraStreamNewFrame) {
      return _buildImageWithFade(state.frame);
    }

    // Placeholder cuando no hay imagen
    return Container(
      height: 240,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              state is CameraStreamConnected
                  ? 'Esperando primera imagen...'
                  : 'Sin imagen disponible',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget de imagen con animación de fade
  Widget _buildImageWithFade(CameraFrame frame) {
    final dateFormat = DateFormat('HH:mm:ss');
    final timestamp = dateFormat.format(frame.receivedAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Última imagen: $timestamp',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Image.memory(
              frame.imageBytes,
              key: ValueKey(frame.receivedAt.millisecondsSinceEpoch),
              fit: BoxFit.contain,
              height: 240,
              width: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 240,
                  color: Colors.red.shade100,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: Colors.red.shade700),
                        const SizedBox(height: 8),
                        Text(
                          'Error al cargar imagen',
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Widget de estadísticas
  Widget _buildStats(CameraStreamState state) {
    int frameCount = 0;

    if (state is CameraStreamConnected) {
      frameCount = state.frameCount;
    } else if (state is CameraStreamNewFrame) {
      frameCount = state.frameCount;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.photo_camera, size: 18, color: Colors.green.shade700),
              const SizedBox(width: 8),
              const Text(
                'Frames recibidos:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Text(
            '$frameCount',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }

  /// Widget de mensaje de error
  Widget _buildErrorMessage(CameraStreamError state) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              state.message,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
  }
}
