import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_bottom_sheet.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/event_entity.dart';
import '../providers/event_provider.dart';
import '../../domain/usecases/create_event_use_case.dart';
import '../../domain/usecases/delete_event_use_case.dart';
import '../../../ministries/domain/entities/ministry_entity.dart';
import '../../../ministries/domain/entities/schedule_entity.dart';
import '../../../ministries/domain/usecases/delete_schedule_use_case.dart';
import '../../../ministries/presentation/pages/schedule_detail_page.dart';
import '../../../ministries/presentation/providers/ministry_provider.dart';
import '../../../ministries/presentation/providers/schedule_provider.dart';

class EventsPage extends ConsumerWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateChangesProvider).asData?.value;
    final canManage = user != null ? (user.isAdm() || user.isLead()) : false;
    final eventsAsync = ref.watch(churchEventsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: canManage
          ? FloatingActionButton(
              tooltip: 'Novo evento',
              onPressed: () => _showCreateDialog(context, ref, user!),
              child: const Icon(Icons.add),
            )
          : null,
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (events) {
          if (events.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(churchEventsProvider);
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 200),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_outlined, size: 56, color: AppColors.textHint),
                        SizedBox(height: 12),
                        Text('Nenhum evento cadastrado.',
                            style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(churchEventsProvider);
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: events.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _EventCard(
                event: events[i],
                canManage: canManage,
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref, UserEntity user) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CreateEventSheet(user: user),
    );
  }
}



// ── Event Card ────────────────────────────────────────────────────────────────

