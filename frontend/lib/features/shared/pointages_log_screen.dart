import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/providers.dart';

final pointagesLogProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) {
  return ref.watch(pointageRepositoryProvider).list();
});

class PointagesLogScreen extends ConsumerWidget {
  const PointagesLogScreen({super.key});

  String _label(String type) {
    switch (type) {
      case 'DEPART':
        return 'Départ';
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
    final async = ref.watch(pointagesLogProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Historique des pointages'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(e.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(pointagesLogProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (rows) {
          if (rows.isEmpty) {
            return const Center(child: Text('Aucun pointage enregistré'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(pointagesLogProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rows.length,
              itemBuilder: (_, i) {
                final p = rows[i] as Map<String, dynamic>;
                final agent = p['agent'] as Map<String, dynamic>? ?? {};
                final site = p['site'] as Map<String, dynamic>? ?? {};
                final type = p['type'] as String? ?? 'DEPART';
                final name =
                    '${agent['firstName'] ?? ''} ${agent['lastName'] ?? ''}'.trim();
                final noted = DateTime.tryParse(p['notedAt'] as String? ?? '');
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
                        backgroundColor: color.withOpacity(0.12),
                        child: Icon(Icons.fingerprint, color: color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name.isEmpty ? 'Agent' : name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            Text(
                              site['name'] as String? ?? 'Site',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary),
                            ),
                            if (noted != null)
                              Text(
                                DateFormat('dd/MM/yyyy HH:mm').format(noted.toLocal()),
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.textTertiary),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
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
              },
            ),
          );
        },
      ),
    );
  }
}
