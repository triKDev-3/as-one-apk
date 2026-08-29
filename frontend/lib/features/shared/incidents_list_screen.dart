import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/providers.dart';
import '../../core/network/api_client.dart';
import 'package:dio/dio.dart';

final incidentsListProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final res = await api.dio.get('/incidents');
    return res.data as List<dynamic>;
  } on DioException catch (e) {
    throw ApiClient.extractError(e);
  }
});

class IncidentsListScreen extends ConsumerWidget {
  final bool canCreate;
  final bool canResolve;
  final String reportRoute;

  const IncidentsListScreen({
    super.key,
    this.canCreate = false,
    this.canResolve = false,
    this.reportRoute = '/chef/incident',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(incidentsListProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Incidents'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () async {
                await context.push(reportRoute);
                ref.invalidate(incidentsListProvider);
              },
              backgroundColor: AppColors.danger,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Signaler',
                  style: TextStyle(color: Colors.white)),
            )
          : null,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(e.toString(), textAlign: TextAlign.center),
              ElevatedButton(
                onPressed: () => ref.invalidate(incidentsListProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (rows) {
          if (rows.isEmpty) {
            return const Center(child: Text('Aucun incident'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(incidentsListProvider),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: rows.length,
              itemBuilder: (_, i) {
                final p = rows[i] as Map<String, dynamic>;
                final site = p['site'] as Map<String, dynamic>? ?? {};
                final by = p['reportedBy'] as Map<String, dynamic>? ?? {};
                final status = p['status'] as String? ?? 'OUVERT';
                final severity = p['severity'] as String? ?? 'MOYENNE';
                final open = status == 'OUVERT' || status == 'EN_COURS';
                final color = !open
                    ? AppColors.accent
                    : (severity == 'HAUTE'
                        ? AppColors.danger
                        : AppColors.warning);
                final created =
                    DateTime.tryParse(p['createdAt'] as String? ?? '');
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              site['name'] as String? ?? 'Site',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 15),
                            ),
                          ),
                          Text(
                            status,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(p['description'] as String? ?? '',
                          style: const TextStyle(fontSize: 13)),
                      const SizedBox(height: 8),
                      Text(
                        '${p['type'] ?? ''} · ${by['firstName'] ?? ''} ${by['lastName'] ?? ''}'
                        '${created != null ? ' · ${DateFormat('dd/MM HH:mm').format(created.toLocal())}' : ''}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),
                      if (canResolve && open)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () async {
                              try {
                                await ref.read(apiClientProvider).dio.patch(
                                      '/incidents/${p['id']}/resolve',
                                    );
                                ref.invalidate(incidentsListProvider);
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(e.toString()),
                                      backgroundColor: AppColors.danger,
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Text('Marquer résolu'),
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
