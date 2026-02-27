import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/use_case.dart';
import '../repositories/ministry_repository.dart';

class AddMemberToMinistryUseCase
    extends UseCase<Unit, AddMemberToMinistryParams> {
  final MinistryRepository _repository;
  AddMemberToMinistryUseCase(this._repository);

  @override
  Future<Either<Failure, Unit>> call(AddMemberToMinistryParams params) {
    return _repository.addMemberToMinistry(params.ministryId, params.userId);
  }
}

class AddMemberToMinistryParams extends Equatable {
  final String ministryId;
  final String userId;

  const AddMemberToMinistryParams({
    required this.ministryId,
    required this.userId,
  });

  @override
  List<Object> get props => [ministryId, userId];
}

