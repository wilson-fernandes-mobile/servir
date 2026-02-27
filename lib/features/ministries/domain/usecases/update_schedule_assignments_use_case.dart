import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/use_case.dart';
import '../entities/schedule_entity.dart';
import '../repositories/schedule_repository.dart';

class UpdateScheduleAssignmentsUseCase
    extends UseCase<Unit, UpdateScheduleAssignmentsParams> {
  final ScheduleRepository _repository;
  UpdateScheduleAssignmentsUseCase(this._repository);

  @override
  Future<Either<Failure, Unit>> call(UpdateScheduleAssignmentsParams params) {
    return _repository.updateScheduleAssignments(
        params.ministryId, params.scheduleId, params.assignments, params.notes);
  }
}

class UpdateScheduleAssignmentsParams extends Equatable {
  final String ministryId;
  final String scheduleId;
  final List<ScheduleAssignment> assignments;
  final String? notes;

  const UpdateScheduleAssignmentsParams({
    required this.ministryId,
    required this.scheduleId,
    required this.assignments,
    this.notes,
  });

  @override
  List<Object?> get props => [ministryId, scheduleId, assignments, notes];
}

