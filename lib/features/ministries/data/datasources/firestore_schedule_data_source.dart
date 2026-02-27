import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/schedule_entity.dart';
import '../models/schedule_model.dart';
import 'schedule_remote_data_source.dart';

class FirestoreScheduleDataSource implements ScheduleRemoteDataSource {
  final FirebaseFirestore _firestore;

  FirestoreScheduleDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> _schedulesCol(String ministryId) =>
      _firestore
          .collection('ministries')
          .doc(ministryId)
          .collection('schedules');

  @override
  Future<List<ScheduleEntity>> getUpcomingSchedules(String ministryId) async {
    // Start of today (local time)
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    final snap = await _schedulesCol(ministryId)
        .where('eventDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .orderBy('eventDate')
        .get();

    final schedules = snap.docs
        .map((doc) => ScheduleModel.fromFirestore(doc, ministryId))
        .toList();

    // Enrich old schedules that don't have shiftStartTime/shiftEndTime stored
    // by fetching them from the linked event document.
    final enriched = await Future.wait(schedules.map((schedule) async {
      if (schedule.shiftStartTime != null && schedule.shiftEndTime != null) {
        return schedule; // already has the times
      }
      final eventId = schedule.eventId;
      final shiftId = schedule.shiftId;
      if (eventId == null || shiftId == null) return schedule;

      try {
        final eventDoc =
            await _firestore.collection('events').doc(eventId).get();
        if (!eventDoc.exists) return schedule;

        final data = eventDoc.data()!;
        final rawShifts = data['shifts'] as List? ?? [];
        final shiftMap = rawShifts
            .cast<Map<String, dynamic>>()
            .firstWhere((s) => s['id'] == shiftId, orElse: () => {});

        final startTime = shiftMap['startTime'] as String?;
        final endTime = shiftMap['endTime'] as String?;
        if (startTime == null || endTime == null) return schedule;

        return (schedule as ScheduleModel).copyWith(
          shiftStartTime: startTime,
          shiftEndTime: endTime,
        );
      } catch (_) {
        return schedule;
      }
    }));

    return enriched;
  }

  @override
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
  }) async {
    final now = DateTime.now();
    final model = ScheduleModel(
      id: '',
      ministryId: ministryId,
      eventTitle: eventTitle,
      eventDate: eventDate,
      assignments: assignments,
      notes: notes,
      createdAt: now,
      createdBy: createdBy,
      eventId: eventId,
      shiftId: shiftId,
      shiftName: shiftName,
      shiftStartTime: shiftStartTime,
      shiftEndTime: shiftEndTime,
    );

    final ref = await _schedulesCol(ministryId).add(model.toFirestore());
    final doc = await ref.get();
    return ScheduleModel.fromFirestore(doc, ministryId);
  }

  @override
  Future<void> updateScheduleAssignments(
      String ministryId,
      String scheduleId,
      List<ScheduleAssignment> assignments,
      String? notes) async {
    final data = <String, dynamic>{
      'assignments': assignments
          .map((a) => {'userId': a.userId, 'roles': a.roles})
          .toList(),
    };
    if (notes != null) data['notes'] = notes;
    await _schedulesCol(ministryId).doc(scheduleId).update(data);
  }

  @override
  Future<void> deleteSchedule(String ministryId, String scheduleId) async {
    await _schedulesCol(ministryId).doc(scheduleId).delete();
  }
}

