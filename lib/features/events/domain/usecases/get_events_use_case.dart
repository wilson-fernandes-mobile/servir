import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/use_case.dart';
import '../entities/event_entity.dart';
import '../repositories/event_repository.dart';

class GetEventsUseCase extends UseCase<List<EventEntity>, String> {
  final EventRepository _repository;
  GetEventsUseCase(this._repository);

  @override
  Future<Either<Failure, List<EventEntity>>> call(String churchId) {
    return _repository.getEvents(churchId);
  }
}

