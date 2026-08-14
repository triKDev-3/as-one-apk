import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/providers.dart';
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
      appBar: AppBar(
        title: const Text('Mon espace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/agent/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off,
                    size: 48, color: AppColors.textSecondary),
                const SizedBox(height: 12),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(agentDashboardProvider),
                  child: const Text('Réessayer'),
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
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bonjour, $name',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dashboard.myRank != null
                        ? 'Classement #${dashboard.myRank} · ${dashboard.rankingScore.toStringAsFixed(1)} ★'
                        : '${dashboard.rankingScore.toStringAsFixed(1)} ★',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 28),
                  _AvailabilityButton(
                    isAvailable: isAvailable,
                    loading: _toggling,
                    onTap: () => _toggleAvailability(isAvailable),
                  ),
                  const SizedBox(height: 20),

                  // Affectations en attente de confirmation
                  if (dashboard.pendingAssignments.isNotEmpty) ...[
                    Text(
                      'À confirmer',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    ...dashboard.pendingAssignments.map((a) {
                      final site = a['site'] as Map<String, dynamic>? ?? {};
                      final id = a['id'] as String;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.warning.withOpacity(0.4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              site['name'] as String? ?? 'Site',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Confirmer avant 22h',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _respond(id, false),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.danger,
                                      side: const BorderSide(color: AppColors.danger),
                                    ),
                                    child: const Text('Refuser'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _respond(id, true),
                                    child: const Text('Confirmer'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],

                  const SizedBox(height: 8),
                  _InfoCard(
                    title: 'Dernier net calculé',
                    value: dashboard.recentPayroll.isNotEmpty
                        ? '${dashboard.recentPayroll.first['netAmount'] ?? '—'} FCFA'
                        : '— FCFA',
                    icon: Icons.account_balance_wallet_outlined,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Actions rapides',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.calendar_today_outlined,
                          label: 'Mes\naffectations',
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.history,
                          label: 'Historique\n& transactions',
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.leaderboard_outlined,
                          label: 'Classement',
                          onTap: () => context.push('/agent/ranking'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Mes affectations',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (dashboard.assignments.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        'Aucune affectation en cours',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ...dashboard.assignments.map((a) {
                      final site =
                          a['site'] as Map<String, dynamic>? ?? {};
                      final status = a['status'] as String? ?? '';
                      final start = a['startDate'] as String? ?? '';
                      return _AssignmentTile(
                        siteName: site['name'] as String? ?? 'Site',
                        type: site['type'] as String? ?? '',
                        date: start.length >= 10
                            ? start.substring(0, 10)
                            : start,
                        status: _statusLabel(status),
                      );
                    }),
                ],
              ),
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

class _AvailabilityButton extends StatelessWidget {
  final bool isAvailable;
  final bool loading;
  final VoidCallback onTap;

  const _AvailabilityButton({
    required this.isAvailable,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isAvailable ? AppColors.accent : AppColors.danger;
    final label = isAvailable ? 'DISPONIBLE' : 'INDISPONIBLE';
    final subtitle = isAvailable
        ? 'Appuyez pour vous déclarer indisponible'
        : 'Appuyez pour vous déclarer disponible';

    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            if (loading)
              const SizedBox(
                height: 36,
                width: 36,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            else
              Icon(
                isAvailable ? Icons.check_circle : Icons.cancel,
                size: 48,
                color: Colors.white,
              ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 42,
            decoration: BoxDecoration(
              color: isPending ? AppColors.warning : AppColors.accent,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  siteName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$type · $date',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (isPending ? AppColors.warning : AppColors.accent)
                  .withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isPending ? AppColors.warning : AppColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
