import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/firestore_schedule_data_source.dart';
import '../../data/datasources/schedule_remote_data_source.dart';
import '../../data/repositories/schedule_repository_impl.dart';
import '../../domain/entities/schedule_entity.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../../domain/usecases/create_schedule_use_case.dart';
import '../../domain/usecases/delete_schedule_use_case.dart';
import '../../domain/usecases/get_upcoming_schedules_use_case.dart';
import '../../domain/usecases/update_schedule_assignments_use_case.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'ministry_provider.dart';

// ── Data layer ────────────────────────────────────────────────────────────────

final scheduleRemoteDataSourceProvider =
    Provider<ScheduleRemoteDataSource>((ref) {
  return FirestoreScheduleDataSource(firestore: ref.read(firestoreProvider));
});

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepositoryImpl(ref.read(scheduleRemoteDataSourceProvider));
});

// ── Use-cases ─────────────────────────────────────────────────────────────────

final getUpcomingSchedulesUseCaseProvider =
    Provider<GetUpcomingSchedulesUseCase>(
  (ref) => GetUpcomingSchedulesUseCase(ref.read(scheduleRepositoryProvider)),
);

final createScheduleUseCaseProvider = Provider<CreateScheduleUseCase>(
  (ref) => CreateScheduleUseCase(ref.read(scheduleRepositoryProvider)),
);

final deleteScheduleUseCaseProvider = Provider<DeleteScheduleUseCase>(
  (ref) => DeleteScheduleUseCase(ref.read(scheduleRepositoryProvider)),
);

final updateScheduleAssignmentsUseCaseProvider =
    Provider<UpdateScheduleAssignmentsUseCase>(
  (ref) =>
      UpdateScheduleAssignmentsUseCase(ref.read(scheduleRepositoryProvider)),
);

// ── Async data ────────────────────────────────────────────────────────────────

/// Fetches upcoming schedules for a given ministry id.
final upcomingSchedulesProvider =
    FutureProvider.family<List<ScheduleEntity>, String>((ref, ministryId) async {
  final useCase = ref.read(getUpcomingSchedulesUseCaseProvider);
  final result = await useCase(ministryId);
  return result.fold((_) => [], (list) => list);
});

/// Fetches all upcoming schedules where the current user is assigned,
/// across ALL church ministries (not just the ones where the user is a listed member/leader).
final myUpcomingSchedulesProvider =
    FutureProvider<List<ScheduleEntity>>((ref) async {
  final user = ref.watch(authStateChangesProvider).asData?.value;
  if (user == null) return [];

  final ministries = await ref.watch(churchMinistriesProvider.future);

  // Busca apenas nos ministérios dos quais o usuário faz parte (membro ou líder)
  final myMinistries = ministries
      .where((m) =>
          m.memberIds.contains(user.id) || m.leaderIds.contains(user.id))
      .toList();

  final useCase = ref.read(getUpcomingSchedulesUseCaseProvider);

  final allSchedules = await Future.wait<List<ScheduleEntity>>(
    myMinistries.map((m) async {
      final result = await useCase(m.id);
      return result.fold((_) => <ScheduleEntity>[], (list) => list);
    }),
  );

  final flat = allSchedules.expand<ScheduleEntity>((list) => list).toList();

  // Keep only schedules where this user is assigned
  final now = DateTime.now();
  final mine = flat
      .where((s) => s.assignments.any((a) => a.userId == user.id))
      .where((s) {
        final d = s.eventDate;
        final isToday =
            d.year == now.year && d.month == now.month && d.day == now.day;

        // Se for hoje e tiver horário de fim, oculta se já encerrou
        if (isToday && s.shiftEndTime != null && s.shiftEndTime!.isNotEmpty) {
          final parts = s.shiftEndTime!.split(':');
          if (parts.length == 2) {
            final endHour = int.tryParse(parts[0]) ?? 23;
            final endMin = int.tryParse(parts[1]) ?? 59;
            final endDt =
                DateTime(d.year, d.month, d.day, endHour, endMin);
            return now.isBefore(endDt);
          }
        }
        return true;
      })
      .toList()
    ..sort((a, b) {
      // Primeiro ordena por data
      final dateCompare = a.eventDate.compareTo(b.eventDate);
      if (dateCompare != 0) return dateCompare;

      // Se a data for igual, ordena por horário de início
      if (a.shiftStartTime != null && b.shiftStartTime != null) {
        return a.shiftStartTime!.compareTo(b.shiftStartTime!);
      }

      // Se um tiver horário e outro não, prioriza o que tem horário
      if (a.shiftStartTime != null) return -1;
      if (b.shiftStartTime != null) return 1;

      // Se nenhum tiver horário, mantém ordem original
      return 0;
    });

  return mine;
});

/// Retorna todas as escalas da igreja para uma data específica.
/// Usado para detectar conflitos de horário ao criar uma nova escala.
final schedulesOnDateProvider =
    FutureProvider.family<List<ScheduleEntity>, DateTime>((ref, date) async {
  final user = ref.watch(authStateChangesProvider).asData?.value;
  if (user == null || user.churchId == null) return [];

  final ministries = await ref.watch(churchMinistriesProvider.future);
  final useCase = ref.read(getUpcomingSchedulesUseCaseProvider);

  final all = await Future.wait<List<ScheduleEntity>>(
    ministries.map((m) async {
      final result = await useCase(m.id);
      return result.fold((_) => <ScheduleEntity>[], (list) => list);
    }),
  );

  return all
      .expand<ScheduleEntity>((list) => list)
      .where((s) =>
          s.eventDate.year == date.year &&
          s.eventDate.month == date.month &&
          s.eventDate.day == date.day)
      .toList();
});
