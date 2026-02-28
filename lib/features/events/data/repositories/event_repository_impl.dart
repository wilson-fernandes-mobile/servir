import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/repositories/event_repository.dart';
import '../datasources/event_remote_data_source.dart';

class EventRepositoryImpl implements EventRepository {
  final EventRemoteDataSource _dataSource;
  EventRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, List<EventEntity>>> getEvents(String churchId) async {
    try {
      return Right(await _dataSource.getEvents(churchId));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<List<EventEntity>> watchEvents(String churchId) {
    return _dataSource.watchEvents(churchId);
  }

  @override
  Future<Either<Failure, EventEntity>> createEvent({
    required String churchId,
    required String name,
    required DateTime date,
    DateTime? endDate,
    required List<ShiftEntity> shifts,
    required String createdBy,
  }) async {
    try {
      return Right(await _dataSource.createEvent(
        churchId: churchId,
        name: name,
        date: date,
        endDate: endDate,
        shifts: shifts,
        createdBy: createdBy,
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteEvent(String eventId) async {
    try {
      await _dataSource.deleteEvent(eventId);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

