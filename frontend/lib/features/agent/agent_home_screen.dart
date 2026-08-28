import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/hero_banner.dart';
import 'agent_repository.dart';
import 'screens/planning_screen.dart';
import 'screens/pointages_history_screen.dart';
import 'screens/remuneration_screen.dart';

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
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.dangerLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.danger),
                ),
                const SizedBox(height: 16),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
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
                // Top Hero Banner
                HeroBanner(
                  userName: name,
                  roleName: 'Agent de Sécurité / Chantier',
                  subtitle: dashboard.myRank != null
                      ? 'Rang #${dashboard.myRank} au classement général'
                      : 'Membre actif du réseau AS ONE',
                  trailing: Row(
                    children: [
                      IconButton.filledTonal(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.12),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.person_outline_rounded, size: 20),
                        onPressed: () => context.push('/agent/profile'),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.12),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.logout_rounded, size: 20),
                        onPressed: _logout,
                      ),
                    ],
                  ),
                  bottomContent: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
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
                      const SizedBox(width: 10),
                      if (dashboard.myRank != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.accent.withOpacity(0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.military_tech_rounded, color: AppColors.accent, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'TOP #${dashboard.myRank}',
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

                // Scrollable Body
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    children: [
                      // 1. Availability Status Card (Hero action)
                      _AvailabilityToggleCard(
                        isAvailable: isAvailable,
                        loading: _toggling,
                        onTap: () => _toggleAvailability(isAvailable),
                      ).animate().fadeIn().slideY(begin: 0.1, end: 0),

                      const SizedBox(height: 20),

                      // 2. Pending Mission Confirmation (if any)
                      if (dashboard.pendingAssignments.isNotEmpty) ...[
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.danger.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.notification_important_rounded, color: AppColors.danger, size: 18),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Proposition de mission reçue !',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.danger,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...dashboard.pendingAssignments.map((a) {
                          final id = a['id'] as String;
                          final site = a['site'] as Map<String, dynamic>? ?? {};
                          return CustomCard(
                            padding: const EdgeInsets.all(16),
                            backgroundColor: AppColors.warningLight.withOpacity(0.4),
                            border: Border.all(color: AppColors.warning.withOpacity(0.5), width: 1.5),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        site['name'] as String? ?? 'Chantier',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.warning,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'À CONFIRMER',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  site['address'] as String? ?? 'Confirmez avant 22h pour valider votre place.',
                                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _respond(id, false),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.danger,
                                          side: const BorderSide(color: AppColors.danger),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                        child: const Text('Refuser', style: TextStyle(fontWeight: FontWeight.w700)),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(14),
                                          boxShadow: AppColors.glowShadow(AppColors.accent),
                                        ),
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.accent,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            elevation: 0,
                                          ),
                                          onPressed: () => _respond(id, true),
                                          child: const Text('Accepter & Valider', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
                                        ),
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

                      // 3. Quick Financial Overview Banner
                      const Text(
                        'Rémunération',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      CustomCard(
                        onTap: () => context.push('/agent/remuneration'),
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary.withOpacity(0.15),
                                    AppColors.primary.withOpacity(0.04),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.primary.withOpacity(0.15)),
                              ),
                              child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Suivi mensuel',
                                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Voir le détail par mois →',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                          ],
                        ),
                      ).animate().fadeIn(delay: 200.ms),

                      const SizedBox(height: 24),

                      // 4. Quick Actions Row
                      const Text(
                        'Accès rapides',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _AgentNavCard(
                              icon: Icons.calendar_month_rounded,
                              label: 'Mon planning',
                              color: AppColors.primary,
                              onTap: () => context.push('/agent/planning'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _AgentNavCard(
                              icon: Icons.history_rounded,
                              label: 'Pointages',
                              color: AppColors.secondary,
                              onTap: () => context.push('/agent/pointages'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _AgentNavCard(
                              icon: Icons.emoji_events_rounded,
                              label: 'Classement',
                              color: AppColors.warning,
                              onTap: () => context.push('/agent/ranking'),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),

                      const SizedBox(height: 28),

                      // Upcoming / Current Assignments list
                      const Text(
                        'Historique des missions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (dashboard.assignments.isEmpty)
                        CustomCard(
                          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.assignment_outlined, size: 36, color: AppColors.textTertiary),
                                const SizedBox(height: 8),
                                const Text(
                                  'Aucune mission enregistrée pour le moment',
                                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...dashboard.assignments.map((a) {
                          final site = a['site'] as Map<String, dynamic>? ?? {};
                          final status = a['status'] as String? ?? '';
                          final start = a['startDate'] as String? ?? '';
                          return _AssignmentTile(
                            siteName: site['name'] as String? ?? 'Chantier',
                            type: site['type'] as String? ?? 'Chantier',
                            date: start.length >= 10 ? start.substring(0, 10) : start,
                            status: _statusLabel(status),
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

  String _statusLabel(String status) {
    switch (status) {
      case 'PENDING_CONFIRMATION':
        return 'En attente';
      case 'CONFIRMED':
      case 'LOCKED':
        return 'Confirmé';
      case 'REFUSED':
        return 'Refusé';
      default:
        return status;
    }
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
            ? [const Color(0xFF047857), const Color(0xFF059669), const Color(0xFF10B981)]
            : [const Color(0xFF991B1B), const Color(0xFFDC2626)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      customShadow: AppColors.glowShadow(activeColor),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: loading
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
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              isAvailable ? 'Actif' : 'Changer',
              style: TextStyle(
                color: activeColor,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AgentNavCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AgentNavCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignmentTile extends StatelessWidget {
  final String siteName;
  final String type;
  final String date;
  final String status;

  const _AssignmentTile({
    required this.siteName,
    required this.type,
    required this.date,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = status == 'En attente';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CustomCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 48,
              decoration: BoxDecoration(
                color: isPending ? AppColors.warning : AppColors.accent,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    siteName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$type · $date',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: (isPending ? AppColors.warning : AppColors.accent)
                    .withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isPending ? AppColors.warning : AppColors.accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
