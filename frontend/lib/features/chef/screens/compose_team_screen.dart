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

  Future<void> _assignSelected() async {
    if (_selectedAgentIds.isEmpty) return;

    final repo = ref.read(assignmentsRepositoryProvider);
    final startStr = DateFormat('yyyy-MM-dd').format(_startDate);
    final endStr =
        _endDate != null ? DateFormat('yyyy-MM-dd').format(_endDate!) : null;

    // Snapshot agents info for WhatsApp after success
    final agentsSnapshot =
        ref.read(availableAgentsProvider).valueOrNull ?? [];
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
    final agentsAsync = ref.watch(availableAgentsProvider);
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
                          .map((a) => GestureDetector(
                                onLongPress: () => _requestTransfer(a),
                                child: Chip(
                                  label: Text(a.agentName),
                                  backgroundColor: Colors.white,
                                  side: const BorderSide(color: AppColors.border),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ))
                          .toList(),
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
                            ref.invalidate(availableAgentsProvider),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (agents) {
                final filtered = agents
                    .where((a) => !alreadyAssignedIds.contains(a.id))
                    .toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('Aucun agent disponible'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(availableAgentsProvider);
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
                      Text(
                        '${agent.phone} · ${agent.rankingScore.toStringAsFixed(1)} ★'
                        '${agent.agentType != null ? ' · ${agent.agentType}' : ''}'
                        '${!agent.isAvailable ? ' · INDISPONIBLE' : ''}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: agent.isAvailable
                                  ? null
                                  : AppColors.danger,
                            ),
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
