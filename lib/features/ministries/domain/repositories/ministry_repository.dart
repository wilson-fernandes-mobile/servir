import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/ministry_entity.dart';

abstract class MinistryRepository {
  Future<Either<Failure, List<MinistryEntity>>> getMinistriesByChurchId(
      String churchId);
  Future<Either<Failure, MinistryEntity>> createMinistry({
    required String name,
    String? description,
    required String churchId,
  });
  Future<Either<Failure, MinistryEntity>> joinMinistry({
    required String userId,
    required String inviteCode,
    required String churchId,
  });
  Future<Either<Failure, Unit>> addMemberToMinistry(
      String ministryId, String userId);
  Future<Either<Failure, Unit>> addLeaderToMinistry(
      String ministryId, String userId);
  Future<Either<Failure, Unit>> removeLeaderFromMinistry(
      String ministryId, String userId);
  Future<Either<Failure, Unit>> removeLeaderFromAllMinistries(
      String churchId, String userId);
  Future<Either<Failure, Unit>> deleteMinistry(String ministryId);
  Future<Either<Failure, Unit>> updateMinistryRoles(
      String ministryId, List<String> roles);
  Future<Either<Failure, MinistryEntity?>> getMinistryById(String ministryId);

  /// Real-time stream of a single ministry. Emits on every Firestore change.
  Stream<MinistryEntity?> watchMinistryById(String ministryId);
}

