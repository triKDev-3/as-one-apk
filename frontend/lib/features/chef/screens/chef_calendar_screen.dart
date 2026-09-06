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

String _kindLabelFr(String kind) {
  switch (kind) {
    case 'assignment':
      return 'Assigné';
    case 'assignment_pending':
      return 'En attente';
    case 'pointage':
      return 'Pointé';
    case 'absent':
      return 'Absent';
    case 'incident':
      return 'Incident';
    default:
      return kind;
  }
}

final chefCalendarProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, monthKey) async {
  final api = ref.watch(apiClientProvider);
  final viewAll = ref.watch(viewAllProvider);
  try {
    final res = await api.dio.get('/stats/calendar', queryParameters: {
      'month': monthKey,
      'all': viewAll.toString(),
    });
    return res.data as Map<String, dynamic>;
  } on DioException catch (e) {
    throw ApiClient.extractError(e);
  }
});

class ChefCalendarScreen extends ConsumerStatefulWidget {
  const ChefCalendarScreen({super.key});

  @override
  ConsumerState<ChefCalendarScreen> createState() =>
      _ChefCalendarScreenState();
}

class _ChefCalendarScreenState extends ConsumerState<ChefCalendarScreen> {
  late DateTime _focused;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focused = now;
    _selected = DateTime(now.year, now.month, now.day); // jour en cours par défaut
  }

  String get _monthKey => DateFormat('yyyy-MM').format(_focused);

  String _basePath(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    if (path.startsWith('/admin')) return '/admin';
    if (path.startsWith('/comptable')) return '/comptable';
    if (path.startsWith('/magasinier')) return '/magasinier';
    return '/chef';
  }

  @override
  Widget build(BuildContext context) {
    final calAsync = ref.watch(chefCalendarProvider(_monthKey));
    final base = _basePath(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Historique'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('$base/notifications'),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: const Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                _Dot(color: AppColors.accent, label: 'Pointages'),
                _Dot(color: AppColors.danger, label: 'Absents / Incidents'),
                _Dot(color: AppColors.warning, label: 'En attente'),
              ],
            ),
          ),
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
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const Divider(height: 1),
          Expanded(
            child: calAsync.maybeWhen(
              data: (data) {
                final key = DateFormat('yyyy-MM-dd').format(_selected);
                final dayMap =
                    (data['days'] as Map<String, dynamic>?)?[key]
                        as Map<String, dynamic>?;
                final events =
                    (dayMap?['events'] as List<dynamic>?) ?? [];
                final summary =
                    (data['summary'] as Map<String, dynamic>?)?[key]
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
                    const SizedBox(height: 8),
                    if (summary != null)
                      Text(
                        '${summary['pointages'] ?? 0} pointage(s) · '
                        '${summary['absents'] ?? 0} absent(s) · '
                        '${summary['incidents'] ?? 0} incident(s) · '
                        '${summary['pending'] ?? 0} en attente',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => context.push(
                              '$base/pointages?date=$key',
                            ),
                            icon: const Icon(Icons.fingerprint),
                            label: const Text('Pointages'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => context.push(
                              '$base/incidents?date=$key',
                            ),
                            icon: const Icon(Icons.warning_amber),
                            label: const Text('Incidents'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (events.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 24),
                        child: Center(
                          child: Text(
                            'Aucune affectation pour ce jour',
                            style:
                                TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      )
                    else ...[
                      if (!events.any((e) {
                        final k = (e as Map)['kind'] as String? ?? '';
                        return k == 'assignment' || k == 'assignment_pending';
                      }))
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Aucune affectation pour ce jour',
                            style: TextStyle(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ...events.map((e) {
                        final m = e as Map<String, dynamic>;
                        final kind = m['kind'] as String? ?? '';
                        final color = kind == 'incident' || kind == 'absent'
                            ? AppColors.danger
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
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      m['label'] as String? ?? '',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700),
                                    ),
                                    if (m['siteName'] != null)
                                      Text(
                                        m['siteName'] as String,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                _kindLabelFr(kind),
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
