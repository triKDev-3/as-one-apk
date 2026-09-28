import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../chef/repositories/sites_repository.dart';

final adminSitesListProvider =
    FutureProvider.autoDispose<List<SiteModel>>((ref) {
  return ref.watch(sitesRepositoryProvider).getSites();
});

class AdminSitesScreen extends ConsumerWidget {
  const AdminSitesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sitesAsync = ref.watch(adminSitesListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gestion des sites'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context
            .push('/admin/sites/create')
            .then((_) => ref.invalidate(adminSitesListProvider)),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: sitesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(err.toString())),
        data: (sites) {
          if (sites.isEmpty) {
            return const Center(child: Text('Aucun site.'));
          }

          final withOps = sites.where((s) => s.hasOperations).length;
          final withoutChef = sites.where((s) => !s.hasChefs).length;

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(adminSitesListProvider),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
              itemCount: sites.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _SummaryChip(
                          label: '${sites.length} sites',
                          color: AppColors.primary,
                        ),
                        _SummaryChip(
                          label: '$withOps en opération',
                          color: AppColors.accent,
                        ),
                        _SummaryChip(
                          label: '$withoutChef sans chef',
                          color: withoutChef > 0
                              ? AppColors.warning
                              : AppColors.textSecondary,
                        ),
                      ],
                    ),
                  );
                }
                return _AdminSiteCard(
                  site: sites[i - 1],
                  onChanged: () => ref.invalidate(adminSitesListProvider),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final Color color;
  const _SummaryChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _AdminSiteCard extends ConsumerWidget {
  final SiteModel site;
  final VoidCallback onChanged;

  const _AdminSiteCard({required this.site, required this.onChanged});

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final ok = await context.push('/admin/sites/edit', extra: site);
    if (ok == true) onChanged();
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Désactiver ce site ?'),
        content: Text(
          '« ${site.name} » ne sera plus visible pour les chefs. '
          'L’historique (pointages, affectations) est conservé.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Désactiver'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ref.read(sitesRepositoryProvider).deleteSite(site.id);
      onChanged();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Site « ${site.name} » désactivé'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _manageChefs(BuildContext context, WidgetRef ref) async {
    final api = ref.read(apiClientProvider);
    final repo = ref.read(sitesRepositoryProvider);

    List<dynamic> chefs = [];
    try {
      final response = await api.dio.get('/users');
      final users = response.data as List<dynamic>;
      chefs = users
          .where((u) => u['role'] == 'CHEF' && u['isActive'] == true)
          .toList();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
      return;
    }

    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final assignedIds = site.chefIds.toSet();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chefs — ${site.name}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Plusieurs chefs peuvent être assignés au même site.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                if (chefs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Aucun chef actif.'),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(ctx).size.height * 0.5,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: chefs.length,
                      itemBuilder: (_, i) {
                        final chef = chefs[i] as Map<String, dynamic>;
                        final id = chef['id'] as String;
                        final name =
                            '${chef['firstName'] ?? ''} ${chef['lastName'] ?? ''}'
                                .trim();
                        final already = assignedIds.contains(id);
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            already ? 'Déjà assigné' : 'Appuyer pour assigner',
                            style: TextStyle(
                              fontSize: 12,
                              color: already
                                  ? AppColors.accent
                                  : AppColors.textSecondary,
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              already
                                  ? Icons.remove_circle_outline
                                  : Icons.person_add_alt_1,
                              color: already
                                  ? AppColors.danger
                                  : AppColors.primary,
                            ),
                            onPressed: () async {
                              try {
                                if (already) {
                                  await repo.removeChef(site.id, id);
                                } else {
                                  await repo.assignChef(site.id, id);
                                }
                                if (ctx.mounted) Navigator.pop(ctx);
                                onChanged();
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('$e'),
                                      backgroundColor: AppColors.danger,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Fermer'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showOperations(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final list = site.activeAssignments;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Opérations — ${site.name}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                if (list.isEmpty)
                  const Text('Aucune affectation active.')
                else
                  ...list.map(
                    (a) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(a.agentName,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(a.status),
                    ),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Fermer'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPermanence = site.isPermanence;
    final color = isPermanence ? AppColors.secondary : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: !site.hasChefs
              ? AppColors.warning.withValues(alpha: 0.5)
              : AppColors.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isPermanence
                        ? Icons.home_work_outlined
                        : Icons.construction,
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        site.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '${site.typeLabel}${site.address != null ? ' · ${site.address}' : ''}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    switch (v) {
                      case 'edit':
                        _edit(context, ref);
                        break;
                      case 'chefs':
                        _manageChefs(context, ref);
                        break;
                      case 'ops':
                        _showOperations(context);
                        break;
                      case 'delete':
                        _delete(context, ref);
                        break;
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Modifier'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'chefs',
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.manage_accounts_outlined),
                        title: Text('Gérer les chefs'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'ops',
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.groups_outlined),
                        title: Text('Opérations en cours'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        dense: true,
                        leading: Icon(Icons.block, color: AppColors.danger),
                        title: Text('Désactiver',
                            style: TextStyle(color: AppColors.danger)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              site.chefsLabel,
              style: TextStyle(
                fontSize: 13,
                color: site.hasChefs
                    ? AppColors.textPrimary
                    : AppColors.warning,
                fontWeight:
                    site.hasChefs ? FontWeight.w500 : FontWeight.w600,
              ),
            ),
            if (site.hasOperations) ...[
              const SizedBox(height: 6),
              Text(
                '${site.activeAgentsCount} agent(s) en opération',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (site.dailyRate != null) ...[
              const SizedBox(height: 4),
              Text(
                'Tarif jour : ${site.dailyRate!.toStringAsFixed(0)} FCFA',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
