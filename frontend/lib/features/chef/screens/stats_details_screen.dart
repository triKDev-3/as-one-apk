import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/network/api_client.dart';

final statsDetailsProvider = FutureProvider.autoDispose.family<List<dynamic>, String>((ref, type) async {
  final api = ref.watch(apiClientProvider);
  final viewAll = ref.watch(viewAllProvider);
  try {
    final response = await api.dio.get('/stats/agents-details', queryParameters: {
      'type': type,
      'all': viewAll.toString(),
    });
    return response.data as List<dynamic>;
  } on DioException catch (e) {
    throw ApiClient.extractError(e);
  }
});

class StatsDetailsScreen extends ConsumerWidget {
  final String statType;

  const StatsDetailsScreen({super.key, required this.statType});

  String _getTitle() {
    switch (statType) {
      case 'total_agents':
        return 'Agents actifs';
      case 'available_agents':
        return 'Agents disponibles';
      case 'busy_agents':
        return 'Agents occupés';
      case 'pending_assignments':
        return 'Affectations en attente';
      case 'today_pointages':
        return 'Pointages du jour';
      default:
        return 'Détails';
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'SUR_CHANTIER':
        return AppColors.primary;
      case 'INDISPONIBLE':
        return AppColors.danger;
      default:
        return AppColors.accent;
    }
  }

  String _statusLabel(String? status, String? currentSite) {
    switch (status) {
      case 'SUR_CHANTIER':
        return 'Sur chantier${currentSite != null ? ' : $currentSite' : ''}';
      case 'INDISPONIBLE':
        return 'Indisponible';
      default:
        return 'Disponible';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(statsDetailsProvider(statType));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_getTitle()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: detailsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(err.toString())),
        data: (users) {
          if (users.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline, size: 56, color: AppColors.textTertiary),
                  SizedBox(height: 12),
                  Text('Aucun agent trouvé.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(statsDetailsProvider(statType)),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              itemBuilder: (context, i) {
                final u = users[i] as Map<String, dynamic>;
                final name = '${u['firstName'] ?? ''} ${u['lastName'] ?? ''}'.trim();
                final phone = u['phone'] as String? ?? '';
                final agentType = u['agentType'] as String? ?? 'AGENT';
                final status = u['status'] as String?;
                final currentSite = u['currentSite'] as String?;
                final statusColor = _statusColor(status);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(name,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Text('$agentType · $phone',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _statusLabel(status, currentSite),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.info_outline_rounded,
                          color: AppColors.textSecondary, size: 20),
                      tooltip: 'Détail',
                      onPressed: () {
                        // Future: navigate to agent detail
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                          builder: (_) => Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800, fontSize: 18)),
                                const SizedBox(height: 6),
                                Text('Type : $agentType',
                                    style: const TextStyle(color: AppColors.textSecondary)),
                                Text('Téléphone : $phone',
                                    style: const TextStyle(color: AppColors.textSecondary)),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _statusLabel(status, currentSite),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
