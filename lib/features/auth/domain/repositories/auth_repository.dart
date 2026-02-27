import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

/// Domain-layer contract — zero Firebase references here.
/// Swap the implementation (data layer) to migrate to a custom API.
abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> signInWithEmail({
    required String email,
    required String password,
  });

  Future<Either<Failure, UserEntity>> signUpWithEmail({
    required String name,
    required String email,
    required String? phone,
    required String password,
  });

  Future<Either<Failure, Unit>> signOut();

  /// Emits the authenticated user, or null when signed-out.
  Stream<UserEntity?> get authStateChanges;
}

