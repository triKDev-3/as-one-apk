import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/network/api_client.dart';

final pendingTransfersProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final r = await api.dio.get('/assignments/transfers/pending');
    return r.data as List<dynamic>;
  } on DioException catch (e) {
    throw ApiClient.extractError(e);
  }
});

class TransfersScreen extends ConsumerWidget {
  const TransfersScreen({super.key});

  Future<void> _resolve(
    WidgetRef ref,
    BuildContext context,
    String id,
    bool accept,
  ) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.dio.patch('/assignments/transfers/$id/resolve', data: {
        'accept': accept,
      });
      ref.invalidate(pendingTransfersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(accept ? 'Transfert accepté' : 'Transfert refusé'),
            backgroundColor: accept ? AppColors.accent : AppColors.danger,
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
    final async = ref.watch(pendingTransfersProvider);
    final myId = ref.watch(authProvider).user?.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Transferts'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('Aucune demande de transfert'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(pendingTransfersProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final t = list[i] as Map<String, dynamic>;
                final assignment =
                    t['assignment'] as Map<String, dynamic>? ?? {};
                final agent =
                    assignment['agent'] as Map<String, dynamic>? ?? {};
                final site =
                    assignment['site'] as Map<String, dynamic>? ?? {};
                final from =
                    t['fromChef'] as Map<String, dynamic>? ?? {};
                final to = t['toChef'] as Map<String, dynamic>? ?? {};
                final id = t['id'] as String;
                final isIncoming = t['toChefId'] == myId;

                final agentName =
                    '${agent['firstName'] ?? ''} ${agent['lastName'] ?? ''}'
                        .trim();
                final fromName =
                    '${from['firstName'] ?? ''} ${from['lastName'] ?? ''}'
                        .trim();
                final toName =
                    '${to['firstName'] ?? ''} ${to['lastName'] ?? ''}'.trim();

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agentName.isEmpty ? 'Agent' : agentName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Site : ${site['name'] ?? '—'}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        isIncoming
                            ? 'De : $fromName'
                            : 'Vers : $toName',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (isIncoming) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    _resolve(ref, context, id, false),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.danger,
                                ),
                                child: const Text('Refuser'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () =>
                                    _resolve(ref, context, id, true),
                                child: const Text('Accepter'),
                              ),
                            ),
                          ],
                        ),
                      ] else
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'En attente de réponse',
                            style: TextStyle(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
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
