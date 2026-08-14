import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/providers.dart';

final payrollPeriodsProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) {
  return ref.watch(payrollRepositoryProvider).listPeriods();
});

class ComptableHomeScreen extends ConsumerStatefulWidget {
  const ComptableHomeScreen({super.key});

  @override
  ConsumerState<ComptableHomeScreen> createState() =>
      _ComptableHomeScreenState();
}

class _ComptableHomeScreenState extends ConsumerState<ComptableHomeScreen> {
  bool _creating = false;

  Future<void> _createPeriod() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final mid = DateTime(now.year, now.month, 15);
    final endMonth = DateTime(now.year, now.month + 1, 0);

    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_view_week),
              title: const Text('Quinzaine (1–15)'),
              subtitle: Text(
                '${DateFormat('dd/MM').format(start)} → ${DateFormat('dd/MM').format(mid)}',
              ),
              onTap: () => Navigator.pop(ctx, 'quinzaine'),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Fin de mois (16–fin)'),
              subtitle: Text(
                '${DateFormat('dd/MM').format(mid.add(const Duration(days: 1)))} → ${DateFormat('dd/MM').format(endMonth)}',
              ),
              onTap: () => Navigator.pop(ctx, 'mois'),
            ),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('Période personnalisée'),
              onTap: () => Navigator.pop(ctx, 'custom'),
            ),
          ],
        ),
      ),
    );

    if (choice == null || !mounted) return;

    DateTime startDate = start;
    DateTime endDate = mid;

    if (choice == 'mois') {
      startDate = mid.add(const Duration(days: 1));
      endDate = endMonth;
    } else if (choice == 'custom') {
      final s = await showDatePicker(
        context: context,
        initialDate: start,
        firstDate: DateTime(2024),
        lastDate: DateTime.now().add(const Duration(days: 30)),
      );
      if (s == null || !mounted) return;
      final e = await showDatePicker(
        context: context,
        initialDate: s.add(const Duration(days: 14)),
        firstDate: s,
        lastDate: DateTime.now().add(const Duration(days: 60)),
      );
      if (e == null) return;
      startDate = s;
      endDate = e;
    }

    setState(() => _creating = true);
    try {
      final period = await ref.read(payrollRepositoryProvider).createPeriod(
            startDate: DateFormat('yyyy-MM-dd').format(startDate),
            endDate: DateFormat('yyyy-MM-dd').format(endDate),
          );
      ref.invalidate(payrollPeriodsProvider);
      if (!mounted) return;
      final id = period['id'] as String?;
      if (id != null) {
        context.push('/comptable/period/$id');
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
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final periodsAsync = ref.watch(payrollPeriodsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Comptabilité'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _creating ? null : _createPeriod,
        backgroundColor: AppColors.accent,
        icon: _creating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.add),
        label: const Text('Nouvelle période'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(payrollPeriodsProvider),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Bonjour, ${user?.firstName ?? 'Comptable'}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Pré-calcul et validation des paies',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Text(
              'Périodes de paie',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            periodsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Text(e.toString()),
              data: (periods) {
                if (periods.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Text(
                      'Aucune période. Créez-en une avec le bouton +',
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return Column(
                  children: periods.map((p) {
                    final id = p['id'] as String? ?? '';
                    final status = p['status'] as String? ?? '';
                    final start = (p['startDate'] as String? ?? '').length >= 10
                        ? (p['startDate'] as String).substring(0, 10)
                        : '';
                    final end = (p['endDate'] as String? ?? '').length >= 10
                        ? (p['endDate'] as String).substring(0, 10)
                        : '';
                    final count = p['_count']?['lines'] ??
                        (p['lines'] is List ? (p['lines'] as List).length : 0);

                    Color statusColor = AppColors.secondary;
                    if (status == 'VALIDATED' || status == 'PAID') {
                      statusColor = AppColors.accent;
                    } else if (status == 'SIMULATION' || status == 'DRAFT') {
                      statusColor = AppColors.warning;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => context.push('/comptable/period/$id'),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.receipt_long,
                                    color: statusColor,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$start → $end',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$count ligne(s)',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.chevron_right,
                                    color: AppColors.textSecondary),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
