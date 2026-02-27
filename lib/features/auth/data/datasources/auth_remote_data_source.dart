import '../../domain/entities/user_entity.dart';

/// Abstract contract for the remote auth data source.
/// Current implementation: Firebase.  Future implementation: REST API.
/// To migrate, create a new class that implements this interface.
abstract class AuthRemoteDataSource {
  Future<UserEntity> signInWithEmail({
    required String email,
    required String password,
  });

  Future<UserEntity> signUpWithEmail({
    required String name,
    required String email,
    required String? phone,
    required String password,
  });

  Future<void> signOut();

  Stream<UserEntity?> get authStateChanges;
}

