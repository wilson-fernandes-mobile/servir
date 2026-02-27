import '../../domain/entities/ministry_entity.dart';

/// Abstract contract for ministry data operations.
/// Swap FirestoreMinistryDataSource for ApiMinistryDataSource to migrate to a REST API.
abstract class MinistryRemoteDataSource {
  Future<List<MinistryEntity>> getMinistriesByChurchId(String churchId);
  Future<MinistryEntity> createMinistry({
    required String name,
    String? description,
    required String churchId,
  });

  /// Adds [userId] to [ministry.memberIds] using the [inviteCode].
  /// Throws [MinistryNotFoundException] if the code is invalid.
  Future<MinistryEntity> joinMinistry({
    required String userId,
    required String inviteCode,
    required String churchId,
  });

  /// Adds [userId] directly to [memberIds] without requiring an invite code.
  /// Used by admins and leaders to join a ministry as a member.
  Future<void> addMemberToMinistry(String ministryId, String userId);

  Future<void> addLeaderToMinistry(String ministryId, String userId);
  Future<void> removeLeaderFromMinistry(String ministryId, String userId);

  /// Removes the user from ALL ministries in the church (used when demoting from leader).
  Future<void> removeLeaderFromAllMinistries(String churchId, String userId);

  /// Permanently deletes the ministry document.
  /// Members are stored inside the ministry document, so deletion automatically
  /// unlinks all members and leaders.
  Future<void> deleteMinistry(String ministryId);

  /// Replaces the ministry's roles list with [roles].
  Future<void> updateMinistryRoles(String ministryId, List<String> roles);

  /// Fetches a single ministry by its document ID. Returns null if not found.
  Future<MinistryEntity?> getMinistryById(String ministryId);

  /// Real-time stream of a single ministry document. Emits every time Firestore changes.
  Stream<MinistryEntity?> watchMinistryById(String ministryId);
}

