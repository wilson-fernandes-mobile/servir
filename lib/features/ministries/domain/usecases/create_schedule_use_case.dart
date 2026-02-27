import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/use_case.dart';
import '../entities/schedule_entity.dart';
import '../repositories/schedule_repository.dart';

class CreateScheduleUseCase
    extends UseCase<ScheduleEntity, CreateScheduleParams> {
  final ScheduleRepository _repository;
  CreateScheduleUseCase(this._repository);

  @override
  Future<Either<Failure, ScheduleEntity>> call(CreateScheduleParams params) {
    return _repository.createSchedule(
      ministryId: params.ministryId,
      eventTitle: params.eventTitle,
      eventDate: params.eventDate,
      assignments: params.assignments,
      notes: params.notes,
      createdBy: params.createdBy,
      eventId: params.eventId,
      shiftId: params.shiftId,
      shiftName: params.shiftName,
      shiftStartTime: params.shiftStartTime,
      shiftEndTime: params.shiftEndTime,
    );
  }
}

class CreateScheduleParams extends Equatable {
  final String ministryId;
  final String eventTitle;
  final DateTime eventDate;
  final List<ScheduleAssignment> assignments;
  final String? notes;
  final String createdBy;
  final String? eventId;
  final String? shiftId;
  final String? shiftName;
  final String? shiftStartTime;
  final String? shiftEndTime;

  const CreateScheduleParams({
    required this.ministryId,
    required this.eventTitle,
    required this.eventDate,
    this.assignments = const [],
    this.notes,
    required this.createdBy,
    this.eventId,
    this.shiftId,
    this.shiftName,
    this.shiftStartTime,
    this.shiftEndTime,
  });

  @override
  List<Object?> get props =>
      [ministryId, eventTitle, eventDate, assignments, notes, createdBy,
       eventId, shiftId, shiftName, shiftStartTime, shiftEndTime];
}

