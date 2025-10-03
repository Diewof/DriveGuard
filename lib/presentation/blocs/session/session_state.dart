import 'package:equatable/equatable.dart';

import '../../../domain/entities/driving_session.dart';
import '../../../domain/entities/session_event.dart' as domain;

abstract class SessionState extends Equatable {
  const SessionState();

  @override
  List<Object?> get props => [];
}

class SessionInitial extends SessionState {}

class SessionLoading extends SessionState {}

class SessionActive extends SessionState {
  final DrivingSession session;

  const SessionActive(this.session);

  @override
  List<Object> get props => [session];
}

class SessionEnded extends SessionState {
  final DrivingSession session;

  const SessionEnded(this.session);

  @override
  List<Object> get props => [session];
}

class SessionsLoaded extends SessionState {
  final List<DrivingSession> sessions;

  const SessionsLoaded(this.sessions);

  @override
  List<Object> get props => [sessions];
}

class SessionEventsLoaded extends SessionState {
  final List<domain.SessionEvent> events;

  const SessionEventsLoaded(this.events);

  @override
  List<Object> get props => [events];
}

class SessionEventAdded extends SessionState {
  final String message;

  const SessionEventAdded(this.message);

  @override
  List<Object> get props => [message];
}

class SessionStatsUpdated extends SessionState {
  final DrivingSession session;

  const SessionStatsUpdated(this.session);

  @override
  List<Object> get props => [session];
}

class SessionError extends SessionState {
  final String message;

  const SessionError(this.message);

  @override
  List<Object> get props => [message];
}

class NoActiveSession extends SessionState {}

class SessionCombinedState extends SessionState {
  final DrivingSession? activeSession;
  final List<DrivingSession> allSessions;
  final List<domain.SessionEvent> currentSessionEvents;
  final bool isLoading;
  final String? error;

  const SessionCombinedState({
    this.activeSession,
    this.allSessions = const [],
    this.currentSessionEvents = const [],
    this.isLoading = false,
    this.error,
  });

  SessionCombinedState copyWith({
    DrivingSession? activeSession,
    List<DrivingSession>? allSessions,
    List<domain.SessionEvent>? currentSessionEvents,
    bool? isLoading,
    String? error,
  }) {
    return SessionCombinedState(
      activeSession: activeSession ?? this.activeSession,
      allSessions: allSessions ?? this.allSessions,
      currentSessionEvents: currentSessionEvents ?? this.currentSessionEvents,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        activeSession,
        allSessions,
        currentSessionEvents,
        isLoading,
        error,
      ];
}