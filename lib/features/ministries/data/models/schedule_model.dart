import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/schedule_entity.dart';

class ScheduleModel extends ScheduleEntity {
  const ScheduleModel({
    required super.id,
    required super.ministryId,
    required super.eventTitle,
    required super.eventDate,
    super.assignments = const [],
    super.notes,
    required super.createdAt,
    required super.createdBy,
    super.eventId,
    super.shiftId,
    super.shiftName,
    super.shiftStartTime,
    super.shiftEndTime,
  });

  factory ScheduleModel.fromFirestore(DocumentSnapshot doc, String ministryId) {
    final data = doc.data() as Map<String, dynamic>;

    final rawAssignments = data['assignments'] as List? ?? [];
    final assignments = rawAssignments.map((raw) {
      final map = raw as Map<String, dynamic>;
      return ScheduleAssignment(
        userId: map['userId'] as String? ?? '',
        roles: List<String>.from(map['roles'] as List? ?? []),
      );
    }).toList();

    return ScheduleModel(
      id: doc.id,
      ministryId: ministryId,
      eventTitle: data['eventTitle'] as String? ?? '',
      eventDate: (data['eventDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      assignments: assignments,
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] as String? ?? '',
      eventId: data['eventId'] as String?,
      shiftId: data['shiftId'] as String?,
      shiftName: data['shiftName'] as String?,
      shiftStartTime: data['shiftStartTime'] as String?,
      shiftEndTime: data['shiftEndTime'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'eventTitle': eventTitle,
      'eventDate': Timestamp.fromDate(eventDate),
      'assignments': assignments
          .map((a) => {'userId': a.userId, 'roles': a.roles})
          .toList(),
      if (notes != null) 'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      if (eventId != null) 'eventId': eventId,
      if (shiftId != null) 'shiftId': shiftId,
      if (shiftName != null) 'shiftName': shiftName,
      if (shiftStartTime != null) 'shiftStartTime': shiftStartTime,
      if (shiftEndTime != null) 'shiftEndTime': shiftEndTime,
    };
  }

  @override
  ScheduleModel copyWith({
    String? id,
    String? ministryId,
    String? eventTitle,
    DateTime? eventDate,
    List<ScheduleAssignment>? assignments,
    String? notes,
    DateTime? createdAt,
    String? createdBy,
    String? eventId,
    String? shiftId,
    String? shiftName,
    String? shiftStartTime,
    String? shiftEndTime,
  }) {
    return ScheduleModel(
      id: id ?? this.id,
      ministryId: ministryId ?? this.ministryId,
      eventTitle: eventTitle ?? this.eventTitle,
      eventDate: eventDate ?? this.eventDate,
      assignments: assignments ?? this.assignments,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      eventId: eventId ?? this.eventId,
      shiftId: shiftId ?? this.shiftId,
      shiftName: shiftName ?? this.shiftName,
      shiftStartTime: shiftStartTime ?? this.shiftStartTime,
      shiftEndTime: shiftEndTime ?? this.shiftEndTime,
    );
  }
}

