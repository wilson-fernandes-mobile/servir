import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/use_case.dart';
import '../entities/church_entity.dart';
import '../repositories/church_repository.dart';

class JoinChurchUseCase extends UseCase<ChurchEntity, JoinChurchParams> {
  final ChurchRepository _repository;
  JoinChurchUseCase(this._repository);

  @override
  Future<Either<Failure, ChurchEntity>> call(JoinChurchParams params) {
    return _repository.joinChurch(
      userId: params.userId,
      inviteCode: params.inviteCode,
    );
  }
}

class JoinChurchParams extends Equatable {
  final String userId;
  final String inviteCode;

  const JoinChurchParams({
    required this.userId,
    required this.inviteCode,
  });

  @override
  List<Object?> get props => [userId, inviteCode];
}

