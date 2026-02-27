import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../churches/presentation/providers/church_provider.dart';
import '../../../events/domain/entities/event_entity.dart';
import '../../../events/presentation/providers/event_provider.dart';
import '../../domain/entities/ministry_entity.dart';
import '../../domain/entities/schedule_entity.dart';
import '../../domain/usecases/add_member_to_ministry_use_case.dart';
import '../../domain/usecases/create_schedule_use_case.dart';
import '../../domain/usecases/delete_ministry_use_case.dart';
import '../../domain/usecases/delete_schedule_use_case.dart';
import '../../domain/usecases/update_ministry_roles_use_case.dart';
import '../providers/ministry_provider.dart';
import '../providers/schedule_provider.dart';
import 'schedule_detail_page.dart';

class MinistryDetailPage extends ConsumerWidget {
  final MinistryEntity ministry;
  const MinistryDetailPage({super.key, required this.ministry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateChangesProvider).asData?.value;
    final isAdmin = user?.role == UserRole.admin;
    final isLeader = user?.role == UserRole.leader;
    final canManage = isAdmin || isLeader;

    // Observa o ministério atualizado do Firestore; usa o objeto passado como fallback.
    final ministryAsync = ref.watch(ministryByIdProvider(ministry.id));
    final current = ministryAsync.asData?.value ?? ministry;

    final schedulesAsync = ref.watch(upcomingSchedulesProvider(ministry.id));
    final allMembersAsync = ref.watch(churchMembersProvider);

    // Admin/líder que ainda não está em memberIds pode participar diretamente.
    final canJoinAsMember = canManage &&
        user != null &&
        !current.memberIds.contains(user.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildHeader(context, ref, isAdmin),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  if (canJoinAsMember)
                    _JoinMinistryBanner(
                      ministryId: current.id,
                      userId: user!.id,
                    ),
                  if (canJoinAsMember) const SizedBox(height: 16),
                  _RolesSection(ministry: current, canManage: canManage, ref: ref),
                  const SizedBox(height: 20),
                  _LeadersSection(ministry: current, allMembersAsync: allMembersAsync),
                  const SizedBox(height: 20),
                  _SchedulesSection(
                    ministry: current,
                    schedulesAsync: schedulesAsync,
                    allMembersAsync: allMembersAsync,
                    canManage: canManage,
                    user: user,
                    ref: ref,
                  ),
                  const SizedBox(height: 20),
                  _MembersSection(ministry: current, allMembersAsync: allMembersAsync),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, bool isAdmin) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 56, bottom: 14, right: 16),
        title: Text(
          ministry.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (ministry.description != null)
                    Text(
                      ministry.description!,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        if (isAdmin)
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            tooltip: 'Excluir ministério',
            onPressed: () => _showDeleteMinistryDialog(context, ref),
          ),
      ],
    );
  }

  void _showDeleteMinistryDialog(BuildContext context, WidgetRef ref) {
    final codeCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete_forever_outlined, color: Colors.red.shade700, size: 22),
            const SizedBox(width: 8),
            const Expanded(child: Text('Excluir Ministério')),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            RichText(
              text: TextSpan(
                style: Theme.of(ctx).textTheme.bodyMedium,
                children: [
                  const TextSpan(text: 'Esta ação é permanente. Digite o código de convite para confirmar a exclusão de '),
                  TextSpan(text: ministry.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: codeCtrl,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                LengthLimitingTextInputFormatter(6),
              ],
              decoration: const InputDecoration(
                labelText: 'Código de convite *',
                prefixIcon: Icon(Icons.vpn_key_outlined),
              ),
              validator: (v) =>
                  (v == null || v.trim().length != 6) ? 'Código inválido' : null,
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.of(ctx).pop();
              final result = await ref.read(deleteMinistryUseCaseProvider).call(
                DeleteMinistryParams(ministry: ministry, inputCode: codeCtrl.text.trim()),
              );
              result.fold(
                (f) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message))); },
                (_) {
                  ref.invalidate(churchMinistriesProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ministério excluído.')));
                    Navigator.of(context).pop();
                  }
                },
              );
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? trailing;
  const _SectionTitle({required this.title, required this.icon, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(title,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ── Roles section ──────────────────────────────────────────────────────────────

class _RolesSection extends StatelessWidget {
  final MinistryEntity ministry;
  final bool canManage;
  final WidgetRef ref;
  const _RolesSection(
      {required this.ministry, required this.canManage, required this.ref});

  void _showEditRoles(BuildContext context) {
    final roles = List<String>.from(ministry.roles);
    final ctrl = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setState) {
          return Padding(
            padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Gerenciar Funções',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: roles
                    .map((r) => Chip(
                          label: Text(r),
                          onDeleted: () => setState(() => roles.remove(r)),
                          deleteIconColor: AppColors.error,
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: ctrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                        hintText: 'Nova função (ex: Guitarra)', isDense: true),
                    onSubmitted: (v) {
                      final val = v.trim();
                      if (val.isNotEmpty && !roles.contains(val)) {
                        setState(() { roles.add(val); ctrl.clear(); });
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: AppColors.primary),
                  onPressed: () {
                    final val = ctrl.text.trim();
                    if (val.isNotEmpty && !roles.contains(val)) {
                      setState(() { roles.add(val); ctrl.clear(); });
                    }
                  },
                ),
              ]),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await ref.read(updateMinistryRolesUseCaseProvider).call(
                    UpdateMinistryRolesParams(ministryId: ministry.id, roles: roles),
                  );
                  // O StreamProvider (ministryByIdProvider) atualiza a tela
                  // automaticamente via Firestore snapshots — sem invalidate.
                  // Apenas invalida a lista para consistência ao voltar.
                  ref.invalidate(churchMinistriesProvider);
                },
                child: const Text('Salvar Funções'),
              ),
            ]),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _SectionTitle(
        title: 'Funções',
        icon: Icons.workspace_premium_outlined,
        trailing: canManage
            ? IconButton(
                icon: const Icon(Icons.edit_outlined,
                    size: 18, color: AppColors.primary),
                tooltip: 'Editar funções',
                onPressed: () => _showEditRoles(context),
              )
            : null,
      ),
      const SizedBox(height: 8),
      if (ministry.roles.isEmpty)
        Text(
          canManage
              ? 'Nenhuma função cadastrada. Toque em editar para adicionar.'
              : 'Nenhuma função cadastrada.',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        )
      else
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: ministry.roles.map((r) => Chip(label: Text(r))).toList(),
        ),
    ]);
  }
}

