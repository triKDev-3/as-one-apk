import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/providers.dart';
import '../../core/network/api_client.dart';
import 'package:dio/dio.dart';

final incidentsListProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final res = await api.dio.get('/incidents');
    return res.data as List<dynamic>;
  } on DioException catch (e) {
    throw ApiClient.extractError(e);
  }
});

class IncidentsListScreen extends ConsumerWidget {
  final bool canCreate;
  final bool canResolve;
  final bool canApplyPenalty;
  final String reportRoute;

  const IncidentsListScreen({
    super.key,
    this.canCreate = false,
    this.canResolve = false,
    this.canApplyPenalty = false,
    this.reportRoute = '/chef/incident',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(incidentsListProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Incidents'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () async {
                await context.push(reportRoute);
                ref.invalidate(incidentsListProvider);
              },
              backgroundColor: AppColors.danger,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Signaler',
                  style: TextStyle(color: Colors.white)),
            )
          : null,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(e.toString(), textAlign: TextAlign.center),
              ElevatedButton(
                onPressed: () => ref.invalidate(incidentsListProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (rows) {
          if (rows.isEmpty) {
            return const Center(child: Text('Aucun incident'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(incidentsListProvider),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: rows.length,
              itemBuilder: (_, i) {
                final p = rows[i] as Map<String, dynamic>;
                return _IncidentCard(
                  data: p,
                  canResolve: canResolve,
                  canApplyPenalty: canApplyPenalty,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _IncidentCard extends ConsumerWidget {
  final Map<String, dynamic> data;
  final bool canResolve;
  final bool canApplyPenalty;

  const _IncidentCard({
    required this.data,
    required this.canResolve,
    required this.canApplyPenalty,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final site = data['site'] as Map<String, dynamic>? ?? {};
    final by = data['reportedBy'] as Map<String, dynamic>? ?? {};
    final status = data['status'] as String? ?? 'OUVERT';
    final severity = data['severity'] as String? ?? 'MOYENNE';
    final penalties = (data['penalties'] as List<dynamic>?) ?? [];
    final open = status == 'OUVERT' || status == 'EN_COURS';
    final color = !open
        ? AppColors.accent
        : (severity == 'HAUTE' ? AppColors.danger : AppColors.warning);
    final created = DateTime.tryParse(data['createdAt'] as String? ?? '');
    final totalPen = penalties.fold<double>(0, (s, e) {
      final m = e as Map<String, dynamic>;
      return s + ((m['amount'] as num?)?.toDouble() ?? 0);
    });

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  site['name'] as String? ?? 'Site',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
              Text(
                status,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(data['description'] as String? ?? '',
              style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 8),
          Text(
            '${data['type'] ?? ''} · ${by['firstName'] ?? ''} ${by['lastName'] ?? ''}'
            '${created != null ? ' · ${DateFormat('dd/MM HH:mm').format(created.toLocal())}' : ''}',
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary),
          ),
          if (penalties.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Pénalités : ${NumberFormat.decimalPattern('fr').format(totalPen)} F',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.danger,
              ),
            ),
          ],
          if (canApplyPenalty || (canResolve && open))
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (canApplyPenalty)
                  TextButton.icon(
                    onPressed: () => _applyPenalty(context, ref),
                    icon: const Icon(Icons.payments_outlined, size: 18),
                    label: const Text('Pénalité'),
                  ),
                if (canResolve && open)
                  TextButton(
                    onPressed: () async {
                      try {
                        await ref
                            .read(apiClientProvider)
                            .dio
                            .patch('/incidents/${data['id']}/resolve');
                        ref.invalidate(incidentsListProvider);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                              backgroundColor: AppColors.danger,
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Marquer résolu'),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _applyPenalty(BuildContext context, WidgetRef ref) async {
    final siteId = data['siteId'] as String? ??
        (data['site'] as Map?)?['id'] as String?;
    List<dynamic> agents = [];
    if (siteId != null) {
      try {
        agents = await ref
            .read(assignmentsRepositoryProvider)
            .getBySite(siteId);
      } catch (_) {}
    }

    if (!context.mounted) return;
    final amountCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    String target = 'ONE_AGENT';
    String? agentId = agents.isNotEmpty
        ? (agents.first.agentId as String)
        : null;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSt) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                20 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Appliquer une pénalité',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Un agent'),
                        selected: target == 'ONE_AGENT',
                        onSelected: (_) =>
                            setSt(() => target = 'ONE_AGENT'),
                      ),
                      ChoiceChip(
                        label: const Text('Toute l’équipe'),
                        selected: target == 'WHOLE_GROUP',
                        onSelected: (_) =>
                            setSt(() => target = 'WHOLE_GROUP'),
                      ),
                    ],
                  ),
                  if (target == 'ONE_AGENT') ...[
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: agentId,
                      items: [
                        for (final a in agents)
                          DropdownMenuItem(
                            value: a.agentId as String,
                            child: Text(a.agentName as String),
                          ),
                      ],
                      onChanged: (v) => setSt(() => agentId = v),
                      decoration:
                          const InputDecoration(labelText: 'Agent'),
                    ),
                  ],
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Montant (F CFA)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: reasonCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Motif',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Enregistrer'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (ok != true) return;
    final amount = num.tryParse(amountCtrl.text.replaceAll(' ', ''));
    if (amount == null || amount <= 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Montant invalide'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
      return;
    }
    try {
      await ref.read(apiClientProvider).dio.post(
        '/incidents/${data['id']}/penalty',
        data: {
          'target': target,
          'amount': amount,
          if (target == 'ONE_AGENT') 'agentId': agentId,
          if (reasonCtrl.text.trim().isNotEmpty)
            'reason': reasonCtrl.text.trim(),
        },
      );
      ref.invalidate(incidentsListProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pénalité appliquée'),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }
}
