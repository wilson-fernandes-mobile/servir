import '../../../../features/auth/domain/entities/user_entity.dart';
import '../models/church_model.dart';

/// Abstract contract for the church data source.
/// To migrate away from Firebase, implement this interface with a new class
/// (e.g. ApiChurchDataSource) and swap it in the provider — nothing else changes.
abstract class ChurchRemoteDataSource {
  /// Creates a church and assigns [adminId] as admin.
  /// [cnpj] deve ser fornecido sem máscara (14 chars brutos).
  Future<ChurchModel> createChurch({
    required String adminId,
    required String name,
    String? city,
    String? phone,
    String? cnpj,
  });

  /// Finds a church by [inviteCode] and links [userId] as a member.
  Future<ChurchModel> joinChurch({
    required String userId,
    required String inviteCode,
  });

  /// Fetches a single church document by its [churchId].
  Future<ChurchModel> getChurchById(String churchId);

  /// Returns all active users that belong to [churchId].
  Future<List<UserEntity>> getChurchMembers(String churchId);

  /// Updates the [role] of a user identified by [userId].
  Future<void> updateMemberRole(String userId, UserRole newRole);
}

