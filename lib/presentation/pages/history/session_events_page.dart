import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../blocs/session/session_bloc.dart';
import '../../blocs/session/session_state.dart';
import '../../../domain/entities/driving_session.dart';
import '../../../domain/entities/session_event.dart' as domain;
import '../../../core/utils/app_colors.dart';
import '../../../core/utils/app_spacing.dart';
import '../../../core/utils/app_typography.dart';
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
        title: Text(
          'Eventos de Sesión',
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
      margin: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Sesión del ${Formatters.formatDate(session.startTime)}',
                  style: AppTypography.h4.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
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
                    color: AppColors.primary,
                    width: AppSpacing.borderThin,
                  ),
                ),
                child: Text(
                  'Completada',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildHeaderStat(
                  'Total Eventos',
                  '${session.dailyStats.totalAlerts}',
                  Icons.warning_amber_outlined,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildHeaderStat(
                  'Riesgo',
                  '${session.riskScore.toStringAsFixed(0)}%',
                  Icons.speed_outlined,
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

  Widget _buildEventsList(List<domain.SessionEvent> events) {
    if (events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.event_note_outlined,
                size: 80,
                color: AppColors.textDisabled,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'No hay eventos registrados',
                style: AppTypography.h3.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Esta sesión no registró eventos de conducción',
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

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return _buildEventCard(event, index);
      },
    );
  }

  Widget _buildEventCard(domain.SessionEvent event, int index) {
    return CommonCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: () => _showEventDetails(event),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getEventTypeColor(event.eventType).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                    ),
                    child: Icon(
                      _getEventTypeIcon(event.eventType),
                      color: _getEventTypeColor(event.eventType),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getEventTypeTitle(event.eventType),
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          event.description,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
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
                        color: _getSeverityColor(event.severity),
                        width: AppSpacing.borderThin,
                      ),
                    ),
                    child: Text(
                      _getSeverityText(event.severity),
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _getSeverityColor(event.severity),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(Icons.access_time_outlined, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    Formatters.formatTime(event.timestamp),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${event.location.latitude.toStringAsFixed(4)}, ${event.location.longitude.toStringAsFixed(4)}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
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
        return AppColors.danger;
      case 'EMERGENCY':
        return AppColors.danger;
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
        return AppColors.danger;
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
    return AppColors.danger;
  }

  void _showEventDetails(domain.SessionEvent event) {
    // TODO: Implement detailed event view with sensor data
  }
}