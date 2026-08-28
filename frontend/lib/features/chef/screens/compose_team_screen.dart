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
  // Filters & sort
  String _contractFilter = 'ALL'; // ALL | PERMANENT | TEMPORAIRE
  String _sortMode = 'score'; // score | days

  Future<void> _assignSelected() async {
    if (_selectedAgentIds.isEmpty) return;

    final repo = ref.read(assignmentsRepositoryProvider);
    final startStr = DateFormat('yyyy-MM-dd').format(_startDate);
    final endStr =
        _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null;

    // Snapshot agents info for WhatsApp after success
    final agentsSnapshot =
        ref.read(availableAgentsProvider(widget.siteId)).valueOrNull ?? [];
    final selectedAgents = agentsSnapshot
        .where((a) => _selectedAgentIds.contains(a.id))
        .toList();

    int success = 0;
    int failed = 0;
    String? lastError;
    final assignedAgents = <AvailableAgent>[];

    for (final agent in selectedAgents) {
      setState(() => _assigningIds.add(agent.id));
      try {
        await repo.createAssignment(
          siteId: widget.siteId,
          agentId: agent.id,
          startDate: startStr,
          endDate: endStr,
        );
        success++;
        assignedAgents.add(agent);
        _selectedAgentIds.remove(agent.id);
      } catch (e) {
        failed++;
        lastError = e.toString();
      } finally {
        if (mounted) {
          setState(() => _assigningIds.remove(agent.id));
        }
      }
    }

    ref.invalidate(siteAssignmentsProvider(widget.siteId));
    ref.invalidate(availableAgentsProvider);

    if (!mounted) return;

    final msg = failed == 0
        ? '$success agent(s) assigné(s) avec succès'
        : '$success OK, $failed échec${lastError != null ? ' : $lastError' : ''}';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
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
              Text(
                'Notifier les agents',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'WhatsApp / SMS avec message prérempli',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              ...agents.map((agent) {
                final msg = WhatsAppHelper.assignmentMessage(
                  agentName: agent.fullName,
                  siteName: siteName,
                  startDate: startStr,
                  endDate: endStr,
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
                        tooltip: 'WhatsApp',
                        onPressed: () async {
                          await WhatsAppHelper.openWhatsApp(
                            phone: agent.phone,
                            message: msg,
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.sms_outlined,
                            color: AppColors.primary),
                        tooltip: 'SMS',
                        onPressed: () async {
                          await WhatsAppHelper.openSms(
                            phone: agent.phone,
                            message: msg,
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        tooltip: 'Copier',
                        onPressed: () async {
                          await WhatsAppHelper.copyMessage(msg);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Message pour ${agent.fullName} copié'),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
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


  Future<void> _requestTransfer(AssignmentModel assignment) async {
    try {
      final chefs = await ref.read(assignmentsRepositoryProvider).listChefs();
      final myId = ref.read(authProvider).user?.id;
      final others = chefs.where((c) => c['id'] != myId).toList();
      if (!mounted || others.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucun autre chef disponible')),
        );
        return;
      }
      final selected = await showModalBottomSheet<String>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(title: Text('Transférer vers…')),
              ...others.map((c) => ListTile(
                    title: Text('${c['firstName']} ${c['lastName']}'),
                    subtitle: Text('${c['phone'] ?? ''}'),
                    onTap: () => Navigator.pop(ctx, c['id'] as String),
                  )),
            ],
          ),
        ),
      );
      if (selected == null) return;
      await ref.read(assignmentsRepositoryProvider).requestTransfer(
            assignmentId: assignment.id,
            toChefId: selected,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demande de transfert envoyée'),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
        );
      }
    }
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

    // Agents déjà sur ce site → exclus de la sélection
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
          // Dates
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: Colors.white,
            child: Row(
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
          ),
          // Filtre + Tri bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: [
                // Contract filter chips
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'Tous',
                          selected: _contractFilter == 'ALL',
                          onTap: () => setState(() => _contractFilter = 'ALL'),
                        ),
                        const SizedBox(width: 6),
                        _FilterChip(
                          label: 'Permanents',
                          selected: _contractFilter == 'PERMANENT',
                          color: AppColors.primary,
                          onTap: () => setState(() => _contractFilter = 'PERMANENT'),
                        ),
                        const SizedBox(width: 6),
                        _FilterChip(
                          label: 'Temporaires',
                          selected: _contractFilter == 'TEMPORAIRE',
                          color: AppColors.secondary,
                          onTap: () => setState(() => _contractFilter = 'TEMPORAIRE'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Sort button
                PopupMenuButton<String>(
                  icon: const Icon(Icons.sort, color: AppColors.primary),
                  tooltip: 'Trier',
                  initialValue: _sortMode,
                  onSelected: (v) => setState(() => _sortMode = v),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'score',
                      child: Text('Par classement ★'),
                    ),
                    const PopupMenuItem(
                      value: 'days',
                      child: Text('Par jours travaillés'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Équipe actuelle
          currentAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (current) {
              if (current.isEmpty) return const SizedBox.shrink();
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: AppColors.accent.withOpacity(0.06),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Équipe actuelle (${current.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: current
                          .map((a) => ActionChip(
                                label: Text(a.agentName),
                                backgroundColor: Colors.white,
                                side: const BorderSide(color: AppColors.border),
                                visualDensity: VisualDensity.compact,
                                avatar: const Icon(Icons.person_remove_outlined, size: 16, color: AppColors.danger),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Libérer l\'agent ?'),
                                      content: Text(
                                        'Libérer ${a.agentName} de ce chantier. '
                                        'Il devra être reconvoqué pour revenir.',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('Annuler'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text('Libérer', style: TextStyle(color: AppColors.danger)),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true && mounted) {
                                    try {
                                      await ref.read(assignmentsRepositoryProvider).releaseAgent(a.id);
                                      ref.invalidate(siteAssignmentsProvider(widget.siteId));
                                      ref.invalidate(availableAgentsProvider(widget.siteId));
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
                                        );
                                      }
                                    }
                                  }
                                },
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Appuyez sur un agent pour le libérer (indisponible). Appui long = transfert.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            },
          ),

          // Liste agents disponibles
          Expanded(
            child: agentsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(err.toString(), textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () =>
                            ref.invalidate(availableAgentsProvider(widget.siteId)),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (agents) {
                var filtered = agents
                    .where((a) => !alreadyAssignedIds.contains(a.id))
                    .toList();

                // Apply contract filter
                if (_contractFilter != 'ALL') {
                  filtered = filtered
                      .where((a) => a.contractType == _contractFilter)
                      .toList();
                }

                // Apply sort
                filtered.sort((a, b) {
                  if (_sortMode == 'days') {
                    return b.daysWorked.compareTo(a.daysWorked);
                  }
                  // Default: score
                  final scoreA = a.avgScore ?? a.rankingScore;
                  final scoreB = b.avgScore ?? b.rankingScore;
                  return scoreB.compareTo(scoreA);
                });

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('Aucun agent disponible'),
                  );
                }

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

                      return _AgentTile(
                        agent: agent,
                        selected: selected,
                        assigning: assigning,
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

          // Bouton d'attribution
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
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
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

  const _DateChip({
    required this.label,
    required this.value,
    required this.onTap,
  });

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
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
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
  final VoidCallback? onTap;

  const _AgentTile({
    required this.agent,
    required this.selected,
    required this.assigning,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? AppColors.accent.withOpacity(0.08)
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
                color: selected ? AppColors.accent : AppColors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withOpacity(0.12),
                  child: Text(
                    agent.firstName.isNotEmpty
                        ? agent.firstName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agent.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Badges row
                      Wrap(
                        spacing: 4,
                        children: [
                          _Badge(
                            label: agent.contractType == 'PERMANENT' ? 'Permanent' : 'Temp.',
                            color: agent.contractType == 'PERMANENT' ? AppColors.primary : AppColors.secondary,
                          ),
                          _Badge(
                            label: '${(agent.avgScore ?? agent.rankingScore).toStringAsFixed(1)} ★',
                            color: AppColors.warning,
                          ),
                          _Badge(
                            label: '${agent.daysWorked}j travaillis',
                            color: AppColors.accent,
                          ),
                          if (agent.isLockedElsewhere)
                            const _Badge(
                              label: 'Indisponible',
                              color: AppColors.danger,
                            )
                          else if (!agent.isAvailable)
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : Colors.transparent,
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
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
