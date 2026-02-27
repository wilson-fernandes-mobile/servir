import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/use_case.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../repositories/church_repository.dart';

class GetChurchMembersUseCase extends UseCase<List<UserEntity>, String> {
  final ChurchRepository _repository;
  GetChurchMembersUseCase(this._repository);

  @override
  Future<Either<Failure, List<UserEntity>>> call(String churchId) {
    return _repository.getChurchMembers(churchId);
  }
}

