import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/hero_banner.dart';

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
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nouvelle période de paie',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Sélectionnez la plage de dates pour le pré-calcul',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              CustomCard(
                onTap: () => Navigator.pop(ctx, 'quinzaine'),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.date_range_rounded, color: AppColors.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Première quinzaine (1–15)',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          Text(
                            '${DateFormat('dd/MM').format(start)} → ${DateFormat('dd/MM').format(mid)}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                  ],
                ),
              ),
              CustomCard(
                onTap: () => Navigator.pop(ctx, 'mois'),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.calendar_month_rounded, color: AppColors.secondary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Deuxième quinzaine (16–Fin)',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          Text(
                            '${DateFormat('dd/MM').format(mid.add(const Duration(days: 1)))} → ${DateFormat('dd/MM').format(endMonth)}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                  ],
                ),
              ),
              CustomCard(
                onTap: () => Navigator.pop(ctx, 'custom'),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.edit_calendar_rounded, color: AppColors.accent),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Période personnalisée',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          Text(
                            'Choisir des dates spécifiques',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                  ],
                ),
              ),
            ],
          ),
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
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: AppColors.glowShadow(AppColors.primary),
        ),
        child: FloatingActionButton.extended(
          onPressed: _creating ? null : _createPeriod,
          backgroundColor: Colors.transparent,
          elevation: 0,
          highlightElevation: 0,
          icon: _creating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text(
            'Nouvelle période',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
      ),
      body: Column(
        children: [
          HeroBanner(
            userName: user?.firstName != null ? '${user!.firstName} ${user.lastName}' : 'Responsable Paie',
            roleName: 'Comptabilité',
            subtitle: 'Générez, vérifiez et validez les virements & décomptes de paie.',
            onLogout: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(payrollPeriodsProvider),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Périodes de paie',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Historique complet',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ).animate().fadeIn().slideX(begin: -0.05, end: 0),
                  const SizedBox(height: 14),
                  periodsAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    ),
                    error: (e, _) => Center(
                      child: Text(
                        e.toString(),
                        style: const TextStyle(color: AppColors.danger),
                      ),
                    ),
                    data: (periods) {
                      if (periods.isEmpty) {
                        return const CustomCard(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textTertiary),
                                SizedBox(height: 12),
                                Text(
                                  'Aucune période de paie enregistrée',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Créez votre première période avec le bouton ci-dessous',
                                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
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
                          String statusLabel = 'BROUILLON';
                          if (status == 'VALIDATED' || status == 'PAID') {
                            statusColor = AppColors.accent;
                            statusLabel = 'VALIDÉ';
                          } else if (status == 'SIMULATION' || status == 'DRAFT') {
                            statusColor = AppColors.warning;
                            statusLabel = 'EN COURS';
                          }

                          return CustomCard(
                            margin: const EdgeInsets.only(bottom: 12),
                            onTap: () => context.push('/comptable/period/$id'),
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    Icons.receipt_long_rounded,
                                    color: statusColor,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$start → $end',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$count agent(s) calculé(s)',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    statusLabel,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: statusColor,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: AppColors.textTertiary),
                              ],
                            ),
                          );
                        }).toList(),
                      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05, end: 0);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
