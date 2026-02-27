import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/use_case.dart';
import '../entities/church_entity.dart';
import '../repositories/church_repository.dart';

class GetChurchUseCase extends UseCase<ChurchEntity, String> {
  final ChurchRepository _repository;
  GetChurchUseCase(this._repository);

  @override
  Future<Either<Failure, ChurchEntity>> call(String churchId) {
    return _repository.getChurchById(churchId);
  }
}

