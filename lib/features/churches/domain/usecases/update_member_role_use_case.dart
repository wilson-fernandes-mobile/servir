import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/use_case.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../repositories/church_repository.dart';

class UpdateMemberRoleUseCase extends UseCase<Unit, UpdateMemberRoleParams> {
  final ChurchRepository _repository;
  UpdateMemberRoleUseCase(this._repository);

  @override
  Future<Either<Failure, Unit>> call(UpdateMemberRoleParams params) {
    return _repository.updateMemberRole(params.userId, params.newRole);
  }
}

class UpdateMemberRoleParams extends Equatable {
  final String userId;
  final UserRole newRole;

  const UpdateMemberRoleParams({
    required this.userId,
    required this.newRole,
  });

  @override
  List<Object?> get props => [userId, newRole];
}

