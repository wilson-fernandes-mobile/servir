import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/user_avatar.dart';
import '../auth/domain/entities/user_entity.dart';
import '../auth/presentation/providers/auth_provider.dart';
import '../churches/presentation/providers/church_notifier.dart';
import '../churches/presentation/providers/church_provider.dart';
import '../ministries/domain/entities/ministry_entity.dart';
import '../ministries/domain/usecases/add_leader_to_ministry_use_case.dart';
import '../ministries/domain/usecases/remove_leader_from_all_ministries_use_case.dart';
import '../ministries/presentation/providers/ministry_provider.dart';

class MembersPage extends ConsumerWidget {
  const MembersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authStateChangesProvider).asData?.value;
    final isAdmin = currentUser?.role == UserRole.admin;
    final membersAsync = ref.watch(churchMembersProvider);

    return membersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erro ao carregar membros: $e')),
      data: (members) {
        if (members.isEmpty) {
          return const Center(
            child: Text(
              'Nenhum membro encontrado.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: members.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final member = members[index];
            return _MemberTile(
              member: member,
              isAdmin: isAdmin,
              currentUserId: currentUser?.id ?? '',
            );
          },
        );
      },
    );
  }
}

class _MemberTile extends ConsumerWidget {
  final UserEntity member;
  final bool isAdmin;
  final String currentUserId;

  const _MemberTile({
    required this.member,
    required this.isAdmin,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCurrentUser = member.id == currentUserId;

    return Card(
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Image.asset(
              'assets/icon/ic_pattern_transparent_background.png',
              fit: BoxFit.fitHeight,
            ),
          ),
          ListTile(
            leading: UserAvatar(
              photoUrl: member.photoUrl,
              userName: member.name,
              radius: 20,
            ),
            title: Text(
              '${member.name}${isCurrentUser ? ' (você)' : ''}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              member.email,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            trailing: _RoleBadge(
              role: member.role,
              canChange: isAdmin && !isCurrentUser,
              onTap: isAdmin && !isCurrentUser
                  ? () => _showRoleDialog(context, ref, member)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  void _showRoleDialog(BuildContext context, WidgetRef ref, UserEntity member) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cargo de ${member.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: UserRole.values.map((role) {
            return RadioListTile<UserRole>(
              title: Text(_roleLabel(role)),
              value: role,
              groupValue: member.role,
              onChanged: (newRole) async {
                Navigator.of(ctx).pop();
                if (newRole == null || newRole == member.role) return;

                // When promoting to leader → show ministry selection first
                if (newRole == UserRole.leader) {
                  if (context.mounted) {
                    _showMinistryDialog(context, ref, member);
                  }
                  return;
                }

                // For admin / member: update role directly
                // If was a leader before → remove from all ministries
                if (member.role == UserRole.leader) {
                  final user = ref.read(authStateChangesProvider).asData?.value;
                  if (user?.churchId != null) {
                    await ref
                        .read(removeLeaderFromAllMinistriesUseCaseProvider)
                        .call(RemoveLeaderFromAllMinistriesParams(
                          churchId: user!.churchId!,
                          userId: member.id,
                        ));
                  }
                }

                final ok = await ref
                    .read(churchNotifierProvider.notifier)
                    .updateMemberRole(member.id, newRole);
                if (ok) {
                  ref.invalidate(churchMembersProvider);
                  ref.invalidate(churchMinistriesProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Cargo de ${member.name} atualizado para ${_roleLabel(newRole)}')),
                    );
                  }
                } else {
                  final error =
                      ref.read(churchNotifierProvider).errorMessage ?? 'Erro';
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(error)));
                  }
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _showMinistryDialog(
      BuildContext context, WidgetRef ref, UserEntity member) {
    final ministriesAsync = ref.read(churchMinistriesProvider);
    final ministries = ministriesAsync.asData?.value ?? [];

    if (ministries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Nenhum ministério cadastrado. Crie um na aba Ministérios primeiro.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => _MinistrySelectionDialog(
        member: member,
        ministries: ministries,
        onConfirm: (selectedIds) async {
          Navigator.of(ctx).pop();
          if (selectedIds.isEmpty) return;

          // 1. Update role to leader
          final ok = await ref
              .read(churchNotifierProvider.notifier)
              .updateMemberRole(member.id, UserRole.leader);
          if (!ok) {
            final error =
                ref.read(churchNotifierProvider).errorMessage ?? 'Erro';
            if (context.mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(error)));
            }
            return;
          }

          // 2. Add user as leader to all selected ministries
          final addUseCase =
              ref.read(addLeaderToMinistryUseCaseProvider);
          for (final ministryId in selectedIds) {
            await addUseCase(AddLeaderToMinistryParams(
              ministryId: ministryId,
              userId: member.id,
            ));
          }

          ref.invalidate(churchMembersProvider);
          ref.invalidate(churchMinistriesProvider);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      '${member.name} agora é líder em ${selectedIds.length} ministério(s)')),
            );
          }
        },
      ),
    );
  }

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.leader:
        return 'Líder';
      case UserRole.member:
        return 'Membro';
    }
  }
}

// ── Role badge ────────────────────────────────────────────────────────────────

class _RoleBadge extends StatelessWidget {
  final UserRole role;
  final bool canChange;
  final VoidCallback? onTap;

  const _RoleBadge({
    required this.role,
    required this.canChange,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (role) {
      UserRole.admin => ('Admin', AppColors.primary, AppColors.primaryLight),
      UserRole.leader =>
        ('Líder', AppColors.secondary, AppColors.secondaryLight),
      UserRole.member =>
        ('Membro', AppColors.textSecondary, AppColors.surfaceVariant),
    };

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (canChange) ...[
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, color: color, size: 16),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: badge);
    }
    return badge;
  }
}

// ── Ministry selection dialog ─────────────────────────────────────────────────

class _MinistrySelectionDialog extends StatefulWidget {
  final UserEntity member;
  final List<MinistryEntity> ministries;
  final void Function(List<String> selectedIds) onConfirm;

  const _MinistrySelectionDialog({
    required this.member,
    required this.ministries,
    required this.onConfirm,
  });

  @override
  State<_MinistrySelectionDialog> createState() =>
      _MinistrySelectionDialogState();
}

class _MinistrySelectionDialogState extends State<_MinistrySelectionDialog> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Ministérios de ${widget.member.name}'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecione os ministérios que este líder irá conduzir:',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 8),
            ...widget.ministries.map((ministry) {
              final isSelected = _selected.contains(ministry.id);
              return CheckboxListTile(
                dense: true,
                title: Text(ministry.name),
                subtitle: ministry.description != null
                    ? Text(
                        ministry.description!,
                        style: const TextStyle(fontSize: 11),
                      )
                    : null,
                value: isSelected,
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _selected.add(ministry.id);
                    } else {
                      _selected.remove(ministry.id);
                    }
                  });
                },
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _selected.isEmpty
              ? null
              : () => widget.onConfirm(_selected.toList()),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
