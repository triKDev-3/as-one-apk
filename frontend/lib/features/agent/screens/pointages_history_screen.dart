import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/providers.dart';

// ─── Model ─────────────────────────────────────────────────────────────────
class PointageRecord {
  final String id;
  final DateTime notedAt;
  final String type;
  final String siteName;
  final String siteType;

  const PointageRecord({
    required this.id,
    required this.notedAt,
    required this.type,
    required this.siteName,
    required this.siteType,
  });

  factory PointageRecord.fromJson(Map<String, dynamic> j) => PointageRecord(
        id: j['id'] as String,
        notedAt: DateTime.parse((j['date'] ?? j['notedAt']) as String),
        type: j['type'] as String? ?? 'DEPART',
        siteName: (j['siteName'] as String?) ??
            (j['site'] is Map ? (j['site']['name'] as String?) : null) ??
            'Chantier',
        siteType: '',
      );
}

// ─── Provider ─────────────────────────────────────────────────────────────
final agentPointagesProvider =
    FutureProvider.autoDispose<List<PointageRecord>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final res = await api.dio.get('/agent/pointages');
    final list = res.data as List<dynamic>;
    return list
        .map((e) => PointageRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  } on DioException catch (e) {
    throw ApiClient.extractError(e);
  }
});

// ─── Screen ───────────────────────────────────────────────────────────────
class PointagesHistoryScreen extends ConsumerWidget {
  const PointagesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pointagesAsync = ref.watch(agentPointagesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Historique des pointages'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: pointagesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    color: AppColors.danger, size: 40),
                const SizedBox(height: 12),
                Text(e.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(agentPointagesProvider),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
        data: (pointages) {
          if (pointages.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.assignment_late_outlined,
                      size: 56, color: AppColors.textTertiary),
                  SizedBox(height: 16),
                  Text(
                    'Aucun pointage enregistré',
                    style: TextStyle(
                        fontSize: 15, color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          final Map<String, List<PointageRecord>> grouped = {};
          for (final p in pointages) {
            final key = DateFormat('MMMM yyyy', 'fr').format(p.notedAt);
            grouped.putIfAbsent(key, () => []).add(p);
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(agentPointagesProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: grouped.length,
              itemBuilder: (ctx, i) {
                final month = grouped.keys.elementAt(i);
                final records = grouped[month]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10, top: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 18,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${month.toUpperCase()} · ${records.length} jours',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...records.map((p) => _PointageTile(record: p)),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _PointageTile extends StatelessWidget {
  final PointageRecord record;

  const _PointageTile({required this.record});

  @override
  Widget build(BuildContext context) {
    String label = 'Départ';
    Color color = AppColors.accent;
    IconData icon = Icons.logout_rounded;

    switch (record.type) {
      case 'ABSENT':
        label = 'Absent';
        color = AppColors.danger;
        icon = Icons.person_off_rounded;
        break;
      case 'ARRIVEE':
        label = 'Arrivée';
        color = AppColors.primary;
        icon = Icons.login_rounded;
        break;
      case 'PRESENCE_PERMANENCE':
        label = 'Présence';
        color = AppColors.primary;
        icon = Icons.fingerprint_rounded;
        break;
      case 'DEPART':
      default:
        label = 'Départ';
        color = AppColors.accent;
        icon = Icons.logout_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.siteName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('EEEE d MMMM · HH:mm', 'fr')
                        .format(record.notedAt.toLocal()),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