// ── Leaders section ────────────────────────────────────────────────────────────

class _LeadersSection extends StatelessWidget {
  final MinistryEntity ministry;
  final AsyncValue<List<UserEntity>> allMembersAsync;
  const _LeadersSection(
      {required this.ministry, required this.allMembersAsync});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _SectionTitle(title: 'Líderes', icon: Icons.star_outline),
      const SizedBox(height: 8),
      allMembersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Erro: $e',
            style: const TextStyle(color: AppColors.error)),
        data: (all) {
          final leaders =
              all.where((m) => ministry.leaderIds.contains(m.id)).toList();
          if (leaders.isEmpty) {
            return const Text('Nenhum líder cadastrado.',
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 13));
          }
          return Column(
            children: leaders
                .map((u) => _ContactTile(user: u, isLeader: true))
                .toList(),
          );
        },
      ),
    ]);
  }
}

class _ContactTile extends StatelessWidget {
  final UserEntity user;
  final bool isLeader;
  const _ContactTile({required this.user, this.isLeader = false});

  void _openSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ContactSheet(user: user, isLeader: isLeader),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => _openSheet(context),
        leading: CircleAvatar(
          backgroundColor:
              isLeader ? AppColors.secondaryLight : AppColors.primaryLight,
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
            style: TextStyle(
              color: isLeader ? AppColors.secondary : AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(user.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLeader)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: AppColors.secondaryLight,
                    borderRadius: BorderRadius.circular(10)),
                child: const Text('Líder',
                    style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

class _ContactSheet extends StatelessWidget {
  final UserEntity user;
  final bool isLeader;
  const _ContactSheet({required this.user, required this.isLeader});

  Future<void> _launchEmail() async {
    final uri = Uri(scheme: 'mailto', path: user.email);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _launchWhatsApp() async {
    final phone = user.phone!.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhone = user.phone != null && user.phone!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),

          // Avatar + nome
          CircleAvatar(
            radius: 32,
            backgroundColor:
                isLeader ? AppColors.secondaryLight : AppColors.primaryLight,
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: isLeader ? AppColors.secondary : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(user.name,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.bold)),
          if (isLeader) ...[
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                  color: AppColors.secondaryLight,
                  borderRadius: BorderRadius.circular(10)),
              child: const Text('Líder',
                  style: TextStyle(
                      color: AppColors.secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          ],
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Email row
          Row(children: [
            const Icon(Icons.email_outlined,
                size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(user.email,
                  style: const TextStyle(fontSize: 14)),
            ),
            TextButton.icon(
              onPressed: _launchEmail,
              icon: const Icon(Icons.send_outlined, size: 16),
              label: const Text('Enviar e-mail'),
            ),
          ]),

          // Phone row
          if (hasPhone) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.phone_outlined,
                  size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(user.phone!,
                    style: const TextStyle(fontSize: 14)),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF25D366)),
                onPressed: _launchWhatsApp,
                icon: const Icon(Icons.chat_outlined, size: 16),
                label: const Text('WhatsApp'),
              ),
            ]),
          ],

          if (!hasPhone) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.phone_outlined,
                  size: 20, color: AppColors.textHint),
              const SizedBox(width: 12),
              const Text('Telefone não cadastrado',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textHint)),
            ]),
          ],
        ],
      ),
    );
  }
}

