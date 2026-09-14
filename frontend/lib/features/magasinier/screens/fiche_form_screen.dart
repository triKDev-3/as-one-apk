import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/asone_loader.dart';
import '../../chef/repositories/sites_repository.dart';
import '../repositories/material_repository.dart';
import 'fiches_list_screen.dart';

class _RowDraft {
  final MaterialItem item;
  final qty = TextEditingController();
  final delivered = TextEditingController();
  final notes = TextEditingController();
  _RowDraft(this.item);
  void dispose() {
    qty.dispose();
    delivered.dispose();
    notes.dispose();
  }

  int get qtyVal => int.tryParse(qty.text.trim()) ?? 0;
  int get deliveredVal => int.tryParse(delivered.text.trim()) ?? 0;
}

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

class _FicheFormScreenState extends ConsumerState<FicheFormScreen> {
  SiteModel? _site;
  MaterialFiche? _fiche;
  final _sector = TextEditingController();
  final _days = TextEditingController(text: '1');
  final _people = TextEditingController();
  final _spaces = TextEditingController();
  final _search = TextEditingController();
  DateTime _requestDate = DateTime.now();
  DateTime? _returnDate;
  final List<_RowDraft> _rows = [];
  bool _loading = true;
  bool _saving = false;
  String _query = '';

  bool get _magasinier => !widget.chefMode;
  bool get _locked =>
      _fiche != null &&
      _fiche!.status != 'REQUESTED' &&
      _fiche!.status != 'DRAFT' &&
      widget.chefMode;

  @override
  void initState() {
    super.initState();
    _site = widget.site;
    _search.addListener(() => setState(() => _query = _search.text.trim().toLowerCase()));
    _boot();
  }

