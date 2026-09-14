import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/asone_loader.dart';
import '../repositories/material_repository.dart';

final catalogItemsProvider =
    FutureProvider.autoDispose<List<MaterialItem>>((ref) {
  return ref.watch(materialRepositoryProvider).listItems(all: true);
});

class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(catalogItemsProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Catalogue F-ACH-07'),
        actions: [
          IconButton(
            tooltip: 'Charger la liste officielle',
            onPressed: () async {
              await ref.read(materialRepositoryProvider).seedCatalog();
              ref.invalidate(catalogItemsProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Catalogue officiel chargé')),
                );
              }
            },
            icon: const Icon(Icons.download_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(context, ref, null),
        child: const Icon(Icons.add),
      ),
      body: async.when(
        loading: () => const AsOneLoader(),
        error: (e, _) => Center(child: Text('$e')),
        data: (items) {
          final cons = items.where((e) => !e.isEquipement).toList();
          final eq = items.where((e) => e.isEquipement).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            children: [
              _Section(
                title: 'Produits et consommables',
                subtitle: 'Retour non obligatoire',
                items: cons,
                onTap: (it) => _edit(context, ref, it),
              ),
              const SizedBox(height: 16),
              _Section(
                title: 'Matériels et équipements',
                subtitle: 'Retour obligatoire',
                items: eq,
                onTap: (it) => _edit(context, ref, it),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    MaterialItem? item,
  ) async {
    final name = TextEditingController(text: item?.name ?? '');
    final refCode = TextEditingController(text: item?.refCode ?? '');
    final price = TextEditingController(
      text: item == null ? '0' : item.unitPrice.toStringAsFixed(0),
    );
    var category = item?.isEquipement == true ? 'EQUIPEMENT' : 'CONSOMMABLE';
    var active = item?.isActive ?? true;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (ctx, setSt) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(item == null ? 'Nouvel article' : 'Modifier l\'article',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                TextField(
                  controller: refCode,
                  decoration: const InputDecoration(labelText: 'Réf. (AIR-DES)'),
                  textCapitalization: TextCapitalization.characters,
                ),
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Désignation'),
                ),
                TextField(
                  controller: price,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Prix unitaire (F)'),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'CONSOMMABLE', label: Text('Consommable')),
                    ButtonSegment(value: 'EQUIPEMENT', label: Text('Équipement')),
                  ],
                  selected: {category},
                  onSelectionChanged: (s) => setSt(() => category = s.first),
                ),
                if (item != null)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Actif'),
                    value: active,
                    onChanged: (v) => setSt(() => active = v),
                  ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(item == null ? 'Créer' : 'Enregistrer'),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (ok != true) return;
    final data = {
      'name': name.text.trim(),
      'refCode': refCode.text.trim().toUpperCase(),
      'category': category,
      'unitPrice': double.tryParse(price.text) ?? 0,
      'returnRequired': category == 'EQUIPEMENT',
      if (item != null) 'isActive': active,
    };
    final repo = ref.read(materialRepositoryProvider);
    if (item == null) {
      await repo.createItem(data);
    } else {
      await repo.updateItem(item.id, data);
    }
    ref.invalidate(catalogItemsProvider);
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<MaterialItem> items;
  final void Function(MaterialItem) onTap;
  const _Section({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        Text(subtitle,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        const SizedBox(height: 8),
        ...items.map(
          (it) => Card(
            margin: const EdgeInsets.only(bottom: 6),
            child: ListTile(
              onTap: () => onTap(it),
              leading: CircleAvatar(
                backgroundColor: it.isEquipement
                    ? AppColors.infoLight
                    : AppColors.secondaryLight,
                child: Text(
                  (it.refCode ?? it.name).substring(0, 2),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
              title: Text(it.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: it.isActive ? null : AppColors.textTertiary,
                  )),
              subtitle: Text(
                '${it.refCode ?? '—'}  ·  ${it.unitPrice.toStringAsFixed(0)} F'
                '${it.isActive ? '' : '  ·  inactif'}',
              ),
              trailing: const Icon(Icons.edit_outlined, size: 18),
            ),
          ),
        ),
      ],
    );
  }
}
