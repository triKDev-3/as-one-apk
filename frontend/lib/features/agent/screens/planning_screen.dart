import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/google_calendar_service.dart';
import '../agent_home_screen.dart';
import 'package:dio/dio.dart';

enum DayStatus {
  worked,
  absent,
  unavailable,
  availableMarked,
  routine,
  assigned,
  assignedPending,
  normal,
}

class AgentCalendarDay {
  final DateTime date;
  final DayStatus status;
  final String? siteName;
  final bool conflict;

  const AgentCalendarDay({
    required this.date,
    required this.status,
    this.siteName,
    this.conflict = false,
  });
}

class AgentCalendarData {
  final Map<String, AgentCalendarDay> days;
  final Map<String, int> stats;
  final List<String> unavailableDates;

  const AgentCalendarData({
    required this.days,
    required this.stats,
    this.unavailableDates = const [],
  });
}

String _ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

final agentCalendarProvider = FutureProvider.autoDispose
    .family<AgentCalendarData, String>((ref, monthKey) async {
  final api = ref.watch(apiClientProvider);
  try {
    final res = await api.dio.get(
      '/agent/calendar',
      queryParameters: {'month': monthKey},
    );
    final raw = res.data as Map<String, dynamic>;

    final Map<String, dynamic> dayMap;
    Map<String, int> stats = {};
    List<String> unavailableDates = [];
    if (raw.containsKey('days') && raw['days'] is Map) {
      dayMap = Map<String, dynamic>.from(raw['days'] as Map);
      final s = raw['stats'] as Map<String, dynamic>? ?? {};
      stats = s.map((k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0));
      unavailableDates = (raw['unavailableDates'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList();
    } else {
      dayMap = raw;
    }

    final Map<String, AgentCalendarDay> result = {};
    for (final entry in dayMap.entries) {
      final d = entry.value as Map<String, dynamic>;
      final date = DateTime.tryParse(entry.key);
      if (date == null) continue;
      DayStatus status;
      switch (d['status'] as String? ?? 'normal') {
        case 'worked':
          status = DayStatus.worked;
          break;
        case 'absent':
          status = DayStatus.absent;
          break;
        case 'unavailable':
          status = DayStatus.unavailable;
          break;
        case 'available_marked':
          status = DayStatus.availableMarked;
          break;
        case 'routine':
          status = DayStatus.routine;
          break;
        case 'assigned':
          status = DayStatus.assigned;
          break;
        case 'assigned_pending':
          status = DayStatus.assignedPending;
          break;
        default:
          status = DayStatus.normal;
      }
      result[entry.key] = AgentCalendarDay(
        date: date,
        status: status,
        siteName: d['siteName'] as String?,
        conflict: d['conflict'] == true,
      );
    }
    return AgentCalendarData(
      days: result,
      stats: stats,
      unavailableDates: unavailableDates,
    );
  } on DioException catch (e) {
    throw ApiClient.extractError(e);
  }
});

class PlanningScreen extends ConsumerStatefulWidget {
  const PlanningScreen({super.key});

  @override
  ConsumerState<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends ConsumerState<PlanningScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  bool _syncing = false;
  bool _marking = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDay = now;
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  String get _monthKey =>
      '${_focusedDay.year}-${_focusedDay.month.toString().padLeft(2, '0')}';

  Future<void> _toggleDayAvailability(
    DateTime day,
    AgentCalendarData data,
  ) async {
    if (_marking) return;

    final key = _ymd(day);
    final existing = data.days[key];

    final today = DateTime.now();
    final dayOnly = DateTime(day.year, day.month, day.day);
    final todayOnly = DateTime(today.year, today.month, today.day);
    if (dayOnly.isBefore(todayOnly)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de modifier un jour déjà passé'),
        ),
      );
      return;
    }

    if (existing?.status == DayStatus.worked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jour déjà travaillé — indisponibilité non modifiable'),
        ),
      );
      return;
    }

    final isUnavailable = existing?.status == DayStatus.unavailable ||
        data.unavailableDates.contains(key);

    // IMPORTANT: utiliser le context du dialogue (go_router),
    // sinon Navigator.pop(context) peut ne rien faire ou fermer la route.
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(key),
          content: Text(
            isUnavailable
                ? 'Marquer ce jour comme DISPONIBLE ?'
                : 'Marquer ce jour comme INDISPONIBLE ?\n\n'
                    'Le chef pourra toujours vous pointer si vous êtes présent.',
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor:
                    isUnavailable ? AppColors.accent : AppColors.danger,
                foregroundColor: Colors.white,
                minimumSize: const Size(140, 44),
              ),
              child: Text(isUnavailable ? 'Disponible' : 'Indisponible'),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) return;

    setState(() => _marking = true);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.dio.post(
        '/agent/availability-mark',
        data: {
          'date': key,
          'available': isUnavailable, // true = repasser dispo
        },
      );

      ref.invalidate(agentCalendarProvider(_monthKey));
      await ref.read(agentCalendarProvider(_monthKey).future);

      if (mounted) {
        final ok = res.data is Map && res.data['success'] == true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ok
                  ? (isUnavailable
                      ? 'Jour marqué disponible'
                      : 'Jour marqué indisponible')
                  : 'Réponse serveur inattendue',
            ),
            backgroundColor:
                isUnavailable ? AppColors.accent : AppColors.danger,
          ),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.extractError(e)),
            backgroundColor: AppColors.danger,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: AppColors.danger,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _marking = false);
    }
  }

  Future<void> _syncToCalendar() async {
    setState(() => _syncing = true);
    try {
      final dashboard = await ref.read(agentDashboardProvider.future);
      final service = GoogleCalendarService();
      await service.syncPlanningToCalendar(
        dashboard.assignments.cast<Map<String, dynamic>>(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Planning synchronisé avec Google Agenda ✅'),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Color? _bg(DayStatus s) {
    switch (s) {
      case DayStatus.worked:
        return const Color(0xFF10B981);
      case DayStatus.absent:
        return const Color(0xFF7F1D1D);
      case DayStatus.unavailable:
        return AppColors.danger;
      case DayStatus.availableMarked:
        return AppColors.primary;
      case DayStatus.routine:
        return const Color(0xFFF59E0B);
      case DayStatus.assigned:
        return AppColors.secondary;
      case DayStatus.assignedPending:
        return AppColors.warning;
      case DayStatus.normal:
        return null;
    }
  }

  String _label(DayStatus s) {
    switch (s) {
      case DayStatus.worked:
        return 'Jour travaillé';
      case DayStatus.absent:
        return 'Absent';
      case DayStatus.unavailable:
        return 'Indisponible';
      case DayStatus.assigned:
        return 'Affecté';
      case DayStatus.assignedPending:
        return 'À confirmer';
      case DayStatus.routine:
        return 'Routine';
      case DayStatus.availableMarked:
        return 'Dispo marquée';
      case DayStatus.normal:
        return 'Libre';
    }
  }

  @override
  Widget build(BuildContext context) {
    final calAsync = ref.watch(agentCalendarProvider(_monthKey));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mon Planning'),
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_syncing)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.sync_rounded),
              tooltip: 'Synchroniser Google Agenda',
              onPressed: _syncToCalendar,
            ),
        ],
      ),
      body: calAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(e.toString(),
                    style: const TextStyle(color: AppColors.danger)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () =>
                      ref.invalidate(agentCalendarProvider(_monthKey)),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
        data: (data) {
          final calDays = data.days;
          final stats = data.stats;

          return Column(
            children: [
              if (stats.isNotEmpty)
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      _StatChip(
                        label: 'Travaillés',
                        value: '${stats['worked'] ?? 0}',
                        color: const Color(0xFF10B981),
                      ),
                      _StatChip(
                        label: 'Affectés',
                        value: '${stats['assigned'] ?? 0}',
                        color: AppColors.secondary,
                      ),
                      _StatChip(
                        label: 'À confirmer',
                        value: '${stats['pending'] ?? 0}',
                        color: AppColors.warning,
                      ),
                      _StatChip(
                        label: 'Indispos',
                        value: '${stats['unavailable'] ?? 0}',
                        color: AppColors.danger,
                      ),
                    ],
                  ),
                ),
              Container(
                color: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: const Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  children: [
                    _LegendItem(color: Color(0xFF10B981), label: 'Travaillé'),
                    _LegendItem(color: AppColors.secondary, label: 'Affecté'),
                    _LegendItem(
                        color: AppColors.warning, label: 'À confirmer'),
                    _LegendItem(
                        color: AppColors.danger, label: 'Indisponible'),
                    _LegendItem(color: Color(0xFFF59E0B), label: 'Routine'),
                  ],
                ),
              ),
              const Divider(height: 1),
              TableCalendar(
                locale: 'fr_FR',
                firstDay: DateTime(2024),
                lastDay: DateTime(2030),
                focusedDay: _focusedDay,
                selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  });
                },
                onPageChanged: (focused) {
                  setState(() => _focusedDay = focused);
                },
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
                  titleTextStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (ctx, day, focusedDay) {
                    final key = _ymd(day);
                    final info = calDays[key];
                    if (info == null) return null;
                    final bgColor = _bg(info.status);
                    if (bgColor == null) return null;
                    return Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: bgColor,
                        shape: BoxShape.circle,
                        border: info.conflict
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${day.day}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _DayDetail(
                  day: _selectedDay,
                  info: calDays[_ymd(_selectedDay)],
                  labelOf: _label,
                  colorOf: _bg,
                  marking: _marking,
                  onToggle: () => _toggleDayAvailability(_selectedDay, data),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DayDetail extends StatelessWidget {
  final DateTime day;
  final AgentCalendarDay? info;
  final String Function(DayStatus) labelOf;
  final Color? Function(DayStatus) colorOf;
  final VoidCallback onToggle;
  final bool marking;

  const _DayDetail({
    required this.day,
    required this.info,
    required this.labelOf,
    required this.colorOf,
    required this.onToggle,
    this.marking = false,
  });

  @override
  Widget build(BuildContext context) {
    final status = info?.status ?? DayStatus.normal;
    final today = DateTime.now();
    final dayOnly = DateTime(day.year, day.month, day.day);
    final todayOnly = DateTime(today.year, today.month, today.day);
    final canEdit =
        !dayOnly.isBefore(todayOnly) && status != DayStatus.worked;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          _ymd(day),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: colorOf(status) ?? AppColors.textTertiary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              labelOf(status),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (info?.conflict == true) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Conflit indispo / mission',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.warning,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (info?.siteName != null) ...[
          const SizedBox(height: 6),
          Text(
            info!.siteName!,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (canEdit)
          FilledButton.icon(
            onPressed: marking ? null : onToggle,
            icon: marking
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    status == DayStatus.unavailable
                        ? Icons.event_available
                        : Icons.event_busy,
                  ),
            style: FilledButton.styleFrom(
              backgroundColor: status == DayStatus.unavailable
                  ? AppColors.accent
                  : AppColors.danger,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
            label: Text(
              marking
                  ? 'Enregistrement…'
                  : status == DayStatus.unavailable
                      ? 'Marquer disponible'
                      : 'Marquer indisponible',
            ),
          ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
