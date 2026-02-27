import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/use_case.dart';
import '../entities/church_entity.dart';
import '../repositories/church_repository.dart';

class CreateChurchUseCase extends UseCase<ChurchEntity, CreateChurchParams> {
  final ChurchRepository _repository;
  CreateChurchUseCase(this._repository);

  @override
  Future<Either<Failure, ChurchEntity>> call(CreateChurchParams params) {
    return _repository.createChurch(
      adminId: params.adminId,
      name: params.name,
      city: params.city,
      phone: params.phone,
      cnpj: params.cnpj,
    );
  }
}

class CreateChurchParams extends Equatable {
  final String adminId;
  final String name;
  final String? city;
  final String? phone;
  /// CNPJ sem máscara (14 chars brutos). Aceita numérico e alfanumérico.
  final String? cnpj;

  const CreateChurchParams({
    required this.adminId,
    required this.name,
    this.city,
    this.phone,
    this.cnpj,
  });

  @override
  List<Object?> get props => [adminId, name, city, phone, cnpj];
}

