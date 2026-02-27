import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../entities/church_entity.dart';

abstract class ChurchRepository {
  /// Creates a new church and makes [adminId] its administrator.
  /// [cnpj] deve ser fornecido sem máscara (14 chars brutos).
  Future<Either<Failure, ChurchEntity>> createChurch({
    required String adminId,
    required String name,
    String? city,
    String? phone,
    String? cnpj,
  });

  /// Finds a church by [inviteCode] and links [userId] as a member.
  Future<Either<Failure, ChurchEntity>> joinChurch({
    required String userId,
    required String inviteCode,
  });

  /// Fetches a church by its [churchId].
  Future<Either<Failure, ChurchEntity>> getChurchById(String churchId);

  /// Returns all active members of the church identified by [churchId].
  Future<Either<Failure, List<UserEntity>>> getChurchMembers(String churchId);

  /// Updates the role of [userId] to [newRole].
  Future<Either<Failure, Unit>> updateMemberRole(
      String userId, UserRole newRole);
}

