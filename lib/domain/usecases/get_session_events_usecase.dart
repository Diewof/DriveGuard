import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../entities/session_event.dart';
import '../repositories/session_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';

class GetSessionEventsUseCase implements UseCase<List<SessionEvent>, GetSessionEventsParams> {
  final SessionRepository repository;

  GetSessionEventsUseCase(this.repository);

  @override
  Future<Either<Failure, List<SessionEvent>>> call(GetSessionEventsParams params) async {
    return await repository.getSessionEvents(
      sessionId: params.sessionId,
      userId: params.userId,
    );
  }
}

class GetSessionEventsParams extends Equatable {
  final String sessionId;
  final String userId;

  const GetSessionEventsParams({
    required this.sessionId,
    required this.userId,
  });

  @override
  List<Object> get props => [sessionId, userId];
}