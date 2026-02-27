import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/use_case.dart';
import '../entities/ministry_entity.dart';
import '../repositories/ministry_repository.dart';

/// Deletes a ministry permanently.
///
/// Business rules enforced here (domain layer):
///   1. The [params.inputCode] must match [params.ministry.inviteCode]
///      (case-insensitive) — confirmation step before a destructive action.
///   2. If the code is wrong, returns a [PermissionFailure] without touching
///      Firestore.
class DeleteMinistryUseCase extends UseCase<Unit, DeleteMinistryParams> {
  final MinistryRepository _repository;
  DeleteMinistryUseCase(this._repository);

  @override
  Future<Either<Failure, Unit>> call(DeleteMinistryParams params) async {
    final codeMatches =
        params.inputCode.trim().toUpperCase() == params.ministry.inviteCode.toUpperCase();

    if (!codeMatches) {
      return const Left(
        PermissionFailure('Código incorreto. A exclusão foi cancelada.'),
      );
    }

    return _repository.deleteMinistry(params.ministry.id);
  }
}

class DeleteMinistryParams extends Equatable {
  /// The ministry to be deleted (already loaded in the UI).
  final MinistryEntity ministry;

  /// The invite code typed by the admin as confirmation.
  final String inputCode;

  const DeleteMinistryParams({
    required this.ministry,
    required this.inputCode,
  });

  @override
  List<Object?> get props => [ministry, inputCode];
}

