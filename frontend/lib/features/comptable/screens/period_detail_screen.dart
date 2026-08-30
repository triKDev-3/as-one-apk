import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../comptable_home_screen.dart';

final periodDetailProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, id) {
  return ref.watch(payrollRepositoryProvider).getPeriod(id);
});

class PeriodDetailScreen extends ConsumerStatefulWidget {
  final String periodId;

  const PeriodDetailScreen({super.key, required this.periodId});

  @override
  ConsumerState<PeriodDetailScreen> createState() => _PeriodDetailScreenState();
}

class _PeriodDetailScreenState extends ConsumerState<PeriodDetailScreen> {
  bool _validating = false;

  Future<void> _validate() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Valider la paie ?'),
        content: const Text(
          'Cette action est définitive (réservée à la Direction). Continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _validating = true);
    try {
      await ref
          .read(payrollRepositoryProvider)
          .validatePeriod(widget.periodId);
      ref.invalidate(periodDetailProvider(widget.periodId));
      ref.invalidate(payrollPeriodsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Période validée'),
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
      if (mounted) setState(() => _validating = false);
    }
  }

  Future<void> _adjustLine(Map<String, dynamic> line) async {
    final primesCtrl = TextEditingController(
      text: '${line['primes'] ?? 0}',
    );
    final retenuesCtrl = TextEditingController(
      text: '${line['retenues'] ?? 0}',
    );

    final result = await showDialog<Map<String, double>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          '${line['agent']?['firstName'] ?? ''} ${line['agent']?['lastName'] ?? ''}',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: primesCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Primes (FCFA)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: retenuesCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Retenues (FCFA)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx, {
                'primes': double.tryParse(primesCtrl.text) ?? 0,
                'retenues': double.tryParse(retenuesCtrl.text) ?? 0,
              });
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (result == null) return;

    try {
      await ref.read(payrollRepositoryProvider).adjustLine(
            lineId: line['id'] as String,
            primes: result['primes'],
            retenues: result['retenues'],
          );
      ref.invalidate(periodDetailProvider(widget.periodId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final periodAsync = ref.watch(periodDetailProvider(widget.periodId));
    final userRole = ref.watch(authProvider).user?.role;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Détail période'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: periodAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (period) {
          final status = period['status'] as String? ?? '';
          final lines = (period['lines'] as List<dynamic>?) ?? [];
          final canValidate =
              userRole == 'ADMIN' && status != 'VALIDATED' && status != 'PAID';

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_fmt(period['startDate'])} → ${_fmt(period['endDate'])}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: lines.isEmpty
                    ? const Center(child: Text('Aucune ligne de paie'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: lines.length,
                        itemBuilder: (context, i) {
                          final line = lines[i] as Map<String, dynamic>;
                          final agent =
                              line['agent'] as Map<String, dynamic>? ?? {};
                          final name =
                              '${agent['firstName'] ?? ''} ${agent['lastName'] ?? ''}'
                                  .trim();
                          final net = line['netAmount'];
                          final base = line['baseAmount'];
                          final primes = line['primes'];
                          final retenues = line['retenues'];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: status == 'VALIDATED' || status == 'PAID'
                                    ? null
                                    : () => _adjustLine(line),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name.isEmpty ? 'Agent' : name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Base $base · +$primes · −$retenues',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '$net F',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              if (canValidate)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton(
                      onPressed: _validating ? null : _validate,
                      child: _validating
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Valider définitivement (Direction)'),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _fmt(dynamic d) {
    final s = d?.toString() ?? '';
    return s.length >= 10 ? s.substring(0, 10) : s;
  }
}
