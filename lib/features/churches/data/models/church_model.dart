import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/church_entity.dart';

class ChurchModel extends ChurchEntity {
  const ChurchModel({
    required super.id,
    required super.name,
    super.city,
    super.phone,
    super.cnpj,
    required super.inviteCode,
    required super.adminId,
    super.isActive,
    required super.createdAt,
  });

  factory ChurchModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChurchModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      city: data['city'] as String?,
      phone: data['phone'] as String?,
      // cnpj armazenado sem máscara; campo inexistente em docs antigos = null
      cnpj: data['cnpj'] as String?,
      inviteCode: data['inviteCode'] as String? ?? '',
      adminId: data['adminId'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'city': city,
      'phone': phone,
      // Persiste null explicitamente para não deixar campo "fantasma"
      'cnpj': cnpj,
      'inviteCode': inviteCode,
      'adminId': adminId,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ChurchModel.fromEntity(ChurchEntity entity) {
    return ChurchModel(
      id: entity.id,
      name: entity.name,
      city: entity.city,
      phone: entity.phone,
      cnpj: entity.cnpj,
      inviteCode: entity.inviteCode,
      adminId: entity.adminId,
      isActive: entity.isActive,
      createdAt: entity.createdAt,
    );
  }
}

