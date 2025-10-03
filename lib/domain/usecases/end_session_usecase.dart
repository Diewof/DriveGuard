import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../entities/driving_session.dart';
import '../repositories/session_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';

class EndSessionUseCase implements UseCase<DrivingSession, EndSessionParams> {
  final SessionRepository repository;

  EndSessionUseCase(this.repository);

  @override
  Future<Either<Failure, DrivingSession>> call(EndSessionParams params) async {
    return await repository.endSession(
      sessionId: params.sessionId,
      userId: params.userId,
      endLatitude: params.endLatitude,
      endLongitude: params.endLongitude,
    );
  }
}

class EndSessionParams extends Equatable {
  final String sessionId;
  final String userId;
  final double endLatitude;
  final double endLongitude;

  const EndSessionParams({
    required this.sessionId,
    required this.userId,
    required this.endLatitude,
    required this.endLongitude,
  });

  @override
  List<Object> get props => [sessionId, userId, endLatitude, endLongitude];
}