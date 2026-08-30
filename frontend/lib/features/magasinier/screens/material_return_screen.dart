import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../chef/repositories/sites_repository.dart';
import '../repositories/material_repository.dart';
import 'material_out_screen.dart';

class MaterialReturnScreen extends ConsumerStatefulWidget {
  const MaterialReturnScreen({super.key});

  @override
  ConsumerState<MaterialReturnScreen> createState() =>
      _MaterialReturnScreenState();
}

class _MaterialReturnScreenState extends ConsumerState<MaterialReturnScreen> {
  SiteModel? _site;
  MaterialItem? _item;
  final _qtyController = TextEditingController(text: '1');
  String _state = 'BON';
  String? _retentionTarget;
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

    if ((_state == 'DEGRADE' || _state == 'MANQUANT') &&
        _retentionTarget == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choisissez le type de retenue (1 agent ou groupe)'),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(materialRepositoryProvider).materialReturn(
            siteId: _site!.id,
            itemId: _item!.id,
            quantity: qty,
            state: _state,
            retentionTarget: _retentionTarget,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Retour enregistré'),
          backgroundColor: AppColors.accent,
        ),
      );
      setState(() {
        _item = null;
        _state = 'BON';
        _retentionTarget = null;
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
    final needsRetention = _state == 'DEGRADE' || _state == 'MANQUANT';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Retour de matériel'),
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
          Text('Article', style: Theme.of(context).textTheme.titleLarge),
          itemsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text(e.toString()),
            data: (items) => RadioGroup<MaterialItem>(
              groupValue: _item,
              onChanged: (v) => setState(() => _item = v),
              child: Column(
                children: items
                    .map(
                      (item) => RadioListTile<MaterialItem>(
                        value: item,
                        title: Text(item.name),
                        subtitle: Text(item.category),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _qtyController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Quantité'),
          ),
          const SizedBox(height: 16),
          Text('État au retour', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Bon'),
                selected: _state == 'BON',
                onSelected: (_) => setState(() {
                  _state = 'BON';
                  _retentionTarget = null;
                }),
              ),
              ChoiceChip(
                label: const Text('Dégradé'),
                selected: _state == 'DEGRADE',
                onSelected: (_) => setState(() => _state = 'DEGRADE'),
              ),
              ChoiceChip(
                label: const Text('Manquant'),
                selected: _state == 'MANQUANT',
                onSelected: (_) => setState(() => _state = 'MANQUANT'),
              ),
            ],
          ),
          if (needsRetention) ...[
            const SizedBox(height: 16),
            Text(
              'Retenue financière',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            RadioGroup<String>(
              groupValue: _retentionTarget,
              onChanged: (v) => setState(() => _retentionTarget = v),
              child: const Column(
                children: [
                  RadioListTile<String>(
                    value: 'ONE_AGENT',
                    title: Text('Un seul agent'),
                  ),
                  RadioListTile<String>(
                    value: 'WHOLE_GROUP',
                    title: Text('Tout le groupe (prix divisé)'),
                  ),
                ],
              ),
            ),
          ],
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
                : const Text('Valider le retour'),
          ),
        ],
      ),
    );
  }
}