// ── Schedules section ─────────────────────────────────────────────────────────

class _SchedulesSection extends StatelessWidget {
  final MinistryEntity ministry;
  final AsyncValue<List<ScheduleEntity>> schedulesAsync;
  final AsyncValue<List<UserEntity>> allMembersAsync;
  final bool canManage;
  final UserEntity? user;
  final WidgetRef ref;

  const _SchedulesSection({
    required this.ministry,
    required this.schedulesAsync,
    required this.allMembersAsync,
    required this.canManage,
    required this.user,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _SectionTitle(
        title: 'Escalas',
        icon: Icons.calendar_month_outlined,
        trailing: canManage
            ? IconButton(
                icon: const Icon(Icons.add_circle_outline,
                    size: 20, color: AppColors.primary),
                tooltip: 'Nova escala',
                onPressed: () => _showCreateScheduleDialog(context),
              )
            : null,
      ),
      const SizedBox(height: 8),
      schedulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Erro: $e',
            style: const TextStyle(color: AppColors.error)),
        data: (schedules) {
          if (schedules.isEmpty) {
            return const Text('Nenhuma escala próxima.',
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 13));
          }
          final allMembers = allMembersAsync.asData?.value ?? [];
          final sorted = [...schedules]
            ..sort((a, b) => a.eventDate.compareTo(b.eventDate));
          return _SchedulesCarousel(
            schedules: sorted,
            allMembers: allMembers,
            canManage: canManage,
            ministry: ministry,
            ref: ref,
            context: context,
          );
        },
      ),
    ]);
  }

  void _showCreateScheduleDialog(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _CreateScheduleSheet(
        ministry: ministry,
        allMembers: allMembersAsync.asData?.value ?? [],
        currentUserId: user?.id ?? '',
        onCreated: () => ref.invalidate(upcomingSchedulesProvider(ministry.id)),
      ),
    );
  }
}

// ── Schedules carousel ────────────────────────────────────────────────────────

class _SchedulesCarousel extends StatefulWidget {
  final List<ScheduleEntity> schedules;
  final List<UserEntity> allMembers;
  final bool canManage;
  final MinistryEntity ministry;
  final WidgetRef ref;
  final BuildContext context;

  const _SchedulesCarousel({
    required this.schedules,
    required this.allMembers,
    required this.canManage,
    required this.ministry,
    required this.ref,
    required this.context,
  });

  @override
  State<_SchedulesCarousel> createState() => _SchedulesCarouselState();
}

