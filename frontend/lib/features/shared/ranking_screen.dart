import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/providers.dart';
import '../../core/network/api_client.dart';

final rankingProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final response = await api.dio.get('/ratings/ranking');
    return response.data as List<dynamic>;
  } on DioException catch (e) {
    throw ApiClient.extractError(e);
  }
});

class RankingScreen extends ConsumerWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingAsync = ref.watch(rankingProvider);
    final currentUserId = ref.watch(authProvider).user?.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Classement des agents'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: rankingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(e.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.invalidate(rankingProvider),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('Aucun classement disponible'));
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(rankingProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final a = list[index] as Map<String, dynamic>;
                final rank = index + 1;
                final name =
                    '${a['firstName'] ?? ''} ${a['lastName'] ?? ''}'.trim();
                final score = (a['rankingScore'] as num?)?.toDouble() ?? 0;
                final type = a['agentType'] as String? ?? '';
                final isMe = a['id'] == currentUserId;

                Color medalColor = AppColors.textSecondary;
                if (rank == 1) medalColor = const Color(0xFFFFD700);
                if (rank == 2) medalColor = const Color(0xFFC0C0C0);
                if (rank == 3) medalColor = const Color(0xFFCD7F32);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isMe
                        ? AppColors.primary.withOpacity(0.08)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isMe ? AppColors.primary : AppColors.border,
                      width: isMe ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 36,
                        child: rank <= 3
                            ? Icon(Icons.emoji_events, color: medalColor)
                            : Text(
                                '#$rank',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                      ),
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primary.withOpacity(0.12),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isMe ? '$name (vous)' : name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isMe
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                            ),
                            if (type.isNotEmpty)
                              Text(
                                type,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star,
                              color: AppColors.warning, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            score.toStringAsFixed(1),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
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
