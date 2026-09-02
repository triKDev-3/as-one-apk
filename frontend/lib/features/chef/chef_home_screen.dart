import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/providers.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/hero_banner.dart';

class LiveStats {
  final int totalAgents;
  final int availableAgents;
  final int busyAgents;
  final int totalChefs;
  final int activeSites;
  final int todayPointages;
  final int openIncidents;
  final int pendingAssignments;
  final DateTime updatedAt;

  const LiveStats({
    required this.totalAgents,
    required this.availableAgents,
    required this.busyAgents,
    required this.totalChefs,
    required this.activeSites,
    required this.todayPointages,
    required this.openIncidents,
    required this.pendingAssignments,
    required this.updatedAt,
  });

  factory LiveStats.fromJson(Map<String, dynamic> j) => LiveStats(
        totalAgents: (j['totalAgents'] as num?)?.toInt() ?? 0,
        availableAgents: (j['availableAgents'] as num?)?.toInt() ?? 0,
        busyAgents: (j['busyAgents'] as num?)?.toInt() ?? 0,
        totalChefs: (j['totalChefs'] as num?)?.toInt() ?? 0,
        activeSites: (j['activeSites'] as num?)?.toInt() ?? 0,
        todayPointages: (j['todayPointages'] as num?)?.toInt() ?? 0,
        openIncidents: (j['openIncidents'] as num?)?.toInt() ?? 0,
        pendingAssignments: (j['pendingAssignments'] as num?)?.toInt() ?? 0,
        updatedAt: DateTime.tryParse(j['updatedAt'] as String? ?? '') ?? DateTime.now(),
      );
}

final liveStatsProvider = StreamProvider.autoDispose<LiveStats>((ref) async* {
  final api = ref.watch(apiClientProvider);
  final viewAll = ref.watch(viewAllProvider);

  Future<LiveStats> fetch() async {
    try {
      final res = await api.dio.get('/stats/live', queryParameters: {'all': viewAll.toString()});
      return LiveStats.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.extractError(e);
    }
  }

  yield await fetch();

  await for (final _ in Stream.periodic(const Duration(seconds: 30))) {
    yield await fetch();
  }
});

final agentsBySiteProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final viewAll = ref.watch(viewAllProvider);
  try {
    final r = await api.dio.get('/stats/agents-by-site', queryParameters: {'all': viewAll.toString()});
    return r.data as List<dynamic>;
  } on DioException catch (e) {
    throw ApiClient.extractError(e);
  }
});

class ChefHomeScreen extends ConsumerStatefulWidget {
  const ChefHomeScreen({super.key});

  @override
  ConsumerState<ChefHomeScreen> createState() => _ChefHomeScreenState();
}

class _ChefHomeScreenState extends ConsumerState<ChefHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final statsAsync = ref.watch(liveStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          HeroBanner(
            userName: user?.firstName != null
                ? '${user!.firstName} ${user.lastName}'
                : 'Chef de Chantier',
            roleName: 'Chef d\'Équipe',
            subtitle: 'Supervisez vos équipes, vos pointages et vos chantiers en temps réel.',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.person_rounded, size: 20),
                  onPressed: () => context.push('/chef/profile'),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  onPressed: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) context.go('/login');
                  },
                ),
              ],
            ),
            bottomContent: CustomCard(
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              borderRadius: 16,
              border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
              onTap: () => context.push('/chef/select-site'),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.apartment_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chantier actif / Permanence',
                          style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Sélectionner ou changer de site',
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
                ],
              ),
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Toutes les activités de l\'entreprise',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Switch(
                  value: ref.watch(viewAllProvider),
                  onChanged: (val) {
                    ref.read(viewAllProvider.notifier).state = val;
                  },
                  activeThumbColor: AppColors.accent,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: 'Tableau de bord'),
                Tab(text: 'Mes équipes'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _DashboardTab(statsAsync: statsAsync),
                const _EquipesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  final AsyncValue<LiveStats> statsAsync;
  const _DashboardTab({required this.statsAsync});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Opérations en temps réel',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            _LiveDot(isConnected: statsAsync.hasValue),
          ],
        ).animate().fadeIn().slideX(begin: -0.05, end: 0),
        const SizedBox(height: 14),
        statsAsync.when(
          loading: () => const _StatsGridSkeleton(),
          error: (_, __) => const SizedBox(),
          data: (stats) => _LiveStatsGrid(stats: stats),
        ),
        const SizedBox(height: 20),
        const Text(
          'Actions rapides',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.1,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _ActionCard(
              icon: Icons.fingerprint_rounded,
              title: 'Mes pointages',
              subtitle: 'Par journée',
              color: AppColors.accent,
              onTap: () => context.push('/chef/select-site'),
            ),
            _ActionCard(
              icon: Icons.star_half_rounded,
              title: 'Mes notations',
              subtitle: 'Évaluer les agents',
              color: AppColors.warning,
              onTap: () => context.push('/chef/select-site'),
            ),
            _ActionCard(
              icon: Icons.warning_amber_rounded,
              title: 'Incidents',
              subtitle: 'Signaler ou consulter',
              color: AppColors.danger,
              onTap: () => context.push('/chef/incidents'),
            ),
            _ActionCard(
              icon: Icons.history_edu_rounded,
              title: 'Interventions',
              subtitle: 'Historique & export',
              color: AppColors.secondary,
              onTap: () => context.push('/chef/interventions'),
            ),
          ],
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 20),
        _TransferCard(onTap: () => context.push('/chef/transfers')),
      ],
    );
  }
}

