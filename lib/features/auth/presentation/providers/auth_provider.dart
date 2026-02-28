import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/datasources/firebase_auth_data_source.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/sign_in_use_case.dart';
import '../../domain/usecases/sign_out_use_case.dart';
import '../../domain/usecases/sign_up_use_case.dart';
import 'auth_notifier.dart';

// ── Infrastructure ────────────────────────────────────────────────────────────

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (_) => FirebaseAuth.instance,
);

final firestoreProvider = Provider<FirebaseFirestore>(
  (_) => FirebaseFirestore.instance,
);

// ── Data layer ────────────────────────────────────────────────────────────────

/// To migrate to a custom API: create ApiAuthDataSource implements AuthRemoteDataSource
/// and swap the return value here. Nothing else changes.
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return FirebaseAuthDataSource(
    firebaseAuth: ref.read(firebaseAuthProvider),
    firestore: ref.read(firestoreProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.read(authRemoteDataSourceProvider));
});

// ── Domain / Use-cases ────────────────────────────────────────────────────────

final signInUseCaseProvider = Provider<SignInUseCase>(
  (ref) => SignInUseCase(ref.read(authRepositoryProvider)),
);

final signUpUseCaseProvider = Provider<SignUpUseCase>(
  (ref) => SignUpUseCase(ref.read(authRepositoryProvider)),
);

final signOutUseCaseProvider = Provider<SignOutUseCase>(
  (ref) => SignOutUseCase(ref.read(authRepositoryProvider)),
);

// ── Presentation ──────────────────────────────────────────────────────────────

/// Auth state stream — used by the router to decide where to redirect.
final authStateChangesProvider = StreamProvider<UserEntity?>((ref) {
  return ref.read(authRepositoryProvider).authStateChanges;
});

/// Auth notifier — call signIn / signUp / signOut from UI widgets.
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    signIn: ref.read(signInUseCaseProvider),
    signUp: ref.read(signUpUseCaseProvider),
    signOut: ref.read(signOutUseCaseProvider),
  );
});

/// Busca um único usuário pelo [userId] direto no Firestore.
/// Cacheado pelo Riverpod — re-usado em qualquer lugar que precise de dados
/// do usuário (nome, foto, etc.) sem depender de listas passadas por parâmetro.
final userByIdProvider =
    FutureProvider.family<UserEntity?, String>((ref, userId) async {
  if (userId.isEmpty) return null;
  final firestore = ref.read(firestoreProvider);
  final doc = await firestore.collection('users').doc(userId).get();
  if (!doc.exists) return null;
  return UserModel.fromFirestore(doc);
});

