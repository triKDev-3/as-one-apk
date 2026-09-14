import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/asone_loader.dart';
import '../../chef/repositories/sites_repository.dart';
import '../repositories/material_repository.dart';
import 'catalog_screen.dart';
import 'fiches_list_screen.dart';

class FicheFormScreen extends ConsumerStatefulWidget {
  final String? ficheId;
  final String? siteId;
  final SiteModel? site;
  final bool chefMode;
  const FicheFormScreen({
    super.key,
    this.ficheId,
    this.siteId,
    this.site,
    this.chefMode = false,
  });

  @override
  ConsumerState<FicheFormScreen> createState() => _FicheFormScreenState();
}

class _DraftLine {
  MaterialItem item;
  final qty = TextEditingController(text: '1');
  final delivered = TextEditingController(text: '0');
  _DraftLine(this.item);
  void dispose() {
    qty.dispose();
    delivered.dispose();
  }
}

class _FicheFormScreenState extends ConsumerState<FicheFormScreen> {
  SiteModel? _site;
  MaterialFiche? _fiche;
  final _sector = TextEditingController();
  final _days = TextEditingController(text: '1');
  final _people = TextEditingController();
  final _spaces = TextEditingController();
  final List<_DraftLine> _lines = [];
  bool _loading = true;
  bool _saving = false;

  bool get _canEditQty =>
      !widget.chefMode || _fiche == null || _fiche!.status == 'REQUESTED';

  bool get _magasinier => !widget.chefMode;

  @override
  void initState() {
    super.initState();
    _site = widget.site;
    _boot();
  }

