import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../repositories/sites_repository.dart';

final sitesListProvider = FutureProvider.autoDispose<List<SiteModel>>((ref) {
  final viewAll = ref.watch(viewAllProvider);
  return ref.watch(sitesRepositoryProvider).getSites(
        all: viewAll,
        includeInactive: true,
      );
});

class SelectSiteScreen extends ConsumerWidget {
  const SelectSiteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sitesAsync = ref.watch(sitesListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mes sites'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: sitesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(err.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(sitesListProvider),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
        data: (sites) {
          if (sites.isEmpty) {
            return const Center(child: Text('Aucun site disponible'));
          }

          final myId = ref.read(authProvider).user?.id ?? '';
          final viewAll = ref.watch(viewAllProvider);

          final active = sites.where((s) => s.isActive).toList();
          final closed = sites.where((s) => !s.isActive).toList();

          final activeChantiers =
              active.where((s) => s.type == 'CHANTIER' || s.type == 'ROUTINE').toList();
          final activePermanences =
              active.where((s) => s.type == 'PERMANENCE').toList();

          int mineFirst(SiteModel a, SiteModel b) {
            final aIsMine = a.chefIds.contains(myId) ? 0 : 1;
            final bIsMine = b.chefIds.contains(myId) ? 0 : 1;
            return aIsMine.compareTo(bIsMine);
          }

          activeChantiers.sort(mineFirst);
          activePermanences.sort(mineFirst);
          closed.sort(mineFirst);

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(sitesListProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Sites actifs pour les opérations. Historique = sites clôturés (relance possible).',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                if (activeChantiers.isNotEmpty) ...[
                  _SectionTitle(
                      title: 'Chantiers actifs', count: activeChantiers.length),
                  const SizedBox(height: 8),
                  ...activeChantiers.map(
                    (s) => _SiteTile(
                      site: s,
                      isMine: !viewAll || s.chefIds.contains(myId),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                if (activePermanences.isNotEmpty) ...[
                  _SectionTitle(
                      title: 'Permanences actives',
                      count: activePermanences.length),
                  const SizedBox(height: 8),
                  ...activePermanences.map(
                    (s) => _SiteTile(
                      site: s,
                      isMine: !viewAll || s.chefIds.contains(myId),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                if (closed.isNotEmpty) ...[
                  _SectionTitle(
                    title: 'Historique (clôturés)',
                    count: closed.length,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 8),
                  ...closed.map(
                    (s) => _SiteTile(
                      site: s,
                      isMine: !viewAll || s.chefIds.contains(myId),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final int count;
  final Color? color;

  const _SectionTitle({
    required this.title,
    required this.count,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: c,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _SiteTile extends StatelessWidget {
  final SiteModel site;
  final bool isMine;

  const _SiteTile({required this.site, this.isMine = false});

  @override
  Widget build(BuildContext context) {
    final isPermanence = site.isPermanence;
    final color = site.isClosed
        ? AppColors.textSecondary
        : (isPermanence ? AppColors.secondary : AppColors.primary);
    final borderColor = site.isClosed
        ? AppColors.border
        : (isMine ? const Color(0xFF10B981) : AppColors.border);
    final borderWidth = isMine && site.isActive ? 2.0 : 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: site.isClosed
            ? AppColors.background
            : (isMine
                ? const Color(0xFF10B981).withValues(alpha: 0.04)
                : Colors.white),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            // Agenda si actif, sinon fiche détail (historique + relance)
            if (site.isActive) {
              context.push('/chef/site/${site.id}/agenda', extra: site);
            } else {
              context.push('/chef/site/${site.id}', extra: site);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: borderWidth),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    site.isClosed
                        ? Icons.history_rounded
                        : (isPermanence
                            ? Icons.home_work_outlined
                            : Icons.construction),
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              site.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: site.isClosed
                                    ? AppColors.textSecondary
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (site.isClosed)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.textSecondary
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Clôturé',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            )
                          else if (isMine)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Mon site',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        site.isClosed
                            ? (site.canRelaunch
                                ? 'Historique \u00b7 Relance possible \u2192'
                                : 'Historique des activités \u2192')
                            : (isMine
                                ? 'Agenda & opérations \u2192'
                                : 'Consultation uniquement'),
                        style: TextStyle(
                          fontSize: 12,
                          color: site.isClosed
                              ? AppColors.primary
                              : (isMine ? color : AppColors.warning),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (site.historyCounts.total > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${site.historyCounts.pointages} ptg \u00b7 '
                          '${site.historyCounts.assignments} aff. \u00b7 '
                          '${site.historyCounts.reports} rapport(s)',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    site.typeLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
