import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/asone_loader.dart';
import '../repositories/material_repository.dart';

class FichePrintScreen extends ConsumerWidget {
  final String ficheId;
  const FichePrintScreen({super.key, required this.ficheId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<MaterialFiche>(
      future: ref.read(materialRepositoryProvider).getFiche(ficheId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Fiche')),
            body: snap.hasError
                ? Center(child: Text('${snap.error}'))
                : const AsOneLoader(),
          );
        }
        final f = snap.data!;
        return Scaffold(
          backgroundColor: const Color(0xFFF3F4F6),
          appBar: AppBar(
            title: Text(f.code),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () => Share.share(_asText(f)),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _Paper(f),
              ),
            ),
          ),
        );
      },
    );
  }

  String _asText(MaterialFiche f) {
    final buf = StringBuffer()
      ..writeln('AS ONE — FICHE F-ACH-07')
      ..writeln(f.code)
      ..writeln('Site : ${f.siteName}')
      ..writeln('Demandeur : ${f.requesterName}')
      ..writeln('Date : ${f.requestDate ?? ''}')
      ..writeln('--- PRODUITS ET CONSOMMABLES ---');
    for (final l in f.lines.where((e) => e.item?.isEquipement != true)) {
      buf.writeln(
          '${l.item?.refCode} ${l.item?.name}  dem=${l.qtyRequested} liv=${l.qtyDelivered} ret=${l.qtyReturned}');
    }
    buf.writeln('--- MATERIELS ET EQUIPEMENTS ---');
    for (final l in f.lines.where((e) => e.item?.isEquipement == true)) {
      buf.writeln(
          '${l.item?.refCode} ${l.item?.name}  dem=${l.qtyRequested} liv=${l.qtyDelivered} ret=${l.qtyReturned} ${l.returnState ?? ''}');
    }
    return buf.toString();
  }
}

class _Paper extends StatelessWidget {
  final MaterialFiche f;
  const _Paper(this.f);

  String _d(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return DateFormat('dd/MM/yyyy').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final cons = f.lines.where((e) => e.item?.isEquipement != true).toList();
    final eq = f.lines.where((e) => e.item?.isEquipement == true).toList();
    return DefaultTextStyle(
      style: const TextStyle(color: Colors.black87, fontSize: 11, height: 1.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text('AS ONE',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: AppColors.primary)),
              const Spacer(),
              const Text('FICHE',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              const Spacer(),
              Text('Date : ${_d(f.requestDate)}\n${f.code}',
                  textAlign: TextAlign.right),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'DEMANDE DE PRODUITS ET DE MATERIELS SITES TEMPORAIRES',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
          ),
          const Divider(thickness: 1.2),
          _kv('SITE / CHANTIER', f.siteName),
          _kv('DATE DE DEMANDE', _d(f.requestDate)),
          _kv('DATE DE RETOUR', _d(f.plannedReturn)),
          _kv('SECTEUR D\'ACTIVITE', f.sector ?? ''),
          _kv('CHEF D\'EQUIPE', f.requesterName),
          _kv('NBRE DE JOUR', '${f.dayCount ?? 1}'),
          _kv('NBRE DE PERSONNE', '${f.personCount ?? ''}'),
          _kv('NBRE D\'ESPACE', '${f.spaceCount ?? ''}'),
          const SizedBox(height: 10),
          _table('SORTIE DE STOCK — PRODUITS ET CONSOMMABLES', cons),
          const SizedBox(height: 10),
          _table('MATERIELS ET EQUIPEMENTS', eq),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _sign('DEMANDEUR', f.requesterName)),
              Expanded(child: _sign('RESPONSABLE DES OPERATIONS', '')),
              Expanded(child: _sign('GESTIONNAIRE DE STOCK', f.magasinierName)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          SizedBox(
              width: 150,
              child: Text(k,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 10))),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(border: Border.all(color: Colors.black26)),
              child: Text(v.isEmpty ? ' ' : v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _table(String title, List<MaterialFicheLine> lines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: const Color(0xFFE2E8F0),
          padding: const EdgeInsets.all(4),
          child: Text(title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 10)),
        ),
        Table(
          border: TableBorder.all(color: Colors.black54, width: 0.6),
          columnWidths: const {
            0: FlexColumnWidth(1.4),
            1: FlexColumnWidth(2.4),
            2: FlexColumnWidth(0.9),
            3: FlexColumnWidth(0.9),
            4: FlexColumnWidth(0.9),
            5: FlexColumnWidth(1.6),
          },
          children: [
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
              children: [
                _th('Réf'),
                _th('Désignation'),
                _th('Qté dem.'),
                _th('Qté livré'),
                _th('Retour'),
                _th('Observations'),
              ],
            ),
            if (lines.isEmpty)
              TableRow(children: List.generate(6, (_) => _td(' '))),
            ...lines.map(
              (l) => TableRow(children: [
                _td(l.item?.refCode ?? ''),
                _td(l.item?.name ?? ''),
                _td('${l.qtyRequested}'),
                _td('${l.qtyDelivered}'),
                _td(l.qtyReturned > 0
                    ? '${l.qtyReturned}${l.returnState == 'DEGRADE' ? ' E' : l.isLost ? ' P' : ''}'
                    : ''),
                _td(l.outNotes ?? l.returnNotes ?? ''),
              ]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _th(String t) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Text(t,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 10)),
    );
  }

  Widget _td(String t) => Padding(
        padding: const EdgeInsets.all(4),
        child: Text(t, style: const TextStyle(fontSize: 10)),
      );

  Widget _sign(String title, String name) {
    return Container(
      height: 72,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(border: Border.all(color: Colors.black54)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800)),
          const Spacer(),
          Text(name, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
