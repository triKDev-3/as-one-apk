import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/network/api_client.dart';
import '../repositories/sites_repository.dart';

final siteTasksProvider =
    FutureProvider.autoDispose.family<List<dynamic>, String>((ref, siteId) async {
  final api = ref.watch(apiClientProvider);
  try {
    final r = await api.dio.get('/sites/$siteId/tasks');
    return r.data as List<dynamic>;
  } on DioException catch (e) {
    throw ApiClient.extractError(e);
  }
});

class SiteTasksScreen extends ConsumerStatefulWidget {
  final String siteId;
  final SiteModel? site;

  const SiteTasksScreen({super.key, required this.siteId, this.site});

  @override
  ConsumerState<SiteTasksScreen> createState() => _SiteTasksScreenState();
}

class _SiteTasksScreenState extends ConsumerState<SiteTasksScreen> {
  final _taskCtrl = TextEditingController();
  bool _adding = false;

  Future<void> _addTask() async {
    final text = _taskCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _adding = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.dio.post('/sites/${widget.siteId}/tasks', data: {
        'description': text,
        'performedAt': DateTime.now().toIso8601String(),
      });
      _taskCtrl.clear();
      ref.invalidate(siteTasksProvider(widget.siteId));
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.extractError(e)),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final siteName = widget.site?.name ?? 'Site';
    final tasksAsync = ref.watch(siteTasksProvider(widget.siteId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Tâches — $siteName'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.push('/chef/report/${widget.siteId}', extra: widget.site);
            },
            child: const Text(
              'Clôturer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _taskCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Nouvelle tâche réalisée…',
                      prefixIcon: Icon(Icons.task_alt),
                    ),
                    onSubmitted: (_) => _addTask(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _adding ? null : _addTask,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.accent,
                  ),
                  icon: _adding
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: tasksAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(e.toString())),
              data: (tasks) {
                if (tasks.isEmpty) {
                  return const Center(
                    child: Text('Aucune tâche enregistrée'),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(siteTasksProvider(widget.siteId)),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: tasks.length,
                    itemBuilder: (context, i) {
                      final t = tasks[i] as Map<String, dynamic>;
                      final desc = t['description'] as String? ?? '';
                      final date = t['performedAt'] as String? ?? '';
                      final by = t['createdBy'] as Map<String, dynamic>?;
                      final byName = by != null
                          ? '${by['firstName'] ?? ''} ${by['lastName'] ?? ''}'
                              .trim()
                          : '';
                      String dateLabel = date;
                      try {
                        dateLabel = DateFormat('dd/MM/yyyy HH:mm')
                            .format(DateTime.parse(date));
                      } catch (_) {}

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle,
                                color: AppColors.accent, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    desc,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$dateLabel${byName.isNotEmpty ? ' · $byName' : ''}',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
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
          ),
        ],
      ),
    );
  }
}
