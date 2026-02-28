import 'package:equatable/equatable.dart';

/// Maps a single member (by userId) to one or more roles inside a schedule.
/// A member can be "Lead + Teclado" at the same time.
class ScheduleAssignment extends Equatable {
  final String userId;
  final List<String> roles;

  const ScheduleAssignment({required this.userId, required this.roles});

  ScheduleAssignment copyWith({String? userId, String? name,List<String>? roles}) {
    return ScheduleAssignment(
      userId: userId ?? this.userId,
      roles: roles ?? this.roles,
    );
  }

  @override
  List<Object?> get props => [userId, roles];
}

/// A ministry schedule (escala) for a specific event/date.
class ScheduleEntity extends Equatable {
  final String id;
  final String ministryId;

  /// Short label for the event, e.g. "Culto Domingo Manhã".
  final String eventTitle;
  final DateTime eventDate;
  final List<ScheduleAssignment> assignments;
  final String? notes;
  final DateTime createdAt;
  final String createdBy;

  /// ID do evento (coleção `events`) vinculado a esta escala. Opcional.
  final String? eventId;

  /// ID do turno (shift) do evento vinculado. Opcional.
  final String? shiftId;

  /// Nome do turno para exibição rápida sem precisar buscar o evento.
  final String? shiftName;

  /// Hora de início do turno, ex: "08:00".
  final String? shiftStartTime;

  /// Hora de fim do turno, ex: "12:00".
  final String? shiftEndTime;

  const ScheduleEntity({
    required this.id,
    required this.ministryId,
    required this.eventTitle,
    required this.eventDate,
    this.assignments = const [],
    this.notes,
    required this.createdAt,
    required this.createdBy,
    this.eventId,
    this.shiftId,
    this.shiftName,
    this.shiftStartTime,
    this.shiftEndTime,
  });

  ScheduleEntity copyWith({
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
    return ScheduleEntity(
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

  @override
  List<Object?> get props => [
        id, ministryId, eventTitle, eventDate,
        assignments, notes, createdAt, createdBy,
        eventId, shiftId, shiftName, shiftStartTime, shiftEndTime,
      ];

  bool timeHasValue() {
    return shiftStartTime != null && shiftEndTime != null;
  }

  String timeEvent() {
    return '$shiftStartTime – $shiftEndTime';
  }
  
  String? get displayTime => timeHasValue() ? timeEvent() : shiftName;
}

