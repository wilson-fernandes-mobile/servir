import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/ministry_entity.dart';

/// Data-layer model that knows how to serialize/deserialize from Firestore.
/// To migrate to a REST API, create a MinistryModelApi that reads from JSON instead.
class MinistryModel extends MinistryEntity {
  const MinistryModel({
    required super.id,
    required super.name,
    super.description,
    required super.churchId,
    required super.inviteCode,
    super.leaderIds = const [],
    super.memberIds = const [],
    super.roles = const [],
    super.isActive = true,
    required super.createdAt,
  });

  factory MinistryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MinistryModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String?,
      churchId: data['churchId'] as String? ?? '',
      inviteCode: data['inviteCode'] as String? ?? '',
      leaderIds: List<String>.from(data['leaderIds'] as List? ?? []),
      memberIds: List<String>.from(data['memberIds'] as List? ?? []),
      roles: List<String>.from(data['roles'] as List? ?? []),
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  @override
  MinistryModel copyWith({
    String? id,
    String? name,
    String? description,
    String? churchId,
    String? inviteCode,
    List<String>? leaderIds,
    List<String>? memberIds,
    List<String>? roles,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return MinistryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      churchId: churchId ?? this.churchId,
      inviteCode: inviteCode ?? this.inviteCode,
      leaderIds: leaderIds ?? this.leaderIds,
      memberIds: memberIds ?? this.memberIds,
      roles: roles ?? this.roles,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      if (description != null) 'description': description,
      'churchId': churchId,
      'inviteCode': inviteCode,
      'leaderIds': leaderIds,
      'memberIds': memberIds,
      'roles': roles,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

