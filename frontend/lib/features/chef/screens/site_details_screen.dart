import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../repositories/sites_repository.dart';

class SiteDetailsScreen extends ConsumerWidget {
  final String siteId;
  final SiteModel site;

  const SiteDetailsScreen({
    super.key,
    required this.siteId,
    required this.site,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final isAssigned = user != null && site.chefIds.contains(user.id);
    final isPermanence = site.isPermanence;
    final color = isPermanence ? AppColors.secondary : AppColors.primary;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(site.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isPermanence
                              ? Icons.home_work_outlined
                              : Icons.construction,
                          color: color,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              site.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (site.address != null &&
                                site.address!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                site.address!,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (!isAssigned) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock, color: AppColors.warning),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Vous n\'êtes pas affecté à ce chantier. Les opérations sont désactivées.',
                        style: TextStyle(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            Text(
              'Opérations',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (isPermanence)
              _ActionTile(
                title: 'Ops permanence (créneaux & offres)',
                icon: Icons.schedule_rounded,
                color: AppColors.secondary,
                onTap: isAssigned
                    ? () => context.push(
                          '/chef/permanence/${site.id}',
                          extra: site,
                        )
                    : null,
              ),
            _ActionTile(
              title: 'Composer l\'équipe',
              icon: Icons.group_add,
              color: AppColors.primary,
              onTap: isAssigned
                  ? () =>
                      context.push('/chef/compose/${site.id}', extra: site)
                  : null,
            ),
            _ActionTile(
              title: 'Faire le pointage',
              icon: Icons.fact_check,
              color: AppColors.accent,
              onTap: isAssigned
                  ? () =>
                      context.push('/chef/pointage/${site.id}', extra: site)
                  : null,
            ),
            _ActionTile(
              title: 'Noter les agents',
              icon: Icons.star_rate,
              color: AppColors.warning,
              onTap: isAssigned
                  ? () => context.push('/chef/rate/${site.id}', extra: site)
                  : null,
            ),
            _ActionTile(
              title: 'Journal des tâches',
              icon: Icons.task_alt,
              color: AppColors.accent,
              onTap: isAssigned
                  ? () => context.push('/chef/tasks/${site.id}', extra: site)
                  : null,
            ),
            _ActionTile(
              title: 'Rapport fin de chantier',
              icon: Icons.assignment_turned_in,
              color: AppColors.primary,
              onTap: isAssigned
                  ? () =>
                      context.push('/chef/report/${site.id}', extra: site)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ActionTile({
    required this.title,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(icon, color: isDisabled ? AppColors.textTertiary : color),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDisabled
                          ? AppColors.textTertiary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: isDisabled
                      ? AppColors.textTertiary
                      : AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
