import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/providers.dart';

class MonthlyPaySummary {
  final String monthKey;
  final int daysWorked;
  final double totalAmount;
  final bool isPaid;
  final String? paidAt;
  final List<Map<String, dynamic>> details;

  const MonthlyPaySummary({
    required this.monthKey,
    required this.daysWorked,
    required this.totalAmount,
    required this.isPaid,
    this.paidAt,
    this.details = const [],
  });

  factory MonthlyPaySummary.fromJson(Map<String, dynamic> j) =>
      MonthlyPaySummary(
        monthKey: j['monthKey'] as String,
        daysWorked: (j['daysWorked'] as num?)?.toInt() ?? 0,
        totalAmount: (j['totalAmount'] as num?)?.toDouble() ?? 0,
        isPaid: j['isPaid'] as bool? ?? false,
        paidAt: j['paidAt'] as String?,
        details: (j['details'] as List<dynamic>?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList() ??
            [],
      );

  String get displayMonth {
    final parts = monthKey.split('-');
    if (parts.length != 2) return monthKey;
    final date = DateTime(int.parse(parts[0]), int.parse(parts[1]));
    return DateFormat('MMMM yyyy', 'fr').format(date);
  }
}

final agentRemunerationProvider =
    FutureProvider.autoDispose<List<MonthlyPaySummary>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final res = await api.dio.get('/agent/remuneration');
    final list = res.data as List<dynamic>;
    return list
        .map((e) => MonthlyPaySummary.fromJson(e as Map<String, dynamic>))
        .toList();
  } on DioException catch (e) {
    throw ApiClient.extractError(e);
  }
});

class RemunerationScreen extends ConsumerStatefulWidget {
  const RemunerationScreen({super.key});

  @override
  ConsumerState<RemunerationScreen> createState() => _RemunerationScreenState();
}

class _RemunerationScreenState extends ConsumerState<RemunerationScreen> {
  final Set<String> _markingPaid = {};

  Future<void> _markAsPaid(MonthlyPaySummary summary) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(summary.displayMonth),
        content: Text(
          'Marquer ce mois comme payé ?\n\n'
          'Montant : ${_formatAmount(summary.totalAmount)} FCFA\n'
          'Jours travaillés : ${summary.daysWorked}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              minimumSize: const Size(160, 44),
            ),
            child: const Text('Marquer payé'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _markingPaid.add(summary.monthKey));
    try {
      final api = ref.read(apiClientProvider);
      await api.dio.post(
        '/agent/remuneration/mark-paid',
        data: {'monthKey': summary.monthKey},
      );
      ref.invalidate(agentRemunerationProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mois marqué comme payé'),
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
      if (mounted) setState(() => _markingPaid.remove(summary.monthKey));
    }
  }

  String _formatAmount(double amount) {
    return NumberFormat('#,##0', 'fr').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(agentRemunerationProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Rémunération'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    color: AppColors.danger, size: 40),
                const SizedBox(height: 12),
                Text(e.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(agentRemunerationProvider),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
        data: (months) {
          if (months.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_balance_wallet_outlined,
                      size: 56, color: AppColors.textTertiary),
                  SizedBox(height: 16),
                  Text(
                    'Aucune donnée de rémunération',
                    style: TextStyle(
                        fontSize: 15, color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          final totalUnpaid = months
              .where((m) => !m.isPaid)
              .fold(0.0, (sum, m) => sum + m.totalAmount);

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(agentRemunerationProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E3A5F), Color(0xFF005C9C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total non payé',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_formatAmount(totalUnpaid)} FCFA',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${months.where((m) => !m.isPaid).length} mois en attente',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Détail par mois',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                ...months.map((m) => _MonthCard(
                      summary: m,
                      formatAmount: _formatAmount,
                      isMarkingPaid: _markingPaid.contains(m.monthKey),
                      onMarkPaid: () => _markAsPaid(m),
                    )),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MonthCard extends StatelessWidget {
  final MonthlyPaySummary summary;
  final String Function(double) formatAmount;
  final bool isMarkingPaid;
  final VoidCallback onMarkPaid;

  const _MonthCard({
    required this.summary,
    required this.formatAmount,
    required this.isMarkingPaid,
    required this.onMarkPaid,
  });

  @override
  Widget build(BuildContext context) {
    final isPaid = summary.isPaid;
    final surface = Theme.of(context).colorScheme.surface;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPaid
              ? AppColors.accent.withValues(alpha: 0.3)
              : AppColors.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    summary.displayMonth.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPaid
                        ? AppColors.accent.withValues(alpha: 0.12)
                        : AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPaid
                            ? Icons.check_circle_rounded
                            : Icons.schedule_rounded,
                        size: 13,
                        color: isPaid ? AppColors.accent : AppColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isPaid ? 'Payé' : 'En attente',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isPaid ? AppColors.accent : AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _StatChip(
                  icon: Icons.calendar_today_rounded,
                  label: '${summary.daysWorked} jours',
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                _StatChip(
                  icon: Icons.account_balance_wallet_rounded,
                  label: '${formatAmount(summary.totalAmount)} FCFA',
                  color: AppColors.secondary,
                ),
              ],
            ),
            if (!isPaid) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isMarkingPaid ? null : onMarkPaid,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: isMarkingPaid
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Marquer comme payé'),
                ),
              ),
            ],
            if (isPaid && summary.paidAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Payé le ${DateFormat('dd/MM/yyyy').format(DateTime.parse(summary.paidAt!))}',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textTertiary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
