import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/providers.dart';
import '../../core/network/api_client.dart';
import '../../core/widgets/asone_loader.dart';

final tasksLogProvider = FutureProvider.autoDispose
    .family<List<dynamic>, ({String? date, String? siteId})>((ref, args) async {
  final api = ref.watch(apiClientProvider);
  try {
    final res = await api.dio.get('/tasks', queryParameters: {
      if (args.date != null && args.date!.isNotEmpty) 'date': args.date,
      if (args.siteId != null && args.siteId!.isNotEmpty) 'siteId': args.siteId,
    });
    return res.data as List<dynamic>;
  } on DioException catch (e) {
    throw ApiClient.extractError(e);
  }
});

class TasksLogScreen extends ConsumerWidget {
  final String? date;
  final String? siteId;

  const TasksLogScreen({super.key, this.date, this.siteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tasksLogProvider((date: date, siteId: siteId)));
    final title = date == null
        ? 'Historique des tâches'
        : 'Tâches du ${DateFormat('dd/MM/yyyy').format(DateTime.parse(date!))}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: async.when(
        loading: () => const AsOneLoader(message: 'Chargement des tâches…'),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(e.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(
                  tasksLogProvider((date: date, siteId: siteId)),
                ),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (rows) {
          if (rows.isEmpty) {
            return Center(
              child: Text(
                date == null
                    ? 'Aucune tâche enregistrée'
                    : 'Aucune tâche pour cette journée',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(
              tasksLogProvider((date: date, siteId: siteId)),
            ),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rows.length,
              itemBuilder: (context, i) {
                final t = rows[i] as Map<String, dynamic>;
                final desc = t['description'] as String? ?? '';
                final site = t['site'] as Map<String, dynamic>?;
                final by = t['createdBy'] as Map<String, dynamic>?;
                final byName = by != null
                    ? '${by['firstName'] ?? ''} ${by['lastName'] ?? ''}'.trim()
                    : '';
                String dateLabel = t['performedAt'] as String? ?? '';
                try {
                  dateLabel = DateFormat('dd/MM/yyyy HH:mm')
                      .format(DateTime.parse(dateLabel).toLocal());
                } catch (_) {}

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.task_alt_rounded,
                          color: AppColors.accent, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              desc,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              [
                                if (site?['name'] != null) site!['name'],
                                dateLabel,
                                if (byName.isNotEmpty) byName,
                              ].join(' · '),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
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
