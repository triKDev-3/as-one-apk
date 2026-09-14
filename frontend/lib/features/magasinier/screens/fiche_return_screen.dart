import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/asone_loader.dart';
import '../repositories/material_repository.dart';
import 'fiches_list_screen.dart';

class _ReturnDraft {
  final MaterialFicheLine line;
  bool checked;
  bool lost;
  String state;
  final qty = TextEditingController();
  final notes = TextEditingController();

  _ReturnDraft(this.line)
      : checked = line.isChecked,
        lost = line.isLost,
        state = line.returnState ?? 'BON' {
    qty.text = line.qtyReturned > 0
        ? '${line.qtyReturned}'
        : '${line.qtyDelivered}';
    notes.text = line.returnNotes ?? '';
  }

  void dispose() {
    qty.dispose();
    notes.dispose();
  }
}

class FicheReturnScreen extends ConsumerStatefulWidget {
  final String ficheId;
  const FicheReturnScreen({super.key, required this.ficheId});

  @override
  ConsumerState<FicheReturnScreen> createState() => _FicheReturnScreenState();
}

class _FicheReturnScreenState extends ConsumerState<FicheReturnScreen> {
  MaterialFiche? _fiche;
  final List<_ReturnDraft> _rows = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final f =
          await ref.read(materialRepositoryProvider).getFiche(widget.ficheId);
      _fiche = f;
      for (final r in _rows) {
        r.dispose();
      }
      _rows
        ..clear()
        ..addAll(f.lines.map(_ReturnDraft.new));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _save({bool close = false}) async {
    setState(() => _saving = true);
    try {
      final repo = ref.read(materialRepositoryProvider);
      await repo.checkReturn(
        widget.ficheId,
        _rows
            .map((r) => {
                  'lineId': r.line.id,
                  'qtyReturned': int.tryParse(r.qty.text) ?? 0,
                  'returnState': r.lost ? 'MANQUANT' : r.state,
                  'isLost': r.lost || r.state == 'MANQUANT',
                  'isChecked': r.checked || r.lost,
                  'returnNotes': r.notes.text.trim().isEmpty
                      ? null
                      : r.notes.text.trim(),
                })
            .toList(),
      );
      if (close) {
        await repo.closeFiche(widget.ficheId);
      }
      ref.invalidate(fichesListProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(close ? 'Fiche clôturée' : 'Retour enregistré'),
          backgroundColor: AppColors.accent,
        ),
      );
      if (close) context.pop();
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
    if (_loading) return const Scaffold(body: AsOneLoader());
    final f = _fiche!;
    final equip = _rows.where((r) => r.line.item?.isEquipement == true).toList();
    final cons = _rows.where((r) => r.line.item?.isEquipement != true).toList();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Retour ${f.code}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            onPressed: () =>
                context.push('/magasinier/fiches/${f.id}/print'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        children: [
          Text(f.siteName,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 4),
          const Text(
            'Cochez les retours, signalez les pertes et les endommagements.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          const Text('Matériels et équipements (retour obligatoire)',
              style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          if (equip.isEmpty)
            const Text('Aucun équipement livré',
                style: TextStyle(color: AppColors.textTertiary)),
          ...equip.map(_row),
          const SizedBox(height: 16),
          const Text('Consommables (retour optionnel)',
              style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          ...cons.map(_row),
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
                      onPressed: () => _save(),
                      child: const Text('Enregistrer le contrôle'),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.tonal(
                      onPressed: () => _save(close: true),
                      child: const Text('Clôturer la fiche'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _row(_ReturnDraft r) {
    final item = r.line.item;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: r.checked,
                  onChanged: (v) => setState(() {
                    r.checked = v ?? false;
                    if (r.checked && r.lost) r.lost = false;
                  }),
                ),
                Expanded(
                  child: Text(
                    '${item?.refCode ?? ''}  ${item?.name ?? ''}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text('Livré ${r.line.qtyDelivered}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
            Row(
              children: [
                SizedBox(
                  width: 72,
                  child: TextField(
                    controller: r.qty,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Retour',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: r.lost ? 'MANQUANT' : r.state,
                    decoration: const InputDecoration(
                      labelText: 'État',
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'BON', child: Text('Bon')),
                      DropdownMenuItem(
                          value: 'DEGRADE', child: Text('Endommagé')),
                      DropdownMenuItem(
                          value: 'MANQUANT', child: Text('Perdu / non retourné')),
                    ],
                    onChanged: (v) => setState(() {
                      r.state = v ?? 'BON';
                      r.lost = v == 'MANQUANT';
                      if (r.lost) r.checked = true;
                    }),
                  ),
                ),
              ],
            ),
            TextField(
              controller: r.notes,
              decoration: const InputDecoration(
                labelText: 'Observations retour',
                isDense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
