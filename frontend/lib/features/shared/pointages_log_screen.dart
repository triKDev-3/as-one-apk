import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/asone_loader.dart';

final pointagesLogProvider =
    FutureProvider.autoDispose.family<List<dynamic>, String?>((ref, date) {
  return ref.watch(pointageRepositoryProvider).list(date: date);
});

class PointagesLogScreen extends ConsumerWidget {
  final String? date;

  const PointagesLogScreen({super.key, this.date});

  /// Libellés métier clairs (DEPART = présence fin de journée)
  String _label(String type) {
    switch (type) {
      case 'DEPART':
        return 'Présent';
      case 'ABSENT':
        return 'Absent';
      case 'PRESENCE_PERMANENCE':
        return 'Présence';
      case 'ARRIVEE':
        return 'Arrivée';
      default:
        return type;
    }
  }

  Color _color(String type) {
    switch (type) {
      case 'DEPART':
        return AppColors.accent;
      case 'ABSENT':
        return AppColors.danger;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pointagesLogProvider(date));
    final title = date == null
        ? 'Historique des pointages'
        : 'Pointages du ${DateFormat('dd/MM/yyyy').format(DateTime.parse(date!))}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: async.when(
        loading: () => const AsOneLoader(message: 'Chargement des pointages…'),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(e.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(pointagesLogProvider(date)),
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
                    ? 'Aucun pointage enregistré'
                    : 'Aucun pointage pour cette journée',
              ),
            );
          }

          final Map<String, List<Map<String, dynamic>>> bySite = {};
          for (final raw in rows) {
            final p = Map<String, dynamic>.from(raw as Map);
            final site = p['site'] as Map<String, dynamic>? ?? {};
            final siteName = site['name'] as String? ?? 'Site inconnu';
            bySite.putIfAbsent(siteName, () => []).add(p);
          }

          final siteNames = bySite.keys.toList()..sort();

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(pointagesLogProvider(date)),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: siteNames.length,
              itemBuilder: (_, i) {
                final siteName = siteNames[i];
                final list = bySite[siteName]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, top: 4),
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
                          Expanded(
                            child: Text(
                              '$siteName · ${list.length} pointage(s)',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...list.map((p) {
                      final agent =
                          p['agent'] as Map<String, dynamic>? ?? {};
                      final type = p['type'] as String? ?? 'DEPART';
                      final name =
                          '${agent['firstName'] ?? ''} ${agent['lastName'] ?? ''}'
                              .trim();
                      final noted =
                          DateTime.tryParse(p['notedAt'] as String? ?? '');
                      final color = _color(type);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: color.withValues(alpha: 0.12),
                              child: Icon(Icons.fingerprint,
                                  color: color, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name.isEmpty ? 'Agent' : name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700),
                                  ),
                                  if (noted != null)
                                    Text(
                                      DateFormat('dd/MM/yyyy HH:mm')
                                          .format(noted.toLocal()),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _label(type),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
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
