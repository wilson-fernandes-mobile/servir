import 'package:equatable/equatable.dart';

enum UserRole {
  admin,
  leader,
  member;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UserRole.member,
    );
  }
}

class UserEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? churchId;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final String? lastDevice;

  // ignore: prefer_const_constructors_in_immutables
  UserEntity({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.churchId,
    this.role = UserRole.member,
    this.isActive = true,
    required this.createdAt,
    this.lastLoginAt,
    this.lastDevice,
  });

  UserEntity copyWith({
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
  }) {
    return UserEntity(
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
    );
  }

  @override
  List<Object?> get props => [
        id, name, email, phone, churchId,
        role, isActive, createdAt, lastLoginAt, lastDevice,
      ];
}

