import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/use_case.dart';
import '../repositories/ministry_repository.dart';

/// Replaces the ministry's custom roles list.
/// Visible to admins and leaders inside the MinistryDetailPage.
class UpdateMinistryRolesUseCase
    extends UseCase<Unit, UpdateMinistryRolesParams> {
  final MinistryRepository _repository;
  UpdateMinistryRolesUseCase(this._repository);

  @override
  Future<Either<Failure, Unit>> call(UpdateMinistryRolesParams params) {
    return _repository.updateMinistryRoles(params.ministryId, params.roles);
  }
}

class UpdateMinistryRolesParams extends Equatable {
  final String ministryId;
  final List<String> roles;

  const UpdateMinistryRolesParams({
    required this.ministryId,
    required this.roles,
  });

  @override
  List<Object?> get props => [ministryId, roles];
}