  Future<void> _boot() async {
    try {
      final repo = ref.read(materialRepositoryProvider);
      var items = await repo.listItems();
      if (items.isEmpty) {
        await repo.seedCatalog();
        items = await repo.listItems();
      }
      items.sort((a, b) {
        final c = a.isEquipement == b.isEquipement
            ? 0
            : (a.isEquipement ? 1 : -1);
        if (c != 0) return c;
        return (a.refCode ?? a.name).compareTo(b.refCode ?? b.name);
      });

      MaterialFiche? fiche;
      if (widget.ficheId != null) {
        fiche = await repo.getFiche(widget.ficheId!);
        _fiche = fiche;
        _sector.text = fiche.sector ?? '';
        _days.text = '${fiche.dayCount ?? 1}';
        _people.text = fiche.personCount?.toString() ?? '';
        _spaces.text = fiche.spaceCount?.toString() ?? '';
        _requestDate = DateTime.tryParse(fiche.requestDate ?? '') ?? DateTime.now();
        _returnDate = DateTime.tryParse(fiche.plannedReturn ?? '');
        _site ??= SiteModel(
          id: fiche.siteId,
          name: fiche.siteName,
          type: fiche.site?['type'] as String? ?? 'CHANTIER',
        );
      } else if (widget.siteId != null && _site == null) {
        final sites = await ref.read(sitesRepositoryProvider).getSites();
        for (final s in sites) {
          if (s.id == widget.siteId) {
            _site = s;
            break;
          }
        }
      }

      final byItem = <String, MaterialFicheLine>{};
      if (fiche != null) {
        for (final l in fiche.lines) {
          byItem[l.itemId] = l;
        }
      }
      for (final it in items) {
        final d = _RowDraft(it);
        final existing = byItem[it.id];
        if (existing != null) {
          if (existing.qtyRequested > 0) d.qty.text = '${existing.qtyRequested}';
          if (existing.qtyDelivered > 0) {
            d.delivered.text = '${existing.qtyDelivered}';
          }
          d.notes.text = existing.outNotes ?? '';
        }
        _rows.add(d);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    _sector.dispose();
    _days.dispose();
    _people.dispose();
    _spaces.dispose();
    _search.dispose();
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

  Future<void> _pickDate({required bool retour}) async {
    final initial = retour ? (_returnDate ?? DateTime.now()) : _requestDate;
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime(2032),
    );
    if (d == null) return;
    setState(() {
      if (retour) {
        _returnDate = d;
      } else {
        _requestDate = d;
      }
    });
  }

  List<Map<String, dynamic>> _filledLines() {
    return _rows
        .where((r) => r.qtyVal > 0 || (_magasinier && r.deliveredVal > 0))
        .map((r) => {
              'itemId': r.item.id,
              'qtyRequested': r.qtyVal,
              if (_magasinier) 'qtyDelivered': r.deliveredVal,
              if (r.notes.text.trim().isNotEmpty) 'outNotes': r.notes.text.trim(),
            })
        .toList();
  }

  Future<void> _save({bool deliver = false}) async {
    if (_site == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisissez un site / chantier')),
      );
      return;
    }
    final lines = _filledLines();
    if (lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Indiquez au moins une quantité demandée'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(materialRepositoryProvider);
      final payload = {
        'siteId': _site!.id,
        'sector': _sector.text.trim().isEmpty ? null : _sector.text.trim(),
        'dayCount': int.tryParse(_days.text) ?? 1,
        'personCount': int.tryParse(_people.text),
        'spaceCount': int.tryParse(_spaces.text),
        'plannedReturn': _returnDate?.toIso8601String(),
        'lines': lines,
      };
      MaterialFiche fiche;
      if (_fiche == null) {
        fiche = await repo.createFiche(payload);
      } else {
        fiche = await repo.updateFiche(_fiche!.id, payload);
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool _match(_RowDraft r) {
    if (_query.isEmpty) return true;
    final hay =
        '${r.item.refCode ?? ''} ${r.item.name}'.toLowerCase();
    return hay.contains(_query);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: AsOneLoader());
    final cons = _rows.where((r) => !r.item.isEquipement && _match(r)).toList();
    final eq = _rows.where((r) => r.item.isEquipement && _match(r)).toList();
    final filled = _rows.where((r) => r.qtyVal > 0).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Text(_fiche?.code ?? 'Fiche F-ACH-07'),
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
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 140),
        children: [
          _headerCard(),
          const SizedBox(height: 10),
          TextField(
            controller: _search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Filtrer un article (la liste reste complète)',
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text('$filled article(s) avec une quantité · ${_rows.length} au catalogue',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          _section(
            'PRODUITS ET CONSOMMABLES',
            'Retour non obligatoire — laissez vide si non demandé',
            cons,
          ),
          const SizedBox(height: 12),
          _section(
            'MATERIELS ET EQUIPEMENTS',
            'Retour obligatoire en fin de chantier',
            eq,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: _saving
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton(
                      onPressed: _locked ? null : () => _save(),
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

  Widget _headerCard() {
    final df = DateFormat('dd/MM/yyyy');
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Text('AS ONE',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        fontSize: 16)),
                Spacer(),
                Text('FICHE F-ACH-07',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'DEMANDE DE PRODUITS ET DE MATERIELS SITES TEMPORAIRES',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
            const Divider(),
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Site / chantier'),
              subtitle: Text(_site?.name ?? 'Sélectionner'),
              trailing: const Icon(Icons.apartment_rounded),
              onTap: widget.siteId == null ? _pickSite : null,
            ),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Date de demande'),
                    subtitle: Text(df.format(_requestDate)),
                    onTap: () => _pickDate(retour: false),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Date de retour'),
                    subtitle: Text(
                        _returnDate == null ? '—' : df.format(_returnDate!)),
                    onTap: () => _pickDate(retour: true),
                  ),
                ),
              ],
            ),
            TextField(
              controller: _sector,
              enabled: !_locked,
              decoration: const InputDecoration(
                labelText: 'Secteur d\'activité',
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _days,
                    enabled: !_locked,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Nbre de jour',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _people,
                    enabled: !_locked,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Nbre de personne',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _spaces,
                    enabled: !_locked,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Nbre d\'espace',
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String hint, List<_RowDraft> rows) {
    return Card(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AppColors.primaryDark,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.3)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
            child: Text(hint,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 8, 4),
            child: Row(
              children: [
                const Expanded(
                    flex: 4,
                    child: Text('Réf / Désignation',
                        style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w800))),
                const SizedBox(
                    width: 58,
                    child: Text('Qté dem.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w800))),
                if (_magasinier)
                  const SizedBox(
                      width: 64,
                      child: Text('Livré',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w800))),
              ],
            ),
          ),
          const Divider(height: 1),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Aucun article',
                  style: TextStyle(color: AppColors.textTertiary)),
            ),
          ...rows.map(_itemRow),
        ],
      ),
    );
  }

  Widget _itemRow(_RowDraft r) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.item.refCode ?? '—',
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary)),
                Text(r.item.name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          SizedBox(
            width: 58,
            child: TextField(
              controller: r.qty,
              enabled: !_locked,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                isDense: true,
                hintText: '—',
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          if (_magasinier) ...[
            const SizedBox(width: 6),
            SizedBox(
              width: 58,
              child: TextField(
                controller: r.delivered,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'Livré',
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
