import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../repositories/sites_repository.dart';

final sitesListProvider = FutureProvider.autoDispose<List<SiteModel>>((ref) {
  final viewAll = ref.watch(viewAllProvider);
  return ref.watch(sitesRepositoryProvider).getSites(all: viewAll);
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
            return const Center(
              child: Text('Aucun site disponible'),
            );
          }

          final myId = ref.read(authProvider).user?.id ?? '';

          final chantiers =
              sites.where((s) => s.type == 'CHANTIER').toList();
          final permanences =
              sites.where((s) => s.type == 'PERMANENCE').toList();

          chantiers.sort((a, b) {
            final aIsMine = a.chefIds.contains(myId) ? 0 : 1;
            final bIsMine = b.chefIds.contains(myId) ? 0 : 1;
            return aIsMine.compareTo(bIsMine);
          });
          permanences.sort((a, b) {
            final aIsMine = a.chefIds.contains(myId) ? 0 : 1;
            final bIsMine = b.chefIds.contains(myId) ? 0 : 1;
            return aIsMine.compareTo(bIsMine);
          });

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(sitesListProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Sélectionnez un site pour ouvrir son agenda et ses opérations.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                if (chantiers.isNotEmpty) ...[
                  _SectionTitle(title: 'Chantiers', count: chantiers.length),
                  const SizedBox(height: 8),
                  ...chantiers.map(
                      (s) => _SiteTile(site: s, isMine: s.chefIds.contains(myId))),
                  const SizedBox(height: 20),
                ],
                if (permanences.isNotEmpty) ...[
                  _SectionTitle(
                      title: 'Sites de permanence', count: permanences.length),
                  const SizedBox(height: 8),
                  ...permanences.map(
                      (s) => _SiteTile(site: s, isMine: s.chefIds.contains(myId))),
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

  const _SectionTitle({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: AppColors.primary,
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
    final color = isPermanence ? AppColors.secondary : AppColors.primary;
    final borderColor = isMine ? const Color(0xFF10B981) : AppColors.border;
    final borderWidth = isMine ? 2.0 : 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isMine
            ? const Color(0xFF10B981).withValues(alpha: 0.04)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          // Nouveau flux : site → agenda (pas la fiche ops plate)
          onTap: () {
            context.push('/chef/site/${site.id}/agenda', extra: site);
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
                    isPermanence
                        ? Icons.home_work_outlined
                        : Icons.construction,
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          if (isMine)
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
                        'Agenda & opérations →',
                        style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (site.address != null && site.address!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          site.address!,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
