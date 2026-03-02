import 'package:equatable/equatable.dart';

/// Representa uma indisponibilidade de um membro da igreja.
/// Pode ser uma data única ou um período com horários.
class UnavailabilityEntity extends Equatable {
  final String id;
  final String userId;
  final String churchId;
  
  /// Data de início da indisponibilidade
  final DateTime startDate;
  
  /// Data de término (null se for apenas um dia)
  final DateTime? endDate;
  
  /// Hora de início (formato "HH:mm", null se for dia inteiro)
  final String? startTime;
  
  /// Hora de término (formato "HH:mm", null se for dia inteiro)
  final String? endTime;
  
  /// Descrição/motivo (opcional, visível apenas para admins/líderes)
  final String? description;
  
  final DateTime createdAt;

  const UnavailabilityEntity({
    required this.id,
    required this.userId,
    required this.churchId,
    required this.startDate,
    this.endDate,
    this.startTime,
    this.endTime,
    this.description,
    required this.createdAt,
  });

  /// Verifica se é um período (tem data de término diferente da data de início)
  bool get isPeriod => endDate != null && !_isSameDay(startDate, endDate!);

  /// Verifica se tem horário específico
  bool get hasTime => startTime != null && endTime != null;

  /// Verifica se a [date] está dentro deste período de indisponibilidade
  bool containsDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = endDate != null
        ? DateTime(endDate!.year, endDate!.month, endDate!.day)
        : start;

    return !normalized.isBefore(start) && !normalized.isAfter(end);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  UnavailabilityEntity copyWith({
    String? id,
    String? userId,
    String? churchId,
    DateTime? startDate,
    DateTime? endDate,
    String? startTime,
    String? endTime,
    String? description,
    DateTime? createdAt,
  }) {
    return UnavailabilityEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      churchId: churchId ?? this.churchId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        churchId,
        startDate,
        endDate,
        startTime,
        endTime,
        description,
        createdAt,
      ];
}

