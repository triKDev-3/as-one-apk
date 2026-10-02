import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../repositories/sites_repository.dart';
import 'select_site_screen.dart';

final siteHistoryProvider = FutureProvider.autoDispose
    .family<SiteActivityHistory, String>((ref, siteId) {
  return ref.watch(sitesRepositoryProvider).getActivityHistory(siteId);
});

class SiteDetailsScreen extends ConsumerStatefulWidget {
  final String siteId;
  final SiteModel site;

  const SiteDetailsScreen({
    super.key,
    required this.siteId,
    required this.site,
  });

  @override
  ConsumerState<SiteDetailsScreen> createState() => _SiteDetailsScreenState();
}

class _SiteDetailsScreenState extends ConsumerState<SiteDetailsScreen> {
  bool _relaunching = false;
  late SiteModel _site;

  @override
  void initState() {
    super.initState();
    _site = widget.site;
  }

  Future<void> _relaunch() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Relancer ce site ?'),
        content: Text(
          _site.isPermanence
              ? 'La permanence sera réactivée. Vous pourrez composer une équipe et intervenir.'
              : 'Le chantier sera rouvert pour une intervention / remise en état. Composez ensuite votre équipe.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Relancer'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _relaunching = true);
    try {
      final updated = await ref.read(sitesRepositoryProvider).relaunchSite(
            widget.siteId,
            reason: _site.isPermanence
                ? 'Intervention permanence'
                : 'Remise en état',
          );
      setState(() => _site = updated);
      ref.invalidate(sitesListProvider);
      ref.invalidate(siteHistoryProvider(widget.siteId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _site.isPermanence
                  ? 'Permanence relancée'
                  : 'Chantier relancé — composez l\'\u00e9quipe',
            ),
            backgroundColor: AppColors.accent,
          ),
        );
        // Ouvrir directement la composition d'\u00e9quipe
        context.push('/chef/compose/${widget.siteId}', extra: _site);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _relaunching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isAssigned = user != null && _site.chefIds.contains(user.id);
    final isPermanence = _site.isPermanence;
    final color = isPermanence ? AppColors.secondary : AppColors.primary;
    final historyAsync = ref.watch(siteHistoryProvider(widget.siteId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_site.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_site.isActive)
            IconButton(
              tooltip: 'Agenda',
              icon: const Icon(Icons.calendar_month_rounded),
              onPressed: () => context.push(
                '/chef/site/${widget.siteId}/agenda',
                extra: _site,
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(siteHistoryProvider(widget.siteId));
          final s =
              await ref.read(sitesRepositoryProvider).getSite(widget.siteId);
          setState(() => _site = s);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // En-tête site
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
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
                              _site.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _Badge(
                                  label: _site.typeLabel,
                                  color: color,
                                ),
                                const SizedBox(width: 6),
                                _Badge(
                                  label: _site.statusLabel,
                                  color: _site.isActive
                                      ? AppColors.accent
                                      : AppColors.textSecondary,
                                ),
                              ],
                            ),
                            if (_site.address != null &&
                                _site.address!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                _site.address!,
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

            // Relance (clôturé ou permanence)
            if (isAssigned &&
                (_site.isClosed || _site.isPermanence)) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: _relaunching ? null : _relaunch,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: _relaunching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.restart_alt_rounded),
                  label: Text(
                    _site.isClosed
                        ? 'Relancer (remise en état)'
                        : 'Relancer l\'intervention',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _site.isClosed
                    ? 'Rouvre le site pour composer une équipe et intervenir.'
                    : 'Permet de recomposer l\'\u00e9quipe pour une nouvelle intervention.',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],

            if (!isAssigned) ...[
              const SizedBox(height: 16),
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
                        'Vous n\'\u00eates pas affecté à ce site. Opérations désactivées.',
                        style: TextStyle(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Actions réorganisées (si actif + assigné)
            if (_site.isActive) ...[
              const SizedBox(height: 24),
              Text(
                'Actions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              const Text(
                'Ordre : équipe \u2192 terrain \u2192 suivi \u2192 clôture',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),

              // 1. Équipe
              _SectionLabel('1. Équipe'),
              if (isPermanence)
                _ActionTile(
                  title: 'Ops permanence (créneaux)',
                  subtitle: 'Planning & offres',
                  icon: Icons.schedule_rounded,
                  color: AppColors.secondary,
                  onTap: isAssigned
                      ? () => context.push(
                            '/chef/permanence/${_site.id}',
                            extra: _site,
                          )
                      : null,
                ),
              _ActionTile(
                title: 'Composer l\'\u00e9quipe',
                subtitle: 'Affecter / libérer des agents',
                icon: Icons.group_add_rounded,
                color: AppColors.primary,
                onTap: isAssigned
                    ? () => context.push(
                          '/chef/compose/${_site.id}',
                          extra: _site,
                        )
                    : null,
              ),

              // 2. Terrain
              const SizedBox(height: 8),
              _SectionLabel('2. Terrain'),
              _ActionTile(
                title: 'Pointage',
                subtitle: 'Présence, absence, photo',
                icon: Icons.fact_check_rounded,
                color: AppColors.accent,
                onTap: isAssigned
                    ? () => context.push(
                          '/chef/pointage/${_site.id}',
                          extra: _site,
                        )
                    : null,
              ),
              _ActionTile(
                title: 'Journal des tâches',
                subtitle: 'Travaux réalisés',
                icon: Icons.task_alt_rounded,
                color: AppColors.accent,
                onTap: isAssigned
                    ? () => context.push(
                          '/chef/tasks/${_site.id}',
                          extra: _site,
                        )
                    : null,
              ),
              _ActionTile(
                title: 'Signaler un incident',
                subtitle: 'Type, sévérité, photo',
                icon: Icons.warning_amber_rounded,
                color: AppColors.danger,
                onTap: isAssigned
                    ? () => context.push('/chef/incident')
                    : null,
              ),

              // 3. Suivi
              const SizedBox(height: 8),
              _SectionLabel('3. Suivi'),
              _ActionTile(
                title: 'Noter les agents',
                subtitle: 'Évaluation de performance',
                icon: Icons.star_rate_rounded,
                color: AppColors.warning,
                onTap: isAssigned
                    ? () => context.push(
                          '/chef/rate/${_site.id}',
                          extra: _site,
                        )
                    : null,
              ),
              _ActionTile(
                title: 'Demande de matériel',
                subtitle: 'Fiche magasin',
                icon: Icons.inventory_2_outlined,
                color: AppColors.primaryDark,
                onTap: isAssigned
                    ? () => context.push(
                          '/chef/material/${_site.id}',
                          extra: _site,
                        )
                    : null,
              ),
              _ActionTile(
                title: 'Agenda du site',
                subtitle: 'Calendrier & activités du jour',
                icon: Icons.calendar_month_rounded,
                color: AppColors.secondary,
                onTap: () => context.push(
                  '/chef/site/${_site.id}/agenda',
                  extra: _site,
                ),
              ),

              // 4. Clôture
              const SizedBox(height: 8),
              _SectionLabel('4. Clôture'),
              _ActionTile(
                title: 'Rapport fin de chantier',
                subtitle: 'Bilan pour validation Direction',
                icon: Icons.assignment_turned_in_rounded,
                color: AppColors.primary,
                onTap: isAssigned
                    ? () => context.push(
                          '/chef/report/${_site.id}',
                          extra: _site,
                        )
                    : null,
              ),
            ],

            // Historique des activités
            const SizedBox(height: 28),
            Text(
              'Historique des activités',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            historyAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('$e',
                  style: const TextStyle(color: AppColors.danger)),
              data: (hist) {
                if (hist.items.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'Aucune activité enregistrée sur ce site',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _CountChip(
                            label: 'Affect.', value: hist.counts.assignments),
                        _CountChip(
                            label: 'Pointages', value: hist.counts.pointages),
                        _CountChip(
                            label: 'Incidents', value: hist.counts.incidents),
                        _CountChip(label: 'Tâches', value: hist.counts.tasks),
                        _CountChip(
                            label: 'Rapports', value: hist.counts.reports),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...hist.items.take(40).map((item) {
                      final icon = _kindIcon(item.kind);
                      final c = _kindColor(item.kind);
                      String when = item.at;
                      try {
                        when = DateFormat('dd/MM/yyyy HH:mm')
                            .format(DateTime.parse(item.at).toLocal());
                      } catch (_) {}
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: c.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(icon, size: 18, color: c),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (item.subtitle != null &&
                                      item.subtitle!.isNotEmpty)
                                    Text(
                                      item.subtitle!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  const SizedBox(height: 2),
                                  Text(
                                    when,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (item.status != null)
                              Text(
                                item.status!,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: c,
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  IconData _kindIcon(String kind) {
    switch (kind) {
      case 'assignment':
        return Icons.person_add_alt_1;
      case 'pointage':
        return Icons.fingerprint;
      case 'incident':
        return Icons.warning_amber_rounded;
      case 'task':
        return Icons.task_alt;
      case 'report':
        return Icons.assignment_turned_in;
      case 'material':
        return Icons.inventory_2_outlined;
      default:
        return Icons.circle;
    }
  }

  Color _kindColor(String kind) {
    switch (kind) {
      case 'assignment':
        return AppColors.primary;
      case 'pointage':
        return AppColors.accent;
      case 'incident':
        return AppColors.danger;
      case 'task':
        return AppColors.secondary;
      case 'report':
        return AppColors.primaryDark;
      case 'material':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.textSecondary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  final int value;
  const _CountChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label $value',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ActionTile({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isDisabled ? AppColors.textTertiary : color)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isDisabled ? AppColors.textTertiary : color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isDisabled
                              ? AppColors.textTertiary
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
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
