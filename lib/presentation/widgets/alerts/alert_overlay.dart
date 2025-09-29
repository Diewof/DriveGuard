import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../../core/services/notification_service.dart';

class AlertOverlay extends StatefulWidget {
  final AlertNotification notification;
  final VoidCallback? onDismiss;
  final VoidCallback? onStop;
  final int? customDuration; // Duración personalizada en segundos

  const AlertOverlay({
    super.key,
    required this.notification,
    this.onDismiss,
    this.onStop,
    this.customDuration,
  });

  @override
  State<AlertOverlay> createState() => _AlertOverlayState();
}

class _AlertOverlayState extends State<AlertOverlay>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  Timer? _autoDismissTimer;
  late int _remainingSeconds;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.customDuration ?? 5; // Usar duración personalizada o default 5
    _setupAnimations();
    _startAnimations();
    _startAutoDismissTimer();

    // Vibración leve adicional al mostrar el overlay
    HapticFeedback.lightImpact();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
  }

  void _startAnimations() {
    _slideController.forward();
    _scaleController.forward();

    // Solo pulsar para alertas HIGH y CRITICAL
    if (widget.notification.severity.index >= AlertSeverity.high.index) {
      _pulseController.repeat(reverse: true);
    }
  }

  void _startAutoDismissTimer() {
    _autoDismissTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingSeconds--;
        });

        if (_remainingSeconds <= 0) {
          _dismiss();
        }
      }
    });
  }

  void _dismiss() {
    _autoDismissTimer?.cancel();

    _slideController.reverse().then((_) {
      if (widget.onDismiss != null) {
        widget.onDismiss!();
      }
    });
  }

  void _stopAlert() {
    if (widget.onStop != null) {
      widget.onStop!();
    }
    _dismiss();
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _pulseController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Color _getSeverityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.low:
        return Colors.yellow[700]!;
      case AlertSeverity.medium:
        return Colors.orange;
      case AlertSeverity.high:
        return Colors.deepOrange;
      case AlertSeverity.critical:
        return Colors.red;
    }
  }

  Color _getBackgroundColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.low:
        return Colors.yellow[50]!;
      case AlertSeverity.medium:
        return Colors.orange[50]!;
      case AlertSeverity.high:
        return Colors.deepOrange[50]!;
      case AlertSeverity.critical:
        return Colors.red[50]!;
    }
  }

  IconData _getAlertIcon(AlertType type) {
    switch (type) {
      case AlertType.distraction:
        return Icons.visibility_off;
      case AlertType.recklessDriving:
        return Icons.speed;
      case AlertType.impact:
        return Icons.car_crash;
      case AlertType.phoneUsage:
        return Icons.phone_android;
      case AlertType.lookAway:
        return Icons.remove_red_eye;
      case AlertType.harshBraking:
        return Icons.report_problem;
    }
  }

  String _getSeverityText(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.low:
        return 'BAJO';
      case AlertSeverity.medium:
        return 'MEDIO';
      case AlertSeverity.high:
        return 'ALTO';
      case AlertSeverity.critical:
        return 'CRÍTICO';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black.withValues(alpha: 0.4),
        child: SafeArea(
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _getBackgroundColor(widget.notification.severity),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getSeverityColor(widget.notification.severity),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header con icono y severidad
                    Row(
                      children: [
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: widget.notification.severity.index >= AlertSeverity.high.index
                                  ? _pulseAnimation.value
                                  : 1.0,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _getSeverityColor(widget.notification.severity),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getAlertIcon(widget.notification.type),
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ALERTA DE SEGURIDAD',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _getSeverityColor(widget.notification.severity),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Severidad: ${_getSeverityText(widget.notification.severity)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _getSeverityColor(widget.notification.severity).withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Contador de tiempo
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getSeverityColor(widget.notification.severity),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_remainingSeconds}s',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Mensaje principal
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[200]!,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        widget.notification.message,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Indicadores de notificación activa
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildNotificationIndicator(
                          Icons.volume_up,
                          'Audio',
                          Colors.blue,
                        ),
                        const SizedBox(width: 16),
                        _buildNotificationIndicator(
                          Icons.vibration,
                          'Vibración',
                          Colors.purple,
                        ),
                        const SizedBox(width: 16),
                        _buildNotificationIndicator(
                          Icons.visibility,
                          'Visual',
                          Colors.green,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Botones de acción
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: _stopAlert,
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.red[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.stop, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'DETENER',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextButton(
                            onPressed: _dismiss,
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.grey[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.close, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'CERRAR',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Barra de progreso
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: _remainingSeconds / 5.0,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getSeverityColor(widget.notification.severity),
                      ),
                      minHeight: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIndicator(
    IconData icon,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: color,
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}