import 'package:flutter/material.dart';

/// Estados de conexión del ESP32-CAM
enum Esp32ConnectionStatus {
  waiting,
  detected,
  connected,
  error,
}

/// Widget que muestra el estado de conexión del ESP32-CAM
class Esp32ConnectionIndicator extends StatelessWidget {
  final Esp32ConnectionStatus status;
  final String? esp32Ip;
  final String? serverIp;
  final int? serverPort;
  final String? errorMessage;

  const Esp32ConnectionIndicator({
    super.key,
    required this.status,
    this.esp32Ip,
    this.serverIp,
    this.serverPort,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            _buildStatusIcon(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getStatusTitle(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getStatusMessage(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (status) {
      case Esp32ConnectionStatus.waiting:
        return const _PulsingIndicator(
          color: Colors.orange,
          icon: Icons.wifi_find,
        );
      case Esp32ConnectionStatus.detected:
        return const _PulsingIndicator(
          color: Colors.yellow,
          icon: Icons.sync,
        );
      case Esp32ConnectionStatus.connected:
        return const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 32,
        );
      case Esp32ConnectionStatus.error:
        return const Icon(
          Icons.error,
          color: Colors.red,
          size: 32,
        );
    }
  }

  String _getStatusTitle() {
    switch (status) {
      case Esp32ConnectionStatus.waiting:
        return 'Esperando ESP32-CAM';
      case Esp32ConnectionStatus.detected:
        return 'ESP32 detectado';
      case Esp32ConnectionStatus.connected:
        return 'ESP32 conectado';
      case Esp32ConnectionStatus.error:
        return 'Error de conexión';
    }
  }

  String _getStatusMessage() {
    switch (status) {
      case Esp32ConnectionStatus.waiting:
        if (serverIp != null && serverPort != null) {
          return 'Servidor escuchando en $serverIp:$serverPort';
        }
        return 'Iniciando servidor...';
      case Esp32ConnectionStatus.detected:
        return 'Estableciendo conexión...';
      case Esp32ConnectionStatus.connected:
        if (esp32Ip != null) {
          return 'Recibiendo stream desde $esp32Ip';
        }
        return 'Conexión activa';
      case Esp32ConnectionStatus.error:
        return errorMessage ?? 'Error desconocido';
    }
  }
}

/// Widget que muestra un indicador pulsante
class _PulsingIndicator extends StatefulWidget {
  final Color color;
  final IconData icon;

  const _PulsingIndicator({
    required this.color,
    required this.icon,
  });

  @override
  State<_PulsingIndicator> createState() => _PulsingIndicatorState();
}

class _PulsingIndicatorState extends State<_PulsingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Icon(
            widget.icon,
            color: widget.color,
            size: 32,
          ),
        );
      },
    );
  }
}
