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
  final String? photoUrl;

  /// Datas em que o usuário marcou indisponibilidade (normalizadas à meia-noite).
  final List<DateTime> unavailableDates;

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
    this.photoUrl,
    this.unavailableDates = const [],
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
    String? photoUrl,
    List<DateTime>? unavailableDates,
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
      photoUrl: photoUrl ?? this.photoUrl,
      unavailableDates: unavailableDates ?? this.unavailableDates,
    );
  }

  /// Verifica se este usuário está indisponível na [date] informada.
  bool isUnavailableOn(DateTime date) {
    return unavailableDates.any(
      (d) => d.year == date.year && d.month == date.month && d.day == date.day,
    );
  }

  bool isAdm() {
    return role == UserRole.admin;
  }

  bool isLead() {
    return role == UserRole.leader;
  }

  @override
  List<Object?> get props => [
        id, name, email, phone, churchId,
        role, isActive, createdAt, lastLoginAt, lastDevice, photoUrl, unavailableDates,
      ];
}

