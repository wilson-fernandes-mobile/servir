import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/unavailability_entity.dart';

class UnavailabilityModel extends UnavailabilityEntity {
  const UnavailabilityModel({
    required super.id,
    required super.userId,
    required super.churchId,
    required super.startDate,
    super.endDate,
    super.startTime,
    super.endTime,
    super.description,
    required super.createdAt,
  });

  factory UnavailabilityModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UnavailabilityModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      churchId: data['churchId'] as String? ?? '',
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      startTime: data['startTime'] as String?,
      endTime: data['endTime'] as String?,
      description: data['description'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'churchId': churchId,
      'startDate': Timestamp.fromDate(
        DateTime(startDate.year, startDate.month, startDate.day),
      ),
      if (endDate != null)
        'endDate': Timestamp.fromDate(
          DateTime(endDate!.year, endDate!.month, endDate!.day),
        ),
      if (startTime != null) 'startTime': startTime,
      if (endTime != null) 'endTime': endTime,
      if (description != null && description!.isNotEmpty)
        'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory UnavailabilityModel.fromEntity(UnavailabilityEntity entity) {
    return UnavailabilityModel(
      id: entity.id,
      userId: entity.userId,
      churchId: entity.churchId,
      startDate: entity.startDate,
      endDate: entity.endDate,
      startTime: entity.startTime,
      endTime: entity.endTime,
      description: entity.description,
      createdAt: entity.createdAt,
    );
  }
}

