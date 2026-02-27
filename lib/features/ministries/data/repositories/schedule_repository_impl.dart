import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/schedule_entity.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../datasources/schedule_remote_data_source.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  final ScheduleRemoteDataSource _dataSource;
  ScheduleRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, List<ScheduleEntity>>> getUpcomingSchedules(
      String ministryId) async {
    try {
      final schedules = await _dataSource.getUpcomingSchedules(ministryId);
      return Right(schedules);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
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
  }) async {
    try {
      final schedule = await _dataSource.createSchedule(
        ministryId: ministryId,
        eventTitle: eventTitle,
        eventDate: eventDate,
        assignments: assignments,
        notes: notes,
        createdBy: createdBy,
        eventId: eventId,
        shiftId: shiftId,
        shiftName: shiftName,
        shiftStartTime: shiftStartTime,
        shiftEndTime: shiftEndTime,
      );
      return Right(schedule);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateScheduleAssignments(
      String ministryId, String scheduleId,
      List<ScheduleAssignment> assignments, String? notes) async {
    try {
      await _dataSource.updateScheduleAssignments(
          ministryId, scheduleId, assignments, notes);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteSchedule(
      String ministryId, String scheduleId) async {
    try {
      await _dataSource.deleteSchedule(ministryId, scheduleId);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

