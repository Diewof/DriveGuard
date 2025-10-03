import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../blocs/session/session_bloc.dart';
import '../../blocs/session/session_state.dart';
import '../../../domain/entities/driving_session.dart';
import '../../../domain/entities/session_event.dart' as domain;
import '../../../core/utils/app_colors.dart';
import '../../../core/widgets/common_card.dart';
import '../../../core/utils/formatters.dart';

class SessionEventsPage extends StatelessWidget {
  final DrivingSession session;

  const SessionEventsPage({
    super.key,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Eventos de Sesión',
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
      body: Column(
        children: [
          _buildSessionHeader(),
          Expanded(
            child: BlocBuilder<SessionBloc, SessionState>(
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
                      ],
                    ),
                  );
                } else if (state is SessionEventsLoaded) {
                  return _buildEventsList(state.events);
                }

                return const Center(
                  child: Text('No hay eventos disponibles'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionHeader() {
    return CommonCard(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sesión del ${Formatters.formatDate(session.startTime)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildHeaderStat(
                  'Total Eventos',
                  '${session.dailyStats.totalAlerts}',
                  Icons.warning,
                ),
              ),
              Expanded(
                child: _buildHeaderStat(
                  'Riesgo',
                  '${session.riskScore.toStringAsFixed(0)}%',
                  Icons.speed,
                  valueColor: _getRiskColor(session.riskScore),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(
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
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEventsList(List<domain.SessionEvent> events) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No hay eventos registrados',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Esta sesión no registró eventos de conducción',
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

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return _buildEventCard(event, index);
      },
    );
  }

  Widget _buildEventCard(domain.SessionEvent event, int index) {
    return CommonCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showEventDetails(event),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _getEventTypeColor(event.eventType).withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getEventTypeIcon(event.eventType),
                      color: _getEventTypeColor(event.eventType),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getEventTypeTitle(event.eventType),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          event.description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getSeverityColor(event.severity).withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getSeverityText(event.severity),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getSeverityColor(event.severity),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    Formatters.formatTime(event.timestamp),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.location_on, size: 16, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    '${event.location.latitude.toStringAsFixed(4)}, ${event.location.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getEventTypeColor(String eventType) {
    switch (eventType) {
      case 'DISTRACTION':
        return AppColors.warning;
      case 'RECKLESS_DRIVING':
        return AppColors.error;
      case 'EMERGENCY':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getEventTypeIcon(String eventType) {
    switch (eventType) {
      case 'DISTRACTION':
        return Icons.visibility_off;
      case 'RECKLESS_DRIVING':
        return Icons.warning;
      case 'EMERGENCY':
        return Icons.emergency;
      default:
        return Icons.info;
    }
  }

  String _getEventTypeTitle(String eventType) {
    switch (eventType) {
      case 'DISTRACTION':
        return 'Distracción';
      case 'RECKLESS_DRIVING':
        return 'Conducción Imprudente';
      case 'EMERGENCY':
        return 'Emergencia';
      default:
        return 'Evento Desconocido';
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'LOW':
        return AppColors.success;
      case 'MEDIUM':
        return AppColors.warning;
      case 'HIGH':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getSeverityText(String severity) {
    switch (severity) {
      case 'LOW':
        return 'Baja';
      case 'MEDIUM':
        return 'Media';
      case 'HIGH':
        return 'Alta';
      default:
        return 'N/A';
    }
  }

  Color _getRiskColor(double riskScore) {
    if (riskScore < 30) return AppColors.success;
    if (riskScore < 60) return AppColors.warning;
    return AppColors.error;
  }

  void _showEventDetails(domain.SessionEvent event) {
    // TODO: Implement detailed event view with sensor data
  }
}