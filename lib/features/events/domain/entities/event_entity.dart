import 'package:equatable/equatable.dart';

/// Um turno (período) dentro de um evento.
/// Ex: "Manhã" das 08:00 às 12:00, "Noite" das 19:00 às 22:00.
class ShiftEntity extends Equatable {
  final String id;
  final String name;       // "Manhã", "Tarde", "Noite", etc.
  final String startTime;  // "08:00"
  final String endTime;    // "12:00"

  const ShiftEntity({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
  });

  ShiftEntity copyWith({
    String? id,
    String? name,
    String? startTime,
    String? endTime,
  }) {
    return ShiftEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  @override
  List<Object?> get props => [id, name, startTime, endTime];
}

/// Um evento da igreja com múltiplos turnos.
class EventEntity extends Equatable {
  final String id;
  final String churchId;
  final String name;
  final DateTime date;
  final List<ShiftEntity> shifts;
  final DateTime createdAt;
  final String createdBy;

  const EventEntity({
    required this.id,
    required this.churchId,
    required this.name,
    required this.date,
    this.shifts = const [],
    required this.createdAt,
    required this.createdBy,
  });

  EventEntity copyWith({
    String? id,
    String? churchId,
    String? name,
    DateTime? date,
    List<ShiftEntity>? shifts,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return EventEntity(
      id: id ?? this.id,
      churchId: churchId ?? this.churchId,
      name: name ?? this.name,
      date: date ?? this.date,
      shifts: shifts ?? this.shifts,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  List<Object?> get props =>
      [id, churchId, name, date, shifts, createdAt, createdBy];
}

