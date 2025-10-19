import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/dashboard/dashboard_bloc.dart';
import '../blocs/session/session_bloc.dart';
import '../widgets/dashboard/control_panel.dart';
import '../widgets/dashboard/risk_indicator.dart';
import '../widgets/dashboard/status_indicator.dart';
import '../widgets/dashboard/stats_cards.dart';
import '../widgets/alerts/alert_overlay.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_card.dart';
import '../../core/services/notification_service.dart';
import 'esp32/esp32_debug_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DashboardBloc(
        sessionBloc: context.read<SessionBloc>(),
        authBloc: context.read<AuthBloc>(),
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
      builder: (context) => AlertOverlay(
        notification: notification,
        customDuration: _notificationService.settings.alertCardDuration,
        onDismiss: () {
          Navigator.of(context).pop();
        },
        onStop: () {
          _notificationService.stopCurrentAlert();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _hideAlertOverlay() {
    if (mounted && Navigator.canPop(context)) {
      Navigator.of(context).pop();
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
      title: const Text(
        'DriveGuard Monitor',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      backgroundColor: AppColors.primaryDark,
      elevation: 2,
      actions: [
        BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, state) {
            return Container(
              margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: state.deviceStatus == 'CONECTADO'
                  ? AppColors.success.withValues(alpha: 0.2)
                  : AppColors.error.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: state.deviceStatus == 'CONECTADO'
                    ? AppColors.success
                    : AppColors.error,
                  width: 1,
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
                          color: (state.deviceStatus == 'CONECTADO'
                            ? AppColors.success
                            : AppColors.error)
                            .withValues(alpha: 0.7 + (_pulseController.value * 0.3)),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    state.deviceStatus,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
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
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.car_rental, color: Colors.white, size: 48),
                SizedBox(height: 8),
                Text(
                  AppConstants.appName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Sistema de Monitoreo',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person, color: AppColors.primary),
            title: const Text('Mi Perfil'),
            onTap: () {
              Navigator.pop(context);
              context.push('/profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.history, color: AppColors.primary),
            title: const Text('Historial'),
            onTap: () {
              Navigator.pop(context);
              context.push('/history');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: AppColors.primary),
            title: const Text('Configuración'),
            onTap: () {
              Navigator.pop(context);
              context.push(AppConstants.notificationSettingsRoute);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.camera_alt, color: AppColors.primary),
            title: const Text('ESP32-CAM Debug'),
            subtitle: const Text('Visualizar stream ESP32', style: TextStyle(fontSize: 12)),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ESP32DebugPage(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text('Cerrar Sesión'),
            onTap: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(AuthLogoutRequested());
              context.go(AppConstants.loginRoute);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSensorData(DashboardState state) {
    final sensorData = state.currentSensorData;
    if (sensorData == null) {
      return const CommonCard(
        child: Center(child: Text('No hay datos de sensores')),
      );
    }

    return CommonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sensores en Tiempo Real',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Icon(Icons.sensors, color: Colors.grey[400]),
            ],
          ),
          const SizedBox(height: 16),
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
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
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
          Text('$axis:', style: const TextStyle(fontSize: 14)),
          Text(
            Formatters.formatSensorValue(value),
            style: const TextStyle(
              fontSize: 14,
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
              const Text(
                'Alertas Recientes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Icon(Icons.history, color: Colors.grey[400]),
            ],
          ),
          const SizedBox(height: 16),
          if (state.recentAlerts.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No hay alertas recientes',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.getSeverityColor(alert['severity']).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.getSeverityColor(alert['severity']).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.getSeverityColor(alert['severity']),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert['type'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Severidad: ${alert['severity']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.getSeverityColor(alert['severity']),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            timeString,
            style: const TextStyle(
              fontSize: 11,
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
      height: 60,
      child: ElevatedButton(
        onPressed: () {
          context.read<DashboardBloc>().add(DashboardEmergencyActivated());
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emergency, size: 28),
            SizedBox(width: 12),
            Text(
              'ACTIVAR PROTOCOLO DE EMERGENCIA',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
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
}