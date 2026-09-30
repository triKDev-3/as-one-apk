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

class _ComposeTeamScreenState extends ConsumerState<ComposeTeamScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final Set<String> _selectedAgentIds = {};
  final Set<String> _assigningIds = {};
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime? _endDate;
  String _missionType = 'TEMPORAIRE';
  final Set<int> _routineDays = {};
  final _salaryCtrl = TextEditingController();
  String _contractFilter = 'ALL';
  String _sortMode = 'score';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _salaryCtrl.dispose();
    super.dispose();
  }

  String get _startStr => DateFormat('yyyy-MM-dd').format(_startDate);
  String? get _endStr =>
      _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null;

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
              '${agent.canForceMultiSite ? 'Il a un pointage DEPART aujourd\'hui \u2192 urgence multi-chantiers possible.' : 'Sans pointage DEPART ce jour, vous ne pouvez pas forcer.\nLibérez-le d\'abord ou attendez un pointage.'}',
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
    final agentsSnapshot =
        ref.read(availableAgentsProvider(widget.siteId)).valueOrNull ?? [];
    final selectedAgents =
        agentsSnapshot.where((a) => _selectedAgentIds.contains(a.id)).toList();

    int success = 0;
    int failed = 0;
    int skipped = 0;
    String? lastError;
    final assignedAgents = <AvailableAgent>[];

    for (final agent in selectedAgents) {
      bool force = false;

      if (agent.isLockedElsewhere || agent.lockedOnSites.isNotEmpty) {
        final action = await _resolveMultiSiteDialog(agent);
        if (action == 'skip') {
          skipped++;
          _selectedAgentIds.remove(agent.id);
          continue;
        }
        if (action == 'force') force = true;
      }

      setState(() => _assigningIds.add(agent.id));
      try {
        await repo.createAssignment(
          siteId: widget.siteId,
          agentId: agent.id,
          startDate: _startStr,
          endDate: _endStr,
          missionType: _missionType,
          routineDays:
              _missionType == 'ROUTINE' ? _routineDays.toList() : null,
          fixedSalary: _missionType == 'PERMANENCE'
              ? double.tryParse(_salaryCtrl.text)
              : null,
          forceMultiSite: force,
        );
        success++;
        assignedAgents.add(agent);
        _selectedAgentIds.remove(agent.id);
      } catch (e) {
        failed++;
        lastError = e.toString();
      } finally {
        if (mounted) setState(() => _assigningIds.remove(agent.id));
      }
    }

    ref.invalidate(availableAgentsProvider(widget.siteId));
    ref.invalidate(siteAssignmentsProvider(widget.siteId));

    if (!mounted) return;

    if (success > 0 && assignedAgents.isNotEmpty) {
      final names = assignedAgents.map((a) => a.fullName).join(', ');
      final phones = assignedAgents
          .map((a) => a.phone)
          .where((p) => p.isNotEmpty)
          .toList();
      final siteName = widget.site?.name ?? 'chantier';
      final msg =
          '\ud83d\udccb *Convocation AS ONE*\n'
          'Vous êtes convoqué(e) sur *$siteName* à partir du *${DateFormat('dd/MM/yyyy').format(_startDate)}*.\n'
          'Confirmez avant 23h la veille dans l\'application.';
      try {
        if (phones.isNotEmpty) {
          await WhatsAppHelper.openWhatsApp(
            phone: phones.length == 1 ? phones.first : '',
            message: msg + (phones.length > 1 ? '\n\n($names)' : ''),
          );
        }
      } catch (_) {}
    }

    final parts = <String>[];
    if (success > 0) parts.add('$success affecté(s)');
    if (skipped > 0) parts.add('$skipped ignoré(s)');
    if (failed > 0) parts.add('$failed échec(s)');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          parts.isEmpty
              ? 'Aucune affectation'
              : parts.join(' \u00b7 ') +
                  (lastError != null && failed > 0 ? '\n$lastError' : ''),
        ),
        backgroundColor: failed > 0 && success == 0
            ? AppColors.danger
            : AppColors.accent,
      ),
    );
  }

  Future<void> _release(AssignmentModel a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Libérer l\'agent ?'),
        content: Text(
          '${a.agentName} sera retiré de l\'équipe et redeviendra disponible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Libérer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(assignmentsRepositoryProvider).releaseAgent(a.id);
      ref.invalidate(availableAgentsProvider(widget.siteId));
      ref.invalidate(siteAssignmentsProvider(widget.siteId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Agent libéré \u2014 de nouveau disponible'),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _pickStart() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _startDate = d);
  }

  Future<void> _pickEnd() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (d != null) setState(() => _endDate = d);
  }

  List<AvailableAgent> _filterSort(List<AvailableAgent> agents) {
    var list = List<AvailableAgent>.from(agents);
    // Défense UI : exclure ceux déjà dans Affectés pour la date choisie
    final assigned =
        ref.read(siteAssignmentsProvider(widget.siteId)).valueOrNull ?? [];
    final assignedIds = assigned
        .where((a) => a.coversDate(_startStr))
        .map((a) => a.agentId)
        .toSet();
    list = list.where((a) => !assignedIds.contains(a.id)).toList();

    if (_contractFilter != 'ALL') {
      list = list.where((a) => a.contractType == _contractFilter).toList();
    }
    if (_sortMode == 'score') {
      list.sort((a, b) => b.rankingScore.compareTo(a.rankingScore));
    } else if (_sortMode == 'name') {
      list.sort((a, b) => a.fullName.compareTo(b.fullName));
    } else if (_sortMode == 'days') {
      list.sort((a, b) => b.daysWorked.compareTo(a.daysWorked));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final siteName = widget.site?.name ?? 'Site';
    final availableAsync = ref.watch(availableAgentsProvider(widget.siteId));
    final assignedAsync = ref.watch(siteAssignmentsProvider(widget.siteId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Équipe \u2014 $siteName'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
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
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _typeChip('TEMPORAIRE', 'Temporaire'),
                    const SizedBox(width: 6),
                    _typeChip('ROUTINE', 'Routine'),
                    const SizedBox(width: 6),
                    _typeChip('PERMANENCE', 'Permanence'),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickStart,
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          'Début ${DateFormat('dd/MM/yyyy').format(_startDate)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickEnd,
                        icon: const Icon(Icons.event, size: 16),
                        label: Text(
                          _endDate == null
                              ? 'Fin (opt.)'
                              : 'Fin ${DateFormat('dd/MM/yyyy').format(_endDate!)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    if (_missionType == 'PERMANENCE') ...[
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: _salaryCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Salaire',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabs,
            labelColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Disponibles'),
              Tab(text: 'Affectés'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                availableAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('$e')),
                  data: (agents) {
                    final list = _filterSort(agents);
                    if (list.isEmpty) {
                      return const Center(
                        child: Text(
                          'Aucun agent disponible\n(les agents déjà affectés n\'apparaissent plus ici)',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      );
                    }
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: Row(
                            children: [
                              Text(
                                '${list.length} dispo.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const Spacer(),
                              if (_selectedAgentIds.isNotEmpty)
                                Text(
                                  '${_selectedAgentIds.length} sélectionné(s)',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                            itemCount: list.length,
                            itemBuilder: (_, i) {
                              final a = list[i];
                              final selected =
                                  _selectedAgentIds.contains(a.id);
                              final busy = _assigningIds.contains(a.id);
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: selected
                                        ? AppColors.primary
                                        : AppColors.primary
                                            .withValues(alpha: 0.12),
                                    child: selected
                                        ? const Icon(Icons.check,
                                            color: Colors.white)
                                        : Text(
                                            a.firstName.isNotEmpty
                                                ? a.firstName[0]
                                                : '?',
                                            style: TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                  ),
                                  title: Text(
                                    a.fullName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700),
                                  ),
                                  subtitle: Text(
                                    [
                                      if (a.rankingScore > 0)
                                        'Score ${a.rankingScore.toStringAsFixed(1)}',
                                      if (a.isLockedElsewhere)
                                        'Occupé ailleurs',
                                      if (a.isUnavailableOn(_startStr))
                                        'Indispo. ce jour',
                                    ].join(' \u00b7 '),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: a.isLockedElsewhere
                                          ? AppColors.danger
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                  trailing: busy
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
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
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
                assignedAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('$e')),
                  data: (items) {
                    final covering =
                        items.where((a) => a.coversDate(_startStr)).toList();
                    if (covering.isEmpty) {
                      return const Center(
                        child: Text(
                          'Aucun agent affecté pour cette date',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
                      itemCount: covering.length,
                      itemBuilder: (_, i) {
                        final a = covering[i];
                        final day = (a.startDate ?? '').length >= 10
                            ? a.startDate!
                                .substring(5, 10)
                                .replaceAll('-', '/')
                            : '';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              a.agentName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              '${a.status} \u00b7 $day',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (v) {
                                if (v == 'release') _release(a);
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'release',
                                  child: Text('Libérer'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _selectedAgentIds.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _assigningIds.isEmpty ? _assignSelected : null,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.person_add),
              label: Text('Affecter (${_selectedAgentIds.length})'),
            ),
    );
  }

  Widget _typeChip(String value, String label) {
    final on = _missionType == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _missionType = value),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: on ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: on ? AppColors.primary : AppColors.border,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            on ? '\u2713 $label' : label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: on ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
