import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/ministry_entity.dart';
import '../../domain/entities/schedule_entity.dart';
import '../../domain/usecases/update_schedule_assignments_use_case.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/schedule_provider.dart';

class ScheduleDetailPage extends ConsumerStatefulWidget {
  final ScheduleEntity schedule;
  final MinistryEntity? ministry;
  final List<UserEntity> allMembers;
  final bool canManage;

  const ScheduleDetailPage({
    super.key,
    required this.schedule,
    this.ministry,
    this.allMembers = const [],
    this.canManage = false,
  });

  @override
  ConsumerState<ScheduleDetailPage> createState() => _ScheduleDetailPageState();
}

class _ScheduleDetailPageState extends ConsumerState<ScheduleDetailPage> {
  late List<ScheduleAssignment> _assignments;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _assignments = List.from(widget.schedule.assignments);
  }

  bool get _isToday {
    final now = DateTime.now();
    final d = widget.schedule.eventDate;
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  Future<void> _save() async {
    final ministryId = widget.ministry?.id ?? widget.schedule.ministryId;
    setState(() => _saving = true);
    final result = await ref
        .read(updateScheduleAssignmentsUseCaseProvider)
        .call(UpdateScheduleAssignmentsParams(
          ministryId: ministryId,
          scheduleId: widget.schedule.id,
          assignments: _assignments,
          notes: widget.schedule.notes,
        ));
    if (!mounted) return;
    setState(() => _saving = false);
    result.fold(
      (f) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(f.message))),
      (_) {
        ref.invalidate(upcomingSchedulesProvider(ministryId));
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Escala atualizada!')));
      },
    );
  }

  void _showAddMemberDialog() {
    final ministry = widget.ministry;
    final available = widget.allMembers
        .where((m) =>
            (ministry == null) ||
            ministry.memberIds.contains(m.id) ||
            ministry.leaderIds.contains(m.id))
        .where((m) => !_assignments.any((a) => a.userId == m.id))
        .toList();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddMemberSheet(
        available: available,
        roles: ministry?.roles ?? const [],
        onAdd: (assignment) {
          setState(() => _assignments.add(assignment));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final date = widget.schedule.eventDate;
    final dateLabel = _isToday
        ? 'Hoje'
        : DateFormat('EEEE, dd/MM/yyyy', 'pt_BR').format(date);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detalhes da Escala'),
        actions: [
          if (widget.canManage && _saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          if (widget.canManage && !_saving)
            TextButton(
              onPressed: _save,
              child: const Text('Salvar'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InfoCard(
            schedule: widget.schedule,
            dateLabel: dateLabel,
            isToday: _isToday,
          ),
          const SizedBox(height: 20),
          Row(children: [
            const Text('Membros escalados',
                style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const Spacer(),
            if (widget.canManage)
              TextButton.icon(
                onPressed: _showAddMemberDialog,
                icon: const Icon(Icons.person_add_outlined, size: 16),
                label: const Text('Adicionar'),
              ),
          ]),
          const SizedBox(height: 8),
          if (_assignments.isEmpty)
            const Text('Nenhum membro escalado.',
                style: TextStyle(color: AppColors.textSecondary)),
          ..._assignments.map((a) => _AssignmentTile(
                key: ValueKey(a.userId),
                userId: a.userId,
                roles: a.roles,
                canManage: widget.canManage,
                onRemove: () =>
                    setState(() => _assignments.removeWhere(
                        (x) => x.userId == a.userId)),
              )),
        ],
      ),
    );
  }
}

// ── Info Card ────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final ScheduleEntity schedule;
  final String dateLabel;
  final bool isToday;

  const _InfoCard({
    required this.schedule,
    required this.dateLabel,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isToday ? AppColors.warningLight : AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              dateLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isToday ? AppColors.warning : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            schedule.eventTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          if (schedule.displayTime != null) ...[
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.access_time_outlined,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                schedule.displayTime!,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
            ]),
          ],
          if (schedule.notes != null && schedule.notes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.notes_outlined,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(schedule.notes!,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
              ),
            ]),
          ],
        ]),
      ),
    );
  }
}

// ── Assignment Tile ───────────────────────────────────────────────────────────

class _AssignmentTile extends ConsumerWidget {
  final String userId;
  final List<String> roles;
  final bool canManage;
  final VoidCallback onRemove;

  const _AssignmentTile({
    super.key,
    required this.userId,
    required this.roles,
    required this.canManage,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userByIdProvider(userId));
    final name = userAsync.maybeWhen(
      data: (user) => user?.name ?? userId,
      orElse: () => '…',
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(children: [
          userAsync.when(
            loading: () => const CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primaryLight,
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, __) => const UserAvatar(
              userName: '?',
              radius: 18,
            ),
            data: (user) => UserAvatar(
              photoUrl: user?.photoUrl,
              userName: user?.name ?? '?',
              radius: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                if (roles.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 2,
                    children: roles
                        .map((r) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(r,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600)),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          if (canManage)
            IconButton(
              icon: Icon(Icons.remove_circle_outline,
                  color: Colors.red.shade400, size: 20),
              onPressed: onRemove,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ]),
      ),
    );
  }
}

// ── Add Member Sheet ──────────────────────────────────────────────────────────

class _AddMemberSheet extends StatefulWidget {
  final List<UserEntity> available;
  final List<String> roles;
  final void Function(ScheduleAssignment) onAdd;

  const _AddMemberSheet({
    required this.available,
    required this.roles,
    required this.onAdd,
  });

  @override
  State<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<_AddMemberSheet> {
  UserEntity? _selected;
  final Set<String> _selectedRoles = {};

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('Adicionar membro',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const Spacer(),
            IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context)),
          ]),
          const SizedBox(height: 12),
          if (widget.available.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text('Todos os membros já foram escalados.',
                  style: TextStyle(color: AppColors.textSecondary)),
            )
          else ...[
            const Text('Membro',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            DropdownButtonFormField<UserEntity>(
              value: _selected,
              hint: const Text('Selecionar membro'),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: widget.available
                  .map((m) => DropdownMenuItem(value: m, child: Text(m.name)))
                  .toList(),
              onChanged: (m) => setState(() => _selected = m),
            ),
            if (widget.roles.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text('Funções',
                  style:
                      TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: widget.roles.map((r) {
                  final selected = _selectedRoles.contains(r);
                  return FilterChip(
                    label: Text(r),
                    selected: selected,
                    onSelected: (v) => setState(() {
                      if (v) {
                        _selectedRoles.add(r);
                      } else {
                        _selectedRoles.remove(r);
                      }
                    }),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selected == null
                    ? null
                    : () {
                        widget.onAdd(ScheduleAssignment(
                          userId: _selected!.id,
                          roles: _selectedRoles.toList(),
                        ));
                        Navigator.pop(context);
                      },
                child: const Text('Adicionar'),
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
