import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/event_remote_data_source.dart';
import '../../data/datasources/firestore_event_data_source.dart';
import '../../data/repositories/event_repository_impl.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/repositories/event_repository.dart';
import '../../domain/usecases/create_event_use_case.dart';
import '../../domain/usecases/delete_event_use_case.dart';
import '../../domain/usecases/get_events_use_case.dart';

// ── Data layer ────────────────────────────────────────────────────────────────

final eventRemoteDataSourceProvider = Provider<EventRemoteDataSource>((ref) {
  return FirestoreEventDataSource(firestore: ref.read(firestoreProvider));
});

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepositoryImpl(ref.read(eventRemoteDataSourceProvider));
});

// ── Use-cases ─────────────────────────────────────────────────────────────────

final getEventsUseCaseProvider = Provider<GetEventsUseCase>(
  (ref) => GetEventsUseCase(ref.read(eventRepositoryProvider)),
);

final createEventUseCaseProvider = Provider<CreateEventUseCase>(
  (ref) => CreateEventUseCase(ref.read(eventRepositoryProvider)),
);

final deleteEventUseCaseProvider = Provider<DeleteEventUseCase>(
  (ref) => DeleteEventUseCase(ref.read(eventRepositoryProvider)),
);

// ── Stream provider ───────────────────────────────────────────────────────────

/// Stream em tempo real dos eventos da igreja atual.
final churchEventsProvider = StreamProvider<List<EventEntity>>((ref) {
  final user = ref.watch(authStateChangesProvider).asData?.value;
  if (user == null || user.churchId == null) return const Stream.empty();
  final repo = ref.read(eventRepositoryProvider);
  return repo.watchEvents(user.churchId!);
});