class _SchedulesCarouselState extends State<_SchedulesCarousel> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    final total = widget.schedules.length;
    return Column(
      children: [
        SizedBox(
          height: 140,
          child: PageView.builder(
            itemCount: total,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, index) {
              final s = widget.schedules[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _ScheduleCard(
                  schedule: s,
                  allMembers: widget.allMembers,
                  canManage: widget.canManage,
                  ministry: widget.ministry,
                  onDelete: () async {
                    final result = await widget.ref
                        .read(deleteScheduleUseCaseProvider)
                        .call(DeleteScheduleParams(
                          ministryId: widget.ministry.id,
                          scheduleId: s.id,
                        ));
                    result.fold(
                      (f) {
                        if (widget.context.mounted) {
                          ScaffoldMessenger.of(widget.context).showSnackBar(
                              SnackBar(content: Text(f.message)));
                        }
                      },
                      (_) => widget.ref
                          .invalidate(upcomingSchedulesProvider(widget.ministry.id)),
                    );
                  },
                ),
              );
            },
          ),
        ),
        if (total > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              total,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _current == i ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _current == i
                      ? AppColors.primary
                      : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final ScheduleEntity schedule;
  final List<UserEntity> allMembers;
  final bool canManage;
  final MinistryEntity ministry;
  final VoidCallback onDelete;

  const _ScheduleCard({
    required this.schedule,
    required this.allMembers,
    required this.canManage,
    required this.ministry,
    required this.onDelete,
  });

  bool get _isToday {
    final now = DateTime.now();
    return schedule.eventDate.year == now.year &&
        schedule.eventDate.month == now.month &&
        schedule.eventDate.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final memberCount = schedule.assignments.length;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ScheduleDetailPage(
            schedule: schedule,
            ministry: ministry,
            allMembers: allMembers,
            canManage: canManage,
          ),
        )),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: _isToday
                          ? AppColors.warningLight
                          : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    _isToday
                        ? 'Hoje'
                        : DateFormat('dd/MM/yyyy').format(schedule.eventDate),
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _isToday
                            ? AppColors.warning
                            : AppColors.primary),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right,
                    size: 18, color: AppColors.textHint),
              ]),
              const SizedBox(height: 8),
              Text(
                schedule.eventTitle,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 15),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (schedule.shiftStartTime != null &&
                  schedule.shiftEndTime != null) ...[
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.access_time_outlined,
                      size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${schedule.shiftStartTime} – ${schedule.shiftEndTime}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ]),
              ] else if (schedule.shiftName != null) ...[
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.access_time_outlined,
                      size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(schedule.shiftName!,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ]),
              ],
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.people_outline,
                    size: 13, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(
                  '$memberCount membro${memberCount != 1 ? 's' : ''} escalado${memberCount != 1 ? 's' : ''}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Create Schedule Sheet ──────────────────────────────────────────────────────

class _CreateScheduleSheet extends ConsumerStatefulWidget {
  final MinistryEntity ministry;
  final List<UserEntity> allMembers;
  final String currentUserId;
  final VoidCallback onCreated;

  const _CreateScheduleSheet({
    required this.ministry,
    required this.allMembers,
    required this.currentUserId,
    required this.onCreated,
  });

  @override
  ConsumerState<_CreateScheduleSheet> createState() =>
      _CreateScheduleSheetState();
}

class _CreateScheduleSheetState extends ConsumerState<_CreateScheduleSheet> {
  EventEntity? _selectedEvent;
  ShiftEntity? _selectedShift;
  final _notesCtrl = TextEditingController();
  // userId → selected roles
  final Map<String, List<String>> _assignments = {};
  bool _saving = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  List<UserEntity> get _ministryMembers => widget.allMembers
      .where((m) =>
          widget.ministry.memberIds.contains(m.id) ||
          widget.ministry.leaderIds.contains(m.id))
      .toList();

  Future<void> _save() async {
    if (_selectedEvent == null || _selectedShift == null) return;
    setState(() => _saving = true);

    final assignmentList = _assignments.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => ScheduleAssignment(userId: e.key, roles: e.value))
        .toList();

    final eventTitle =
        '${_selectedEvent!.name} – ${_selectedShift!.name}';

    final result = await ref.read(createScheduleUseCaseProvider).call(
          CreateScheduleParams(
            ministryId: widget.ministry.id,
            eventTitle: eventTitle,
            eventDate: _selectedEvent!.date,
            assignments: assignmentList,
            notes: _notesCtrl.text.trim().isEmpty
                ? null
                : _notesCtrl.text.trim(),
            createdBy: widget.currentUserId,
            eventId: _selectedEvent!.id,
            shiftId: _selectedShift!.id,
            shiftName: _selectedShift!.name,
            shiftStartTime: _selectedShift!.startTime,
            shiftEndTime: _selectedShift!.endTime,
          ),
        );

    if (!mounted) return;
    setState(() => _saving = false);

    result.fold(
      (f) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(f.message))),
      (_) {
        widget.onCreated();
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(churchEventsProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            const Text(
              'Nova Escala',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // ── Event picker ─────────────────────────────────────────────
            const Text(
              'Evento *',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            eventsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Erro ao carregar eventos: $e'),
              data: (events) {
                if (events.isEmpty) {
                  return const Text(
                    'Nenhum evento cadastrado.',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  );
                }
                return DropdownButtonFormField<EventEntity>(
                  value: _selectedEvent,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    isDense: true,
                    prefixIcon: Icon(Icons.event_outlined),
                  ),
                  hint: const Text('Selecione o evento'),
                  items: events
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(
                              '${e.name}  ·  ${DateFormat('dd/MM/yyyy').format(e.date)}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: (e) => setState(() {
                    _selectedEvent = e;
                    _selectedShift = null; // reset shift
                  }),
                );
              },
            ),
            const SizedBox(height: 16),

            // ── Shift picker (visible only when event is selected) ───────
            if (_selectedEvent != null) ...[
              const Text(
                'Turno *',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary),
              ),
              const SizedBox(height: 6),
              if (_selectedEvent!.shifts.isEmpty)
                const Text(
                  'Este evento não possui turnos cadastrados.',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 13),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _selectedEvent!.shifts.map((shift) {
                    final isSelected = _selectedShift?.id == shift.id;
                    return ChoiceChip(
                      label: Text(
                          '${shift.name} (${shift.startTime}–${shift.endTime})'),
                      selected: isSelected,
                      onSelected: (_) =>
                          setState(() => _selectedShift = shift),
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                          color: isSelected ? Colors.white : null,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 16),
            ],

            // ── Member assignment ────────────────────────────────────────
            if (widget.ministry.roles.isNotEmpty &&
                _ministryMembers.isNotEmpty) ...[
              const Text(
                'Membros e Funções',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary),
              ),
              const SizedBox(height: 6),
              ..._ministryMembers.map((member) {
                final memberRoles = _assignments[member.id] ?? [];
                return ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title:
                      Text(member.name, style: const TextStyle(fontSize: 13)),
                  subtitle: memberRoles.isEmpty
                      ? null
                      : Text(
                          memberRoles.join(', '),
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.primary),
                        ),
                  children: widget.ministry.roles
                      .map((role) => CheckboxListTile(
                            dense: true,
                            title: Text(role,
                                style: const TextStyle(fontSize: 13)),
                            value: memberRoles.contains(role),
                            onChanged: (v) => setState(() {
                              final list = List<String>.from(
                                  _assignments[member.id] ?? []);
                              if (v == true) {
                                list.add(role);
                              } else {
                                list.remove(role);
                              }
                              _assignments[member.id] = list;
                            }),
                          ))
                      .toList(),
                );
              }),
              const SizedBox(height: 4),
            ],

            // ── Notes ────────────────────────────────────────────────────
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                  labelText: 'Observações (opcional)', isDense: true),
            ),
            const SizedBox(height: 20),

            // ── Save button ──────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed:
                    (_selectedEvent == null || _selectedShift == null || _saving)
                        ? null
                        : _save,
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Criar Escala'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Join Ministry Banner ───────────────────────────────────────────────────────

