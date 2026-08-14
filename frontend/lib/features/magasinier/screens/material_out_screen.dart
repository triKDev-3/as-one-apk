import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../chef/repositories/sites_repository.dart';
import '../repositories/material_repository.dart';

final materialItemsProvider =
    FutureProvider.autoDispose<List<MaterialItem>>((ref) {
  return ref.watch(materialRepositoryProvider).listItems();
});

class MaterialOutScreen extends ConsumerStatefulWidget {
  const MaterialOutScreen({super.key});

  @override
  ConsumerState<MaterialOutScreen> createState() => _MaterialOutScreenState();
}

class _MaterialOutScreenState extends ConsumerState<MaterialOutScreen> {
  SiteModel? _site;
  MaterialItem? _item;
  final _qtyController = TextEditingController(text: '1');
  bool _loading = false;

  Future<void> _pickSite() async {
    final sites = await ref.read(sitesRepositoryProvider).getSites();
    if (!mounted) return;
    final selected = await showModalBottomSheet<SiteModel>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (_, scroll) => ListView.builder(
          controller: scroll,
          itemCount: sites.length,
          itemBuilder: (_, i) {
            final s = sites[i];
            return ListTile(
              title: Text(s.name),
              subtitle: Text(s.typeLabel),
              onTap: () => Navigator.pop(ctx, s),
            );
          },
        ),
      ),
    );
    if (selected != null) setState(() => _site = selected);
  }

  Future<void> _submit() async {
    if (_site == null || _item == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Site et article obligatoires')),
      );
      return;
    }
    final qty = int.tryParse(_qtyController.text) ?? 0;
    if (qty < 1) return;

    setState(() => _loading = true);
    try {
      final result = await ref.read(materialRepositoryProvider).materialOut(
            siteId: _site!.id,
            itemId: _item!.id,
            quantity: qty,
          );
      if (!mounted) return;
      final refCode = result['printableRef'] ?? '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sortie enregistrée — Réf. $refCode'),
          backgroundColor: AppColors.accent,
        ),
      );
      setState(() {
        _item = null;
        _qtyController.text = '1';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(materialItemsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sortie de matériel'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Chantier / Site'),
            subtitle: Text(_site?.name ?? 'Sélectionner…'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickSite,
          ),
          const Divider(),
          const SizedBox(height: 8),
          Text('Article', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          itemsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text(e.toString()),
            data: (items) => Column(
              children: items
                  .map(
                    (item) => RadioListTile<MaterialItem>(
                      value: item,
                      groupValue: _item,
                      title: Text(item.name),
                      subtitle: Text(
                        '${item.category} · ${item.unitPrice.toStringAsFixed(0)} FCFA',
                      ),
                      onChanged: (v) => setState(() => _item = v),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _qtyController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Quantité',
              prefixIcon: Icon(Icons.numbers),
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Text('Enregistrer la sortie'),
          ),
        ],
      ),
    );
  }
}
