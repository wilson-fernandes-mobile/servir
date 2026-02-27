import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/use_case.dart';
import '../entities/schedule_entity.dart';
import '../repositories/schedule_repository.dart';

class GetUpcomingSchedulesUseCase
    extends UseCase<List<ScheduleEntity>, String> {
  final ScheduleRepository _repository;
  GetUpcomingSchedulesUseCase(this._repository);

  @override
  Future<Either<Failure, List<ScheduleEntity>>> call(String ministryId) {
    return _repository.getUpcomingSchedules(ministryId);
  }
}

