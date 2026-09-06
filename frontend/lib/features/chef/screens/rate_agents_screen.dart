import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../repositories/sites_repository.dart';
import '../repositories/assignments_repository.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';

class RateAgentsScreen extends ConsumerStatefulWidget {
  final String siteId;
  final SiteModel? site;
  final String? date;

  const RateAgentsScreen({
    super.key,
    required this.siteId,
    this.site,
    this.date,
  });

  @override
  ConsumerState<RateAgentsScreen> createState() => _RateAgentsScreenState();
}

class _RateAgentsScreenState extends ConsumerState<RateAgentsScreen> {
  final Map<String, int> _scores = {};
  final Set<String> _submitting = {};
  final Set<String> _done = {};

  Future<void> _submitRating(AssignmentModel a) async {
    final score = _scores[a.agentId] ?? 0;
    if (score < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisissez une note de 1 à 5')),
      );
      return;
    }

    setState(() => _submitting.add(a.agentId));
    try {
      final api = ref.read(apiClientProvider);
      await api.dio.post('/ratings', data: {
        'assignmentId': a.id,
        'agentId': a.agentId,
        'score': score,
      });
      setState(() {
        _done.add(a.agentId);
        _submitting.remove(a.agentId);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${a.agentName} noté $score/5'),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    } on DioException catch (e) {
      setState(() => _submitting.remove(a.agentId));
      if (mounted) {
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
  Widget build(BuildContext context) {
    final siteName = widget.site?.name ?? 'Site';
    final assignmentsAsync =
        ref.watch(siteAssignmentsProvider(widget.siteId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Noter — $siteName'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: assignmentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (assignments) {
          final day = widget.date;
          final active = assignments
              .where((a) =>
                  (a.status == 'CONFIRMED' ||
                      a.status == 'LOCKED' ||
                      a.status == 'COMPLETED') &&
                  (day == null || day.isEmpty || a.coversDate(day)))
              .toList();

          if (active.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  day != null && day.isNotEmpty
                      ? 'Aucune affectation pour ce jour'
                      : 'Aucun agent à noter',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: active.length,
            itemBuilder: (context, index) {
              final a = active[index];
              final score = _scores[a.agentId] ?? 0;
              final done = _done.contains(a.agentId);
              final loading = _submitting.contains(a.agentId);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: done ? AppColors.accent : AppColors.border,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                          child: Text(
                            a.agentName.isNotEmpty
                                ? a.agentName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            a.agentName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (done)
                          const Icon(Icons.check_circle,
                              color: AppColors.accent),
                      ],
                    ),
                    if (!done) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (i) {
                          final star = i + 1;
                          return IconButton(
                            onPressed: loading
                                ? null
                                : () => setState(
                                      () => _scores[a.agentId] = star,
                                    ),
                            icon: Icon(
                              star <= score
                                  ? Icons.star
                                  : Icons.star_border,
                              color: AppColors.warning,
                              size: 32,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: loading ? null : () => _submitRating(a),
                          child: loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Valider la note'),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
