import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/camera_stream/camera_stream_bloc.dart';
import '../../blocs/camera_stream/camera_stream_event.dart';
import '../../blocs/camera_stream/camera_stream_state.dart';
import '../../widgets/esp32/esp32_debug_panel.dart';

/// Página de debug del ESP32-CAM
class ESP32DebugPage extends StatefulWidget {
  const ESP32DebugPage({super.key});

  @override
  State<ESP32DebugPage> createState() => _ESP32DebugPageState();
}

class _ESP32DebugPageState extends State<ESP32DebugPage> {
  @override
  void initState() {
    super.initState();
    // Iniciar el stream al entrar a la página si no está iniciado
    final bloc = context.read<CameraStreamBloc>();
    if (bloc.state is CameraStreamInitial || bloc.state is CameraStreamStopped) {
      bloc.add(const StartCameraStream());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ESP32-CAM Debug'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          // Botón de reconexión
          BlocBuilder<CameraStreamBloc, CameraStreamState>(
            builder: (context, state) {
              if (state is CameraStreamError) {
                return IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Reconectar',
                  onPressed: () {
                    context.read<CameraStreamBloc>().add(
                          const ReconnectCameraStream(),
                        );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
          // Botón de información
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Información',
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Panel de debug principal
            const ESP32DebugPanel(),

            // Instrucciones de configuración
            _buildInstructionsCard(),

            const SizedBox(height: 16),
          ],
        ),
      ),
      // Botón flotante para iniciar/detener servidor
      floatingActionButton: BlocBuilder<CameraStreamBloc, CameraStreamState>(
        builder: (context, state) {
          final isRunning = state is CameraStreamConnected ||
              state is CameraStreamNewFrame ||
              state is CameraStreamLoading;

          return FloatingActionButton.extended(
            onPressed: () {
              if (isRunning) {
                _confirmStopServer(context);
              } else {
                context.read<CameraStreamBloc>().add(const StartCameraStream());
              }
            },
            icon: Icon(isRunning ? Icons.stop : Icons.play_arrow),
            label: Text(isRunning ? 'Detener' : 'Iniciar'),
            backgroundColor: isRunning ? Colors.red : Colors.green,
          );
        },
      ),
    );
  }

  /// Widget con instrucciones de configuración
  Widget _buildInstructionsCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ExpansionTile(
        leading: const Icon(Icons.help_outline, color: Colors.blue),
        title: const Text(
          'Instrucciones de Configuración',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInstructionStep(
                  '1',
                  'Conecta tu smartphone y ESP32-CAM a la misma red WiFi',
                ),
                const SizedBox(height: 12),
                _buildInstructionStep(
                  '2',
                  'Asegúrate de que el servidor esté iniciado (botón verde)',
                ),
                const SizedBox(height: 12),
                _buildInstructionStep(
                  '3',
                  'Copia la dirección IP mostrada arriba',
                ),
                const SizedBox(height: 12),
                _buildInstructionStep(
                  '4',
                  'Configura esa IP en el código del ESP32-CAM',
                ),
                const SizedBox(height: 12),
                _buildInstructionStep(
                  '5',
                  'Reinicia el ESP32-CAM y las imágenes comenzarán a llegar',
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.amber.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Nota: Ambos dispositivos deben estar en la misma red local',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Widget para un paso de instrucción
  Widget _buildInstructionStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              text,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }

  /// Muestra diálogo de información
  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info, color: Colors.blue),
            SizedBox(width: 8),
            Text('Información'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ESP32-CAM Debug Panel',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Esta pantalla muestra las imágenes recibidas en tiempo real desde tu ESP32-CAM.',
              ),
              SizedBox(height: 12),
              Text(
                'Características:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Servidor HTTP embebido en puerto 8080'),
              Text('• Recepción automática de frames JPEG'),
              Text('• Visualización en tiempo real'),
              Text('• Contador de frames recibidos'),
              Text('• Reconexión automática en caso de error'),
              SizedBox(height: 12),
              Text(
                'Frecuencia de envío ESP32: ~2 FPS (500ms)',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  /// Confirma antes de detener el servidor
  void _confirmStopServer(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Detener servidor'),
        content: const Text(
          '¿Estás seguro de que deseas detener el servidor?\n\n'
          'El ESP32-CAM dejará de enviar imágenes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<CameraStreamBloc>().add(const StopCameraStream());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Detener'),
          ),
        ],
      ),
    );
  }
}