class _EquipesTab extends ConsumerWidget {
  const _EquipesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sitesAsync = ref.watch(agentsBySiteProvider);

    return sitesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(e.toString(), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.invalidate(agentsBySiteProvider),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
      data: (sites) {
        if (sites.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.business_outlined, size: 56, color: AppColors.textTertiary),
                SizedBox(height: 12),
                Text('Aucun site actif', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(agentsBySiteProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sites.length,
            itemBuilder: (context, i) {
              final site = sites[i] as Map<String, dynamic>;
              final siteName = site['name'] as String? ?? 'Site';
              final siteType = site['type'] as String? ?? 'CHANTIER';
              final agents = site['agents'] as List<dynamic>? ?? [];
              final agentCount = site['agentCount'] as int? ?? agents.length;
              final isPermanence = siteType == 'PERMANENCE';
              final color = isPermanence ? AppColors.secondary : AppColors.primary;

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isPermanence ? Icons.home_work_outlined : Icons.construction,
                              color: color,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(siteName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700, fontSize: 15)),
                                Text(isPermanence ? 'Permanence' : 'Chantier',
                                    style: TextStyle(fontSize: 12, color: color)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$agentCount agent${agentCount > 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (agents.isNotEmpty) ...[
                      const Divider(height: 1),
                      ...agents.take(4).map((a) {
                        final ag = a as Map<String, dynamic>;
                        final name = '${ag['firstName'] ?? ''} ${ag['lastName'] ?? ''}'.trim();
                        final phone = ag['phone'] as String? ?? '';
                        final agentType = ag['agentType'] as String? ?? '';
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: color.withValues(alpha: 0.1),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
                            ),
                          ),
                          title: Text(name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                          subtitle: Text('$agentType · $phone',
                              style: const TextStyle(fontSize: 11)),
                        );
                      }),
                    ] else
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('Aucun agent affecté à ce site',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 13)),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const Spacer(),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransferCard extends StatelessWidget {
  final VoidCallback onTap;
  const _TransferCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.sync_alt_rounded,
                    color: AppColors.secondary, size: 26),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transferts d\'agents',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Demander ou prêter du personnel',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: AppColors.textTertiary, size: 14),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 350.ms);
  }
}

class _LiveDot extends StatefulWidget {
  final bool isConnected;
  const _LiveDot({required this.isConnected});

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.isConnected ? AppColors.accent : AppColors.textTertiary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.4 + 0.6 * _ctrl.value),
            ),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          widget.isConnected ? 'AS ONE Live' : 'Chargement…',
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }
}

class _LiveStatsGrid extends StatelessWidget {
  final LiveStats stats;
  const _LiveStatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _StatTile(
              icon: Icons.group_rounded,
              label: 'Agents actifs',
              value: '${stats.totalAgents}',
              color: AppColors.primary,
              onTap: () => context.push('/chef/stats-details/total_agents'),
            ),
            const SizedBox(width: 10),
            _StatTile(
              icon: Icons.check_circle_rounded,
              label: 'Disponibles',
              value: '${stats.availableAgents}',
              color: AppColors.accent,
              onTap: () =>
                  context.push('/chef/stats-details/available_agents'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _StatTile(
              icon: Icons.apartment_rounded,
              label: 'Sites actifs',
              value: '${stats.activeSites}',
              color: AppColors.secondary,
              onTap: () => context.push('/chef/select-site'),
            ),
            const SizedBox(width: 10),
            _StatTile(
              icon: Icons.fingerprint_rounded,
              label: 'Pointages auj.',
              value: '${stats.todayPointages}',
              color: AppColors.warning,
              onTap: () =>
                  context.push('/chef/stats-details/today_pointages'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _StatTile(
              icon: Icons.pending_actions_rounded,
              label: 'En attente',
              value: '${stats.pendingAssignments}',
              color: AppColors.primary.withValues(alpha: 0.7),
              onTap: () =>
                  context.push('/chef/stats-details/pending_assignments'),
            ),
            const SizedBox(width: 10),
            _StatTile(
              icon: Icons.warning_amber_rounded,
              label: 'Incidents ouverts',
              value: '${stats.openIncidents}',
              color: AppColors.danger,
              onTap: () => context.push('/chef/incidents'),
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 50.ms);
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: color,
                          height: 1,
                        ),
                      ),
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsGridSkeleton extends StatelessWidget {
  const _StatsGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
