import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/providers.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/whatsapp_helper.dart';
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
  final String? date;

  const IncidentsListScreen({
    super.key,
    this.canCreate = false,
    this.canResolve = false,
    this.canApplyPenalty = false,
    this.reportRoute = '/chef/incident',
    this.date,
  });

  bool _matchesDate(Map<String, dynamic> p, String day) {
    final created = DateTime.tryParse(p['createdAt'] as String? ?? '');
    if (created == null) return false;
    final key = DateFormat('yyyy-MM-dd').format(created.toLocal());
    return key == day;
  }

  Future<void> _share(
    BuildContext context,
    List<Map<String, dynamic>> rows,
  ) async {
    final dateLabel = date == null
        ? 'Tous les incidents'
        : DateFormat('dd/MM/yyyy').format(DateTime.parse(date!));
    final text = WhatsAppHelper.dailyIncidentsReport(
      dateLabel: dateLabel,
      rows: rows,
    );

    final action = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Exporter le rapport',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.chat, color: Color(0xFF25D366)),
              title: const Text('Envoyer par WhatsApp'),
              onTap: () => Navigator.pop(ctx, 'wa'),
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('Copier le texte'),
              onTap: () => Navigator.pop(ctx, 'copy'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (action == 'wa') {
      await WhatsAppHelper.openWhatsApp(message: text);
    } else if (action == 'copy') {
      await WhatsAppHelper.copyMessage(text);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rapport copié')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(incidentsListProvider);
    final title = date == null
        ? 'Incidents'
        : 'Incidents du ${DateFormat('dd/MM/yyyy').format(DateTime.parse(date!))}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          async.maybeWhen(
            data: (rows) {
              var filtered = rows
                  .map((e) => Map<String, dynamic>.from(e as Map))
                  .toList();
              if (date != null) {
                filtered =
                    filtered.where((p) => _matchesDate(p, date!)).toList();
              }
              if (filtered.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.ios_share_rounded),
                tooltip: 'Exporter / WhatsApp',
                onPressed: () => _share(context, filtered),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
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
          var filtered = rows
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          if (date != null) {
            filtered =
                filtered.where((p) => _matchesDate(p, date!)).toList();
          }

          if (filtered.isEmpty) {
            return Center(
              child: Text(date == null
                  ? 'Aucun incident'
                  : 'Aucun incident pour cette journée'),
            );
          }

          final Map<String, List<Map<String, dynamic>>> bySite = {};
          for (final p in filtered) {
            final site = p['site'] as Map<String, dynamic>? ?? {};
            final siteName = site['name'] as String? ?? 'Site inconnu';
            bySite.putIfAbsent(siteName, () => []).add(p);
          }
          final siteNames = bySite.keys.toList()..sort();

          return Column(
            children: [
              Material(
                color: Colors.white,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _share(context, filtered),
                          icon: const Icon(Icons.chat, size: 18),
                          label: const Text('WhatsApp'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final dateLabel = date == null
                                ? 'Tous'
                                : DateFormat('dd/MM/yyyy')
                                    .format(DateTime.parse(date!));
                            final text = WhatsAppHelper.dailyIncidentsReport(
                              dateLabel: dateLabel,
                              rows: filtered,
                            );
                            await WhatsAppHelper.copyMessage(text);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Rapport copié')),
                              );
                            }
                          },
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          label: const Text('Copier'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(incidentsListProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                    itemCount: siteNames.length,
                    itemBuilder: (_, i) {
                      final siteName = siteNames[i];
                      final list = bySite[siteName]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: 8, top: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: AppColors.danger,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$siteName · ${list.length}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...list.map(
                            (p) => _IncidentCard(
                              data: p,
                              canResolve: canResolve,
                              canApplyPenalty: canApplyPenalty,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
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
    String? agentId =
        agents.isNotEmpty ? (agents.first.agentId as String) : null;

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
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Un agent'),
                        selected: target == 'ONE_AGENT',
                        onSelected: (_) => setSt(() => target = 'ONE_AGENT'),
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
                    decoration: const InputDecoration(labelText: 'Motif'),
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
