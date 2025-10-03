import 'package:dartz/dartz.dart';

import '../entities/driving_session.dart';
import '../repositories/session_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';

class GetUserSessionsUseCase implements UseCase<List<DrivingSession>, String> {
  final SessionRepository repository;

  GetUserSessionsUseCase(this.repository);

  @override
  Future<Either<Failure, List<DrivingSession>>> call(String userId) async {
    return await repository.getUserSessions(userId);
  }
}