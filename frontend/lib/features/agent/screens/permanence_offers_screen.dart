import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/network/api_client.dart';

final permanenceOffersProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final res = await api.dio.get('/permanence/offers');
    return res.data as List<dynamic>? ?? [];
  } on DioException catch (e) {
    throw ApiClient.extractError(e);
  }
});

class PermanenceOffersScreen extends ConsumerWidget {
  const PermanenceOffersScreen({super.key});

  Future<void> _apply(BuildContext context, WidgetRef ref, String slotId) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.dio.post('/permanence/slots/$slotId/apply');
      ref.invalidate(permanenceOffersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Candidature envoyée'),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    } on DioException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.extractError(e)),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(permanenceOffersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Offres de permanence'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (offers) {
          if (offers.isEmpty) {
            return const Center(
              child: Text('Aucune offre ouverte pour le moment'),
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(permanenceOffersProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: offers.length,
              itemBuilder: (_, i) {
                final o = offers[i] as Map<String, dynamic>;
                final site = o['site'] as Map<String, dynamic>? ?? {};
                final slots = o['slots'] as List<dynamic>? ?? [];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          site['name'] as String? ?? 'Site',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        Text(
                          '${o['workDaysPerWeek'] ?? 6} jours / semaine',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 10),
                        ...slots.map((sr) {
                          final s = sr as Map<String, dynamic>;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${s['startTime']} – ${s['endTime']}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700),
                                      ),
                                      Text(
                                        '${s['salary']} F · ${s['requiredAgents']} poste(s)',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      _apply(context, ref, s['id'] as String),
                                  child: const Text('Postuler'),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
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
