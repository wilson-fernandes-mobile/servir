import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/use_case.dart';
import '../entities/ministry_entity.dart';
import '../repositories/ministry_repository.dart';

class JoinMinistryUseCase
    extends UseCase<MinistryEntity, JoinMinistryParams> {
  final MinistryRepository _repository;
  JoinMinistryUseCase(this._repository);

  @override
  Future<Either<Failure, MinistryEntity>> call(JoinMinistryParams params) {
    return _repository.joinMinistry(
      userId: params.userId,
      inviteCode: params.inviteCode,
      churchId: params.churchId,
    );
  }
}

class JoinMinistryParams extends Equatable {
  final String userId;
  final String inviteCode;
  final String churchId;

  const JoinMinistryParams({
    required this.userId,
    required this.inviteCode,
    required this.churchId,
  });

  @override
  List<Object?> get props => [userId, inviteCode, churchId];
}

