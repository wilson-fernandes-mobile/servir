import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/use_case.dart';
import '../repositories/ministry_repository.dart';

class AddLeaderToMinistryUseCase extends UseCase<Unit, AddLeaderToMinistryParams> {
  final MinistryRepository _repository;
  AddLeaderToMinistryUseCase(this._repository);

  @override
  Future<Either<Failure, Unit>> call(AddLeaderToMinistryParams params) {
    return _repository.addLeaderToMinistry(params.ministryId, params.userId);
  }
}

class AddLeaderToMinistryParams extends Equatable {
  final String ministryId;
  final String userId;

  const AddLeaderToMinistryParams({
    required this.ministryId,
    required this.userId,
  });

  @override
  List<Object> get props => [ministryId, userId];
}

