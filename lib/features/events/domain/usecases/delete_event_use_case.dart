import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/use_case.dart';
import '../repositories/event_repository.dart';

class DeleteEventUseCase extends UseCase<Unit, DeleteEventParams> {
  final EventRepository _repository;
  DeleteEventUseCase(this._repository);

  @override
  Future<Either<Failure, Unit>> call(DeleteEventParams params) {
    return _repository.deleteEvent(params.eventId);
  }
}

class DeleteEventParams extends Equatable {
  final String eventId;
  const DeleteEventParams({required this.eventId});

  @override
  List<Object?> get props => [eventId];
}

