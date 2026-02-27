import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/use_case.dart';
import '../entities/ministry_entity.dart';
import '../repositories/ministry_repository.dart';

class GetMinistriesUseCase extends UseCase<List<MinistryEntity>, String> {
  final MinistryRepository _repository;
  GetMinistriesUseCase(this._repository);

  @override
  Future<Either<Failure, List<MinistryEntity>>> call(String churchId) {
    return _repository.getMinistriesByChurchId(churchId);
  }
}

