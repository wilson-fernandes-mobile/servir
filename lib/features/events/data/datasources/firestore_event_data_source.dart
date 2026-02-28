import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/event_entity.dart';
import '../models/event_model.dart';
import 'event_remote_data_source.dart';

class FirestoreEventDataSource implements EventRemoteDataSource {
  final FirebaseFirestore _firestore;
  const FirestoreEventDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('events');

  /// Filtra client-side: mantém apenas eventos cujo [effectiveEndDate] >= hoje.
  List<EventEntity> _filterUpcoming(List<EventModel> list) {
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    return list
        .where((e) => !e.effectiveEndDate.isBefore(startOfToday))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  @override
  Future<List<EventEntity>> getEvents(String churchId) async {
    final snap = await _col
        .where('churchId', isEqualTo: churchId)
        .get();
    return _filterUpcoming(snap.docs.map(EventModel.fromFirestore).toList());
  }

  @override
  Stream<List<EventEntity>> watchEvents(String churchId) {
    return _col
        .where('churchId', isEqualTo: churchId)
        .snapshots()
        .map((snap) =>
            _filterUpcoming(snap.docs.map(EventModel.fromFirestore).toList()));
  }

  @override
  Future<EventEntity> createEvent({
    required String churchId,
    required String name,
    required DateTime date,
    DateTime? endDate,
    required List<ShiftEntity> shifts,
    required String createdBy,
  }) async {
    // Garante IDs nos turnos caso não tenham sido gerados na UI
    final shiftsWithIds = shifts.map((s) {
      if (s.id.isEmpty) {
        return ShiftEntity(
          id: const Uuid().v4(),
          name: s.name,
          startTime: s.startTime,
          endTime: s.endTime,
        );
      }
      return s;
    }).toList();

    final now = DateTime.now();
    final model = EventModel(
      id: '',
      churchId: churchId,
      name: name,
      date: date,
      endDate: endDate,
      shifts: shiftsWithIds,
      createdAt: now,
      createdBy: createdBy,
    );

    final ref = await _col.add(model.toFirestore());
    final doc = await ref.get();
    return EventModel.fromFirestore(doc);
  }

  @override
  Future<void> deleteEvent(String eventId) async {
    await _col.doc(eventId).delete();
  }
}

