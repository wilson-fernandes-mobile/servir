import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/use_case.dart';
import '../repositories/auth_repository.dart';

class SignOutUseCase implements UseCaseNoParams<Unit> {
  final AuthRepository _repository;

  const SignOutUseCase(this._repository);

  @override
  Future<Either<Failure, Unit>> call() {
    return _repository.signOut();
  }
}

