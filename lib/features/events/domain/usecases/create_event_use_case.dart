import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/use_case.dart';
import '../entities/event_entity.dart';
import '../repositories/event_repository.dart';

class CreateEventUseCase extends UseCase<EventEntity, CreateEventParams> {
  final EventRepository _repository;
  CreateEventUseCase(this._repository);

  @override
  Future<Either<Failure, EventEntity>> call(CreateEventParams params) {
    return _repository.createEvent(
      churchId: params.churchId,
      name: params.name,
      date: params.date,
      shifts: params.shifts,
      createdBy: params.createdBy,
    );
  }
}

class CreateEventParams extends Equatable {
  final String churchId;
  final String name;
  final DateTime date;
  final List<ShiftEntity> shifts;
  final String createdBy;

  const CreateEventParams({
    required this.churchId,
    required this.name,
    required this.date,
    required this.shifts,
    required this.createdBy,
  });

  @override
  List<Object?> get props => [churchId, name, date, shifts, createdBy];
}