class _JoinMinistryBanner extends ConsumerStatefulWidget {
  final String ministryId;
  final String userId;
  const _JoinMinistryBanner(
      {required this.ministryId, required this.userId});

  @override
  ConsumerState<_JoinMinistryBanner> createState() =>
      _JoinMinistryBannerState();
}

class _JoinMinistryBannerState extends ConsumerState<_JoinMinistryBanner> {
  bool _loading = false;

  Future<void> _join() async {
    setState(() => _loading = true);
    final result = await ref
        .read(addMemberToMinistryUseCaseProvider)
        .call(AddMemberToMinistryParams(
          ministryId: widget.ministryId,
          userId: widget.userId,
        ));
    if (!mounted) return;
    setState(() => _loading = false);
    result.fold(
      (f) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(f.message))),
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você entrou neste ministério!')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.primaryLight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(children: [
          const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Você ainda não é membro deste ministério.',
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : TextButton(
                  onPressed: _join,
                  child: const Text('Participar'),
                ),
        ]),
      ),
    );
  }
}

// ── Members section ────────────────────────────────────────────────────────────

class _MembersSection extends StatelessWidget {
  final MinistryEntity ministry;
  final AsyncValue<List<UserEntity>> allMembersAsync;
  const _MembersSection(
      {required this.ministry, required this.allMembersAsync});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _SectionTitle(title: 'Membros', icon: Icons.people_outline),
      const SizedBox(height: 8),
      allMembersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Text('Erro: $e', style: const TextStyle(color: AppColors.error)),
        data: (all) {
          // Inclui líderes + membros; evita duplicatas
          final seen = <String>{};
          final entries = <({UserEntity user, bool isLeader})>[];

          for (final u in all) {
            if (ministry.leaderIds.contains(u.id) && seen.add(u.id)) {
              entries.add((user: u, isLeader: true));
            }
          }
          for (final u in all) {
            if (ministry.memberIds.contains(u.id) && seen.add(u.id)) {
              entries.add((user: u, isLeader: false));
            }
          }

          if (entries.isEmpty) {
            return const Text('Nenhum membro neste ministério.',
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 13));
          }
          return Column(
            children: entries
                .map((e) => _ContactTile(user: e.user, isLeader: e.isLeader))
                .toList(),
          );
        },
      ),
    ]);
  }
}

