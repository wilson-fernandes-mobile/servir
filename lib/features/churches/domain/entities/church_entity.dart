import 'package:equatable/equatable.dart';

class ChurchEntity extends Equatable {
  final String id;
  final String name;
  final String? city;
  final String? phone;
  /// CNPJ da organização — aceita formato numérico atual e o novo formato
  /// alfanumérico (Receita Federal, julho/2026).
  /// Armazenado sem máscara (14 chars brutos, ex: `12ABC34500016X`).
  final String? cnpj;
  final String inviteCode;
  final String adminId;
  final bool isActive;
  final DateTime createdAt;

  const ChurchEntity({
    required this.id,
    required this.name,
    this.city,
    this.phone,
    this.cnpj,
    required this.inviteCode,
    required this.adminId,
    this.isActive = true,
    required this.createdAt,
  });

  ChurchEntity copyWith({
    String? id,
    String? name,
    String? city,
    String? phone,
    String? cnpj,
    String? inviteCode,
    String? adminId,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return ChurchEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      city: city ?? this.city,
      phone: phone ?? this.phone,
      cnpj: cnpj ?? this.cnpj,
      inviteCode: inviteCode ?? this.inviteCode,
      adminId: adminId ?? this.adminId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, city, phone, cnpj, inviteCode, adminId, isActive, createdAt];
}

