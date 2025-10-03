import 'package:dartz/dartz.dart';

import '../entities/driving_session.dart';
import '../repositories/session_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';

class GetActiveSessionUseCase implements UseCase<DrivingSession?, String> {
  final SessionRepository repository;

  GetActiveSessionUseCase(this.repository);

  @override
  Future<Either<Failure, DrivingSession?>> call(String userId) async {
    return await repository.getActiveSession(userId);
  }
}