import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/hero_banner.dart';
import '../../core/widgets/asone_bottom_nav.dart';
import 'agent_repository.dart';

final agentDashboardProvider =
    FutureProvider.autoDispose<AgentDashboard>((ref) async {
  final repo = ref.watch(agentRepositoryProvider);
  return repo.getDashboard();
});

class AgentHomeScreen extends ConsumerStatefulWidget {
  const AgentHomeScreen({super.key});

  @override
  ConsumerState<AgentHomeScreen> createState() => _AgentHomeScreenState();
}

class _AgentHomeScreenState extends ConsumerState<AgentHomeScreen> {
  bool _toggling = false;

  Future<void> _toggleAvailability(bool current) async {
    setState(() => _toggling = true);
    try {
      final newValue = !current;
      final result = await ref
          .read(agentRepositoryProvider)
          .toggleAvailability(newValue);

      ref.read(authProvider.notifier).updateAvailability(result);
      ref.invalidate(agentDashboardProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result
                  ? 'Vous êtes maintenant disponible'
                  : 'Vous êtes maintenant indisponible',
            ),
            backgroundColor: result ? AppColors.accent : AppColors.danger,
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
      if (mounted) setState(() => _toggling = false);
    }
  }

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  Future<void> _respond(String assignmentId, bool accept) async {
    try {
      await ref
          .read(agentRepositoryProvider)
          .respondToAssignment(assignmentId, accept);
      ref.invalidate(agentDashboardProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(accept ? 'Affectation confirmée' : 'Affectation refusée'),
            backgroundColor: accept ? AppColors.accent : AppColors.danger,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(agentDashboardProvider);
    final authUser = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const AsOneBottomNav(role: 'AGENT', currentIndex: 0),
      body: dashboardAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.danger),
                const SizedBox(height: 16),
                Text(err.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => ref.invalidate(agentDashboardProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
        data: (dashboard) {
          final isAvailable = dashboard.isAvailable;
          final name = dashboard.fullName.isNotEmpty
              ? dashboard.fullName
              : (authUser?.fullName ?? 'Agent');

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(agentDashboardProvider),
            child: Column(
              children: [
                HeroBanner(
                  userName: name,
                  roleName: 'Agent de Sécurité / Chantier',
                  subtitle: dashboard.myRank != null
                      ? 'Rang #${dashboard.myRank} au classement général'
                      : 'Membre actif du réseau AS ONE',
                  trailing: IconButton.filledTonal(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    onPressed: _logout,
                  ),
                  bottomContent: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, color: AppColors.warning, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              '${dashboard.rankingScore.toStringAsFixed(1)} / 5.0',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    children: [
                      _AvailabilityToggleCard(
                        isAvailable: isAvailable,
                        loading: _toggling,
                        onTap: () => _toggleAvailability(isAvailable),
                      ).animate().fadeIn().slideY(begin: 0.1, end: 0),
                      const SizedBox(height: 20),
                      if (dashboard.pendingAssignments.isNotEmpty) ...[
                        const Text(
                          'Proposition de mission reçue !',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.danger,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...dashboard.pendingAssignments.map((a) {
                          final id = a['id'] as String;
                          final site = a['site'] as Map<String, dynamic>? ?? {};
                          return CustomCard(
                            padding: const EdgeInsets.all(16),
                            backgroundColor: AppColors.warningLight.withValues(alpha: 0.4),
                            border: Border.all(color: AppColors.warning.withValues(alpha: 0.5), width: 1.5),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  site['name'] as String? ?? 'Chantier',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Confirmez avant 22h pour valider votre place.',
                                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _respond(id, false),
                                        child: const Text('Refuser'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => _respond(id, true),
                                        child: const Text('Accepter'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 24),
                      ],
                      const Text(
                        'Rémunération',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      CustomCard(
                        onTap: () => context.push('/agent/remuneration'),
                        padding: const EdgeInsets.all(18),
                        child: const Row(
                          children: [
                            Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary),
                            SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'Voir le détail par mois →',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Historique des missions',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      if (dashboard.assignments.isEmpty)
                        const CustomCard(
                          padding: EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                          child: Center(
                            child: Text('Aucune mission enregistrée'),
                          ),
                        )
                      else
                        ...dashboard.assignments.map((a) {
                          final site = a['site'] as Map<String, dynamic>? ?? {};
                          final status = a['status'] as String? ?? '';
                          final start = a['startDate'] as String? ?? '';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: CustomCard(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          site['name'] as String? ?? 'Chantier',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          '${site['type'] ?? ''} · ${start.length >= 10 ? start.substring(0, 10) : start}',
                                          style: const TextStyle(color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(status),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AvailabilityToggleCard extends StatelessWidget {
  final bool isAvailable;
  final bool loading;
  final VoidCallback onTap;

  const _AvailabilityToggleCard({
    required this.isAvailable,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isAvailable ? AppColors.accent : AppColors.danger;
    final title = isAvailable ? 'DISPONIBLE POUR MISSION' : 'ACTUELLEMENT INDISPONIBLE';
    final subtitle = isAvailable
        ? 'Vous recevez les propositions de chantiers'
        : 'Touchez pour réactiver votre disponibilité';

    return CustomCard(
      onTap: loading ? null : onTap,
      padding: const EdgeInsets.all(18),
      gradient: LinearGradient(
        colors: isAvailable
            ? [const Color(0xFF047857), const Color(0xFF10B981)]
            : [const Color(0xFF991B1B), const Color(0xFFDC2626)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      customShadow: AppColors.glowShadow(activeColor),
      child: Row(
        children: [
          loading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              : Icon(
                  isAvailable ? Icons.check_circle_rounded : Icons.pause_circle_rounded,
                  color: Colors.white,
                  size: 28,
                ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                Text(subtitle,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
