import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/use_case.dart';
import '../entities/ministry_entity.dart';
import '../repositories/ministry_repository.dart';

class CreateMinistryUseCase
    extends UseCase<MinistryEntity, CreateMinistryParams> {
  final MinistryRepository _repository;
  CreateMinistryUseCase(this._repository);

  @override
  Future<Either<Failure, MinistryEntity>> call(CreateMinistryParams params) {
    return _repository.createMinistry(
      name: params.name,
      description: params.description,
      churchId: params.churchId,
    );
  }
}

class CreateMinistryParams extends Equatable {
  final String name;
  final String? description;
  final String churchId;

  const CreateMinistryParams({
    required this.name,
    this.description,
    required this.churchId,
  });

  @override
  List<Object?> get props => [name, description, churchId];
}

