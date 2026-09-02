import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/utils/whatsapp_helper.dart';
import '../repositories/sites_repository.dart';

final pointagesByDateProvider =
    FutureProvider.family<List<dynamic>, String>((ref, siteAndDate) async {
  final parts = siteAndDate.split('|');
  return ref.read(pointageRepositoryProvider).getBySite(parts[0], date: parts[1]);
});

class PointageScreen extends ConsumerStatefulWidget {
  final String siteId;
  final SiteModel? site;

  const PointageScreen({super.key, required this.siteId, this.site});

  @override
  ConsumerState<PointageScreen> createState() => _PointageScreenState();
}

class _PointageScreenState extends ConsumerState<PointageScreen> {
  final Set<String> _selected = {};
  bool _submitting = false;
  final String _type = 'DEPART';
  File? _photo;
  final _picker = ImagePicker();
  List<Map<String, dynamic>>? _lastPointedAgents;
  DateTime _selectedDate = DateTime.now();
  final List<Map<String, dynamic>> _extraAgents = [];

  Future<void> _pickPhoto(ImageSource source) async {
    final permission =
        source == ImageSource.camera ? Permission.camera : Permission.photos;
    final status = await permission.request();
    if (status.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Veuillez autoriser l\'accès dans les paramètres.')),
        );
        openAppSettings();
      }
      return;
    }
    if (source == ImageSource.camera && !status.isGranted) return;
    final x = await _picker.pickImage(
        source: source, maxWidth: 1600, imageQuality: 75);
    if (x != null) setState(() => _photo = File(x.path));
  }

  Future<void> _submit() async {
    if (_selected.isEmpty) return;
    setState(() => _submitting = true);
    try {
      String? photoUrl;
      if (_photo != null) {
        photoUrl =
            await ref.read(pointageRepositoryProvider).uploadPhoto(_photo!);
      }
      final result = await ref.read(pointageRepositoryProvider).createPointage(
            siteId: widget.siteId,
            agentIds: _selected.toList(),
            type: _type,
            photoUrl: photoUrl,
            notedAt: DateFormat('yyyy-MM-dd').format(_selectedDate),
          );
      if (!mounted) return;
      final success = result['successCount'] ?? 0;
      final skipped = result['skippedCount'] ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Pointage terminé : $success OK${skipped > 0 ? ', $skipped déjà pointé(s)' : ''}'),
        backgroundColor: AppColors.accent,
      ));
      final assignments =
          ref.read(siteAssignmentsProvider(widget.siteId)).valueOrNull ?? [];
      final pointedAgentsInfo = assignments
          .where((a) => _selected.contains(a.agentId))
          .map<Map<String, dynamic>>(
              (a) => {'name': a.agentName, 'phone': a.agentPhone})
          .toList();
      setState(() {
        _lastPointedAgents = pointedAgentsInfo;
        _selected.clear();
      });
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      ref.invalidate(pointagesByDateProvider('${widget.siteId}|$dateStr'));
      ref.invalidate(siteAssignmentsProvider(widget.siteId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showAddAgentModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddAgentModal(
        onAgentSelected: (agent) {
          setState(() {
            if (!_extraAgents.any((a) => a['agentId'] == agent.id)) {
              _extraAgents.add({
                'agentId': agent.id,
                'agentName': '${agent.firstName} ${agent.lastName}',
                'agentPhone': agent.phone ?? '',
                'status': 'EXTRA',
              });
            }
          });
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final siteName = widget.site?.name ?? 'Site';
    final assignmentsAsync = ref.watch(siteAssignmentsProvider(widget.siteId));
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Pointage — $siteName'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          if (_photo != null)
            Stack(children: [
              Image.file(_photo!,
                  width: double.infinity, height: 200, fit: BoxFit.cover),
              Positioned(
                top: 8,
                right: 8,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => setState(() => _photo = null),
                  ),
                ),
              ),
            ]),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setState(() {
                        _selectedDate = date;
                        _selected.clear();
                      });
                    }
                  },
                  child: Row(children: [
                    const Icon(Icons.calendar_today,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Date: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                          ),
                    ),
                  ]),
                ),
                if (_photo == null)
                  Row(children: [
                    IconButton(
                      onPressed: _showAddAgentModal,
                      icon: const Icon(Icons.person_add, color: AppColors.accent),
                    ),
                    IconButton(
                      onPressed: () => _pickPhoto(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt, color: AppColors.accent),
                    ),
                    IconButton(
                      onPressed: () => _pickPhoto(ImageSource.gallery),
                      icon:
                          const Icon(Icons.photo_library, color: AppColors.accent),
                    ),
                  ]),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Glissez vers la droite pour marquer absent.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: assignmentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text(err.toString())),
              data: (assignments) {
                final active = assignments
                    .where((a) =>
                        a.status == 'CONFIRMED' ||
                        a.status == 'LOCKED' ||
                        a.status == 'PENDING_CONFIRMATION')
                    .map<Map<String, dynamic>>((a) => {
                          'id': a.id,
                          'agentId': a.agentId,
                          'agentName': a.agentName,
                          'agentPhone': a.agentPhone,
                          'status': a.status,
                        })
                    .toList();
                for (final extra in _extraAgents) {
                  if (!active.any((a) => a['agentId'] == extra['agentId'])) {
                    active.add(extra);
                  }
                }
                if (active.isEmpty) {
                  return const Center(
                      child: Text('Aucun agent assigné sur ce site'));
                }
                final todayPointagesAsync = ref.watch(
                    pointagesByDateProvider('${widget.siteId}|$dateStr'));
                final pointages = todayPointagesAsync.valueOrNull ?? [];
                final pointesIds = pointages
                    .map((p) => (p as Map)['agentId'] as String? ?? '')
                    .where((id) => id.isNotEmpty)
                    .toSet();

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: active.length,
                  itemBuilder: (context, index) {
                    final a = active[index];
                    final isAlreadyPointed =
                        pointesIds.contains(a['agentId']);
                    final isSelected = _selected.contains(a['agentId']);
                    final isConfirmed = a['status'] == 'CONFIRMED' ||
                        a['status'] == 'LOCKED';

                    final agentCard = Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: isAlreadyPointed
                            ? AppColors.accent.withValues(alpha: 0.04)
                            : (isSelected
                                ? AppColors.accent.withValues(alpha: 0.08)
                                : (isConfirmed
                                    ? Colors.green.withValues(alpha: 0.05)
                                    : Colors.white)),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: isAlreadyPointed
                              ? null
                              : () {
                                  setState(() {
                                    if (isSelected) {
                                      _selected.remove(a['agentId']);
                                    } else {
                                      _selected.add(a['agentId']);
                                    }
                                  });
                                },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isAlreadyPointed
                                    ? Colors.grey.withValues(alpha: 0.5)
                                    : (isSelected
                                        ? AppColors.accent
                                        : AppColors.border),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.primary
                                    .withValues(
                                        alpha: isAlreadyPointed ? 0.05 : 0.12),
                                child: Text(
                                  (a['agentName'] as String).isNotEmpty
                                      ? (a['agentName'] as String)[0]
                                          .toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: isAlreadyPointed
                                        ? Colors.grey
                                        : AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(a['agentName'],
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: isAlreadyPointed
                                              ? Colors.grey
                                              : null,
                                        )),
                                    Text(a['agentPhone'],
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                                color: isAlreadyPointed
                                                    ? Colors.grey
                                                    : null)),
                                  ],
                                ),
                              ),
                              if (isAlreadyPointed)
                                const Text('Déjà pointé',
                                    style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500))
                              else
                                Icon(
                                  isSelected
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: isSelected
                                      ? AppColors.accent
                                      : AppColors.textSecondary,
                                ),
                            ]),
                          ),
                        ),
                      ),
                    );

                    if (isAlreadyPointed) return agentCard;

                    return Dismissible(
                      key: ValueKey(a['agentId']),
                      direction: DismissDirection.startToEnd,
                      confirmDismiss: (_) async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Signaler absent ?'),
                            content: Text(
                              'Marquer ${a['agentName']} absent le ${DateFormat('dd/MM/yyyy').format(_selectedDate)} ?',
                            ),
                            actions: [
                              TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Annuler')),
                              TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, true),
                                  child: const Text('Confirmer',
                                      style:
                                          TextStyle(color: AppColors.danger))),
                            ],
                          ),
                        );
                        if (confirm != true) return false;
                        try {
                          await ref
                              .read(pointageRepositoryProvider)
                              .createPointage(
                                siteId: widget.siteId,
                                agentIds: [a['agentId'] as String],
                                type: 'ABSENT',
                                notedAt: dateStr,
                              );
                          if (a['id'] != null && a['status'] != 'EXTRA') {
                            try {
                              await ref
                                  .read(assignmentsRepositoryProvider)
                                  .releaseAgent(a['id']);
                            } catch (_) {}
                          }
                          ref.invalidate(
                              siteAssignmentsProvider(widget.siteId));
                          ref.invalidate(pointagesByDateProvider(
                              '${widget.siteId}|$dateStr'));
                          return true;
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: AppColors.danger),
                            );
                          }
                          return false;
                        }
                      },
                      background: Container(
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 20),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: const Icon(Icons.person_off, color: Colors.white),
                      ),
                      child: agentCard,
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_lastPointedAgents != null) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final text = WhatsAppHelper.pointageReportMessage(
                            siteName: siteName,
                            date: DateFormat('dd/MM/yyyy')
                                .format(_selectedDate),
                            type: _type,
                            agents: _lastPointedAgents!,
                          );
                          if (_photo != null) {
                            await SharePlus.instance.share(ShareParams(
                              files: [XFile(_photo!.path)],
                              text: text,
                            ));
                          } else {
                            await SharePlus.instance
                                .share(ShareParams(text: text));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: const Icon(Icons.share),
                        label: const Text('Partager WhatsApp',
                            style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(children: [
                    TextButton(
                      onPressed: () {
                        final assignments = ref
                            .read(siteAssignmentsProvider(widget.siteId))
                            .valueOrNull;
                        if (assignments == null) return;
                        final pointages = ref
                                .read(pointagesByDateProvider(
                                    '${widget.siteId}|$dateStr'))
                                .valueOrNull ??
                            [];
                        final pointesIds = pointages
                            .map((p) =>
                                (p as Map)['agentId'] as String? ?? '')
                            .where((id) => id.isNotEmpty)
                            .toSet();
                        setState(() {
                          _selected.clear();
                          for (final a in assignments) {
                            if (!pointesIds.contains(a.agentId) &&
                                (a.status == 'CONFIRMED' ||
                                    a.status == 'LOCKED' ||
                                    a.status == 'PENDING_CONFIRMATION')) {
                              _selected.add(a.agentId);
                            }
                          }
                          for (final extra in _extraAgents) {
                            if (!pointesIds.contains(extra['agentId'])) {
                              _selected.add(extra['agentId']);
                            }
                          }
                        });
                      },
                      child: const Text('Tout sélectionner'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed:
                            _selected.isEmpty || _submitting ? null : _submit,
                        child: _submitting
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: Colors.white),
                              )
                            : Text(
                                'Pointer${_selected.isEmpty ? '' : ' (${_selected.length})'}'),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddAgentModal extends ConsumerStatefulWidget {
  final Function(dynamic) onAgentSelected;
  const _AddAgentModal({required this.onAgentSelected});

  @override
  ConsumerState<_AddAgentModal> createState() => _AddAgentModalState();
}

class _AddAgentModalState extends ConsumerState<_AddAgentModal> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final agentsAsync = ref.watch(availableAgentsProvider(null));
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(children: [
        const SizedBox(height: 16),
        Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        const Text('Ajouter un agent',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Rechercher par nom...',
              prefixIcon: const Icon(Icons.search),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (v) => setState(() => _search = v.toLowerCase()),
          ),
        ),
        Expanded(
          child: agentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text(err.toString())),
            data: (agents) {
              final filtered = agents.where((a) {
                final name = '${a.firstName} ${a.lastName}'.toLowerCase();
                return name.contains(_search);
              }).toList();
              if (filtered.isEmpty) {
                return const Center(child: Text('Aucun agent trouvé'));
              }
              return ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final a = filtered[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.1),
                      child: Text(a.firstName[0],
                          style: const TextStyle(color: AppColors.primary)),
                    ),
                    title: Text('${a.firstName} ${a.lastName}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(a.phone),
                    onTap: () => widget.onAgentSelected(a),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}
