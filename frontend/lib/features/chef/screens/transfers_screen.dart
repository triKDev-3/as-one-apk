import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/network/api_client.dart';

final pendingTransfersProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final r = await api.dio.get('/assignments/transfers/pending');
    return r.data as List<dynamic>;
  } on DioException catch (e) {
    throw ApiClient.extractError(e);
  }
});

// Provider to list all chefs (for "Demander" dialog)
final chefsListProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final r = await api.dio.get('/users', queryParameters: {'role': 'CHEF'});
    return r.data as List<dynamic>;
  } on DioException catch (e) {
    throw ApiClient.extractError(e);
  }
});

// Provider to list agents on my sites (for "Libérer" dialog)
final myAgentsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final r = await api.dio.get('/assignments/my-agents');
    return r.data as List<dynamic>;
  } on DioException catch (e) {
    throw ApiClient.extractError(e);
  }
});

class TransfersScreen extends ConsumerWidget {
  const TransfersScreen({super.key});

  Future<void> _resolve(
    WidgetRef ref,
    BuildContext context,
    String id,
    bool accept,
  ) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.dio.patch('/assignments/transfers/$id/resolve', data: {
        'accept': accept,
      });
      ref.invalidate(pendingTransfersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(accept ? 'Transfert accepté' : 'Transfert refusé'),
            backgroundColor: accept ? AppColors.accent : AppColors.danger,
          ),
        );
      }
    } on DioException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.extractError(e)),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _showDemanderDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _DemanderAgentSheet(
        onSuccess: () => ref.invalidate(pendingTransfersProvider),
      ),
    );
  }

  void _showLibererDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => _LibererAgentSheet(
        onSuccess: () => ref.invalidate(pendingTransfersProvider),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pendingTransfersProvider);
    final myId = ref.watch(authProvider).user?.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Transferts d\'agents'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      // ── Action buttons at the bottom ──
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text('Demander un agent'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => _showDemanderDialog(context, ref),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.person_remove_rounded),
                  label: const Text('Libérer un agent'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => _showLibererDialog(context, ref),
                ),
              ),
            ],
          ),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sync_alt_rounded, size: 56, color: AppColors.textTertiary),
                  SizedBox(height: 12),
                  Text('Aucune demande de transfert en cours',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(pendingTransfersProvider),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final t = list[i] as Map<String, dynamic>;
                final assignment =
                    t['assignment'] as Map<String, dynamic>? ?? {};
                final agent =
                    assignment['agent'] as Map<String, dynamic>? ?? {};
                final site = assignment['site'] as Map<String, dynamic>? ?? {};
                final from = t['fromChef'] as Map<String, dynamic>? ?? {};
                final to = t['toChef'] as Map<String, dynamic>? ?? {};
                final id = t['id'] as String;
                final isIncoming = t['toChefId'] == myId;

                final agentName =
                    '${agent['firstName'] ?? ''} ${agent['lastName'] ?? ''}'.trim();
                final fromName =
                    '${from['firstName'] ?? ''} ${from['lastName'] ?? ''}'.trim();
                final toName =
                    '${to['firstName'] ?? ''} ${to['lastName'] ?? ''}'.trim();

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isIncoming
                          ? AppColors.primary.withValues(alpha: 0.3)
                          : AppColors.border,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isIncoming
                                  ? AppColors.primary.withValues(alpha: 0.1)
                                  : AppColors.textTertiary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isIncoming ? 'Demande reçue' : 'Demande envoyée',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isIncoming
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        agentName.isEmpty ? 'Agent' : agentName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Site : ${site['name'] ?? '—'}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        isIncoming ? 'De : $fromName' : 'Vers : $toName',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (isIncoming) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _resolve(ref, context, id, false),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.danger,
                                  side: const BorderSide(color: AppColors.danger),
                                ),
                                child: const Text('Refuser'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _resolve(ref, context, id, true),
                                child: const Text('Accepter'),
                              ),
                            ),
                          ],
                        ),
                      ] else
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'En attente de réponse',
                            style: TextStyle(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ─── Feuille "Demander un agent" ──────────────────────────────────────────────
class _DemanderAgentSheet extends ConsumerStatefulWidget {
  final VoidCallback onSuccess;
  const _DemanderAgentSheet({required this.onSuccess});

  @override
  ConsumerState<_DemanderAgentSheet> createState() => _DemanderAgentSheetState();
}

class _DemanderAgentSheetState extends ConsumerState<_DemanderAgentSheet> {
  String? _selectedChefId;
  String? _selectedAgentId;
  final _noteController = TextEditingController();
  bool _loading = false;
  List<dynamic> _agents = [];

  Future<void> _loadAgents(String chefId) async {
    try {
      final api = ref.read(apiClientProvider);
      final r = await api.dio.get('/assignments/chef/$chefId/agents');
      setState(() => _agents = r.data as List<dynamic>);
    } catch (_) {
      setState(() => _agents = []);
    }
  }

  Future<void> _submit() async {
    if (_selectedChefId == null || _selectedAgentId == null) return;
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.dio.post('/assignments/transfers', data: {
        'fromChefId': _selectedChefId,
        'agentId': _selectedAgentId,
        'note': _noteController.text.trim(),
      });
      widget.onSuccess();
      if (mounted) Navigator.pop(context);
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
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chefsAsync = ref.watch(chefsListProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Demander un agent',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 4),
          const Text('Sélectionnez le chef source et l\'agent souhaité',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 20),
          // Chef selector
          chefsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(e.toString()),
            data: (chefs) => DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Chef source',
                prefixIcon: Icon(Icons.person_rounded),
              ),
              items: chefs.map((c) {
                final name = '${c['firstName']} ${c['lastName']}';
                return DropdownMenuItem(value: c['id'] as String, child: Text(name));
              }).toList(),
              onChanged: (id) {
                setState(() {
                  _selectedChefId = id;
                  _selectedAgentId = null;
                  _agents = [];
                });
                if (id != null) _loadAgents(id);
              },
            ),
          ),
          if (_agents.isNotEmpty) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Agent à demander',
                prefixIcon: Icon(Icons.engineering_rounded),
              ),
              items: _agents.map((a) {
                final name = '${a['firstName']} ${a['lastName']}';
                return DropdownMenuItem(value: a['id'] as String, child: Text(name));
              }).toList(),
              onChanged: (id) => setState(() => _selectedAgentId = id),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Note (optionnel)',
              prefixIcon: Icon(Icons.notes_rounded),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Envoyer la demande'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Feuille "Libérer un agent" ───────────────────────────────────────────────
