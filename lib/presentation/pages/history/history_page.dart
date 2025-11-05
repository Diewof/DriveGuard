import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../blocs/session/session_bloc.dart';
import '../../blocs/session/session_event.dart';
import '../../blocs/session/session_state.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../../domain/entities/driving_session.dart';
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/app_spacing.dart';
import '../../../core/utils/app_typography.dart';
import '../../../core/widgets/common_card.dart';
import '../../../core/utils/formatters.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  void _loadSessions() {
    final userId = context.read<AuthBloc>().state.user?.id;
    if (userId != null) {
      context.read<SessionBloc>().add(LoadUserSessions(userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Historial de Sesiones',
          style: AppTypography.h3.copyWith(
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryDark,
        elevation: AppSpacing.elevation2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_outlined, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocBuilder<SessionBloc, SessionState>(
        builder: (context, state) {
          if (state is SessionLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is SessionError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.textDisabled,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Error al cargar sesiones',
                      style: AppTypography.h4.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      state.message,
                      style: AppTypography.body.copyWith(
                        color: AppColors.danger,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ElevatedButton.icon(
                      onPressed: _loadSessions,
                      icon: const Icon(Icons.refresh_outlined),
                      label: const Text('Reintentar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else if (state is SessionsLoaded) {
            return _buildSessionsList(state.sessions);
          }

          return const Center(
            child: Text('No hay datos de sesiones disponibles'),
          );
        },
      ),
    );
  }

  Widget _buildSessionsList(List<DrivingSession> sessions) {
    if (sessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.history_outlined,
                size: 80,
                color: AppColors.textDisabled,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'No hay sesiones registradas',
                style: AppTypography.h3.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Comienza a monitorear tu conducción para ver el historial aquí',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadSessions(),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: sessions.length,
        itemBuilder: (context, index) {
          final session = sessions[index];
          return _buildSessionCard(session);
        },
      ),
    );
  }

  Widget _buildSessionCard(DrivingSession session) {
    final duration = session.endTime != null
        ? session.endTime!.difference(session.startTime)
        : Duration.zero;

    return CommonCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: () => _showSessionDetails(session),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con badge y fecha
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Sesión de Conducción',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusCircular),
                      border: Border.all(
                        color: _getStatusColor(session.status),
                        width: AppSpacing.borderThin,
                      ),
                    ),
                    child: Text(
                      _getStatusText(session.status),
                      style: AppTypography.caption.copyWith(
                        color: _getStatusColor(session.status),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    Formatters.formatDateTime(session.startTime),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // Stats en grid 2x2
              Row(
                children: [
                  Expanded(
                    child: _buildSessionStat(
                      'Duración',
                      _formatDuration(duration),
                      Icons.timer_outlined,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildSessionStat(
                      'Distancia',
                      '${session.totalDistance.toStringAsFixed(1)} km',
                      Icons.straighten_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _buildSessionStat(
                      'Vel. Prom.',
                      '${session.averageSpeed.toStringAsFixed(1)} km/h',
                      Icons.speed_outlined,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildSessionStat(
                      'Riesgo',
                      '${session.riskScore.toStringAsFixed(0)}%',
                      Icons.warning_amber_outlined,
                      valueColor: _getRiskColor(session.riskScore),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _buildAlertsSummary(session.dailyStats),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionStat(
    String label,
    String value,
    IconData icon, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              Text(
                value,
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAlertsSummary(DailyStats stats) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        border: Border.all(
          color: AppColors.border,
          width: AppSpacing.borderThin,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildAlertCount(
            'Distracción',
            stats.distractionCount,
            AppColors.warning,
            Icons.visibility_off_outlined,
          ),
          Container(
            width: 1,
            height: 32,
            color: AppColors.divider,
          ),
          _buildAlertCount(
            'Imprudencia',
            stats.recklessCount,
            AppColors.moderate,
            Icons.speed_outlined,
          ),
          Container(
            width: 1,
            height: 32,
            color: AppColors.divider,
          ),
          _buildAlertCount(
            'Emergencia',
            stats.emergencyCount,
            AppColors.danger,
            Icons.emergency_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCount(String label, int count, Color color, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: color,
        ),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: AppTypography.h4.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return AppColors.success;
      case 'PAUSED':
        return AppColors.warning;
      case 'COMPLETED':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'ACTIVE':
        return 'Activa';
      case 'PAUSED':
        return 'Pausada';
      case 'COMPLETED':
        return 'Completada';
      default:
        return 'Desconocido';
    }
  }

  Color _getRiskColor(double riskScore) {
    if (riskScore < 30) return AppColors.success;
    if (riskScore < 60) return AppColors.warning;
    return AppColors.danger;
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  void _showSessionDetails(DrivingSession session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSessionDetailsModal(session),
    );
  }

  Widget _buildSessionDetailsModal(DrivingSession session) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Detalles de Sesión',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Fecha de inicio', Formatters.formatDateTime(session.startTime)),
                  if (session.endTime != null)
                    _buildDetailRow('Fecha de fin', Formatters.formatDateTime(session.endTime!)),
                  _buildDetailRow('Estado', _getStatusText(session.status)),
                  _buildDetailRow('Dispositivo', session.deviceId),
                  const Divider(height: 24),
                  _buildDetailRow('Distancia total', '${session.totalDistance} km'),
                  _buildDetailRow('Velocidad promedio', '${session.averageSpeed} km/h'),
                  _buildDetailRow('Velocidad máxima', '${session.maxSpeed} km/h'),
                  _buildDetailRow('Puntuación de riesgo', '${session.riskScore}%'),
                  const Divider(height: 24),
                  const Text(
                    'Estadísticas del día',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow('Tiempo de conducción', '${session.dailyStats.totalDrivingTime ~/ 60} minutos'),
                  _buildDetailRow('Eventos de distracción', '${session.dailyStats.distractionCount}'),
                  _buildDetailRow('Eventos de imprudencia', '${session.dailyStats.recklessCount}'),
                  _buildDetailRow('Eventos de emergencia', '${session.dailyStats.emergencyCount}'),
                  _buildDetailRow('Total de alertas', '${session.dailyStats.totalAlerts}'),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showSessionEvents(session);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Ver Eventos de la Sesión'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSessionEvents(DrivingSession session) {
    final userId = context.read<AuthBloc>().state.user?.id;
    if (userId != null && session.id != null) {
      context.read<SessionBloc>().add(LoadSessionEvents(
        sessionId: session.id!,
        userId: userId,
      ));

      context.push('/history/session-events', extra: session);
    }
  }
}