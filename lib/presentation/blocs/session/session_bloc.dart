import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecases/start_session_usecase.dart';
import '../../../domain/usecases/end_session_usecase.dart';
import '../../../domain/usecases/add_session_event_usecase.dart';
import '../../../domain/usecases/get_user_sessions_usecase.dart';
import '../../../domain/usecases/get_session_events_usecase.dart';
import '../../../domain/usecases/get_active_session_usecase.dart';
import 'session_event.dart';
import 'session_state.dart';

class SessionBloc extends Bloc<SessionEvent, SessionState> {
  final StartSessionUseCase startSessionUseCase;
  final EndSessionUseCase endSessionUseCase;
  final AddSessionEventUseCase addSessionEventUseCase;
  final GetUserSessionsUseCase getUserSessionsUseCase;
  final GetSessionEventsUseCase getSessionEventsUseCase;
  final GetActiveSessionUseCase getActiveSessionUseCase;

  SessionBloc({
    required this.startSessionUseCase,
    required this.endSessionUseCase,
    required this.addSessionEventUseCase,
    required this.getUserSessionsUseCase,
    required this.getSessionEventsUseCase,
    required this.getActiveSessionUseCase,
  }) : super(SessionInitial()) {
    on<StartSession>(_onStartSession);
    on<EndSession>(_onEndSession);
    on<AddSessionEvent>(_onAddSessionEvent);
    on<LoadUserSessions>(_onLoadUserSessions);
    on<LoadSessionEvents>(_onLoadSessionEvents);
    on<LoadActiveSession>(_onLoadActiveSession);
  }

  Future<void> _onStartSession(
    StartSession event,
    Emitter<SessionState> emit,
  ) async {
    emit(SessionLoading());

    final result = await startSessionUseCase(StartSessionParams(
      userId: event.userId,
      deviceId: event.deviceId,
      latitude: event.latitude,
      longitude: event.longitude,
    ));

    result.fold(
      (failure) => emit(SessionError(failure.message)),
      (sessionId) {
        add(LoadActiveSession(event.userId));
      },
    );
  }

  Future<void> _onEndSession(
    EndSession event,
    Emitter<SessionState> emit,
  ) async {
    emit(SessionLoading());

    final result = await endSessionUseCase(EndSessionParams(
      sessionId: event.sessionId,
      userId: event.userId,
      endLatitude: event.endLatitude,
      endLongitude: event.endLongitude,
    ));

    result.fold(
      (failure) => emit(SessionError(failure.message)),
      (session) => emit(SessionEnded(session)),
    );
  }

  Future<void> _onAddSessionEvent(
    AddSessionEvent event,
    Emitter<SessionState> emit,
  ) async {
    final result = await addSessionEventUseCase(AddSessionEventParams(
      sessionId: event.sessionId,
      userId: event.userId,
      eventType: event.eventType,
      severity: event.severity,
      description: event.description,
      latitude: event.latitude,
      longitude: event.longitude,
      sensorData: event.sensorData,
    ));

    result.fold(
      (failure) => emit(SessionError(failure.message)),
      (_) => emit(const SessionEventAdded('Event added successfully')),
    );
  }

  Future<void> _onLoadUserSessions(
    LoadUserSessions event,
    Emitter<SessionState> emit,
  ) async {
    emit(SessionLoading());

    final result = await getUserSessionsUseCase(event.userId);

    result.fold(
      (failure) => emit(SessionError(failure.message)),
      (sessions) => emit(SessionsLoaded(sessions)),
    );
  }

  Future<void> _onLoadSessionEvents(
    LoadSessionEvents event,
    Emitter<SessionState> emit,
  ) async {
    emit(SessionLoading());

    final result = await getSessionEventsUseCase(GetSessionEventsParams(
      sessionId: event.sessionId,
      userId: event.userId,
    ));

    result.fold(
      (failure) => emit(SessionError(failure.message)),
      (events) => emit(SessionEventsLoaded(events)),
    );
  }

  Future<void> _onLoadActiveSession(
    LoadActiveSession event,
    Emitter<SessionState> emit,
  ) async {
    emit(SessionLoading());

    final result = await getActiveSessionUseCase(event.userId);

    result.fold(
      (failure) => emit(SessionError(failure.message)),
      (session) {
        if (session != null) {
          emit(SessionActive(session));
        } else {
          emit(NoActiveSession());
        }
      },
    );
  }
}