import 'package:equatable/equatable.dart';

class MinistryEntity extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String churchId;
  final String inviteCode;
  final List<String> leaderIds;
  final List<String> memberIds;
  /// Custom roles/functions for this ministry (e.g. ['Guitarrista', 'Lead', 'Teclado']).
  /// Admin or leader can manage this list via the detail page.
  final List<String> roles;
  final bool isActive;
  final DateTime createdAt;

  const MinistryEntity({
    required this.id,
    required this.name,
    this.description,
    required this.churchId,
    required this.inviteCode,
    this.leaderIds = const [],
    this.memberIds = const [],
    this.roles = const [],
    this.isActive = true,
    required this.createdAt,
  });

  MinistryEntity copyWith({
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
    return MinistryEntity(
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

  @override
  List<Object?> get props =>
      [id, name, description, churchId, inviteCode, leaderIds, memberIds, roles, isActive, createdAt];
}

