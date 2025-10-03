import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../blocs/session/session_bloc.dart';
import '../../blocs/session/session_event.dart';
import '../../blocs/session/session_state.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../../domain/entities/driving_session.dart';
import '../../../core/utils/app_colors.dart';
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
        title: const Text(
          'Historial de Sesiones',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.primaryDark,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocBuilder<SessionBloc, SessionState>(
        builder: (context, state) {
          if (state is SessionLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is SessionError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${state.message}',
                    style: const TextStyle(color: AppColors.error),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadSessions,
                    child: const Text('Reintentar'),
                  ),
                ],
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No hay sesiones registradas',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Comienza a monitorear tu conducción para ver el historial aquí',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadSessions(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
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
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showSessionDetails(session),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getStatusColor(session.status),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getStatusText(session.status),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(session.status),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    Formatters.formatDateTime(session.startTime),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildSessionStat(
                      'Duración',
                      _formatDuration(duration),
                      Icons.timer,
                    ),
                  ),
                  Expanded(
                    child: _buildSessionStat(
                      'Distancia',
                      '${session.totalDistance.toStringAsFixed(1)} km',
                      Icons.straighten,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildSessionStat(
                      'Vel. Prom.',
                      '${session.averageSpeed.toStringAsFixed(1)} km/h',
                      Icons.speed,
                    ),
                  ),
                  Expanded(
                    child: _buildSessionStat(
                      'Riesgo',
                      '${session.riskScore.toStringAsFixed(0)}%',
                      Icons.warning,
                      valueColor: _getRiskColor(session.riskScore),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAlertsSummary(DailyStats stats) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildAlertCount('Distracción', stats.distractionCount, AppColors.warning),
          _buildAlertCount('Imprudencia', stats.recklessCount, AppColors.error),
          _buildAlertCount('Emergencia', stats.emergencyCount, AppColors.error),
        ],
      ),
    );
  }

  Widget _buildAlertCount(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
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
    return AppColors.error;
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
              label + ':',
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