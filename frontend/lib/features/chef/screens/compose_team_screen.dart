import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/utils/whatsapp_helper.dart';
import '../repositories/sites_repository.dart';
import '../repositories/assignments_repository.dart';

class ComposeTeamScreen extends ConsumerStatefulWidget {
  final String siteId;
  final SiteModel? site;

  const ComposeTeamScreen({
    super.key,
    required this.siteId,
    this.site,
  });

  @override
  ConsumerState<ComposeTeamScreen> createState() => _ComposeTeamScreenState();
}

class _ComposeTeamScreenState extends ConsumerState<ComposeTeamScreen> {
  final Set<String> _selectedAgentIds = {};
  final Set<String> _assigningIds = {};
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime? _endDate;
  String _missionType = 'TEMPORAIRE';
  final Set<int> _routineDays = {};
  final _salaryCtrl = TextEditingController();

  String _contractFilter = 'ALL';
  String _sortMode = 'score';

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<String> _resolveMultiSiteDialog(AvailableAgent agent) async {
    final sites = agent.lockedSitesLabel.isEmpty
        ? 'un autre chantier'
        : agent.lockedSitesLabel;

    return await showDialog<String>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Conflit multi-sites'),
            content: Text(
              '${agent.fullName} est déjà affecté sur :\n\n$sites\n\n'
              '${agent.canForceMultiSite
                  ? 'Il a un pointage DEPART aujourd\'hui → urgence multi-chantiers possible.'
                  : 'Sans pointage DEPART ce jour, vous ne pouvez pas forcer.\nLibérez-le d\'abord ou attendez un pointage.'}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, 'skip'),
                child: const Text('Ignorer cet agent'),
              ),
              if (agent.canForceMultiSite)
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, 'force'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                  ),
                  child: const Text('Forcer (urgence)'),
                )
              else
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, 'skip'),
                  child: const Text('OK',
                      style: TextStyle(color: AppColors.danger)),
                ),
            ],
          ),
        ) ??
        'skip';
  }

  Future<void> _assignSelected() async {
    if (_selectedAgentIds.isEmpty) return;

    final repo = ref.read(assignmentsRepositoryProvider);
    final available =
        ref.read(availableAgentsProvider(widget.siteId)).valueOrNull ?? [];
    final byId = {for (final a in available) a.id: a};

    int ok = 0;
    int skipped = 0;
    final errors = <String>[];

    for (final id in _selectedAgentIds.toList()) {
      final agent = byId[id];
      if (agent == null) continue;

      bool force = false;
      if (agent.isLockedElsewhere) {
        final choice = await _resolveMultiSiteDialog(agent);
        if (choice == 'skip') {
          skipped++;
          continue;
        }
        if (choice == 'force') force = true;
      }

      setState(() => _assigningIds.add(id));
      try {
        await repo.createAssignment(
          siteId: widget.siteId,
          agentId: id,
          startDate: _fmtDate(_startDate),
          endDate: _endDate != null ? _fmtDate(_endDate!) : null,
          missionType: _missionType,
          routineDays:
              _missionType == 'ROUTINE' ? _routineDays.toList() : null,
          fixedSalary:
              double.tryParse(_salaryCtrl.text.replaceAll(',', '.')),
          forceMultiSite: force,
        );
        ok++;
        _selectedAgentIds.remove(id);
      } catch (e) {
        errors.add('${agent.fullName}: $e');
      } finally {
        if (mounted) setState(() => _assigningIds.remove(id));
      }
    }

    ref.invalidate(availableAgentsProvider(widget.siteId));
    ref.invalidate(siteAssignmentsProvider(widget.siteId));

    if (!mounted) return;
    final msg = [
      if (ok > 0) '$ok affecté(s)',
      if (skipped > 0) '$skipped ignoré(s)',
      if (errors.isNotEmpty) '${errors.length} erreur(s)',
    ].join(' · ');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg.isEmpty ? 'Rien à faire' : msg),
        backgroundColor:
            errors.isNotEmpty ? AppColors.danger : AppColors.success,
      ),
    );
    if (errors.isNotEmpty) {
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Erreurs'),
          content: SingleChildScrollView(child: Text(errors.join('\n\n'))),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c), child: const Text('OK')),
          ],
        ),
      );
    }
  }

  Future<void> _releaseAgent(String assignmentId, String agentName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Libérer l\'agent'),
        content: Text(
          'Libérer $agentName de ce site ?\n\n'
          'L\'affectation sera annulée et l\'agent redevient disponible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Libérer'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ref.read(assignmentsRepositoryProvider).releaseAgent(assignmentId);
      ref.invalidate(availableAgentsProvider(widget.siteId));
      ref.invalidate(siteAssignmentsProvider(widget.siteId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$agentName libéré'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Échec libération: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _showNotifySheet(AssignmentModel assignment) {
    final siteName = widget.site?.name ?? 'Site';
    final start = (assignment.startDate ?? '').length >= 10
        ? assignment.startDate!.substring(0, 10)
        : _fmtDate(DateTime.now());
    final end = (assignment.endDate ?? '').length >= 10
        ? assignment.endDate!.substring(0, 10)
        : null;

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.send, color: Color(0xFF25D366)),
              title: const Text('Renvoyer message d\'affectation'),
              subtitle: const Text('WhatsApp — convocation initiale'),
              onTap: () async {
                Navigator.pop(sheetContext);
                final msg = WhatsAppHelper.assignmentMessage(
                  agentName: assignment.agentName,
                  siteName: siteName,
                  startDate: start,
                  endDate: end,
                );
                await WhatsAppHelper.openWhatsApp(
                  phone: assignment.agentPhone,
                  message: msg,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copier le message'),
              subtitle: const Text('Coller dans WhatsApp / SMS'),
              onTap: () async {
                Navigator.pop(sheetContext);
                final msg = WhatsAppHelper.assignmentMessage(
                  agentName: assignment.agentName,
                  siteName: siteName,
                  startDate: start,
                  endDate: end,
                );
                await WhatsAppHelper.copyMessage(msg);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Message copié')),
                );
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.notifications_active, color: Color(0xFF25D366)),
              title: const Text('Rappel jour J'),
              subtitle: const Text('WhatsApp — confirmer avant 23h la veille'),
              onTap: () async {
                Navigator.pop(sheetContext);
                final msg = WhatsAppHelper.assignmentReminderMessage(
                  agentName: assignment.agentName,
                  siteName: siteName,
                  startDate: start,
                  endDate: end,
                );
                await WhatsAppHelper.openWhatsApp(
                  phone: assignment.agentPhone,
                  message: msg,
                );
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.person_remove, color: AppColors.danger),
              title: const Text('Libérer l\'agent'),
              onTap: () {
                Navigator.pop(sheetContext);
                _releaseAgent(assignment.id, assignment.agentName);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickStartDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _startDate = d);
  }

  Future<void> _pickEndDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(const Duration(days: 7)),
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (d != null) setState(() => _endDate = d);
  }

  @override
  void dispose() {
    _salaryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final siteName = widget.site?.name ?? 'Site';
    final availableAsync = ref.watch(availableAgentsProvider(widget.siteId));
    final assignedAsync = ref.watch(siteAssignmentsProvider(widget.siteId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Équipe — $siteName'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(availableAgentsProvider(widget.siteId));
              ref.invalidate(siteAssignmentsProvider(widget.siteId));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildMissionParams(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth > 600;
                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _buildAvailablePanel(availableAsync)),
                      const VerticalDivider(width: 1),
                      Expanded(child: _buildAssignedPanel(assignedAsync)),
                    ],
                  );
                }
                return DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      const TabBar(
                        tabs: [
                          Tab(text: 'Disponibles'),
                          Tab(text: 'Affectés'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildAvailablePanel(availableAsync),
                            _buildAssignedPanel(assignedAsync),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_selectedAgentIds.isNotEmpty)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _assigningIds.isEmpty ? _assignSelected : null,
                    icon: _assigningIds.isNotEmpty
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.group_add),
                    label: Text(
                      'Affecter ${_selectedAgentIds.length} agent(s)',
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMissionParams() {
    final df = DateFormat('dd/MM/yyyy');
    return Material(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('Temporaire'),
                  selected: _missionType == 'TEMPORAIRE',
                  onSelected: (_) =>
                      setState(() => _missionType = 'TEMPORAIRE'),
                ),
                ChoiceChip(
                  label: const Text('Routine'),
                  selected: _missionType == 'ROUTINE',
                  onSelected: (_) => setState(() => _missionType = 'ROUTINE'),
                ),
                ChoiceChip(
                  label: const Text('Permanence'),
                  selected: _missionType == 'PERMANENCE',
                  onSelected: (_) =>
                      setState(() => _missionType = 'PERMANENCE'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.calendar_today, size: 16),
                  label: Text('Début ${df.format(_startDate)}'),
                  onPressed: _pickStartDate,
                ),
                ActionChip(
                  avatar: const Icon(Icons.event, size: 16),
                  label: Text(_endDate == null
                      ? 'Fin (opt.)'
                      : 'Fin ${df.format(_endDate!)}'),
                  onPressed: _pickEndDate,
                ),
                SizedBox(
                  width: 110,
                  height: 36,
                  child: TextField(
                    controller: _salaryCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: 'Salaire',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
            if (_missionType == 'ROUTINE') ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                children: List.generate(7, (i) {
                  const labels = [
                    'Lun',
                    'Mar',
                    'Mer',
                    'Jeu',
                    'Ven',
                    'Sam',
                    'Dim'
                  ];
                  final selected = _routineDays.contains(i + 1);
                  return FilterChip(
                    label: Text(labels[i]),
                    selected: selected,
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _routineDays.add(i + 1);
                        } else {
                          _routineDays.remove(i + 1);
                        }
                      });
                    },
                  );
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvailablePanel(AsyncValue<List<AvailableAgent>> async) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              const Text('Disponibles',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              DropdownButton<String>(
                value: _contractFilter,
                isDense: true,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 'ALL', child: Text('Tous')),
                  DropdownMenuItem(value: 'CDI', child: Text('CDI')),
                  DropdownMenuItem(value: 'CDD', child: Text('CDD')),
                  DropdownMenuItem(
                      value: 'TEMPORAIRE', child: Text('Temporaire')),
                  DropdownMenuItem(
                      value: 'JOURNALIER', child: Text('Journalier')),
                ],
                onChanged: (v) =>
                    setState(() => _contractFilter = v ?? 'ALL'),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _sortMode,
                isDense: true,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 'score', child: Text('Score')),
                  DropdownMenuItem(value: 'name', child: Text('Nom')),
                ],
                onChanged: (v) => setState(() => _sortMode = v ?? 'score'),
              ),
            ],
          ),
        ),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erreur: $e')),
            data: (list) {
              var filtered = list;
              if (_contractFilter != 'ALL') {
                filtered = filtered
                    .where((a) => a.contractType == _contractFilter)
                    .toList();
              }
              if (_sortMode == 'name') {
                filtered = [...filtered]
                  ..sort((a, b) => a.fullName.compareTo(b.fullName));
              } else {
                filtered = [...filtered]
                  ..sort(
                      (a, b) => b.rankingScore.compareTo(a.rankingScore));
              }
              if (filtered.isEmpty) {
                return const Center(child: Text('Aucun agent disponible'));
              }
              return ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (ctx, i) {
                  final a = filtered[i];
                  final selected = _selectedAgentIds.contains(a.id);
                  final busy = _assigningIds.contains(a.id);
                  return ListTile(
                    dense: true,
                    selected: selected,
                    leading: Checkbox(
                      value: selected,
                      onChanged: busy
                          ? null
                          : (v) {
                              setState(() {
                                if (v == true) {
                                  _selectedAgentIds.add(a.id);
                                } else {
                                  _selectedAgentIds.remove(a.id);
                                }
                              });
                            },
                    ),
                    title:
                        Text(a.fullName, style: const TextStyle(fontSize: 14)),
                    subtitle: Text(
                      [
                        a.contractType,
                        'Score ${a.rankingScore.toStringAsFixed(0)}',
                        if (a.isLockedElsewhere) '⚠️ multi-sites',
                      ].join(' · '),
                      style: TextStyle(
                        fontSize: 12,
                        color: a.isLockedElsewhere
                            ? AppColors.warning
                            : null,
                      ),
                    ),
                    trailing: busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                    onTap: busy
                        ? null
                        : () {
                            setState(() {
                              if (selected) {
                                _selectedAgentIds.remove(a.id);
                              } else {
                                _selectedAgentIds.add(a.id);
                              }
                            });
                          },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAssignedPanel(AsyncValue<List<AssignmentModel>> async) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Text('Affectés',
              style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erreur: $e')),
            data: (list) {
              if (list.isEmpty) {
                return const Center(child: Text('Aucun agent affecté'));
              }
              return ListView.builder(
                itemCount: list.length,
                itemBuilder: (ctx, i) {
                  final a = list[i];
                  String startLabel = '—';
                  if ((a.startDate ?? '').length >= 10) {
                    try {
                      final d = DateTime.parse(a.startDate!);
                      startLabel = DateFormat('dd/MM').format(d);
                    } catch (_) {
                      startLabel = a.startDate!.substring(0, 10);
                    }
                  }
                  String endLabel = '';
                  if ((a.endDate ?? '').length >= 10) {
                    try {
                      final d = DateTime.parse(a.endDate!);
                      endLabel = ' → ${DateFormat('dd/MM').format(d)}';
                    } catch (_) {
                      endLabel = ' → ${a.endDate!.substring(0, 10)}';
                    }
                  }
                  return ListTile(
                    dense: true,
                    title: Text(a.agentName,
                        style: const TextStyle(fontSize: 14)),
                    subtitle: Text(
                      '${a.status} · $startLabel$endLabel',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.more_vert, size: 20),
                      onPressed: () => _showNotifySheet(a),
                    ),
                    onTap: () => _showNotifySheet(a),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
