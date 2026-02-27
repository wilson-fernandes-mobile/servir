import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/use_case.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class SignUpParams {
  final String name;
  final String email;
  final String? phone;
  final String password;

  const SignUpParams({
    required this.name,
    required this.email,
    this.phone,
    required this.password,
  });
}

class SignUpUseCase implements UseCase<UserEntity, SignUpParams> {
  final AuthRepository _repository;

  const SignUpUseCase(this._repository);

  @override
  Future<Either<Failure, UserEntity>> call(SignUpParams params) {
    return _repository.signUpWithEmail(
      name: params.name,
      email: params.email,
      phone: params.phone,
      password: params.password,
    );
  }
}

