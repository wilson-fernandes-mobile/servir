import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/church_remote_data_source.dart';
import '../../data/datasources/firestore_church_data_source.dart';
import '../../data/repositories/church_repository_impl.dart';
import '../../domain/entities/church_entity.dart';
import '../../domain/repositories/church_repository.dart';
import '../../domain/usecases/create_church_use_case.dart';
import '../../domain/usecases/get_church_members_use_case.dart';
import '../../domain/usecases/get_church_use_case.dart';
import '../../domain/usecases/join_church_use_case.dart';
import '../../domain/usecases/update_member_role_use_case.dart';
import 'church_notifier.dart';

// ── Data layer ────────────────────────────────────────────────────────────────

/// To migrate to a custom API: create ApiChurchDataSource implements ChurchRemoteDataSource
/// and swap the return value here. Nothing else changes.
final churchRemoteDataSourceProvider = Provider<ChurchRemoteDataSource>((ref) {
  return FirestoreChurchDataSource(
    firestore: ref.read(firestoreProvider),
  );
});

final churchRepositoryProvider = Provider<ChurchRepository>((ref) {
  return ChurchRepositoryImpl(ref.read(churchRemoteDataSourceProvider));
});

// ── Domain / Use-cases ────────────────────────────────────────────────────────

final createChurchUseCaseProvider = Provider<CreateChurchUseCase>(
  (ref) => CreateChurchUseCase(ref.read(churchRepositoryProvider)),
);

final joinChurchUseCaseProvider = Provider<JoinChurchUseCase>(
  (ref) => JoinChurchUseCase(ref.read(churchRepositoryProvider)),
);

final getChurchUseCaseProvider = Provider<GetChurchUseCase>(
  (ref) => GetChurchUseCase(ref.read(churchRepositoryProvider)),
);

final getChurchMembersUseCaseProvider = Provider<GetChurchMembersUseCase>(
  (ref) => GetChurchMembersUseCase(ref.read(churchRepositoryProvider)),
);

final updateMemberRoleUseCaseProvider = Provider<UpdateMemberRoleUseCase>(
  (ref) => UpdateMemberRoleUseCase(ref.read(churchRepositoryProvider)),
);

// ── Async data providers ──────────────────────────────────────────────────────

/// Fetches the current user's church. Returns null if user has no churchId.
final currentChurchProvider = FutureProvider<ChurchEntity?>((ref) async {
  final user = ref.watch(authStateChangesProvider).asData?.value;
  if (user == null || user.churchId == null) return null;
  final useCase = ref.read(getChurchUseCaseProvider);
  final result = await useCase(user.churchId!);
  return result.fold((_) => null, (church) => church);
});

/// Fetches all active members of the current user's church.
final churchMembersProvider = FutureProvider<List<UserEntity>>((ref) async {
  final user = ref.watch(authStateChangesProvider).asData?.value;
  if (user == null || user.churchId == null) return [];
  final useCase = ref.read(getChurchMembersUseCaseProvider);
  final result = await useCase(user.churchId!);
  return result.fold((_) => [], (members) => members);
});

// ── Presentation ──────────────────────────────────────────────────────────────

final churchNotifierProvider =
    StateNotifierProvider<ChurchNotifier, ChurchState>((ref) {
  return ChurchNotifier(
    createChurch: ref.read(createChurchUseCaseProvider),
    joinChurch: ref.read(joinChurchUseCaseProvider),
    updateMemberRole: ref.read(updateMemberRoleUseCaseProvider),
  );
});

