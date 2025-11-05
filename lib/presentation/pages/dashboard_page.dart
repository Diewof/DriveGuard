import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/dashboard/dashboard_bloc.dart';
import '../blocs/session/session_bloc.dart';
import '../../domain/repositories/camera_repository.dart';
import '../widgets/dashboard/control_panel.dart';
import '../widgets/dashboard/risk_indicator.dart';
import '../widgets/dashboard/status_indicator.dart';
import '../widgets/dashboard/stats_cards.dart';
import '../widgets/dashboard/emergency_confirmation_card.dart';
import '../widgets/alerts/alert_overlay.dart';
import '../widgets/esp32/esp32_connection_indicator.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_colors.dart';
import '../../core/utils/app_spacing.dart';
import '../../core/utils/app_typography.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_card.dart';
import '../../core/services/notification_service.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DashboardBloc(
        sessionBloc: context.read<SessionBloc>(),
        authBloc: context.read<AuthBloc>(),
        cameraRepository: context.read<CameraRepository>(),
      ),
      child: const DashboardView(),
    );
  }
}

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _alertController;
  final NotificationService _notificationService = NotificationService();
  bool _emergencyDialogShown = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _alertController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _initializeNotificationService();
  }

  Future<void> _initializeNotificationService() async {
    await _notificationService.initialize();

    // Configurar callbacks para mostrar/ocultar overlays
    _notificationService.onShowOverlay = _showAlertOverlay;
    _notificationService.onHideOverlay = _hideAlertOverlay;
  }

  void _showAlertOverlay(AlertNotification notification) {

    if (!mounted) {
      return;
    }

    _hideAlertOverlay(); // Cerrar overlay anterior si existe

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (dialogContext) => AlertOverlay(
        notification: notification,
        customDuration: _notificationService.settings.alertCardDuration,
        onDismiss: () {
          if (Navigator.canPop(dialogContext)) {
            Navigator.of(dialogContext, rootNavigator: false).pop();
          }
        },
        onStop: () {
          _notificationService.stopCurrentAlert();
          if (Navigator.canPop(dialogContext)) {
            Navigator.of(dialogContext, rootNavigator: false).pop();
          }
        },
      ),
    );
  }

  void _hideAlertOverlay() {
    if (mounted) {
      // Intentar cerrar el diálogo de forma segura
      try {
        final navigator = Navigator.of(context, rootNavigator: false);
        if (navigator.canPop()) {
          navigator.pop();
        }
      } catch (e) {
        // Ignorar errores si el diálogo ya se cerró
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _alertController.dispose();
    _notificationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: _buildAppBar(),
      drawer: _buildDrawer(context),
      body: BlocListener<DashboardBloc, DashboardState>(
        listener: (context, state) {
          _updateAnimations(state);

          // Mostrar/ocultar card de confirmación de emergencia
          if (state.showEmergencyConfirmation && !_emergencyDialogShown) {
            _showEmergencyConfirmation(context, state.emergencyCountdown);
          } else if (!state.showEmergencyConfirmation && _emergencyDialogShown) {
            _hideEmergencyConfirmation(context);
          }
        },
        child: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ControlPanel(
                    isMonitoring: state.isMonitoring,
                    sessionDuration: state.sessionDuration,
                    onToggleMonitoring: () => _toggleMonitoring(context, state),
                  ),
                  const SizedBox(height: 16),
                  _buildEsp32ConnectionIndicator(context),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: RiskIndicator(riskScore: state.riskScore),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: StatusIndicator(
                          currentAlertType: state.currentAlertType,
                          alertAnimation: _alertController,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  StatsCards(
                    distractionCount: state.distractionCount,
                    recklessCount: state.recklessCount,
                    emergencyCount: state.emergencyCount,
                  ),
                  const SizedBox(height: 16),
                  _buildSensorData(state),
                  const SizedBox(height: 16),
                  _buildRecentAlerts(state),
                  const SizedBox(height: 20),
                  _buildEmergencyButton(context),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        'DriveGuard Monitor',
        style: AppTypography.h3.copyWith(
          color: Colors.white,
        ),
      ),
      backgroundColor: AppColors.primaryDark,
      elevation: AppSpacing.elevation2,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            final isConnected = state.deviceStatus == 'CONECTADO';
            final statusColor = isConnected ? AppColors.success : AppColors.danger;

            return Container(
              margin: const EdgeInsets.only(right: AppSpacing.md, top: AppSpacing.sm, bottom: AppSpacing.sm),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSpacing.radiusCircular),
                border: Border.all(
                  color: statusColor,
                  width: AppSpacing.borderThin,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: statusColor.withValues(
                            alpha: 0.7 + (_pulseController.value * 0.3),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    state.deviceStatus,
                    style: AppTypography.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header con gradiente de marca
          Container(
            height: 220,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Logo con sombra
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                        ),
                        child: Image.asset(
                          'assets/images/logo_app.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.white.withValues(alpha: 0.15),
                              child: const Icon(
                                Icons.shield_outlined,
                                color: Colors.white,
                                size: 40,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      AppConstants.appName,
                      style: AppTypography.h2.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Sistema de Monitoreo Inteligente',
                      style: AppTypography.body.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Menú items con hover states
          _buildDrawerItem(
            context: context,
            icon: Icons.person_outline,
            title: 'Mi Perfil',
            onTap: () {
              Navigator.pop(context);
              context.push('/profile');
            },
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.history_outlined,
            title: 'Historial',
            onTap: () {
              Navigator.pop(context);
              context.push('/history');
            },
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.notifications_outlined,
            title: 'Notificaciones',
            onTap: () {
              Navigator.pop(context);
              context.push(AppConstants.notificationSettingsRoute);
            },
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.tune_outlined,
            title: 'Detección',
            onTap: () {
              Navigator.pop(context);
              context.push('/detection-settings');
            },
          ),
          _buildDrawerItem(
            context: context,
            icon: Icons.camera_enhance_outlined,
            title: 'Detectar y Calibrar Cam',
            subtitle: 'Verificar posición y ajustar ROI',
            onTap: () {
              Navigator.pop(context);
              context.push('/camera-calibration');
            },
          ),

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Divider(
              color: AppColors.divider,
              thickness: 1,
            ),
          ),

          _buildDrawerItem(
            context: context,
            icon: Icons.support_agent,
            title: 'Soporte',
            subtitle: 'Ayuda y preguntas frecuentes',
            onTap: () {
              Navigator.pop(context);
              context.push('/support');
            },
          ),

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Divider(
              color: AppColors.divider,
              thickness: 1,
            ),
          ),

          _buildDrawerItem(
            context: context,
            icon: Icons.logout_outlined,
            title: 'Cerrar Sesión',
            iconColor: AppColors.danger,
            textColor: AppColors.danger,
            onTap: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(AuthLogoutRequested());
              context.go(AppConstants.loginRoute);
            },
          ),

          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: iconColor ?? AppColors.primary,
                  size: AppSpacing.iconMedium,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.body.copyWith(
                          color: textColor ?? AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textDisabled,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEsp32ConnectionIndicator(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        // Si no está monitoreando, no mostrar el indicador
        if (!state.isMonitoring) {
          return const SizedBox.shrink();
        }

        // Determinar estado de conexión basado en el estado del BLoC
        Esp32ConnectionStatus status;

        if (state.deviceStatus == 'CONECTADO') {
          status = Esp32ConnectionStatus.connected;
        } else if (state.serverIp != null) {
          status = Esp32ConnectionStatus.waiting;
        } else {
          return const SizedBox.shrink();
        }

        return Esp32ConnectionIndicator(
          status: status,
          esp32Ip: state.esp32Ip,
          serverIp: state.serverIp,
          serverPort: state.serverPort,
        );
      },
    );
  }

  Widget _buildSensorData(DashboardState state) {
    final sensorData = state.currentSensorData;
    if (sensorData == null) {
      return CommonCard(
        child: Center(
          child: Text(
            'No hay datos de sensores',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return CommonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sensores en Tiempo Real',
                style: AppTypography.h4,
              ),
              Icon(
                Icons.sensors_outlined,
                color: AppColors.textDisabled,
                size: AppSpacing.iconSmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildSensorGroup(
                  'Acelerómetro (m/s²)',
                  [
                    ('X', sensorData.accelerationX),
                    ('Y', sensorData.accelerationY),
                    ('Z', sensorData.accelerationZ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSensorGroup(
                  'Giroscopio (°/s)',
                  [
                    ('X', sensorData.gyroscopeX),
                    ('Y', sensorData.gyroscopeY),
                    ('Z', sensorData.gyroscopeZ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSensorGroup(String title, List<(String, double)> values) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...values.map((value) => _buildSensorValue(value.$1, value.$2)),
      ],
    );
  }

  Widget _buildSensorValue(String axis, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$axis:', style: AppTypography.body),
          Text(
            Formatters.formatSensorValue(value),
            style: AppTypography.body.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAlerts(DashboardState state) {
    return CommonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Alertas Recientes',
                style: AppTypography.h4,
              ),
              Icon(
                Icons.history,
                color: AppColors.textDisabled,
                size: AppSpacing.iconSmall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (state.recentAlerts.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.paddingSection),
                child: Text(
                  'No hay alertas recientes',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            Column(
              children: state.recentAlerts.map((alert) {
                final timeString = Formatters.formatTime(alert['time']);
                return _buildAlertItem(alert, timeString);
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(Map<String, dynamic> alert, String timeString) {
    final severityColor = AppColors.getSeverityColor(alert['severity']);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.getSeverityBackgroundColor(alert['severity']),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        border: Border.all(
          color: severityColor.withValues(alpha: 0.3),
          width: AppSpacing.borderThin,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: severityColor,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert['type'],
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Severidad: ${alert['severity']}',
                  style: AppTypography.caption.copyWith(
                    color: severityColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            timeString,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSpacing.buttonHeightLarge,
      child: ElevatedButton(
        onPressed: () {
          context.read<DashboardBloc>().add(DashboardEmergencyActivated());
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.danger,
          foregroundColor: Colors.white,
          elevation: AppSpacing.elevation3,
          shadowColor: AppColors.danger.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusCircular),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emergency, size: AppSpacing.iconLarge),
            const SizedBox(width: AppSpacing.md),
            Text(
              'ACTIVAR PROTOCOLO DE EMERGENCIA',
              style: AppTypography.button.copyWith(
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleMonitoring(BuildContext context, DashboardState state) {
    if (state.isMonitoring) {
      context.read<DashboardBloc>().add(DashboardStopMonitoring());
    } else {
      context.read<DashboardBloc>().add(DashboardStartMonitoring());
    }
  }

  void _updateAnimations(DashboardState state) {
    // Pulse animation
    if (state.deviceStatus == 'CONECTADO' && state.isMonitoring) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat();
      }
    } else {
      if (_pulseController.isAnimating) {
        _pulseController.stop();
      }
    }

    // Alert animation
    if (state.currentAlertType != 'NORMAL') {
      _alertController.forward().then((_) {
        _alertController.reverse();
      });
    }
  }

  void _showEmergencyConfirmation(BuildContext context, int countdown) {
    // Solo mostrar si no está ya visible
    if (!mounted || _emergencyDialogShown) return;

    _emergencyDialogShown = true;

    showDialog(
      context: context,
      barrierDismissible: false, // No se puede cerrar tocando fuera
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (dialogContext) => EmergencyConfirmationCard(
        countdown: countdown,
        onCancel: () {
          context.read<DashboardBloc>().add(DashboardEmergencyCancelled());
        },
      ),
    ).then((_) {
      // Cuando se cierre el diálogo, actualizar la bandera
      _emergencyDialogShown = false;
    });
  }

  void _hideEmergencyConfirmation(BuildContext context) {
    if (mounted && _emergencyDialogShown) {
      try {
        final navigator = Navigator.of(context, rootNavigator: false);
        if (navigator.canPop()) {
          navigator.pop();
        }
        _emergencyDialogShown = false;
      } catch (e) {
        // Ignorar errores si el diálogo ya se cerró
        _emergencyDialogShown = false;
      }
    }
  }
}