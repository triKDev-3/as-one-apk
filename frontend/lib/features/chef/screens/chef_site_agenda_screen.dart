import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/asone_loader.dart';
import '../repositories/sites_repository.dart';
import '../../shared/ops_history.dart';
import 'select_site_screen.dart';

final siteCalendarProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, ({String siteId, String month})>((ref, args) async {
  final api = ref.watch(apiClientProvider);
  try {
    final res = await api.dio.get('/stats/calendar', queryParameters: {
      'month': args.month,
      'siteId': args.siteId,
    });
    return res.data as Map<String, dynamic>;
  } on DioException catch (e) {
    throw ApiClient.extractError(e);
  }
});

/// Agenda d'un site : jour sélectionné → opérations du jour.
/// Bouton + en haut qui déploie le menu Ops.
class ChefSiteAgendaScreen extends ConsumerStatefulWidget {
  final String siteId;
  final SiteModel? site;

  const ChefSiteAgendaScreen({
    super.key,
    required this.siteId,
    this.site,
  });

  @override
  ConsumerState<ChefSiteAgendaScreen> createState() =>
      _ChefSiteAgendaScreenState();
}

class _ChefSiteAgendaScreenState extends ConsumerState<ChefSiteAgendaScreen>
    with SingleTickerProviderStateMixin {
  late DateTime _focused;
  late DateTime _selected;
  bool _opsOpen = false;
  late AnimationController _opsCtrl;
  OpsHistoryFilter _filter = OpsHistoryFilter.all;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focused = now;
    _selected = DateTime(now.year, now.month, now.day);
    _opsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  void dispose() {
    _opsCtrl.dispose();
    super.dispose();
  }

  String get _monthKey => DateFormat('yyyy-MM').format(_focused);
  String get _dayKey => DateFormat('yyyy-MM-dd').format(_selected);

  void _toggleOps() {
    setState(() {
      _opsOpen = !_opsOpen;
      if (_opsOpen) {
        _opsCtrl.forward();
      } else {
        _opsCtrl.reverse();
      }
    });
  }

  SiteModel? get _site => widget.site;
  bool get _isPermanence => _site?.isPermanence ?? false;

  void _go(String path, {String? date}) {
    setState(() {
      _opsOpen = false;
      _opsCtrl.reverse();
    });
    final q = date != null && date.isNotEmpty ? '?date=$date' : '';
    context.push('$path$q', extra: _site);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final sites = ref.watch(sitesListProvider).valueOrNull;
    SiteModel? site = widget.site;
    if (site == null && sites != null) {
      for (final s in sites) {
        if (s.id == widget.siteId) {
          site = s;
          break;
        }
      }
    }
    final isMine = user?.isAdmin == true ||
        !ref.watch(viewAllProvider) ||
        (user != null && (site?.chefIds.contains(user.id) ?? false));
    final title = site?.name ?? widget.site?.name ?? 'Agenda site';
    final calAsync = ref.watch(
      siteCalendarProvider((siteId: widget.siteId, month: _monthKey)),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/chef/notifications'),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!isMine)
            Container(
              width: double.infinity,
              color: AppColors.warning.withValues(alpha: 0.12),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline_rounded, color: AppColors.warning),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Consultation uniquement. Vous n\'êtes pas affecté à ce site — les opérations sont bloquées.',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
          Material(
            color: Colors.white,
            elevation: 1,
            child: Column(
              children: [
                InkWell(
                  onTap: _toggleOps,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        AnimatedRotation(
                          turns: _opsOpen ? 0.125 : 0,
                          duration: const Duration(milliseconds: 220),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.add,
                                color: Colors.white, size: 26),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Opérations',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                _opsOpen
                                    ? 'Toucher pour fermer'
                                    : 'Équipe, pointage, notes, rapport…',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          _opsOpen
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
                SizeTransition(
                  sizeFactor: CurvedAnimation(
                    parent: _opsCtrl,
                    curve: Curves.easeOutCubic,
                  ),
                  axisAlignment: -1,
                  child: Container(
                    width: double.infinity,
                    color: AppColors.background,
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (_isPermanence)
                          _OpsChip(
                            icon: Icons.schedule_rounded,
                            label: 'Ops permanence',
                            color: AppColors.secondary,
                            onTap: () => _go(
                                '/chef/permanence/${widget.siteId}',
                                date: _dayKey),
                          ),
                        _OpsChip(
                          icon: Icons.group_add_rounded,
                          label: 'Composer équipe',
                          color: AppColors.primary,
                          onTap: () =>
                              _go('/chef/compose/${widget.siteId}', date: _dayKey),
                        ),
                        _OpsChip(
                          icon: Icons.fact_check_rounded,
                          label: 'Pointage',
                          color: AppColors.accent,
                          onTap: () =>
                              _go('/chef/pointage/${widget.siteId}', date: _dayKey),
                        ),
                        _OpsChip(
                          icon: Icons.star_rate_rounded,
                          label: 'Noter',
                          color: AppColors.warning,
                          onTap: () =>
                              _go('/chef/rate/${widget.siteId}', date: _dayKey),
                        ),
                        _OpsChip(
                          icon: Icons.task_alt_rounded,
                          label: 'Tâches',
                          color: AppColors.accent,
                          onTap: () =>
                              _go('/chef/tasks/${widget.siteId}', date: _dayKey),
                        ),
                        _OpsChip(
                          icon: Icons.assignment_turned_in_rounded,
                          label: 'Rapport fin',
                          color: AppColors.primary,
                          onTap: () =>
                              _go('/chef/report/${widget.siteId}', date: _dayKey),
                        ),
                        _OpsChip(
                          icon: Icons.inventory_2_outlined,
                          label: 'Demande matériel',
                          color: AppColors.primaryDark,
                          onTap: () => _go(
                            '/chef/material/${widget.siteId}',
                            date: _dayKey,
                          ),
                        ),
                        _OpsChip(
                          icon: Icons.warning_amber_rounded,
                          label: 'Incident',
                          color: AppColors.danger,
                          onTap: () => context.push('/chef/incident'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Légende
          Container(
            color: Colors.white,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: const Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                _Dot(color: AppColors.accent, label: 'Pointages'),
                _Dot(color: AppColors.danger, label: 'Absents / Incidents'),
                _Dot(color: AppColors.warning, label: 'En attente'),
                _Dot(color: AppColors.secondary, label: 'Tâches'),
              ],
            ),
          ),

          // Calendrier
          calAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: AsOneLoader(),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text(e.toString(),
                  style: const TextStyle(color: AppColors.danger)),
            ),
            data: (data) {
              final summary =
                  (data['summary'] as Map<String, dynamic>?) ?? {};

              return TableCalendar(
                locale: 'fr_FR',
                firstDay: DateTime(2024),
                lastDay: DateTime(2030),
                focusedDay: _focused,
                selectedDayPredicate: (d) => isSameDay(d, _selected),
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selected = selected;
                    _focused = focused;
                  });
                },
                onPageChanged: (f) => setState(() => _focused = f),
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  todayDecoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: false,
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (ctx, day, events) {
                    final key = DateFormat('yyyy-MM-dd').format(day);
                    final s = summary[key] as Map<String, dynamic>?;
                    if (s == null || s['hasActivity'] != true) {
                      return const SizedBox.shrink();
                    }
                    return Positioned(
                      bottom: 2,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if ((s['pointages'] as num? ?? 0) > 0)
                            const _Mark(AppColors.accent),
                          if ((s['absents'] as num? ?? 0) > 0 ||
                              (s['incidents'] as num? ?? 0) > 0)
                            const _Mark(AppColors.danger),
                          if ((s['pending'] as num? ?? 0) > 0)
                            const _Mark(AppColors.warning),
                          if ((s['tasks'] as num? ?? 0) > 0)
                            const _Mark(AppColors.secondary),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),

          const Divider(height: 1),

          // Opérations du jour sélectionné
          Expanded(
            child: calAsync.maybeWhen(
              data: (data) {
                final dayMap =
                    (data['days'] as Map<String, dynamic>?)?[_dayKey]
                        as Map<String, dynamic>?;
                final events =
                    ((dayMap?['events'] as List<dynamic>?) ?? [])
                        .where((e) => opsHistoryMatches(
                              (e as Map)['kind'] as String? ?? '',
                              _filter,
                            ))
                        .toList();
                final summary =
                    (data['summary'] as Map<String, dynamic>?)?[_dayKey]
                        as Map<String, dynamic>?;

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      DateFormat('EEEE d MMMM yyyy', 'fr').format(_selected),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (summary != null)
                      Text(
                        '${summary['pointages'] ?? 0} présent(s) · '
                        '${summary['absents'] ?? 0} absent(s) · '
                        '${summary['incidents'] ?? 0} incident(s) · '
                        '${summary['tasks'] ?? 0} tâche(s) · '
                        '${summary['pending'] ?? 0} en attente',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    const SizedBox(height: 12),
                    OpsHistoryFilterBar(
                      value: _filter,
                      onChanged: (f) => setState(() => _filter = f),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => context.push(
                            '/chef/pointages?date=$_dayKey',
                          ),
                          icon: const Icon(Icons.fingerprint, size: 18),
                          label: const Text('Pointages'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => context.push(
                            '/chef/incidents?date=$_dayKey',
                          ),
                          icon: const Icon(Icons.warning_amber, size: 18),
                          label: const Text('Incidents'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => context.push(
                            '/chef/taches?date=$_dayKey&siteId=${widget.siteId}',
                          ),
                          icon: const Icon(Icons.task_alt, size: 18),
                          label: const Text('Tâches'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (events.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 32),
                        child: Center(
                          child: Text(
                            opsHistoryEmptyLabel(_filter),
                            style: const TextStyle(
                                color: AppColors.textSecondary),
                          ),
                        ),
                      )
                    else
                      ...events.map((e) {
                        final m = e as Map<String, dynamic>;
                        final kind = m['kind'] as String? ?? '';
                        final color = kind == 'incident' || kind == 'absent'
                            ? AppColors.danger
                            : kind == 'task'
                                ? AppColors.secondary
                                : kind.contains('pending')
                                    ? AppColors.warning
                                    : AppColors.accent;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  m['label'] as String? ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                              Text(
                                opsKindLabelFr(kind),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                );
              },
              orElse: () => const AsOneLoader(),
            ),
          ),
        ],
      ),
    );
  }
}

class _OpsChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OpsChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final String label;
  const _Dot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _Mark extends StatelessWidget {
  final Color color;
  const _Mark(this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
