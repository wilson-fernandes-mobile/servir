import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/event_entity.dart';

class ShiftModel extends ShiftEntity {
  const ShiftModel({
    required super.id,
    required super.name,
    required super.startTime,
    required super.endTime,
  });

  factory ShiftModel.fromMap(Map<String, dynamic> map) {
    return ShiftModel(
      id: map['id'] as String? ?? const Uuid().v4(),
      name: map['name'] as String? ?? '',
      startTime: map['startTime'] as String? ?? '',
      endTime: map['endTime'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'startTime': startTime,
        'endTime': endTime,
      };
}

class EventModel extends EventEntity {
  const EventModel({
    required super.id,
    required super.churchId,
    required super.name,
    required super.date,
    super.shifts = const [],
    required super.createdAt,
    required super.createdBy,
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawShifts = data['shifts'] as List? ?? [];
    return EventModel(
      id: doc.id,
      churchId: data['churchId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      shifts: rawShifts
          .map((s) => ShiftModel.fromMap(s as Map<String, dynamic>))
          .toList(),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'churchId': churchId,
        'name': name,
        'date': Timestamp.fromDate(date),
        'shifts': shifts
            .map((s) => ShiftModel(
                  id: s.id,
                  name: s.name,
                  startTime: s.startTime,
                  endTime: s.endTime,
                ).toMap())
            .toList(),
        'createdAt': Timestamp.fromDate(createdAt),
        'createdBy': createdBy,
      };
}

