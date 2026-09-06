import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/network/api_client.dart';
import '../repositories/sites_repository.dart';

/// Gestion opérations permanence : créneaux, effectifs, publication, candidatures.
class PermanenceOpsScreen extends ConsumerStatefulWidget {
  final String siteId;
  final SiteModel? site;

  const PermanenceOpsScreen({super.key, required this.siteId, this.site});

  @override
  ConsumerState<PermanenceOpsScreen> createState() =>
      _PermanenceOpsScreenState();
}

class _SlotForm {
  String start = '13:00';
  String end = '21:00';
  String salary = '4500';
  String required = '1';
  String label = '';
}

class _PermanenceOpsScreenState extends ConsumerState<PermanenceOpsScreen> {
  final _titleCtrl = TextEditingController();
  final _daysCtrl = TextEditingController(text: '6');
  final List<_SlotForm> _slots = [_SlotForm()];
  List<dynamic> _schedules = [];
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      final res =
          await api.dio.get('/permanence/schedules/site/${widget.siteId}');
      setState(() => _schedules = res.data as List<dynamic>? ?? []);
    } catch (_) {
      setState(() => _schedules = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    if (_slots.isEmpty) return;
    setState(() => _saving = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.dio.post('/permanence/schedules', data: {
        'siteId': widget.siteId,
        'title': _titleCtrl.text.trim().isEmpty
            ? null
            : _titleCtrl.text.trim(),
        'workDaysPerWeek': int.tryParse(_daysCtrl.text) ?? 6,
        'slots': _slots
            .map((s) => {
                  'startTime': s.start.trim(),
                  'endTime': s.end.trim(),
                  'salary': double.tryParse(s.salary) ?? 0,
                  'requiredAgents': int.tryParse(s.required) ?? 1,
                  'label': s.label.trim().isEmpty ? null : s.label.trim(),
                })
            .toList(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Planning créé (brouillon)'),
            backgroundColor: AppColors.accent,
          ),
        );
      }
      await _load();
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.extractError(e)),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _publish(String id) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.dio.post('/permanence/schedules/$id/publish');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offre envoyée à tous les agents'),
            backgroundColor: AppColors.accent,
          ),
        );
      }
      await _load();
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.extractError(e)),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _resolve(String appId, bool accept) async {
    String? msg;
    if (!accept) {
      msg = await showDialog<String>(
        context: context,
        builder: (ctx) {
          final ctrl = TextEditingController(
            text:
                'Merci pour votre candidature. Malheureusement ce créneau a été attribué à un autre profil. Nous vous recontacterons pour de prochaines opportunités.',
          );
          return AlertDialog(
            title: const Text('Message de refus'),
            content: TextField(
              controller: ctrl,
              maxLines: 4,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Annuler')),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, ctrl.text),
                child: const Text('Envoyer'),
              ),
            ],
          );
        },
      );
      if (msg == null) return;
    }
    try {
      final api = ref.read(apiClientProvider);
      await api.dio.patch('/permanence/applications/$appId', data: {
        'accept': accept,
        if (msg != null) 'rejectMessage': msg,
      });
      await _load();
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.extractError(e)),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final siteName = widget.site?.name ?? 'Permanence';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Ops permanence — $siteName'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Nouveau planning',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Titre (optionnel)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _daysCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Jours de travail / semaine',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                ..._slots.asMap().entries.map((e) {
                  final i = e.key;
                  final s = e.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Créneau ${i + 1}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField<String>(
                                  initialValue: s.start,
                                  decoration: const InputDecoration(
                                      labelText: 'Début',
                                      border: OutlineInputBorder()),
                                  onChanged: (v) => s.start = v ?? s.start,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField<String>(
                                  initialValue: s.end,
                                  decoration: const InputDecoration(
                                      labelText: 'Fin',
                                      border: OutlineInputBorder()),
                                  onChanged: (v) => s.end = v ?? s.end,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField<String>(
                                  initialValue: s.salary,
                                  decoration: const InputDecoration(
                                      labelText: 'Salaire / intervalle',
                                      border: OutlineInputBorder()),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) => s.salary = v ?? s.salary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField<String>(
                                  initialValue: s.required,
                                  decoration: const InputDecoration(
                                      labelText: 'Effectif',
                                      border: OutlineInputBorder()),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) =>
                                      s.required = v ?? s.required,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                TextButton.icon(
                  onPressed: () => setState(() => _slots.add(_SlotForm())),
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter un créneau'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _saving ? null : _create,
                  child: Text(_saving ? 'Enregistrement…' : 'Créer le planning'),
                ),
                const Divider(height: 32),
                const Text(
                  'Plannings existants',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 8),
                if (_schedules.isEmpty)
                  const Text('Aucun planning pour ce site.')
                else
                  ..._schedules.map((raw) {
                    final m = raw as Map<String, dynamic>;
                    final status = m['status'] as String? ?? '';
                    final slots = m['slots'] as List<dynamic>? ?? [];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    m['title'] as String? ?? 'Planning',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800),
                                  ),
                                ),
                                Chip(
                                  label: Text(status,
                                      style: const TextStyle(fontSize: 11)),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                            Text(
                              '${m['workDaysPerWeek'] ?? 6} j / semaine',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            ...slots.map((sr) {
                              final s = sr as Map<String, dynamic>;
                              final apps =
                                  s['applications'] as List<dynamic>? ?? [];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${s['startTime']}-${s['endTime']} · ${s['salary']} F · ${s['requiredAgents']} poste(s)',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                    ...apps.map((ar) {
                                      final a = ar as Map<String, dynamic>;
                                      final agent = a['agent']
                                              as Map<String, dynamic>? ??
                                          {};
                                      final st = a['status'] as String? ?? '';
                                      final name =
                                          '${agent['firstName'] ?? ''} ${agent['lastName'] ?? ''}'
                                              .trim();
                                      return ListTile(
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        title: Text('$name · $st'),
                                        trailing: st == 'PENDING'
                                            ? Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(
                                                        Icons.check,
                                                        color: AppColors.accent),
                                                    onPressed: () => _resolve(
                                                        a['id'] as String,
                                                        true),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                        Icons.close,
                                                        color: AppColors.danger),
                                                    onPressed: () => _resolve(
                                                        a['id'] as String,
                                                        false),
                                                  ),
                                                ],
                                              )
                                            : null,
                                      );
                                    }),
                                  ],
                                ),
                              );
                            }),
                            if (status == 'DRAFT')
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      _publish(m['id'] as String),
                                  icon: const Icon(Icons.send),
                                  label: const Text(
                                      'Envoyer l\'offre aux agents'),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}
