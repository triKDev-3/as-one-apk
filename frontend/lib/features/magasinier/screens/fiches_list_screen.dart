import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/asone_loader.dart';
import '../repositories/material_repository.dart';

final fichesListProvider = FutureProvider.autoDispose
    .family<List<MaterialFiche>, ({String? siteId, String? status})>((ref, q) {
  return ref.watch(materialRepositoryProvider).listFiches(
        siteId: q.siteId,
        status: q.status,
      );
});

class FichesListScreen extends ConsumerStatefulWidget {
  final String? siteId;
  final bool chefMode;
  const FichesListScreen({super.key, this.siteId, this.chefMode = false});

  @override
  ConsumerState<FichesListScreen> createState() => _FichesListScreenState();
}

class _FichesListScreenState extends ConsumerState<FichesListScreen> {
  String? _status;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(fichesListProvider((
      siteId: widget.siteId,
      status: _status,
    )));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Fiches matériel'),
        actions: [
          IconButton(
            tooltip: 'Nouvelle fiche',
            onPressed: () {
              final path = widget.chefMode
                  ? '/chef/material/${widget.siteId ?? ''}'
                  : '/magasinier/fiches/new';
              context.push(path, extra: widget.siteId);
            },
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (widget.chefMode) {
            if (widget.siteId == null || widget.siteId!.isEmpty) {
              context.push('/chef/select-site');
              return;
            }
            context.push('/chef/material/${widget.siteId}');
          } else {
            context.push('/magasinier/fiches/new');
          }
        },
        icon: const Icon(Icons.post_add_rounded),
        label: Text(widget.chefMode ? 'Demander' : 'Générer une fiche'),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                _chip('Toutes', null),
                _chip('Demandées', 'REQUESTED'),
                _chip('Livrées', 'DELIVERED'),
                _chip('Retours', 'RETURN_IN_PROGRESS'),
                _chip('Clôturées', 'CLOSED'),
              ],
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const AsOneLoader(),
              error: (e, _) => Center(child: Text('$e')),
              data: (list) {
                if (list.isEmpty) {
                  return const Center(child: Text('Aucune fiche pour le moment'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _FicheTile(
                    fiche: list[i],
                    chefMode: widget.chefMode,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String? value) {
    final selected = _status == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _status = value),
      ),
    );
  }
}

class _FicheTile extends StatelessWidget {
  final MaterialFiche fiche;
  final bool chefMode;
  const _FicheTile({required this.fiche, required this.chefMode});

  @override
  Widget build(BuildContext context) {
    final date = fiche.requestDate != null
        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(fiche.requestDate!))
        : '';
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        title: Text(fiche.code,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        subtitle: Text(
          '${fiche.siteName}\n$date · ${fiche.lines.length} articles'
          '${fiche.requesterName.isEmpty ? '' : ' · ${fiche.requesterName}'}',
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StatusPill(fiche.statusLabel),
            const SizedBox(height: 4),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
        onTap: () {
          final base = chefMode ? '/chef' : '/magasinier';
          if (!chefMode &&
              (fiche.status == 'DELIVERED' ||
                  fiche.status == 'RETURN_IN_PROGRESS')) {
            context.push('$base/fiches/${fiche.id}/return');
          } else {
            context.push('$base/fiches/${fiche.id}');
          }
        },
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  const _StatusPill(this.label);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}
