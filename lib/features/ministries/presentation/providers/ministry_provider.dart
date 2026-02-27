import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/firestore_ministry_data_source.dart';
import '../../data/datasources/ministry_remote_data_source.dart';
import '../../data/repositories/ministry_repository_impl.dart';
import '../../domain/entities/ministry_entity.dart';
import '../../domain/repositories/ministry_repository.dart';
import '../../domain/usecases/add_leader_to_ministry_use_case.dart';
import '../../domain/usecases/add_member_to_ministry_use_case.dart';
import '../../domain/usecases/create_ministry_use_case.dart';
import '../../domain/usecases/delete_ministry_use_case.dart';
import '../../domain/usecases/get_ministries_use_case.dart';
import '../../domain/usecases/join_ministry_use_case.dart';
import '../../domain/usecases/remove_leader_from_all_ministries_use_case.dart';
import '../../domain/usecases/update_ministry_roles_use_case.dart';

// ── Data layer ────────────────────────────────────────────────────────────────

/// To migrate to a custom API: create ApiMinistryDataSource implements MinistryRemoteDataSource
/// and swap the return value here. Nothing else changes.
final ministryRemoteDataSourceProvider = Provider<MinistryRemoteDataSource>((ref) {
  return FirestoreMinistryDataSource(firestore: ref.read(firestoreProvider));
});

final ministryRepositoryProvider = Provider<MinistryRepository>((ref) {
  return MinistryRepositoryImpl(ref.read(ministryRemoteDataSourceProvider));
});

// ── Use-cases ─────────────────────────────────────────────────────────────────

final getMinistriesUseCaseProvider = Provider<GetMinistriesUseCase>(
  (ref) => GetMinistriesUseCase(ref.read(ministryRepositoryProvider)),
);

final createMinistryUseCaseProvider = Provider<CreateMinistryUseCase>(
  (ref) => CreateMinistryUseCase(ref.read(ministryRepositoryProvider)),
);

final addLeaderToMinistryUseCaseProvider =
    Provider<AddLeaderToMinistryUseCase>(
  (ref) => AddLeaderToMinistryUseCase(ref.read(ministryRepositoryProvider)),
);

final addMemberToMinistryUseCaseProvider =
    Provider<AddMemberToMinistryUseCase>(
  (ref) => AddMemberToMinistryUseCase(ref.read(ministryRepositoryProvider)),
);

final removeLeaderFromAllMinistriesUseCaseProvider =
    Provider<RemoveLeaderFromAllMinistriesUseCase>(
  (ref) => RemoveLeaderFromAllMinistriesUseCase(
      ref.read(ministryRepositoryProvider)),
);

final joinMinistryUseCaseProvider = Provider<JoinMinistryUseCase>(
  (ref) => JoinMinistryUseCase(ref.read(ministryRepositoryProvider)),
);

final deleteMinistryUseCaseProvider = Provider<DeleteMinistryUseCase>(
  (ref) => DeleteMinistryUseCase(ref.read(ministryRepositoryProvider)),
);

final updateMinistryRolesUseCaseProvider =
    Provider<UpdateMinistryRolesUseCase>(
  (ref) => UpdateMinistryRolesUseCase(ref.read(ministryRepositoryProvider)),
);

// ── Async data providers ──────────────────────────────────────────────────────

/// Fetches all active ministries for the current user's church.
final churchMinistriesProvider = FutureProvider<List<MinistryEntity>>((ref) async {
  final user = ref.watch(authStateChangesProvider).asData?.value;
  if (user == null || user.churchId == null) return [];
  final useCase = ref.read(getMinistriesUseCaseProvider);
  final result = await useCase(user.churchId!);
  return result.fold((_) => [], (list) => list);
});

/// Stream em tempo real de um único ministério — atualiza a tela automaticamente
/// sempre que o documento mudar no Firestore, sem precisar invalidar manualmente.
final ministryByIdProvider =
    StreamProvider.family<MinistryEntity?, String>((ref, ministryId) {
  final repo = ref.read(ministryRepositoryProvider);
  return repo.watchMinistryById(ministryId);
});

