import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../auth/domain/entities/user_entity.dart';
import '../auth/presentation/providers/auth_provider.dart';
import '../churches/presentation/providers/church_provider.dart';
import '../events/presentation/pages/events_page.dart';
import '../events/presentation/providers/event_provider.dart';
import '../members/members_page.dart';
import '../ministries/domain/entities/schedule_entity.dart';
import '../ministries/presentation/pages/ministries_page.dart';
import '../ministries/presentation/pages/schedule_detail_page.dart';
import '../ministries/presentation/providers/ministry_provider.dart';
import '../ministries/presentation/providers/schedule_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateChangesProvider).asData?.value;
    final isAdmin = user?.role == UserRole.admin;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            offset: const Offset(0, 48),
            icon: const CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primaryLight,
              child: Icon(Icons.person, size: 16, color: AppColors.primary),
            ),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18),
                    SizedBox(width: 8),
                    Text(AppStrings.logout),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'logout') {
                ref.read(authNotifierProvider.notifier).signOut();
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: switch (_selectedIndex) {
        1 => const EventsPage(),
        2 => const MinistriesPage(),
        3 => const MembersPage(),
        _ => _buildHomeBody(user?.name ?? 'Usuário', isAdmin, user),
      },
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: AppStrings.schedules,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups_outlined),
            activeIcon: Icon(Icons.groups),
            label: AppStrings.ministries,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: AppStrings.members,
          ),
        ],
      ),
    );
  }

  Widget _buildHomeBody(String userName, bool isAdmin, UserEntity? user) {
    final schedulesAsync = ref.watch(myUpcomingSchedulesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Olá, $userName 👋',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Veja o que acontece esta semana',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          if (isAdmin) ...[
            const SizedBox(height: 20),
            _AdminChurchCard(),
          ],
          const SizedBox(height: 24),
          _buildQuickActions(),
          const SizedBox(height: 24),
          const Text(
            'Minhas Escalas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          schedulesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _buildEmptySchedules(),
            data: (schedules) {
              if (schedules.isEmpty) return _buildEmptySchedules();
              return Column(
                children: schedules
                    .map((s) => _HomeScheduleCard(schedule: s))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final eventsCount =
        ref.watch(churchEventsProvider).asData?.value.length;
    final ministriesCount =
        ref.watch(churchMinistriesProvider).asData?.value.length;
    final membersCount =
        ref.watch(churchMembersProvider).asData?.value.length;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _QuickActionCard(
          icon: Icons.calendar_month,
          label: 'Escalas',
          color: AppColors.primary,
          onTap: () => setState(() => _selectedIndex = 1),
        ),
        _QuickActionCard(
          icon: Icons.event,
          label: 'Eventos',
          color: AppColors.secondary,
          count: eventsCount,
          onTap: () => setState(() => _selectedIndex = 1),
        ),
        _QuickActionCard(
          icon: Icons.groups,
          label: 'Ministérios',
          color: AppColors.warning,
          count: ministriesCount,
          onTap: () => setState(() => _selectedIndex = 2),
        ),
        _QuickActionCard(
          icon: Icons.people,
          label: 'Membros',
          color: AppColors.error,
          count: membersCount,
          onTap: () => setState(() => _selectedIndex = 3),
        ),
      ],
    );
  }

  Widget _buildEmptySchedules() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.event_available_outlined,
                size: 40, color: AppColors.textHint),
            const SizedBox(height: 12),
            const Text(
              'Nenhuma escala nos próximos dias',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Home schedule card ────────────────────────────────────────────────────────

class _HomeScheduleCard extends StatelessWidget {
  final ScheduleEntity schedule;
  const _HomeScheduleCard({required this.schedule});

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('EEE, d MMM', 'pt_BR').format(schedule.eventDate);
    final isToday = DateUtils.isSameDay(schedule.eventDate, DateTime.now());
    final timeLabel = schedule.displayTime;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ScheduleDetailPage(schedule: schedule),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Badge de data
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isToday
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : AppColors.textHint.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isToday ? 'Hoje' : dateLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isToday ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule.eventTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (timeLabel != null) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.access_time_outlined,
                              size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(timeLabel,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Admin church info card ────────────────────────────────────────────────────

class _AdminChurchCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final churchAsync = ref.watch(currentChurchProvider);

    return churchAsync.when(
      loading: () => const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (church) {
        if (church == null) return const SizedBox.shrink();
        return Card(
          color: AppColors.primary,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.church, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        church.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Código de convite',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      church.inviteCode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.white70),
                      tooltip: 'Copiar código',
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: church.inviteCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Código copiado para a área de transferência')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Quick action card ─────────────────────────────────────────────────────────

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final int? count;
  final VoidCallback? onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            // Padrão decorativo no canto direito
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        if (count != null) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
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
}

