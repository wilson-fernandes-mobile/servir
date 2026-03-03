import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/user_entity.dart';

/// Data-layer model that knows how to serialize/deserialize from Firestore.
/// To migrate to a REST API, create a UserModelApi that reads from JSON instead.
class UserModel extends UserEntity {
  UserModel({
    required super.id,
    required super.name,
    required super.email,
    super.phone,
    super.churchId,
    super.role,
    super.isActive,
    required super.createdAt,
    super.lastLoginAt,
    super.lastDevice,
    super.photoUrl,
    super.unavailableDates,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawDates = data['unavailableDates'] as List<dynamic>? ?? [];
    return UserModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String?,
      churchId: data['churchId'] as String?,
      role: UserRole.fromString(data['role'] as String? ?? 'member'),
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
      lastDevice: data['lastDevice'] as String?,
      photoUrl: data['photoUrl'] as String?,
      unavailableDates: rawDates
          .whereType<Timestamp>()
          .map((ts) => ts.toDate())
          .toList(),
    );
  }

  @override
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? churchId,
    UserRole? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    String? lastDevice,
    String? photoUrl,
    List<DateTime>? unavailableDates,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      churchId: churchId ?? this.churchId,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      lastDevice: lastDevice ?? this.lastDevice,
      photoUrl: photoUrl ?? this.photoUrl,
      unavailableDates: unavailableDates ?? this.unavailableDates,
    );
  }

  /// Converts to a Firestore-compatible map.
  /// When migrating to REST, swap this for a `toJson()` method.
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'churchId': churchId,
      'role': role.name,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      if (lastLoginAt != null) 'lastLoginAt': Timestamp.fromDate(lastLoginAt!),
      if (lastDevice != null) 'lastDevice': lastDevice,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'unavailableDates': unavailableDates
          .map((d) => Timestamp.fromDate(DateTime(d.year, d.month, d.day)))
          .toList(),
    };
  }
}