class _LibererAgentSheet extends ConsumerStatefulWidget {
  final VoidCallback onSuccess;
  const _LibererAgentSheet({required this.onSuccess});

  @override
  ConsumerState<_LibererAgentSheet> createState() => _LibererAgentSheetState();
}

class _LibererAgentSheetState extends ConsumerState<_LibererAgentSheet> {
  String? _selectedAgentId;
  String? _selectedChefId;
  bool _loading = false;

  Future<void> _submit() async {
    if (_selectedAgentId == null || _selectedChefId == null) return;
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.dio.post('/assignments/transfers', data: {
        'toChefId': _selectedChefId,
        'agentId': _selectedAgentId,
      });
      widget.onSuccess();
      if (mounted) Navigator.pop(context);
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
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myAgentsAsync = ref.watch(myAgentsProvider);
    final chefsAsync = ref.watch(chefsListProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Libérer un agent',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 4),
          const Text('Proposez un de vos agents à un autre chef',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 20),
          myAgentsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(e.toString()),
            data: (agents) => DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Agent à libérer',
                prefixIcon: Icon(Icons.engineering_rounded),
              ),
              items: agents.map((a) {
                final name = '${a['firstName']} ${a['lastName']}';
                return DropdownMenuItem(value: a['id'] as String, child: Text(name));
              }).toList(),
              onChanged: (id) => setState(() => _selectedAgentId = id),
            ),
          ),
          const SizedBox(height: 12),
          chefsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(e.toString()),
            data: (chefs) => DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Chef destinataire',
                prefixIcon: Icon(Icons.person_rounded),
              ),
              items: chefs.map((c) {
                final name = '${c['firstName']} ${c['lastName']}';
                return DropdownMenuItem(value: c['id'] as String, child: Text(name));
              }).toList(),
              onChanged: (id) => setState(() => _selectedChefId = id),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Libérer l\'agent', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
