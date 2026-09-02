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

          final withOps =
              sites.where((s) => s.hasOperations).length;
          final withoutChef =
              sites.where((s) => !s.hasChefs).length;

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(adminSitesListProvider),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
              itemCount: sites.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        _SummaryChip(
                          label: '${sites.length} sites',
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        _SummaryChip(
                          label: '$withOps en opération',
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 8),
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
        return StatefulBuilder(
          builder: (ctx, setSt) {
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
                        child: Text('Aucun chef actif dans le système.'),
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
                              leading: CircleAvatar(
                                backgroundColor: already
                                    ? AppColors.accent.withValues(alpha: 0.15)
                                    : AppColors.primary.withValues(alpha: 0.1),
                                child: Icon(
                                  already
                                      ? Icons.check_rounded
                                      : Icons.person_outline,
                                  color: already
                                      ? AppColors.accent
                                      : AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: already
                                      ? AppColors.accent
                                      : AppColors.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                already
                                    ? 'Déjà assigné à ce site'
                                    : 'Appuyer pour assigner',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: already
                                      ? AppColors.accent
                                      : AppColors.textSecondary,
                                ),
                              ),
                              trailing: already
                                  ? IconButton(
                                      tooltip: 'Retirer',
                                      icon: const Icon(Icons.remove_circle_outline,
                                          color: AppColors.danger),
                                      onPressed: () async {
                                        try {
                                          await repo.removeChef(site.id, id);
                                          if (ctx.mounted) Navigator.pop(ctx);
                                          onChanged();
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    '$name retiré du site'),
                                                backgroundColor:
                                                    AppColors.warning,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text('$e'),
                                                backgroundColor:
                                                    AppColors.danger,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                    )
                                  : IconButton(
                                      tooltip: 'Assigner',
                                      icon: const Icon(Icons.person_add_alt_1,
                                          color: AppColors.primary),
                                      onPressed: () async {
                                        try {
                                          await repo.assignChef(site.id, id);
                                          if (ctx.mounted) Navigator.pop(ctx);
                                          onChanged();
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    '$name assigné à ${site.name}'),
                                                backgroundColor:
                                                    AppColors.accent,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text('$e'),
                                                backgroundColor:
                                                    AppColors.danger,
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
                    const SizedBox(height: 8),
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
                  'Opérations en cours — ${site.name}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                if (list.isEmpty)
                  const Text('Aucune affectation active.')
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(ctx).size.height * 0.45,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final a = list[i];
                        final pending =
                            a.status == 'PENDING_CONFIRMATION';
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            pending
                                ? Icons.hourglass_top_rounded
                                : Icons.person_pin_rounded,
                            color: pending
                                ? AppColors.warning
                                : AppColors.accent,
                          ),
                          title: Text(a.agentName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            pending ? 'En attente de confirmation' : a.status,
                            style: TextStyle(
                              fontSize: 12,
                              color: pending
                                  ? AppColors.warning
                                  : AppColors.textSecondary,
                            ),
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
                        site.address ?? site.typeLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Gérer les chefs',
                  icon: const Icon(Icons.manage_accounts_rounded,
                      color: AppColors.primary),
                  onPressed: () => _manageChefs(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Chefs assignés
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  site.hasChefs
                      ? Icons.supervisor_account_rounded
                      : Icons.person_off_outlined,
                  size: 18,
                  color: site.hasChefs
                      ? AppColors.accent
                      : AppColors.warning,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: site.hasChefs
                      ? Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: site.chefs
                              .map(
                                (c) => Chip(
                                  visualDensity: VisualDensity.compact,
                                  label: Text(
                                    c.fullName,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  backgroundColor:
                                      AppColors.accent.withValues(alpha: 0.1),
                                  side: BorderSide.none,
                                ),
                              )
                              .toList(),
                        )
                      : const Text(
                          'Aucun chef assigné — appuyez sur l’icône pour en ajouter',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Opérations en cours
            InkWell(
              onTap: site.hasOperations ? () => _showOperations(context) : null,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: site.hasOperations
                      ? AppColors.accent.withValues(alpha: 0.08)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.engineering_rounded,
                      size: 18,
                      color: site.hasOperations
                          ? AppColors.accent
                          : AppColors.textTertiary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        site.hasOperations
                            ? '${site.activeAgentsCount} agent(s) en opération — voir détail'
                            : 'Aucune opération en cours',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: site.hasOperations
                              ? AppColors.accent
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    if (site.hasOperations)
                      const Icon(Icons.chevron_right,
                          size: 18, color: AppColors.accent),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
