import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/use_case.dart';
import '../repositories/schedule_repository.dart';

class DeleteScheduleUseCase extends UseCase<Unit, DeleteScheduleParams> {
  final ScheduleRepository _repository;
  DeleteScheduleUseCase(this._repository);

  @override
  Future<Either<Failure, Unit>> call(DeleteScheduleParams params) {
    return _repository.deleteSchedule(params.ministryId, params.scheduleId);
  }
}

class DeleteScheduleParams extends Equatable {
  final String ministryId;
  final String scheduleId;

  const DeleteScheduleParams({
    required this.ministryId,
    required this.scheduleId,
  });

  @override
  List<Object?> get props => [ministryId, scheduleId];
}

