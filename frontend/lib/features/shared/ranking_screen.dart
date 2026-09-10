import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/providers.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/custom_card.dart';

enum RankingSortMode { score, days }

class RankingQuery {
  final RankingSortMode mode;
  final String month; // yyyy-MM
  const RankingQuery(this.mode, this.month);

  @override
  bool operator ==(Object other) =>
      other is RankingQuery && other.mode == mode && other.month == month;

  @override
  int get hashCode => Object.hash(mode, month);
}

final rankingProvider = FutureProvider.autoDispose
    .family<List<dynamic>, RankingQuery>((ref, q) async {
  final api = ref.watch(apiClientProvider);
  final sortBy = q.mode == RankingSortMode.days ? 'days' : 'score';
  try {
    final response = await api.dio.get('/ratings/ranking', queryParameters: {
      'sortBy': sortBy,
      'month': q.month,
    });
    return response.data as List<dynamic>;
  } on DioException catch (e) {
    throw ApiClient.extractError(e);
  }
});

class RankingScreen extends ConsumerStatefulWidget {
  const RankingScreen({super.key});

  @override
  ConsumerState<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends ConsumerState<RankingScreen> {
  RankingSortMode _sortMode = RankingSortMode.score;
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  String get _monthKey => DateFormat('yyyy-MM').format(_month);

  RankingQuery get _query => RankingQuery(_sortMode, _monthKey);

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
    });
  }

  @override
  Widget build(BuildContext context) {
    final rankingAsync = ref.watch(rankingProvider(_query));
    final currentUserId = ref.watch(authProvider).user?.id;
    final monthLabel = DateFormat('MMMM yyyy', 'fr').format(_month);
    final now = DateTime.now();
    final isCurrentMonth =
        _month.year == now.year && _month.month == now.month;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Classement du mois'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          // ── Sort toggle button ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _SortToggle(
              current: _sortMode,
              onChanged: (mode) => setState(() => _sortMode = mode),
            ),
          ),
        ],
      ),
      body: rankingAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 44, color: AppColors.danger),
                const SizedBox(height: 12),
                Text(e.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(rankingProvider(_query)),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.military_tech_outlined, size: 56, color: AppColors.textTertiary),
                  SizedBox(height: 12),
                  Text(
                    'Aucun classement disponible pour le moment',
                    style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }

          final topThree = list.take(3).toList();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(rankingProvider(_query)),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                // Sélecteur de mois
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => _shiftMonth(-1),
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              monthLabel[0].toUpperCase() + monthLabel.substring(1),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              isCurrentMonth ? 'Mois en cours' : 'Mois clôturé',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: isCurrentMonth ? null : () => _shiftMonth(1),
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
                  ),
                ),
                // ── Sort mode info chip ─────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      key: ValueKey(_sortMode),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: (_sortMode == RankingSortMode.score
                                ? AppColors.warning
                                : AppColors.secondary)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: (_sortMode == RankingSortMode.score
                                  ? AppColors.warning
                                  : AppColors.secondary)
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _sortMode == RankingSortMode.score
                                ? Icons.star_rounded
                                : Icons.calendar_today_rounded,
                            size: 14,
                            color: _sortMode == RankingSortMode.score
                                ? AppColors.warning
                                : AppColors.secondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _sortMode == RankingSortMode.score
                                ? 'Trié par note moyenne du mois'
                                : 'Trié par jours travaillés du mois',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _sortMode == RankingSortMode.score
                                  ? AppColors.warning
                                  : AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Top 3 Podium ────────────────────────────────────────
                if (topThree.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                    decoration: BoxDecoration(
                      gradient: AppColors.heroCardGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryDark.withValues(alpha: 0.2),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          _sortMode == RankingSortMode.score
                              ? 'TOP DU MOIS — NOTES'
                              : 'TOP DU MOIS — JOURS TRAVAILLÉS',
                          style: const TextStyle(
                            color: AppColors.secondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (topThree.length > 1)
                              _PodiumAvatar(
                                agent: topThree[1],
                                rank: 2,
                                color: const Color(0xFFC0C0C0),
                                sortMode: _sortMode,
                                isCurrent: topThree[1]['id'] == currentUserId,
                              ),
                            if (topThree.isNotEmpty)
                              _PodiumAvatar(
                                agent: topThree[0],
                                rank: 1,
                                color: const Color(0xFFFFD700),
                                isLarge: true,
                                sortMode: _sortMode,
                                isCurrent: topThree[0]['id'] == currentUserId,
                              ),
                            if (topThree.length > 2)
                              _PodiumAvatar(
                                agent: topThree[2],
                                rank: 3,
                                color: const Color(0xFFCD7F32),
                                sortMode: _sortMode,
                                isCurrent: topThree[2]['id'] == currentUserId,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),
                  const SizedBox(height: 24),
                ],

                const Text(
                  'Tous les agents',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                // ── Agent list ──────────────────────────────────────────
                ...List.generate(list.length, (index) {
                  final a = list[index] as Map<String, dynamic>;
                  final rank = index + 1;
                  final name = '${a['firstName'] ?? ''} ${a['lastName'] ?? ''}'.trim();
                  final score = (a['rankingScore'] as num?)?.toDouble() ?? 0;
                  final days = (a['daysWorked'] as num?)?.toInt() ?? 0;
                  final type = a['agentType'] as String? ?? 'Agent';
                  final isMe = a['id'] == currentUserId;

                  Color medalColor = AppColors.textSecondary;
                  if (rank == 1) medalColor = const Color(0xFFFFD700);
                  if (rank == 2) medalColor = const Color(0xFFC0C0C0);
                  if (rank == 3) medalColor = const Color(0xFFCD7F32);

                  return CustomCard(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    backgroundColor: isMe ? AppColors.secondaryLight.withValues(alpha: 0.6) : Colors.white,
                    border: isMe ? Border.all(color: AppColors.primary, width: 1.5) : null,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 32,
                          child: rank <= 3
                              ? Icon(Icons.military_tech_rounded, color: medalColor, size: 24)
                              : Text(
                                  '#$rank',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: isMe ? AppColors.primaryGradient : null,
                            color: isMe ? null : AppColors.primary.withValues(alpha: 0.1),
                          ),
                          child: Center(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: TextStyle(
                                color: isMe ? Colors.white : AppColors.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isMe ? '$name (Vous)' : name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: isMe ? AppColors.primary : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                type,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Primary badge: current sort criterion
                        _StatBadge(
                          icon: _sortMode == RankingSortMode.score
                              ? Icons.star_rounded
                              : Icons.calendar_today_rounded,
                          color: _sortMode == RankingSortMode.score
                              ? AppColors.warning
                              : AppColors.secondary,
                          label: _sortMode == RankingSortMode.score
                              ? score.toStringAsFixed(1)
                              : '$days j.',
                        ),
                        // Secondary badge: other criterion
                        const SizedBox(width: 6),
                        _StatBadge(
                          icon: _sortMode == RankingSortMode.score
                              ? Icons.calendar_today_rounded
                              : Icons.star_rounded,
                          color: _sortMode == RankingSortMode.score
                              ? AppColors.secondary.withValues(alpha: 0.6)
                              : AppColors.warning.withValues(alpha: 0.6),
                          label: _sortMode == RankingSortMode.score
                              ? '$days j.'
                              : score.toStringAsFixed(1),
                          small: true,
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Reusable badge widget ────────────────────────────────────────────────────
class _StatBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final bool small;

  const _StatBadge({
    required this.icon,
    required this.color,
    required this.label,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 7 : 10,
        vertical: small ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: small ? 12 : 16),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: small ? 11 : 13,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sort toggle widget ───────────────────────────────────────────────────────
class _SortToggle extends StatelessWidget {
  final RankingSortMode current;
  final ValueChanged<RankingSortMode> onChanged;

  const _SortToggle({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleChip(
            icon: Icons.star_rounded,
            label: 'Score',
            selected: current == RankingSortMode.score,
            color: AppColors.warning,
            onTap: () => onChanged(RankingSortMode.score),
          ),
          const SizedBox(width: 3),
          _ToggleChip(
            icon: Icons.calendar_today_rounded,
            label: 'Jours',
            selected: current == RankingSortMode.days,
            color: AppColors.secondary,
            onTap: () => onChanged(RankingSortMode.days),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: selected ? color : AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? color : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Podium avatar ────────────────────────────────────────────────────────────
class _PodiumAvatar extends StatelessWidget {
  final Map<String, dynamic> agent;
  final int rank;
  final Color color;
  final bool isLarge;
  final bool isCurrent;
  final RankingSortMode sortMode;

  const _PodiumAvatar({
    required this.agent,
    required this.rank,
    required this.color,
    required this.sortMode,
    this.isLarge = false,
    this.isCurrent = false,
  });

  @override
  Widget build(BuildContext context) {
    final name = '${agent['firstName'] ?? ''}'.trim();
    final score = (agent['rankingScore'] as num?)?.toDouble() ?? 0;
    final days = (agent['daysWorked'] as num?)?.toInt() ?? 0;
    final size = isLarge ? 56.0 : 46.0;

    return Column(
      children: [
        Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2.5),
                color: Colors.white.withValues(alpha: 0.15),
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isLarge ? 22 : 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        // Show primary metric based on sort mode
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              sortMode == RankingSortMode.score
                  ? Icons.star_rounded
                  : Icons.calendar_today_rounded,
              color: AppColors.warning,
              size: 13,
            ),
            const SizedBox(width: 2),
            Text(
              sortMode == RankingSortMode.score
                  ? score.toStringAsFixed(1)
                  : '$days j.',
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
