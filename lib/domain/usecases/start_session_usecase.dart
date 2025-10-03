import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../repositories/session_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';

class StartSessionUseCase implements UseCase<String, StartSessionParams> {
  final SessionRepository repository;

  StartSessionUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(StartSessionParams params) async {
    return await repository.startSession(
      userId: params.userId,
      deviceId: params.deviceId,
      latitude: params.latitude,
      longitude: params.longitude,
    );
  }
}

class StartSessionParams extends Equatable {
  final String userId;
  final String deviceId;
  final double latitude;
  final double longitude;

  const StartSessionParams({
    required this.userId,
    required this.deviceId,
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object> get props => [userId, deviceId, latitude, longitude];
}