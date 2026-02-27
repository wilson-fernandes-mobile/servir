import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/event_entity.dart';

abstract class EventRepository {
  /// Lista todos os eventos da igreja.
  Future<Either<Failure, List<EventEntity>>> getEvents(String churchId);

  /// Cria um novo evento com turnos.
  Future<Either<Failure, EventEntity>> createEvent({
    required String churchId,
    required String name,
    required DateTime date,
    required List<ShiftEntity> shifts,
    required String createdBy,
  });

  /// Exclui um evento (e seus turnos, pois ficam embutidos no documento).
  Future<Either<Failure, Unit>> deleteEvent(String eventId);

  /// Stream em tempo real dos eventos da igreja.
  Stream<List<EventEntity>> watchEvents(String churchId);
}

