import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/asone_loader.dart';
import '../../magasinier/repositories/material_repository.dart';

final damagesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  return ref.watch(materialRepositoryProvider).listDamages();
});

class DamagesScreen extends ConsumerWidget {
  const DamagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(damagesProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Dommages & sanctions')),
      body: async.when(
        loading: () => const AsOneLoader(),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('Aucun dommage signalé'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final d = list[i];
              final sanctioned = d['sanction'] != null;
              return Card(
                child: ListTile(
                  isThreeLine: true,
                  title: Text(
                    '${d['refCode'] ?? ''} ${d['itemName'] ?? ''}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    '${d['siteName']} · ${d['ficheCode']}\n'
                    'Livré ${d['qtyDelivered']}  ·  retour ${d['qtyReturned']}  ·  manquant ${d['qtyMissing']}\n'
                    '${d['returnState'] ?? ''} ${d['isLost'] == true ? 'PERTE' : ''}'
                    '${d['returnNotes'] != null ? ' · ${d['returnNotes']}' : ''}',
                  ),
                  trailing: sanctioned
                      ? Chip(
                          label: Text(
                              '${(d['sanction'] as Map)['amount']} F'),
                          backgroundColor: AppColors.warningLight,
                        )
                      : FilledButton(
                          onPressed: () => _sanction(context, ref, d),
                          child: const Text('Sanction'),
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _sanction(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> d,
  ) async {
    final amount = TextEditingController(
      text: ((d['unitPrice'] as num?) ?? 0).toStringAsFixed(0),
    );
    final reason = TextEditingController(
      text: '${d['itemName']} — ${d['siteName']}',
    );
    var target = 'WHOLE_GROUP';
    String? agentId;
    List<dynamic> agents = [];
    try {
      final res =
          await ref.read(apiClientProvider).dio.get('/users', queryParameters: {
        'role': 'AGENT',
      });
      agents = res.data as List<dynamic>;
    } catch (_) {}

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (ctx, setSt) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Appliquer une retenue',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                        value: 'ONE_AGENT', label: Text('1 agent')),
                    ButtonSegment(
                        value: 'WHOLE_GROUP', label: Text('Équipe')),
                  ],
                  selected: {target},
                  onSelectionChanged: (s) => setSt(() => target = s.first),
                ),
                if (target == 'ONE_AGENT')
                  DropdownButtonFormField<String>(
                    value: agentId,
                    decoration:
                        const InputDecoration(labelText: 'Agent responsable'),
                    items: agents
                        .map((a) => DropdownMenuItem(
                              value: a['id'] as String,
                              child: Text(
                                  '${a['firstName'] ?? ''} ${a['lastName'] ?? ''}'),
                            ))
                        .toList(),
                    onChanged: (v) => setSt(() => agentId = v),
                  ),
                TextField(
                  controller: amount,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Montant (F CFA)'),
                ),
                TextField(
                  controller: reason,
                  decoration: const InputDecoration(labelText: 'Motif'),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Déduire de la paie'),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (ok != true) return;
    await ref.read(materialRepositoryProvider).applySanction(
          lineId: d['lineId'] as String,
          target: target,
          amount: double.tryParse(amount.text) ?? 0,
          agentId: agentId,
          reason: reason.text,
        );
    ref.invalidate(damagesProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Retenue appliquée')),
      );
    }
  }
}
