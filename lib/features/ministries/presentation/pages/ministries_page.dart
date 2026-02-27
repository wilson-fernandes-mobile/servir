import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/ministry_entity.dart';
import '../../domain/usecases/create_ministry_use_case.dart';
import '../../domain/usecases/delete_ministry_use_case.dart';
import '../../domain/usecases/join_ministry_use_case.dart';
import '../providers/ministry_provider.dart';
import 'ministry_detail_page.dart';

class MinistriesPage extends ConsumerWidget {
  const MinistriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateChangesProvider).asData?.value;
    final isAdmin = user?.role == UserRole.admin;
    final isLeader = user?.role == UserRole.leader;
    final canSeeCode = isAdmin || isLeader;
    final ministriesAsync = ref.watch(churchMinistriesProvider);

    return Scaffold(
      body: ministriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text('Erro ao carregar ministérios: $e')),
        data: (ministries) {
          if (ministries.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.groups_outlined,
                      size: 56, color: AppColors.textHint),
                  const SizedBox(height: 12),
                  const Text(
                    'Nenhum ministério cadastrado',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  if (isAdmin) ...[
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Criar ministério'),
                      onPressed: () =>
                          _showCreateDialog(context, ref, user!.churchId!),
                    ),
                  ],
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: ministries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, index) => _MinistryCard(
              ministry: ministries[index],
              showCode: canSeeCode,
              isAdmin: isAdmin,
            ),
          );
        },
      ),
      floatingActionButton: isAdmin
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.small(
                  heroTag: 'fab_join',
                  tooltip: 'Entrar com código',
                  onPressed: () {
                    final u =
                        ref.read(authStateChangesProvider).asData?.value;
                    if (u != null && u.churchId != null) {
                      _showJoinDialog(context, ref, u.id, u.churchId!);
                    }
                  },
                  child: const Icon(Icons.group_add_outlined),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: 'fab_create',
                  tooltip: 'Criar ministério',
                  onPressed: () {
                    final churchId = ref
                        .read(authStateChangesProvider)
                        .asData
                        ?.value
                        ?.churchId;
                    if (churchId != null) {
                      _showCreateDialog(context, ref, churchId);
                    }
                  },
                  child: const Icon(Icons.add),
                ),
              ],
            )
          : FloatingActionButton.extended(
              tooltip: 'Entrar em um ministério',
              onPressed: () {
                final u = ref.read(authStateChangesProvider).asData?.value;
                if (u != null && u.churchId != null) {
                  _showJoinDialog(context, ref, u.id, u.churchId!);
                }
              },
              icon: const Icon(Icons.group_add_outlined),
              label: const Text('Entrar com código'),
            ),
    );
  }

  void _showJoinDialog(
      BuildContext context, WidgetRef ref, String userId, String churchId) {
    final codeCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Entrar em Ministério'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: codeCtrl,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
              LengthLimitingTextInputFormatter(6),
            ],
            decoration: const InputDecoration(
              labelText: 'Código de convite *',
              prefixIcon: Icon(Icons.vpn_key_outlined),
              hintText: 'Ex: ABC123',
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Informe o código';
              if (v.trim().length != 6) return 'O código deve ter 6 caracteres';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.of(ctx).pop();
              final useCase = ref.read(joinMinistryUseCaseProvider);
              final result = await useCase(JoinMinistryParams(
                userId: userId,
                inviteCode: codeCtrl.text.trim().toUpperCase(),
                churchId: churchId,
              ));
              result.fold(
                (failure) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(failure.message)));
                  }
                },
                (_) {
                  ref.invalidate(churchMinistriesProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Você entrou no ministério!')),
                    );
                  }
                },
              );
            },
            child: const Text('Entrar'),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(
      BuildContext context, WidgetRef ref, String churchId) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Novo Ministério'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nome *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Informe o nome' : null,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descCtrl,
                decoration:
                    const InputDecoration(labelText: 'Descrição (opcional)'),
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.of(ctx).pop();
              final useCase = ref.read(createMinistryUseCaseProvider);
              final result = await useCase(CreateMinistryParams(
                name: nameCtrl.text.trim(),
                description: descCtrl.text.trim().isEmpty
                    ? null
                    : descCtrl.text.trim(),
                churchId: churchId,
              ));
              result.fold(
                (failure) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(failure.message)));
                  }
                },
                (_) {
                  ref.invalidate(churchMinistriesProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Ministério criado com sucesso!')),
                    );
                  }
                },
              );
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }
}


