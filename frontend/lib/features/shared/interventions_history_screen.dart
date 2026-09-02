import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/providers.dart';
import '../../core/network/api_client.dart';

class InterventionsFilter {
  final String? from;
  final String? to;
  final String status; // ALL | CONFIRMED | ...

  const InterventionsFilter({
    this.from,
    this.to,
    this.status = 'ALL',
  });

  InterventionsFilter copyWith({
    String? from,
    String? to,
    String? status,
  }) {
    return InterventionsFilter(
      from: from ?? this.from,
      to: to ?? this.to,
      status: status ?? this.status,
    );
  }
}

final interventionsFilterProvider =
    StateProvider.autoDispose<InterventionsFilter>(
  (_) => InterventionsFilter(
    from: DateFormat('yyyy-MM-dd')
        .format(DateTime.now().subtract(const Duration(days: 30))),
    to: DateFormat('yyyy-MM-dd').format(DateTime.now()),
  ),
);

final interventionsHistoryProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final filter = ref.watch(interventionsFilterProvider);
  final viewAll = ref.watch(viewAllProvider);
  try {
    final res = await api.dio.get(
      '/stats/interventions',
      queryParameters: {
        if (filter.from != null) 'from': filter.from,
        if (filter.to != null) 'to': filter.to,
        if (filter.status != 'ALL') 'status': filter.status,
        'all': viewAll.toString(),
      },
    );
    return res.data as Map<String, dynamic>;
  } on DioException catch (e) {
    throw ApiClient.extractError(e);
  }
});

class InterventionsHistoryScreen extends ConsumerWidget {
  const InterventionsHistoryScreen({super.key});

  Color _statusColor(String s) {
    switch (s) {
      case 'CONFIRMED':
      case 'LOCKED':
        return AppColors.accent;
      case 'PENDING_CONFIRMATION':
        return AppColors.warning;
      case 'REFUSED':
      case 'CANCELLED':
        return AppColors.danger;
      default:
        return AppColors.textSecondary;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'CONFIRMED':
        return 'Confirmé';
      case 'LOCKED':
        return 'Verrouillé';
      case 'PENDING_CONFIRMATION':
        return 'En attente';
      case 'REFUSED':
        return 'Refusé';
      case 'CANCELLED':
        return 'Annulé';
      default:
        return s;
    }
  }

  Future<void> _exportCsv(
    BuildContext context,
    List<dynamic> items,
  ) async {
    final buf = StringBuffer();
    buf.writeln(
      'Date début;Date fin;Agent;Téléphone;Site;Type site;Statut;Type mission;Chef;Contrat',
    );
    for (final raw in items) {
      final m = raw as Map<String, dynamic>;
      String d(dynamic v) {
        if (v == null) return '';
        final dt = DateTime.tryParse(v.toString());
        if (dt == null) return v.toString();
        return DateFormat('dd/MM/yyyy').format(dt.toLocal());
      }

      buf.writeln([
        d(m['startDate']),
        d(m['endDate']),
        '"${m['agentName'] ?? ''}"',
        m['agentPhone'] ?? '',
        '"${m['siteName'] ?? ''}"',
        m['siteType'] ?? '',
        m['status'] ?? '',
        m['missionType'] ?? '',
        '"${m['chefName'] ?? ''}"',
        m['agentContract'] ?? '',
      ].join(';'));
    }

    final name =
        'interventions_asone_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';
    await Share.share(
      buf.toString(),
      subject: name,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fichier CSV prêt à partager / enregistrer'),
          backgroundColor: AppColors.accent,
        ),
      );
    }
  }

  Future<void> _pickDate(
    BuildContext context,
    WidgetRef ref, {
    required bool isFrom,
  }) async {
    final filter = ref.read(interventionsFilterProvider);
    final initial = DateTime.tryParse(
          (isFrom ? filter.from : filter.to) ?? '',
        ) ??
        DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    final key = DateFormat('yyyy-MM-dd').format(picked);
    ref.read(interventionsFilterProvider.notifier).state = isFrom
        ? filter.copyWith(from: key)
        : filter.copyWith(to: key);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(interventionsHistoryProvider);
    final filter = ref.watch(interventionsFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Historique interventions'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          async.maybeWhen(
            data: (data) {
              final items = (data['items'] as List<dynamic>?) ?? [];
              return IconButton(
                tooltip: 'Exporter CSV',
                icon: const Icon(Icons.file_download_outlined),
                onPressed: items.isEmpty
                    ? null
                    : () => _exportCsv(context, items),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtres
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _pickDate(context, ref, isFrom: true),
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          filter.from != null
                              ? 'Du ${DateFormat('dd/MM/yy').format(DateTime.parse(filter.from!))}'
                              : 'Date début',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _pickDate(context, ref, isFrom: false),
                        icon: const Icon(Icons.event, size: 16),
                        label: Text(
                          filter.to != null
                              ? 'Au ${DateFormat('dd/MM/yy').format(DateTime.parse(filter.to!))}'
                              : 'Date fin',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final s in const [
                        'ALL',
                        'CONFIRMED',
                        'PENDING_CONFIRMATION',
                        'LOCKED',
                        'REFUSED',
                        'CANCELLED',
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(
                              s == 'ALL' ? 'Tous' : _statusLabel(s),
                              style: const TextStyle(fontSize: 11),
                            ),
                            selected: filter.status == s,
                            onSelected: (_) {
                              ref
                                  .read(interventionsFilterProvider.notifier)
                                  .state = filter.copyWith(status: s);
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: async.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(e.toString(), textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () =>
                            ref.invalidate(interventionsHistoryProvider),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (data) {
                final items = (data['items'] as List<dynamic>?) ?? [];
                final count = data['count'] as int? ?? items.length;

                if (items.isEmpty) {
                  return const Center(
                    child: Text('Aucune intervention sur cette période'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(interventionsHistoryProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length + 1,
                    itemBuilder: (_, i) {
                      if (i == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Text(
                                '$count intervention(s)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () =>
                                    _exportCsv(context, items),
                                icon: const Icon(Icons.share_outlined,
                                    size: 18),
                                label: const Text('Exporter CSV'),
                              ),
                            ],
                          ),
                        );
                      }

                      final m =
                          items[i - 1] as Map<String, dynamic>;
                      final status = m['status'] as String? ?? '';
                      final color = _statusColor(status);
                      final start = DateTime.tryParse(
                          m['startDate'] as String? ?? '');
                      final end = DateTime.tryParse(
                          m['endDate'] as String? ?? '');

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
                                    m['siteName'] as String? ?? 'Site',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _statusLabel(status),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              m['agentName'] as String? ?? 'Agent',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              [
                                if (start != null)
                                  'Du ${DateFormat('dd/MM/yyyy').format(start.toLocal())}',
                                if (end != null)
                                  'au ${DateFormat('dd/MM/yyyy').format(end.toLocal())}',
                                if (m['missionType'] != null)
                                  m['missionType'],
                                if (m['chefName'] != null)
                                  'Chef: ${m['chefName']}',
                              ].join(' · '),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
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
