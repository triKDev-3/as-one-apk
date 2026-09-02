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

  /// Dialogue conflit multi-sites → force | skip | cancel batch
  Future<String> _resolveMultiSiteDialog(AvailableAgent agent) async {
    final sites = agent.lockedSitesLabel.isEmpty
        ? 'un autre chantier'
        : agent.lockedSitesLabel;

    return await showDialog<String>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Conflit multi-sites'),
            content: Text(
              '${agent.fullName} est déjà affecté sur :\n\n$sites\n\n'
              '${agent.canForceMultiSite
                  ? 'Il a un pointage DEPART aujourd\'hui → urgence multi-chantiers possible.'
                  : 'Sans pointage DEPART ce jour, vous ne pouvez pas forcer.\nLibérez-le d\'abord ou attendez un pointage.'}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, 'skip'),
                child: const Text('Ignorer cet agent'),
              ),
              if (agent.canForceMultiSite)
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, 'force'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                  ),
                  child: const Text('Forcer (urgence)'),
                )
              else
                TextButton(
                  onPressed: () => Navigator.pop(context, 'skip'),
                  child: const Text('OK', style: TextStyle(color: AppColors.danger)),
                ),
            ],
          ),
        ) ??
        'skip';
  }

  Future<void> _assignSelected() async {
    if (_selectedAgentIds.isEmpty) return;

    final repo = ref.read(assignmentsRepositoryProvider);
    final startStr = DateFormat('yyyy-MM-dd').format(_startDate);
    final endStr =
        _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null;

    final agentsSnapshot =
        ref.read(availableAgentsProvider(widget.siteId)).valueOrNull ?? [];
    final selectedAgents = agentsSnapshot
        .where((a) => _selectedAgentIds.contains(a.id))
        .toList();

    int success = 0;
    int failed = 0;
    int skipped = 0;
    String? lastError;
    final assignedAgents = <AvailableAgent>[];

    for (final agent in selectedAgents) {
      bool force = false;

      // Prévention UI si déjà en conflit connu
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
          startDate: startStr,
          endDate: endStr,
          missionType: _missionType,
          routineDays:
              _missionType == 'ROUTINE' ? _routineDays.toList() : null,
          fixedSalary: _missionType == 'PERMANENTE'
              ? double.tryParse(_salaryCtrl.text)
              : null,
          forceMultiSite: force,
        );
        success++;
        assignedAgents.add(agent);
        _selectedAgentIds.remove(agent.id);
      } catch (e) {
        final err = e.toString();
        // Conflit renvoyé par l'API (ex. dates chevauchantes non détectées côté UI)
        if (err.contains('MULTI_SITE') ||
            err.toLowerCase().contains('multi-sites') ||
            err.toLowerCase().contains('verrouillé')) {
          if (!force && agent.canForceMultiSite && mounted) {
            final action = await _resolveMultiSiteDialog(agent);
            if (action == 'force') {
              try {
                await repo.createAssignment(
                  siteId: widget.siteId,
                  agentId: agent.id,
                  startDate: startStr,
                  endDate: endStr,
                  missionType: _missionType,
                  routineDays: _missionType == 'ROUTINE'
                      ? _routineDays.toList()
                      : null,
                  fixedSalary: _missionType == 'PERMANENTE'
                      ? double.tryParse(_salaryCtrl.text)
                      : null,
                  forceMultiSite: true,
                );
                success++;
                assignedAgents.add(agent);
                _selectedAgentIds.remove(agent.id);
                continue;
              } catch (e2) {
                failed++;
                lastError = e2.toString();
              }
            } else {
              skipped++;
              _selectedAgentIds.remove(agent.id);
            }
          } else {
            failed++;
            lastError = err;
          }
        } else {
          failed++;
          lastError = err;
        }
      } finally {
        if (mounted) {
          setState(() => _assigningIds.remove(agent.id));
        }
      }
    }

    ref.invalidate(siteAssignmentsProvider(widget.siteId));
    ref.invalidate(availableAgentsProvider);

    if (!mounted) return;

    final parts = <String>[];
    if (success > 0) parts.add('$success OK');
    if (skipped > 0) parts.add('$skipped ignoré(s)');
    if (failed > 0) {
      parts.add('$failed échec${lastError != null ? ' : $lastError' : ''}');
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(parts.isEmpty ? 'Aucune action' : parts.join(' · ')),
        backgroundColor: failed == 0 ? AppColors.accent : AppColors.warning,
      ),
    );

    if (assignedAgents.isNotEmpty && mounted) {
      _showMessageOptions(assignedAgents);
    }
  }

  void _showMessageOptions(List<AvailableAgent> agents) {
    final siteName = widget.site?.name ?? 'site';
    final startStr = DateFormat('dd/MM/yyyy').format(_startDate);
    final endStr =
        _endDate != null ? DateFormat('dd/MM/yyyy').format(_endDate!) : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Notifier les agents',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              ...agents.map((agent) {
                final msg = WhatsAppHelper.assignmentMessage(
                  agentName: agent.fullName,
                  siteName: siteName,
                  startDate: startStr,
                  endDate: endStr,
                  missionType: _missionType,
                  routineDays: _missionType == 'ROUTINE'
                      ? _routineDays.toList()
                      : null,
                );
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(agent.fullName),
                  subtitle: Text(agent.phone),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chat, color: Color(0xFF25D366)),
                        onPressed: () => WhatsAppHelper.openWhatsApp(
                          phone: agent.phone,
                          message: msg,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.sms_outlined,
                            color: AppColors.primary),
                        onPressed: () => WhatsAppHelper.openSms(
                          phone: agent.phone,
                          message: msg,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Fermer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate.add(const Duration(days: 1)),
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final siteName = widget.site?.name ?? 'Site';
    final agentsAsync = ref.watch(availableAgentsProvider(widget.siteId));
    final currentAsync = ref.watch(siteAssignmentsProvider(widget.siteId));
    final startKey = DateFormat('yyyy-MM-dd').format(_startDate);

    final alreadyAssignedIds = <String>{};
    currentAsync.whenData((list) {
      for (final a in list) {
        alreadyAssignedIds.add(a.agentId);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(siteName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _missionType,
                  decoration:
                      const InputDecoration(labelText: 'Type de mission'),
                  items: const [
                    DropdownMenuItem(
                        value: 'TEMPORAIRE',
                        child: Text('Chantier / Temporaire')),
                    DropdownMenuItem(
                        value: 'ROUTINE',
                        child: Text('Routine (ex: chaque mardi)')),
                    DropdownMenuItem(
                        value: 'PERMANENTE', child: Text('Permanence')),
                  ],
                  onChanged: (v) =>
                      setState(() => _missionType = v ?? 'TEMPORAIRE'),
                ),
                const SizedBox(height: 12),
                if (_missionType == 'TEMPORAIRE')
                  Row(
                    children: [
                      Expanded(
                        child: _DateChip(
                          label: 'Début',
                          value: DateFormat('dd/MM/yyyy').format(_startDate),
                          onTap: _pickStartDate,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _DateChip(
                          label: 'Fin (optionnel)',
                          value: _endDate != null
                              ? DateFormat('dd/MM/yyyy').format(_endDate!)
                              : '—',
                          onTap: _pickEndDate,
                        ),
                      ),
                    ],
                  ),
                if (_missionType == 'ROUTINE')
                  Wrap(
                    spacing: 8,
                    children: [1, 2, 3, 4, 5, 6, 7].map((day) {
                      final labels = [
                        'Lun',
                        'Mar',
                        'Mer',
                        'Jeu',
                        'Ven',
                        'Sam',
                        'Dim'
                      ];
                      return ChoiceChip(
                        label: Text(labels[day - 1]),
                        selected: _routineDays.contains(day),
                        onSelected: (val) {
                          setState(() {
                            if (val) {
                              _routineDays.add(day);
                            } else {
                              _routineDays.remove(day);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                if (_missionType == 'PERMANENTE')
                  Row(
                    children: [
                      Expanded(
                        child: _DateChip(
                          label: 'Date de début',
                          value: DateFormat('dd/MM/yyyy').format(_startDate),
                          onTap: _pickStartDate,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _salaryCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Salaire Fixe',
                            suffixText: 'FCFA',
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'Tous',
                          selected: _contractFilter == 'ALL',
                          onTap: () =>
                              setState(() => _contractFilter = 'ALL'),
                        ),
                        const SizedBox(width: 6),
                        _FilterChip(
                          label: 'Permanents',
                          selected: _contractFilter == 'PERMANENT',
                          color: AppColors.primary,
                          onTap: () =>
                              setState(() => _contractFilter = 'PERMANENT'),
                        ),
                        const SizedBox(width: 6),
                        _FilterChip(
                          label: 'Temporaires',
                          selected: _contractFilter == 'TEMPORAIRE',
                          color: AppColors.secondary,
                          onTap: () =>
                              setState(() => _contractFilter = 'TEMPORAIRE'),
                        ),
                      ],
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.sort, color: AppColors.primary),
                  onSelected: (v) => setState(() => _sortMode = v),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'score', child: Text('Par classement')),
                    PopupMenuItem(
                        value: 'days', child: Text('Par jours travaillés')),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          currentAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (current) {
              if (current.isEmpty) return const SizedBox.shrink();
              return Container(
                width: double.infinity,
                color: AppColors.accent.withValues(alpha: 0.06),
                child: ExpansionTile(
                  initiallyExpanded: true,
                  title: Text('Équipe actuelle (${current.length})',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Wrap(
                        spacing: 6,
                        children: current
                            .map((a) => ActionChip(
                                  label: Text(a.agentName),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('Libérer ?'),
                                        content: Text(
                                            'Libérer ${a.agentName} de ce chantier ?'),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Annuler')),
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text('Libérer',
                                                  style: TextStyle(
                                                      color:
                                                          AppColors.danger))),
                                        ],
                                      ),
                                    );
                                    if (confirm == true && context.mounted) {
                                      await ref
                                          .read(assignmentsRepositoryProvider)
                                          .releaseAgent(a.id);
                                      ref.invalidate(
                                          siteAssignmentsProvider(
                                              widget.siteId));
                                      ref.invalidate(
                                          availableAgentsProvider(
                                              widget.siteId));
                                    }
                                  },
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: agentsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text(err.toString())),
              data: (agents) {
                var filtered = agents
                    .where((a) => !alreadyAssignedIds.contains(a.id))
                    .toList();
                if (_contractFilter != 'ALL') {
                  filtered = filtered
                      .where((a) => a.contractType == _contractFilter)
                      .toList();
                }
                filtered.sort((a, b) {
                  if (_sortMode == 'days') {
                    return b.daysWorked.compareTo(a.daysWorked);
                  }
                  return (b.avgScore ?? b.rankingScore)
                      .compareTo(a.avgScore ?? a.rankingScore);
                });

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(availableAgentsProvider(widget.siteId));
                    ref.invalidate(siteAssignmentsProvider(widget.siteId));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final agent = filtered[index];
                      final selected = _selectedAgentIds.contains(agent.id);
                      final assigning = _assigningIds.contains(agent.id);
                      final dayIndispo = agent.isUnavailableOn(startKey);

                      return _AgentTile(
                        agent: agent,
                        selected: selected,
                        assigning: assigning,
                        dayIndispo: dayIndispo,
                        onTap: assigning
                            ? null
                            : () {
                                setState(() {
                                  if (selected) {
                                    _selectedAgentIds.remove(agent.id);
                                  } else {
                                    _selectedAgentIds.add(agent.id);
                                  }
                                });
                              },
                      );
                    },
                  ),
                );
              },
            ),
          ),
          if (_selectedAgentIds.isNotEmpty)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed:
                      _assigningIds.isNotEmpty ? null : _assignSelected,
                  child: _assigningIds.isNotEmpty
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : Text(
                          'Attribuer ${_selectedAgentIds.length} agent(s)',
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _DateChip(
      {required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
            Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _AgentTile extends StatelessWidget {
  final AvailableAgent agent;
  final bool selected;
  final bool assigning;
  final bool dayIndispo;
  final VoidCallback? onTap;

  const _AgentTile({
    required this.agent,
    required this.selected,
    required this.assigning,
    this.dayIndispo = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final multiConflict =
        agent.isLockedElsewhere || agent.lockedOnSites.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? AppColors.accent.withValues(alpha: 0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: multiConflict
                    ? AppColors.danger
                    : (selected ? AppColors.accent : AppColors.border),
                width: selected || multiConflict ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Text(
                    agent.firstName.isNotEmpty
                        ? agent.firstName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(agent.fullName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                      const SizedBox(height: 2),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          _Badge(
                            label: agent.contractType == 'PERMANENT'
                                ? 'Permanent'
                                : 'Temp.',
                            color: agent.contractType == 'PERMANENT'
                                ? AppColors.primary
                                : AppColors.secondary,
                          ),
                          _Badge(
                            label:
                                '${(agent.avgScore ?? agent.rankingScore).toStringAsFixed(1)} ★',
                            color: AppColors.warning,
                          ),
                          _Badge(
                            label: '${agent.daysWorked}j',
                            color: AppColors.accent,
                          ),
                          if (multiConflict)
                            _Badge(
                              label: agent.canForceMultiSite
                                  ? 'Multi-sites (force OK)'
                                  : 'Sur ${agent.lockedSitesLabel}',
                              color: AppColors.danger,
                            ),
                          if (dayIndispo)
                            const _Badge(
                              label: 'Indispo ce jour',
                              color: AppColors.warning,
                            )
                          else if (!agent.isAvailable && !multiConflict)
                            const _Badge(
                              label: 'Inactif',
                              color: AppColors.textSecondary,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (assigning)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    selected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: selected
                        ? AppColors.accent
                        : AppColors.textSecondary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color = AppColors.accent,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : Colors.transparent,
          border: Border.all(color: selected ? color : AppColors.border),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? color : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