class _EventCard extends ConsumerWidget {
  final EventEntity event;
  final bool canManage;
  const _EventCard({required this.event, required this.canManage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final periodStr = event.formattedDateRange;

    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => _showEventOptions(context, ref),
        child: Stack(
          children: [
            Positioned(
              right: 0, top: 0, bottom: 0,
              child: Image.asset(
                'assets/icon/ic_pattern_transparent_background.png',
                fit: BoxFit.fitHeight,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.event, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text(periodStr,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                        if (event.shifts.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: event.shifts
                                .map((s) => _ShiftChip(shift: s))
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEventOptions(BuildContext context, WidgetRef ref) {
    final actions = [
      BottomSheetAction(
        icon: Icons.visibility_outlined,
        label: 'Visualizar Detalhes',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => EventDetailPage(event: event),
            ),
          );
        },
      ),
      BottomSheetAction(
        icon: Icons.delete_outline,
        label: 'Excluir Evento',
        iconColor: AppColors.error,
        textColor: AppColors.error,
        visible: canManage,
        onTap: () => _confirmDelete(context, ref),
      ),
    ];

    CustomBottomSheet.show(context: context, actions: actions);
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir evento'),
        content: Text(
            'Tem certeza que deseja excluir "${event.name}"? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(deleteEventUseCaseProvider).call(
                  DeleteEventParams(eventId: event.id));
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}

// ── Event Schedules Widget ────────────────────────────────────────────────────

class _EventSchedulesWidget extends ConsumerWidget {
  final EventEntity event;
  final List<MinistryEntity> ministries;

  const _EventSchedulesWidget({
    required this.event,
    required this.ministries,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Busca escalas de todos os ministérios e filtra por eventId
    final allSchedulesFutures = ministries.map((ministry) {
      return ref.watch(upcomingSchedulesProvider(ministry.id));
    }).toList();

    // Aguarda todas as futures
    return FutureBuilder<List<List<ScheduleEntity>>>(
      future: Future.wait(allSchedulesFutures.map((asyncValue) {
        return asyncValue.when(
          data: (schedules) => Future.value(schedules),
          loading: () => Future.value(<ScheduleEntity>[]),
          error: (_, __) => Future.value(<ScheduleEntity>[]),
        );
      })),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        // Flatten e filtra por eventId
        final allSchedules = snapshot.data!.expand((list) => list).toList();
        final eventSchedules = allSchedules
            .where((s) => s.eventId == event.id)
            .toList();

        if (eventSchedules.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Nenhuma escala criada para este evento',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          );
        }

        // Agrupa por ministério
        final Map<String, List<ScheduleEntity>> byMinistry = {};
        for (final schedule in eventSchedules) {
          byMinistry.putIfAbsent(schedule.ministryId, () => []).add(schedule);
        }

        // Filtra apenas ministérios que existem
        final validEntries = byMinistry.entries.where((entry) {
          return ministries.any((m) => m.id == entry.key);
        }).toList();

        if (validEntries.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Nenhuma escala criada para este evento',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: validEntries.map((entry) {
            final ministry = ministries.firstWhere((m) => m.id == entry.key);
            final schedules = entry.value;

            return _MinistryScheduleSection(
              ministry: ministry,
              schedules: schedules,
            );
          }).toList(),
        );
      },
    );
  }
}

// ── Ministry Schedule Section ─────────────────────────────────────────────────

class _MinistryScheduleSection extends ConsumerWidget {
  final MinistryEntity ministry;
  final List<ScheduleEntity> schedules;

  const _MinistryScheduleSection({
    required this.ministry,
    required this.schedules,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ordena as escalas por horário
    final sortedSchedules = [...schedules]..sort((a, b) {
      // Prioriza por shiftStartTime se existir
      if (a.shiftStartTime != null && b.shiftStartTime != null) {
        return a.shiftStartTime!.compareTo(b.shiftStartTime!);
      }
      // Se não tiver horário, usa o shiftName
      if (a.shiftName != null && b.shiftName != null) {
        return a.shiftName!.compareTo(b.shiftName!);
      }
      // Fallback: mantém ordem original
      return 0;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(Icons.groups_outlined, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                ministry.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        ...sortedSchedules.map((schedule) => _ScheduleItem(
          schedule: schedule,
          ministry: ministry,
        )),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ── Schedule Item ─────────────────────────────────────────────────────────────

class _ScheduleItem extends ConsumerWidget {
  final ScheduleEntity schedule;
  final MinistryEntity ministry;

  const _ScheduleItem({
    required this.schedule,
    required this.ministry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateChangesProvider).asData?.value;
    final canManage = user != null &&
        (user.isAdm() ||
            ministry.leaderIds.contains(user.id));

    return FutureBuilder<Map<String, UserEntity>>(
      future: _loadUsers(ref, schedule.assignments.map((a) => a.userId).toList()),
      builder: (context, snapshot) {
        final users = snapshot.data ?? {};

        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.divider),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _showScheduleOptions(context, ref, canManage, users.values.toList()),
            child: Stack(
              children: [
                // Padrão de fundo
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Image.asset(
                    'assets/icon/ic_pattern_transparent_background.png',
                    fit: BoxFit.fitHeight,
                  ),
                ),

                // Conteúdo
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Horário/Turno
                      if (schedule.shiftName != null || schedule.displayTime != null) ...[
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              schedule.displayTime ?? schedule.shiftName ?? '',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Avatares sobrepostos + contador
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Stack de avatares
                          SizedBox(
                            width: schedule.assignments.isEmpty
                                ? 0
                                : (schedule.assignments.length * 24.0) + 8,
                            height: 28,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: schedule.assignments.asMap().entries.map((entry) {
                                final index = entry.key;
                                final assignment = entry.value;
                                final user = users[assignment.userId];
                                final userName = user?.name ?? '?';
                                final roles = assignment.roles.join(', ');
                                final tooltipText = roles.isNotEmpty
                                    ? '$userName - $roles'
                                    : userName;

                                return Positioned(
                                  left: index * 18.0, // Sobreposição de 24px
                                  child: Tooltip(
                                    message: tooltipText,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: UserAvatar(
                                        photoUrl: user?.photoUrl,
                                        userName: userName,
                                        radius: 12,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                          // Contador abaixo dos avatares
                          if (schedule.assignments.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.people,
                                  size: 14,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Total Escalado ${schedule.assignments.length}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showScheduleOptions(BuildContext context, WidgetRef ref, bool canManage, List<UserEntity> allMembers) {
    final actions = [
      BottomSheetAction(
        icon: Icons.visibility_outlined,
        label: 'Visualizar Detalhes',
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ScheduleDetailPage(
                schedule: schedule,
                ministry: ministry,
                allMembers: allMembers,
                canManage: canManage,
              ),
            ),
          );
        },
      ),
      BottomSheetAction(
        icon: Icons.delete_outline,
        label: 'Excluir Escala',
        iconColor: AppColors.error,
        textColor: AppColors.error,
        visible: canManage,
        onTap: () => _confirmDelete(context, ref),
      ),
    ];

    CustomBottomSheet.show(context: context, actions: actions);
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Escala'),
        content: const Text('Tem certeza que deseja excluir esta escala?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final result = await ref.read(deleteScheduleUseCaseProvider).call(
        DeleteScheduleParams(
          ministryId: ministry.id,
          scheduleId: schedule.id,
        ),
      );

      if (context.mounted) {
        result.fold(
          (failure) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(failure.message)),
          ),
          (_) {
            ref.invalidate(upcomingSchedulesProvider(ministry.id));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Escala excluída com sucesso!')),
            );
          },
        );
      }
    }
  }

  Future<Map<String, UserEntity>> _loadUsers(WidgetRef ref, List<String> userIds) async {
    final Map<String, UserEntity> result = {};
    for (final userId in userIds) {
      try {
        final user = await ref.read(userByIdProvider(userId).future);
        if (user != null) {
          result[userId] = user;
        }
      } catch (_) {
        // Ignora erros
      }
    }
    return result;
  }
}

class _ShiftChip extends StatelessWidget {
  final ShiftEntity shift;
  const _ShiftChip({required this.shift});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${shift.name}  ${shift.displayTime}',
        style: const TextStyle(
            fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ── Create Event Bottom Sheet ─────────────────────────────────────────────────

class _CreateEventSheet extends ConsumerStatefulWidget {
  final UserEntity user;
  const _CreateEventSheet({required this.user});

  @override
  ConsumerState<_CreateEventSheet> createState() => _CreateEventSheetState();
}

class _CreateEventSheetState extends ConsumerState<_CreateEventSheet> {
  final _nameCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  DateTime? _endDate;
  final List<_ShiftDraft> _shifts = [];
  bool _saving = false;

  // Sugestões rápidas de turno
  static const _suggestions = ['Manhã', 'Tarde', 'Noite'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);

    final shifts = _shifts
        .where((s) => s.name.isNotEmpty)
        .map((s) => ShiftEntity(
              id: const Uuid().v4(),
              name: s.name,
              startTime: s.startTime,
              endTime: s.endTime,
            ))
        .toList();

    final result = await ref.read(createEventUseCaseProvider).call(
          CreateEventParams(
            churchId: widget.user.churchId!,
            name: _nameCtrl.text.trim(),
            date: _date,
            endDate: _endDate,
            shifts: shifts,
            createdBy: widget.user.id,
          ),
        );

    if (mounted) {
      setState(() => _saving = false);
      result.fold(
        (f) => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(f.message))),
        (_) => Navigator.of(context).pop(),
      );
    }
  }

  void _addShift({String name = ''}) {
    setState(() => _shifts.add(_ShiftDraft(name: name)));
  }


  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    final dateStr = fmt.format(_date);
    final endDateStr = _endDate != null ? fmt.format(_endDate!) : null;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                const Expanded(
                  child: Text('Novo Evento',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Nome
            TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nome do evento *',
                prefixIcon: Icon(Icons.event_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Data de início
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() {
                    _date = picked;
                    // Se endDate ficou antes da nova data de início, resetar
                    if (_endDate != null && _endDate!.isBefore(_date)) {
                      _endDate = null;
                    }
                  });
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Data de início *',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                  border: OutlineInputBorder(),
                ),
                child: Text(dateStr),
              ),
            ),
            const SizedBox(height: 12),

            // Data de fim
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _endDate ?? _date,
                  firstDate: _date,
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _endDate = picked);
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Data de fim',
                  prefixIcon: const Icon(Icons.event_available_outlined),
                  border: const OutlineInputBorder(),
                  suffixIcon: _endDate != null
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => setState(() => _endDate = null),
                        )
                      : null,
                ),
                child: Text(
                  endDateStr ?? 'Igual à data de início',
                  style: TextStyle(
                    color: endDateStr == null
                        ? Theme.of(context).hintColor
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Turnos
            Row(
              children: [
                const Expanded(
                    child: Text('Turnos',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600))),
                // Botões de sugestão rápida
                ..._suggestions.map((s) => Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: ActionChip(
                        label: Text(s, style: const TextStyle(fontSize: 12)),
                        onPressed: () => _addShift(name: s),
                      ),
                    )),
              ],
            ),
            const SizedBox(height: 8),

            ..._shifts.asMap().entries.map((e) => _ShiftEditor(
                  key: ValueKey(e.key),
                  draft: e.value,
                  onRemove: () => setState(() => _shifts.removeAt(e.key)),
                )),

            TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Adicionar turno'),
              onPressed: () => _addShift(),
            ),
            const SizedBox(height: 16),

            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Salvar evento'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shift Draft model ─────────────────────────────────────────────────────────

class _ShiftDraft {
  String name;
  String startTime;
  String endTime;
  _ShiftDraft({this.name = '', this.startTime = '', this.endTime = ''});
}

// ── Shift Editor Row ──────────────────────────────────────────────────────────

class _ShiftEditor extends StatefulWidget {
  final _ShiftDraft draft;
  final VoidCallback onRemove;
  const _ShiftEditor({super.key, required this.draft, required this.onRemove});

  @override
  State<_ShiftEditor> createState() => _ShiftEditorState();
}

class _ShiftEditorState extends State<_ShiftEditor> {
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.draft.name);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isStart) async {
    final initial = _parseTime(isStart ? widget.draft.startTime : widget.draft.endTime);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      final str = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isStart) {
          widget.draft.startTime = str;
        } else {
          widget.draft.endTime = str;
        }
      });
    }
  }

  TimeOfDay _parseTime(String t) {
    if (t.isEmpty) return TimeOfDay.now();
    final parts = t.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppColors.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Nome do turno (ex: Manhã)',
                      isDense: true,
                      border: InputBorder.none,
                    ),
                    onChanged: (v) => widget.draft.name = v,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: widget.onRemove,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.access_time, size: 16),
                    label: Text(
                      widget.draft.startTime.isEmpty
                          ? 'Início'
                          : widget.draft.startTime,
                      style: const TextStyle(fontSize: 13),
                    ),
                    onPressed: () => _pickTime(true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.access_time_filled, size: 16),
                    label: Text(
                      widget.draft.endTime.isEmpty
                          ? 'Fim'
                          : widget.draft.endTime,
                      style: const TextStyle(fontSize: 13),
                    ),
                    onPressed: () => _pickTime(false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Event Detail Page ─────────────────────────────────────────────────────────

class EventDetailPage extends ConsumerWidget {
  final EventEntity event;

  const EventDetailPage({super.key, required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ministriesAsync = ref.watch(churchMinistriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(event.name),
      ),
      body: ministriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Erro ao carregar escalas: $e',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
        data: (ministries) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event Header
                _buildEventHeader(),
                const SizedBox(height: 24),

                // Schedules
                _EventSchedulesWidget(
                  event: event,
                  ministries: ministries,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventHeader() {
    return Card(
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // Padrão de fundo
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Opacity(
              opacity: 0.15,
              child: Image.asset(
                'assets/icon/ic_pattern_transparent_background.png',
                fit: BoxFit.fitHeight,
              ),
            ),
          ),

          // Conteúdo
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.event,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            event.formattedDateRange,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (event.shifts.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text(
                    'Turnos',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: event.shifts.map((s) => _ShiftChip(shift: s)).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
