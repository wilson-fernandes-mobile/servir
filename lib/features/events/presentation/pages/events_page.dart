import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/event_entity.dart';
import '../providers/event_provider.dart';
import '../../domain/usecases/create_event_use_case.dart';
import '../../domain/usecases/delete_event_use_case.dart';

class EventsPage extends ConsumerWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateChangesProvider).asData?.value;
    final canManage =
        user?.role == UserRole.admin || user?.role == UserRole.leader;
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
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_outlined, size: 56, color: AppColors.textHint),
                  SizedBox(height: 12),
                  Text('Nenhum evento cadastrado.',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _EventCard(
              event: events[i],
              canManage: canManage,
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
    final dateStr = DateFormat('dd/MM/yyyy').format(event.date);
    return Card(
      clipBehavior: Clip.hardEdge,
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
                      Text(dateStr,
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
                if (canManage)
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        color: Colors.red.shade400, size: 20),
                    onPressed: () => _confirmDelete(context, ref),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
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
        '${shift.name}  ${shift.startTime}–${shift.endTime}',
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
    final dateStr = DateFormat('dd/MM/yyyy').format(_date);
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

            // Data
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _date = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Data do evento *',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                  border: OutlineInputBorder(),
                ),
                child: Text(dateStr),
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