  Future<void> _boot() async {
    try {
      if (widget.ficheId != null) {
        final f =
            await ref.read(materialRepositoryProvider).getFiche(widget.ficheId!);
        _fiche = f;
        _sector.text = f.sector ?? '';
        _days.text = '${f.dayCount ?? 1}';
        _people.text = f.personCount?.toString() ?? '';
        _spaces.text = f.spaceCount?.toString() ?? '';
        _site ??= SiteModel(
          id: f.siteId,
          name: f.siteName,
          type: f.site?['type'] as String? ?? 'CHANTIER',
        );
        for (final l in f.lines) {
          if (l.item == null) continue;
          final d = _DraftLine(l.item!);
          d.qty.text = '${l.qtyRequested}';
          d.delivered.text = '${l.qtyDelivered}';
          _lines.add(d);
        }
      } else if (widget.siteId != null && _site == null) {
        final sites = await ref.read(sitesRepositoryProvider).getSites();
        for (final s in sites) {
          if (s.id == widget.siteId) {
            _site = s;
            break;
          }
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    for (final l in _lines) {
      l.dispose();
    }
    _sector.dispose();
    _days.dispose();
    _people.dispose();
    _spaces.dispose();
    super.dispose();
  }

  Future<void> _pickSite() async {
    final sites = await ref.read(sitesRepositoryProvider).getSites();
    if (!mounted) return;
    final selected = await showModalBottomSheet<SiteModel>(
      context: context,
      builder: (ctx) => ListView(
        children: sites
            .map((s) => ListTile(
                  title: Text(s.name),
                  subtitle: Text(s.typeLabel),
                  onTap: () => Navigator.pop(ctx, s),
                ))
            .toList(),
      ),
    );
    if (selected != null) setState(() => _site = selected);
  }

  Future<void> _addItems() async {
    var items = ref.read(catalogItemsProvider).valueOrNull;
    items ??= await ref.read(materialRepositoryProvider).listItems();
    if (!mounted) return;
    final chosen = <MaterialItem>{};
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          builder: (_, scroll) {
            final cons = items!.where((e) => !e.isEquipement).toList();
            final eq = items.where((e) => e.isEquipement).toList();
            return StatefulBuilder(
              builder: (ctx, setSt) {
                Widget group(String title, List<MaterialItem> list) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text(title,
                            style: const TextStyle(fontWeight: FontWeight.w800)),
                      ),
                      ...list.map((it) {
                        final on = chosen.contains(it) ||
                            _lines.any((l) => l.item.id == it.id);
                        return CheckboxListTile(
                          value: on,
                          title: Text(it.name),
                          subtitle: Text(it.refCode ?? ''),
                          onChanged: (v) => setSt(() {
                            if (v == true) {
                              chosen.add(it);
                            } else {
                              chosen.remove(it);
                            }
                          }),
                        );
                      }),
                    ],
                  );
                }

                return Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Sélectionner les articles',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                    ),
                    Expanded(
                      child: ListView(
                        controller: scroll,
                        children: [
                          group('Produits et consommables', cons),
                          group('Matériels et équipements', eq),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Ajouter'),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
    setState(() {
      for (final it in chosen) {
        if (_lines.any((l) => l.item.id == it.id)) continue;
        _lines.add(_DraftLine(it));
      }
    });
  }

  Map<String, dynamic> _payload() {
    return {
      'siteId': _site!.id,
      'sector': _sector.text.trim().isEmpty ? null : _sector.text.trim(),
      'dayCount': int.tryParse(_days.text) ?? 1,
      'personCount': int.tryParse(_people.text),
      'spaceCount': int.tryParse(_spaces.text),
      'lines': _lines
          .map((l) => {
                'itemId': l.item.id,
                'qtyRequested': int.tryParse(l.qty.text) ?? 0,
                if (_magasinier)
                  'qtyDelivered': int.tryParse(l.delivered.text) ?? 0,
              })
          .where((l) => (l['qtyRequested'] as int) > 0)
          .toList(),
    };
  }

  Future<void> _save({bool deliver = false}) async {
    if (_site == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisissez un site / chantier')),
      );
      return;
    }
    final lines = (_payload()['lines'] as List);
    if (lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez au moins un article')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(materialRepositoryProvider);
      MaterialFiche fiche;
      if (_fiche == null) {
        fiche = await repo.createFiche(_payload());
      } else {
        fiche = await repo.updateFiche(_fiche!.id, _payload());
      }
      if (deliver) {
        fiche = await repo.deliverFiche(fiche.id);
      }
      ref.invalidate(fichesListProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(deliver
              ? 'Fiche ${fiche.code} livrée'
              : 'Fiche ${fiche.code} enregistrée'),
          backgroundColor: AppColors.accent,
        ),
      );
      context.push(
        '${widget.chefMode ? '/chef' : '/magasinier'}/fiches/${fiche.id}/print',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: AsOneLoader());
    }
    final cons = _lines.where((l) => !l.item.isEquipement).toList();
    final eq = _lines.where((l) => l.item.isEquipement).toList();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_fiche?.code ??
            (widget.chefMode ? 'Demande matériel' : 'Fiche F-ACH-07')),
        actions: [
          if (_fiche != null)
            IconButton(
              icon: const Icon(Icons.print_outlined),
              onPressed: () => context.push(
                '${widget.chefMode ? '/chef' : '/magasinier'}/fiches/${_fiche!.id}/print',
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Site / chantier'),
            subtitle: Text(_site?.name ?? 'Sélectionner'),
            trailing: const Icon(Icons.apartment_rounded),
            onTap: widget.siteId == null ? _pickSite : null,
          ),
          TextField(
            controller: _sector,
            decoration: const InputDecoration(labelText: 'Secteur d\'activité'),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _days,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Nbre de jour'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _people,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Nbre de personne'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _spaces,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Nbre d\'espace'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text('Sortie de stock',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
              TextButton.icon(
                onPressed: _addItems,
                icon: const Icon(Icons.add),
                label: const Text('Articles'),
              ),
            ],
          ),
          _group('Produits et consommables', cons),
          _group('Matériels et équipements', eq),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: _saving
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilledButton(
                      onPressed: _canEditQty ? () => _save() : null,
                      child: Text(widget.chefMode
                          ? 'Envoyer la demande'
                          : 'Enregistrer la fiche'),
                    ),
                    if (_magasinier) ...[
                      const SizedBox(height: 8),
                      FilledButton.tonal(
                        onPressed: () => _save(deliver: true),
                        child: const Text('Valider la livraison'),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  Widget _group(String title, List<_DraftLine> lines) {
    if (lines.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w800, color: AppColors.primary)),
        const SizedBox(height: 6),
        ...lines.map((l) {
          return Card(
            margin: const EdgeInsets.only(bottom: 6),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.item.refCode ?? '',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textSecondary)),
                        Text(l.item.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 56,
                    child: TextField(
                      controller: l.qty,
                      keyboardType: TextInputType.number,
                      enabled: _canEditQty,
                      decoration: const InputDecoration(
                        labelText: 'Qté',
                        isDense: true,
                      ),
                    ),
                  ),
                  if (_magasinier) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 64,
                      child: TextField(
                        controller: l.delivered,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Livré',
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                  IconButton(
                    onPressed: _canEditQty
                        ? () => setState(() {
                              _lines.remove(l);
                              l.dispose();
                            })
                        : null,
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
