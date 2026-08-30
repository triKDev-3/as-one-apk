import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/google_calendar_service.dart';
import '../agent_home_screen.dart';
import 'package:dio/dio.dart';

// ─── Models ──────────────────────────────────────────────────────────────────
enum DayStatus { worked, unavailable, availableMarked, routine, normal }

class AgentCalendarDay {
  final DateTime date;
  final DayStatus status;
  final String? siteName;

  const AgentCalendarDay({
    required this.date,
    required this.status,
    this.siteName,
  });
}

// ─── Provider ─────────────────────────────────────────────────────────────────
final agentCalendarProvider = FutureProvider.autoDispose.family<
    Map<String, AgentCalendarDay>, String>((ref, monthKey) async {
  final api = ref.watch(apiClientProvider);
  try {
    final res = await api.dio.get('/agent/calendar', queryParameters: {'month': monthKey});
    final data = res.data as Map<String, dynamic>;
    final Map<String, AgentCalendarDay> result = {};
    for (final entry in data.entries) {
      final d = entry.value as Map<String, dynamic>;
      final dateStr = entry.key;
      final date = DateTime.tryParse(dateStr);
      if (date == null) continue;
      DayStatus status;
      switch (d['status'] as String? ?? 'normal') {
        case 'worked':
          status = DayStatus.worked;
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
        default:
          status = DayStatus.normal;
      }
      result[dateStr] = AgentCalendarDay(
        date: date,
        status: status,
        siteName: d['siteName'] as String?,
      );
    }
    return result;
  } on DioException catch (e) {
    throw ApiClient.extractError(e);
  }
});

// ─── Screen ──────────────────────────────────────────────────────────────────
class PlanningScreen extends ConsumerStatefulWidget {
  const PlanningScreen({super.key});

  @override
  ConsumerState<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends ConsumerState<PlanningScreen> {
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime? _selectedDay;

  String get _monthKey => DateFormat('yyyy-MM').format(_focusedDay);

  Future<void> _toggleDayAvailability(DateTime day, Map<String, AgentCalendarDay> calDays) async {
    final key = DateFormat('yyyy-MM-dd').format(day);
    final existing = calDays[key];

    // Only allow toggling future days
    if (!day.isAfter(DateTime.now().subtract(const Duration(days: 1)))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous ne pouvez modifier que les jours à venir')),
      );
      return;
    }

    final isCurrentlyMarkedUnavailable = existing?.status == DayStatus.unavailable;
    final confirmText = isCurrentlyMarkedUnavailable
        ? 'Marquer ce jour comme DISPONIBLE ?'
        : 'Marquer ce jour comme INDISPONIBLE ?';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(DateFormat('EEEE d MMMM yyyy', 'fr').format(day)),
        content: Text(confirmText),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isCurrentlyMarkedUnavailable ? AppColors.accent : AppColors.danger,
            ),
            child: Text(isCurrentlyMarkedUnavailable ? 'Disponible' : 'Indisponible'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final api = ref.read(apiClientProvider);
      await api.dio.post('/agent/availability-mark', data: {
        'date': key,
        'available': isCurrentlyMarkedUnavailable,
      });
      ref.invalidate(agentCalendarProvider(_monthKey));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isCurrentlyMarkedUnavailable
                ? 'Jour marqué disponible'
                : 'Jour marqué indisponible'),
            backgroundColor: isCurrentlyMarkedUnavailable ? AppColors.accent : AppColors.danger,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  bool _syncing = false;

  Future<void> _syncToCalendar() async {
    setState(() => _syncing = true);
    try {
      final dashboard = await ref.read(agentDashboardProvider.future);
      final service = GoogleCalendarService();
      await service.syncPlanningToCalendar(dashboard.assignments.cast<Map<String, dynamic>>());
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
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
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
              padding: EdgeInsets.only(right: 16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.sync_rounded),
              tooltip: 'Synchroniser avec Google Agenda',
              onPressed: _syncToCalendar,
            ),
        ],
      ),
      body: Column(
        children: [
          // Legend
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: const Wrap(
              alignment: WrapAlignment.spaceEvenly,
              spacing: 12,
              runSpacing: 4,
              children: [
                _LegendItem(color: Color(0xFF10B981), label: 'Jour travaillé'),
                _LegendItem(color: AppColors.danger, label: 'Indisponible'),
                _LegendItem(color: AppColors.primary, label: 'Dispo marquée'),
                _LegendItem(color: Color(0xFFF59E0B), label: 'Routine'),
              ],
            ),
          ),
          const Divider(height: 1),

          // Calendar
          calAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(e.toString(), style: const TextStyle(color: AppColors.danger)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(agentCalendarProvider(_monthKey)),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
            data: (calDays) {
              return TableCalendar(
                locale: 'fr_FR',
                firstDay: DateTime(2024),
                lastDay: DateTime(2030),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (d) =>
                    _selectedDay != null && isSameDay(d, _selectedDay),
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  });
                  _toggleDayAvailability(selected, calDays);
                },
                onPageChanged: (focused) {
                  setState(() => _focusedDay = focused);
                },
                onFormatChanged: (f) => setState(() => _calendarFormat = f),
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  todayDecoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.3),
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
                    final key = DateFormat('yyyy-MM-dd').format(day);
                    final info = calDays[key];
                    if (info == null) return null;

                    Color? bgColor;
                    Color textColor = AppColors.textPrimary;
                    switch (info.status) {
                      case DayStatus.worked:
                        bgColor = const Color(0xFF10B981);
                        textColor = Colors.white;
                        break;
                      case DayStatus.unavailable:
                        bgColor = AppColors.danger;
                        textColor = Colors.white;
                        break;
                      case DayStatus.availableMarked:
                        bgColor = AppColors.primary;
                        textColor = Colors.white;
                        break;
                      case DayStatus.routine:
                        bgColor = const Color(0xFFF59E0B); // amber
                        textColor = Colors.white;
                        break;
                      case DayStatus.normal:
                        break;
                    }

                    if (bgColor == null) return null;

                    return Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: bgColor,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),

          // Selected day detail
          if (_selectedDay != null)
            calAsync.maybeWhen(
              data: (calDays) {
                final key = DateFormat('yyyy-MM-dd').format(_selectedDay!);
                final info = calDays[key];
                if (info == null || info.status == DayStatus.normal) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        info.status == DayStatus.worked
                            ? Icons.check_circle_rounded
                            : info.status == DayStatus.unavailable
                                ? Icons.cancel_rounded
                                : info.status == DayStatus.routine
                                    ? Icons.repeat_rounded
                                    : Icons.event_available_rounded,
                        color: info.status == DayStatus.worked
                            ? const Color(0xFF10B981)
                            : info.status == DayStatus.unavailable
                                ? AppColors.danger
                                : info.status == DayStatus.routine
                                    ? const Color(0xFFF59E0B)
                                    : AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('EEEE d MMMM', 'fr').format(_selectedDay!),
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            if (info.siteName != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                info.siteName!,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Appuyez sur un jour futur pour marquer votre disponibilité ou indisponibilité.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
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
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}
