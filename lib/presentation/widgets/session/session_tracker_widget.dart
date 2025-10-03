import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../../blocs/session/session_bloc.dart';
import '../../blocs/session/session_event.dart';
import '../../blocs/session/session_state.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../../domain/entities/session_event.dart' as domain;
import '../../../core/utils/app_colors.dart';
import '../../../core/widgets/common_card.dart';

class SessionTrackerWidget extends StatefulWidget {
  final bool isMonitoring;
  final Duration? sessionDuration;
  final VoidCallback? onSessionStateChanged;

  const SessionTrackerWidget({
    super.key,
    required this.isMonitoring,
    this.sessionDuration,
    this.onSessionStateChanged,
  });

  @override
  State<SessionTrackerWidget> createState() => _SessionTrackerWidgetState();
}

class _SessionTrackerWidgetState extends State<SessionTrackerWidget> {
  String? _currentSessionId;

  @override
  void initState() {
    super.initState();
    _loadActiveSession();
  }

  void _loadActiveSession() {
    final userId = context.read<AuthBloc>().state.user?.id;
    if (userId != null) {
      context.read<SessionBloc>().add(LoadActiveSession(userId));
    }
  }

  Future<Position> _getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _startSession() async {
    try {
      final position = await _getCurrentPosition();
      final userId = context.read<AuthBloc>().state.user?.id;

      if (userId != null) {
        context.read<SessionBloc>().add(StartSession(
          userId: userId,
          deviceId: 'ESP32-001', // This should come from device connection
          latitude: position.latitude,
          longitude: position.longitude,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting session: $e')),
      );
    }
  }

  Future<void> _endSession() async {
    if (_currentSessionId == null) return;

    try {
      final position = await _getCurrentPosition();
      final userId = context.read<AuthBloc>().state.user?.id;

      if (userId != null) {
        context.read<SessionBloc>().add(EndSession(
          sessionId: _currentSessionId!,
          userId: userId,
          endLatitude: position.latitude,
          endLongitude: position.longitude,
        ));
        _currentSessionId = null;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error ending session: $e')),
      );
    }
  }

  void _addSessionEvent({
    required String eventType,
    required String severity,
    required String description,
    required Map<String, double> sensorData,
  }) async {
    if (_currentSessionId == null) return;

    try {
      final position = await _getCurrentPosition();
      final userId = context.read<AuthBloc>().state.user?.id;

      if (userId != null) {
        context.read<SessionBloc>().add(AddSessionEvent(
          sessionId: _currentSessionId!,
          userId: userId,
          eventType: eventType,
          severity: severity,
          description: description,
          latitude: position.latitude,
          longitude: position.longitude,
          sensorData: sensorData,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding event: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SessionBloc, SessionState>(
      listener: (context, state) {
        if (state is SessionActive) {
          _currentSessionId = state.session.id;
          widget.onSessionStateChanged?.call();
        } else if (state is SessionEnded) {
          _currentSessionId = null;
          widget.onSessionStateChanged?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session ended successfully')),
          );
        } else if (state is NoActiveSession) {
          _currentSessionId = null;
        } else if (state is SessionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Session error: ${state.message}')),
          );
        }
      },
      child: BlocBuilder<SessionBloc, SessionState>(
        builder: (context, state) {
          return CommonCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Session Control',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Icon(
                      widget.isMonitoring ? Icons.play_circle_filled : Icons.pause_circle_filled,
                      color: widget.isMonitoring ? AppColors.success : AppColors.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (state is SessionLoading)
                  const Center(child: CircularProgressIndicator())
                else if (state is SessionActive)
                  _buildActiveSessionInfo(state.session)
                else
                  _buildInactiveSessionInfo(),
                const SizedBox(height: 16),
                _buildSessionControls(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveSessionInfo(session) {
    final duration = widget.sessionDuration ?? Duration.zero;
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Session Active',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Duration: ${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          'Events: ${session.dailyStats.totalAlerts}',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildInactiveSessionInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'No Active Session',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Start monitoring to begin tracking your driving session',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildSessionControls() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: widget.isMonitoring ? null : _startSession,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: !widget.isMonitoring ? null : _endSession,
            icon: const Icon(Icons.stop),
            label: const Text('End'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  // Method to be called from dashboard when events are detected
  void addDistactionEvent(Map<String, double> sensorData) {
    _addSessionEvent(
      eventType: domain.EventType.distraction.value,
      severity: domain.EventSeverity.medium.value,
      description: 'Conductor mirando el celular',
      sensorData: sensorData,
    );
  }

  void addRecklessEvent(Map<String, double> sensorData) {
    _addSessionEvent(
      eventType: domain.EventType.recklessDriving.value,
      severity: domain.EventSeverity.high.value,
      description: 'Giro brusco detectado',
      sensorData: sensorData,
    );
  }

  void addEmergencyEvent(Map<String, double> sensorData) {
    _addSessionEvent(
      eventType: domain.EventType.emergency.value,
      severity: domain.EventSeverity.high.value,
      description: 'Situación de emergencia detectada',
      sensorData: sensorData,
    );
  }
}