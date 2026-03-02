import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../churches/presentation/providers/church_provider.dart';
import '../../domain/entities/unavailability_entity.dart';
import '../providers/unavailability_provider.dart';
import 'create_unavailability_page.dart';

class UnavailabilityPage extends ConsumerStatefulWidget {
  const UnavailabilityPage({super.key});

  @override
  ConsumerState<UnavailabilityPage> createState() =>
      _UnavailabilityPageState();
}

class _UnavailabilityPageState extends ConsumerState<UnavailabilityPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now(); // Inicia com o dia atual selecionado

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateChangesProvider).asData?.value;
    final unavailabilitiesAsync = ref.watch(churchUnavailabilitiesProvider);
    final membersAsync = ref.watch(churchMembersProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Indisponibilidades', style: TextStyle(fontSize: 18)),
            // Text('Louvor',
            //     style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implementar filtro
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const CreateUnavailabilityPage(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: unavailabilitiesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (unavailabilities) {
          return membersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erro: $e')),
            data: (members) {
              return _buildBody(unavailabilities, members);
            },
          );
        },
      ),
    );
  }

  Widget _buildBody(
      List<UnavailabilityEntity> unavailabilities, List<UserEntity> members) {
    // Mapa de userId -> UserEntity para lookup rápido
    final userMap = {for (var m in members) m.id: m};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Calendário ──────────────────────────────────────────────────
        _buildCalendar(unavailabilities),
        const SizedBox(height: 16),

        // ── Data selecionada (se houver) ────────────────────────────────
        if (_selectedDay != null) ...[
          _buildSelectedDayCard(unavailabilities, userMap),
          const SizedBox(height: 16),
        ],

        // ── Lista de indisponibilidades ─────────────────────────────────
        _buildUnavailabilityList(unavailabilities, userMap),
      ],
    );
  }

  Widget _buildCalendar(List<UnavailabilityEntity> unavailabilities) {
    final monthName = DateFormat('MMMM \'de\' yyyy', 'pt_BR').format(_focusedDay);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header com navegação
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _focusedDay = DateTime(
                        _focusedDay.year,
                        _focusedDay.month - 1,
                      );
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    monthName.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() {
                      _focusedDay = DateTime(
                        _focusedDay.year,
                        _focusedDay.month + 1,
                      );
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Dias da semana
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['dom.', 'seg.', 'ter.', 'qua.', 'qui.', 'sex.', 'sáb.']
                  .map((day) => Expanded(
                        child: Text(
                          day,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            // Grid de dias
            _buildDaysGrid(unavailabilities),
          ],
        ),
      ),
    );
  }

  Widget _buildDaysGrid(List<UnavailabilityEntity> unavailabilities) {
    final firstDay = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    final daysInMonth = lastDay.day;
    final startWeekday = firstDay.weekday % 7; // 0 = domingo

    final List<Widget> dayWidgets = [];

    // Espaços vazios antes do primeiro dia
    for (int i = 0; i < startWeekday; i++) {
      dayWidgets.add(const SizedBox());
    }

    // Dias do mês
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_focusedDay.year, _focusedDay.month, day);
      final hasUnavailability = unavailabilities.any((u) => u.containsDate(date));
      final isToday = _isSameDay(date, DateTime.now());
      final isSelected = _selectedDay != null && _isSameDay(date, _selectedDay!);

      dayWidgets.add(_buildDayCell(day, date, hasUnavailability, isToday, isSelected));
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: dayWidgets,
    );
  }

  Widget _buildDayCell(int day, DateTime date, bool hasMarker, bool isToday, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedDay = date;
        });
      },
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : isToday
                  ? AppColors.primary.withOpacity(0.1)
                  : null,
          shape: BoxShape.circle,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontSize: 13,
                fontWeight: isToday || isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? Colors.white
                    : isToday
                        ? AppColors.primary
                        : AppColors.textPrimary,
              ),
            ),
            if (hasMarker) ...[
              const SizedBox(height: 2),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : AppColors.warning,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildSelectedDayCard(
      List<UnavailabilityEntity> unavailabilities, Map<String, UserEntity> userMap) {
    final fmt = DateFormat('EEEE, d \'de\' MMMM', 'pt_BR');
    final dayUnavailabilities = unavailabilities
        .where((u) => u.containsDate(_selectedDay!))
        .toList();

    return Card(
      elevation: 0,
      color: AppColors.primaryLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.event_busy, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fmt.format(_selectedDay!),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dayUnavailabilities.isEmpty
                        ? 'Nenhuma indisponibilidade'
                        : '${dayUnavailabilities.length} ${dayUnavailabilities.length == 1 ? 'pessoa' : 'pessoas'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
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

  Widget _buildUnavailabilityList(
      List<UnavailabilityEntity> unavailabilities, Map<String, UserEntity> userMap) {
    // Filtra apenas as indisponibilidades do dia selecionado
    final dayUnavailabilities = _selectedDay != null
        ? unavailabilities.where((u) => u.containsDate(_selectedDay!)).toList()
        : <UnavailabilityEntity>[];

    if (dayUnavailabilities.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.event_available_outlined,
                size: 48, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text(
              _selectedDay != null
                  ? 'Nenhuma indisponibilidade neste dia'
                  : 'Selecione um dia no calendário',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    // Agrupa por usuário
    final Map<String, List<UnavailabilityEntity>> byUser = {};
    for (final u in dayUnavailabilities) {
      byUser.putIfAbsent(u.userId, () => []).add(u);
    }

    return Column(
      children: byUser.entries.map((entry) {
        final user = userMap[entry.key];
        final userUnavailabilities = entry.value;

        return _UnavailabilityUserCard(
          user: user,
          unavailabilities: userUnavailabilities,
        );
      }).toList(),
    );
  }
}

// ── Card de indisponibilidade por usuário ─────────────────────────────────────

class _UnavailabilityUserCard extends StatelessWidget {
  final UserEntity? user;
  final List<UnavailabilityEntity> unavailabilities;

  const _UnavailabilityUserCard({
    required this.user,
    required this.unavailabilities,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    final userName = user?.name ?? 'Usuário desconhecido';

    // Pega a primeira indisponibilidade para mostrar no resumo
    final first = unavailabilities.first;
    final periodStr = first.endDate != null && first.isPeriod
        ? '${fmt.format(first.startDate)} a ${fmt.format(first.endDate!)}'
        : fmt.format(first.startDate);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.primaryLight,
            child: Text(
              userName[0].toUpperCase(),
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            userName,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          subtitle: Text(
            periodStr,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          children: unavailabilities.map((u) {
            final period = u.endDate != null && u.isPeriod
                ? '${fmt.format(u.startDate)} a ${fmt.format(u.endDate!)}'
                : fmt.format(u.startDate);

            return ListTile(
              dense: true,
              contentPadding: const EdgeInsets.only(left: 72, right: 16),
              leading: const Icon(Icons.event_busy_outlined,
                  size: 16, color: AppColors.warning),
              title: Text(period, style: const TextStyle(fontSize: 13)),
              subtitle: u.hasTime
                  ? Text('${u.startTime} – ${u.endTime}',
                      style: const TextStyle(fontSize: 11))
                  : null,
            );
          }).toList(),
        ),
      ),
    );
  }
}


