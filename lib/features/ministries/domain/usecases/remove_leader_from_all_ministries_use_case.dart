import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/use_case.dart';
import '../repositories/ministry_repository.dart';

class RemoveLeaderFromAllMinistriesUseCase
    extends UseCase<Unit, RemoveLeaderFromAllMinistriesParams> {
  final MinistryRepository _repository;
  RemoveLeaderFromAllMinistriesUseCase(this._repository);

  @override
  Future<Either<Failure, Unit>> call(
      RemoveLeaderFromAllMinistriesParams params) {
    return _repository.removeLeaderFromAllMinistries(
        params.churchId, params.userId);
  }
}

class RemoveLeaderFromAllMinistriesParams extends Equatable {
  final String churchId;
  final String userId;

  const RemoveLeaderFromAllMinistriesParams({
    required this.churchId,
    required this.userId,
  });

  @override
  List<Object> get props => [churchId, userId];
}