// ── Ministry card ─────────────────────────────────────────────────────────────

class _MinistryCard extends ConsumerWidget {
  final MinistryEntity ministry;
  final bool showCode;
  final bool isAdmin;
  const _MinistryCard({
    required this.ministry,
    this.showCode = false,
    this.isAdmin = false,
  });

  void _navigateToDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MinistryDetailPage(ministry: ministry),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    final codeCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete_forever_outlined,
                color: Colors.red.shade700, size: 22),
            const SizedBox(width: 8),
            const Text('Excluir Ministério'),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: Theme.of(ctx).textTheme.bodyMedium,
                  children: [
                    const TextSpan(
                        text:
                            'Esta ação é permanente e desvinculará todos os membros do ministério '),
                    TextSpan(
                      text: ministry.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
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
                  labelText: 'Código do ministério *',
                  prefixIcon: Icon(Icons.vpn_key_outlined),
                  hintText: 'Ex: ABC123',
                  helperText: 'Digite o código de convite para confirmar',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Informe o código para confirmar';
                  }
                  if (v.trim().length != 6) {
                    return 'O código deve ter 6 caracteres';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.of(ctx).pop();
              final useCase = ref.read(deleteMinistryUseCaseProvider);
              final result = await useCase(DeleteMinistryParams(
                ministry: ministry,
                inputCode: codeCtrl.text.trim(),
              ));
              result.fold(
                (failure) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(failure.message)));
                  }
                },
                (_) {
                  ref.invalidate(churchMinistriesProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Ministério excluído com sucesso.')),
                    );
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderCount = ministry.leaderIds.length;
    final memberCount = ministry.memberIds.length;
    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => _navigateToDetail(context),
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
            Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.groups,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ministry.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (ministry.description != null)
                      Text(
                        ministry.description!,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (leaderCount > 0)
                          _Badge(
                            label:
                                '$leaderCount líder${leaderCount > 1 ? 'es' : ''}',
                            color: AppColors.secondary,
                            bgColor: AppColors.secondaryLight,
                          ),
                        if (leaderCount > 0 && memberCount > 0)
                          const SizedBox(width: 6),
                        if (memberCount > 0)
                          _Badge(
                            label:
                                '$memberCount membro${memberCount > 1 ? 's' : ''}',
                            color: AppColors.primary,
                            bgColor: AppColors.primaryLight,
                          ),
                      ],
                    ),
                    if (showCode && ministry.inviteCode.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(
                              ClipboardData(text: ministry.inviteCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Código copiado!'),
                                duration: Duration(seconds: 2)),
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.vpn_key_outlined,
                                size: 13, color: AppColors.textHint),
                            const SizedBox(width: 4),
                            Text(
                              ministry.inviteCode,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.copy,
                                size: 13, color: AppColors.textHint),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isAdmin)
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      color: Colors.red.shade400, size: 20),
                  tooltip: 'Excluir ministério',
                  onPressed: () => _showDeleteDialog(context, ref),
                )
              else
                const Icon(Icons.chevron_right,
                    color: AppColors.textHint, size: 20),
            ],
          ),
        ),
          ],
        ),
      ),
    );
  }
}


class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textHint,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final String name;
  final bool isLeader;
  const _MemberTile({required this.name, required this.isLeader});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: isLeader ? AppColors.secondaryLight : AppColors.primaryLight,
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            color: isLeader ? AppColors.secondary : AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
      title: Text(name, style: const TextStyle(fontSize: 14)),
      trailing: isLeader
          ? Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.secondaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Líder',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;
  const _Badge(
      {required this.label, required this.color, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
