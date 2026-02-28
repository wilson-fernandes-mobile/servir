import '../../domain/entities/event_entity.dart';

abstract class EventRemoteDataSource {
  Future<List<EventEntity>> getEvents(String churchId);
  Future<EventEntity> createEvent({
    required String churchId,
    required String name,
    required DateTime date,
    DateTime? endDate,
    required List<ShiftEntity> shifts,
    required String createdBy,
  });
  Future<void> deleteEvent(String eventId);
  Stream<List<EventEntity>> watchEvents(String churchId);
}

