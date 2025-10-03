import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../repositories/session_repository.dart';
import '../../core/errors/failures.dart';
import '../../core/usecases/usecase.dart';

class AddSessionEventUseCase implements UseCase<void, AddSessionEventParams> {
  final SessionRepository repository;

  AddSessionEventUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(AddSessionEventParams params) async {
    return await repository.addSessionEvent(
      sessionId: params.sessionId,
      userId: params.userId,
      eventType: params.eventType,
      severity: params.severity,
      description: params.description,
      latitude: params.latitude,
      longitude: params.longitude,
      sensorData: params.sensorData,
    );
  }
}

class AddSessionEventParams extends Equatable {
  final String sessionId;
  final String userId;
  final String eventType;
  final String severity;
  final String description;
  final double latitude;
  final double longitude;
  final Map<String, double> sensorData;

  const AddSessionEventParams({
    required this.sessionId,
    required this.userId,
    required this.eventType,
    required this.severity,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.sensorData,
  });

  @override
  List<Object> get props => [
        sessionId,
        userId,
        eventType,
        severity,
        description,
        latitude,
        longitude,
        sensorData,
      ];
}