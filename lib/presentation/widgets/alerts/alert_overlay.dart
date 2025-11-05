import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/app_spacing.dart';
import '../../../core/utils/app_typography.dart';

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

    if (mounted && widget.onDismiss != null) {
      widget.onDismiss!();
    }
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
        return AppColors.warning;
      case AlertSeverity.medium:
        return AppColors.moderate;
      case AlertSeverity.high:
        return AppColors.danger;
      case AlertSeverity.critical:
        return const Color(0xFFDC2626); // red-700
    }
  }

  Color _getBackgroundColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.low:
        return AppColors.getSeverityBackgroundColor('LOW');
      case AlertSeverity.medium:
        return AppColors.getSeverityBackgroundColor('MEDIUM');
      case AlertSeverity.high:
        return AppColors.getSeverityBackgroundColor('HIGH');
      case AlertSeverity.critical:
        return AppColors.getSeverityBackgroundColor('CRITICAL');
    }
  }

  IconData _getAlertIcon(AlertType type) {
    switch (type) {
      // IMU-based alerts
      case AlertType.harshBraking:
        return Icons.warning; // Frenado brusco
      case AlertType.aggressiveAcceleration:
        return Icons.speed; // Aceleración agresiva
      case AlertType.sharpTurn:
        return Icons.turn_sharp_right; // Giro cerrado
      case AlertType.weaving:
        return Icons.sync_alt; // Zigzagueo
      case AlertType.roughRoad:
        return Icons.terrain; // Camino irregular
      case AlertType.speedBump:
        return Icons.landscape; // Lomo de toro

      // Vision-based alerts
      case AlertType.distraction:
        return Icons.phone_android; // Distracción por celular
      case AlertType.inattention:
        return Icons.visibility_off; // Desatención visual
      case AlertType.handsOff:
        return Icons.front_hand; // Manos fuera del volante
      case AlertType.noFaceDetected:
        return Icons.person_off; // Sin rostro detectado
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
    final severityColor = _getSeverityColor(widget.notification.severity);
    final backgroundColor = _getBackgroundColor(widget.notification.severity);

    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.overlay,
        child: SafeArea(
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                margin: const EdgeInsets.all(AppSpacing.paddingSection),
                padding: const EdgeInsets.all(AppSpacing.paddingSection),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                  border: Border.all(
                    color: severityColor,
                    width: AppSpacing.borderMedium,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: 0,
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
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: severityColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getAlertIcon(widget.notification.type),
                                  color: Colors.white,
                                  size: AppSpacing.iconLarge,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ALERTA DE SEGURIDAD',
                                style: AppTypography.label.copyWith(
                                  color: severityColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Severidad: ${_getSeverityText(widget.notification.severity)}',
                                style: AppTypography.caption.copyWith(
                                  color: severityColor.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Contador de tiempo
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: severityColor,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                          ),
                          child: Text(
                            '${_remainingSeconds}s',
                            style: AppTypography.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.paddingSection),

                    // Mensaje principal
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                        border: Border.all(
                          color: AppColors.border,
                          width: AppSpacing.borderThin,
                        ),
                      ),
                      child: Text(
                        widget.notification.message,
                        style: AppTypography.alertBody.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.paddingSection),

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
                      value: _remainingSeconds / (widget.customDuration ?? 5).toDouble(),
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