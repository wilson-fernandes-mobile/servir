import '../../domain/entities/schedule_entity.dart';

abstract class ScheduleRemoteDataSource {
  /// Returns schedules for [ministryId] with eventDate >= today (upcoming + today).
  Future<List<ScheduleEntity>> getUpcomingSchedules(String ministryId);

  /// Creates a new schedule document under `ministries/{ministryId}/schedules`.
  Future<ScheduleEntity> createSchedule({
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

  /// Updates only the assignments (and optionally notes) of an existing schedule.
  Future<void> updateScheduleAssignments(
      String ministryId, String scheduleId, List<ScheduleAssignment> assignments, String? notes);

  /// Permanently deletes a schedule document.
  Future<void> deleteSchedule(String ministryId, String scheduleId);
}

