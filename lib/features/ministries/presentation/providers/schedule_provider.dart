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
/// across all ministries they belong to.
final myUpcomingSchedulesProvider =
    FutureProvider<List<ScheduleEntity>>((ref) async {
  final user = ref.watch(authStateChangesProvider).asData?.value;
  if (user == null) return [];

  final ministries = await ref.watch(churchMinistriesProvider.future);

  // Only look at ministries where the user is a member or leader
  final myMinistries = ministries.where((m) =>
      m.memberIds.contains(user.id) || m.leaderIds.contains(user.id)).toList();

  final useCase = ref.read(getUpcomingSchedulesUseCaseProvider);

  final allSchedules = await Future.wait<List<ScheduleEntity>>(
    myMinistries.map((m) async {
      final result = await useCase(m.id);
      return result.fold((_) => <ScheduleEntity>[], (list) => list);
    }),
  );

  final flat = allSchedules.expand<ScheduleEntity>((list) => list).toList();

  // Keep only schedules where this user is assigned
  final mine = flat
      .where((s) => s.assignments.any((a) => a.userId == user.id))
      .toList()
    ..sort((a, b) => a.eventDate.compareTo(b.eventDate));

  return mine;
});

