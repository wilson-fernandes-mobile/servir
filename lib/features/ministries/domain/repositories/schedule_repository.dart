import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/schedule_entity.dart';

abstract class ScheduleRepository {
  Future<Either<Failure, List<ScheduleEntity>>> getUpcomingSchedules(
      String ministryId);

  Future<Either<Failure, ScheduleEntity>> createSchedule({
    required String ministryId,
    required String eventTitle,
    required DateTime eventDate,
    required List<ScheduleAssignment> assignments,
    String? notes,
    required String createdBy,
    String? eventId,
    String? shiftId,
    String? shiftName,
    String? shiftStartTime,
    String? shiftEndTime,
  });

  Future<Either<Failure, Unit>> updateScheduleAssignments(
      String ministryId, String scheduleId,
      List<ScheduleAssignment> assignments, String? notes);

  Future<Either<Failure, Unit>> deleteSchedule(
      String ministryId, String scheduleId);
}

