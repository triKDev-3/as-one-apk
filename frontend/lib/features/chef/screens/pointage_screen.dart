import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../repositories/sites_repository.dart';
import '../repositories/assignments_repository.dart';

class PointageScreen extends ConsumerStatefulWidget {
  final String siteId;
  final SiteModel? site;

  const PointageScreen({super.key, required this.siteId, this.site});

  @override
  ConsumerState<PointageScreen> createState() => _PointageScreenState();
}

class _PointageScreenState extends ConsumerState<PointageScreen> {
  final Set<String> _selected = {};
  final Set<String> _hiddenIds = {};
  bool _submitting = false;
  File? _photo;
  final _picker = ImagePicker();
  List<dynamic> _today = [];

  @override
  void initState() {
    super.initState();
    _loadToday();
  }

  Future<void> _loadToday() async {
    try {
      final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final list = await ref.read(pointageRepositoryProvider).getBySite(
            widget.siteId,
            date: date,
          );
      if (mounted) setState(() => _today = list);
    } catch (_) {}
  }

  Set<String> get _alreadyDone {
    return _today
        .where((e) {
          final t = (e as Map)['type'] as String? ?? '';
          return t == 'DEPART' || t == 'ABSENT';
        })
        .map((e) => (e as Map)['agentId'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final permission =
        source == ImageSource.camera ? Permission.camera : Permission.photos;
    final status = await permission.request();
    if (status.isPermanentlyDenied) {
      if (mounted) openAppSettings();
      return;
    }
    if (source == ImageSource.camera && !status.isGranted) return;
    final x = await _picker.pickImage(
        source: source, maxWidth: 1600, imageQuality: 75);
    if (x != null) setState(() => _photo = File(x.path));
  }

  Future<String?> _confirmSwipe(AssignmentModel a) async {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(a.agentName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 6),
              const Text(
                'Glissement confirmé — que voulez-vous faire ?',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.person_off_outlined,
                    color: AppColors.warning),
                title: const Text('Marquer absent'),
                subtitle: const Text('Ne sera pas payé pour aujourd\'hui'),
                onTap: () => Navigator.pop(ctx, 'absent'),
              ),
              ListTile(
                leading: const Icon(Icons.remove_circle_outline,
                    color: AppColors.danger),
                title: const Text('Retirer de la liste'),
                subtitle: const Text('Libère l\'agent de ce chantier'),
                onTap: () => Navigator.pop(ctx, 'remove'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _onSwipe(AssignmentModel a) async {
    final action = await _confirmSwipe(a);
    if (action == null) return false;
    try {
      if (action == 'absent') {
        await ref.read(pointageRepositoryProvider).createPointage(
              siteId: widget.siteId,
              agentIds: [a.agentId],
              type: 'ABSENT',
            );
      } else {
        await ref.read(assignmentsRepositoryProvider).releaseAgent(a.id);
      }
      setState(() {
        _hiddenIds.add(a.agentId);
        _selected.remove(a.agentId);
      });
      await _loadToday();
      ref.invalidate(siteAssignmentsProvider(widget.siteId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(action == 'absent'
              ? '${a.agentName} marqué absent'
              : '${a.agentName} retiré de l\'équipe'),
          backgroundColor: AppColors.accent,
        ));
      }
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.danger,
        ));
      }
      return false;
    }
  }

  Future<void> _submitDepart() async {
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
            type: 'DEPART',
            photoUrl: photoUrl,
          );
      if (!mounted) return;
      final success = result['successCount'] ?? 0;
      final skipped = result['skippedCount'] ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Départs : $success OK${skipped > 0 ? ', $skipped déjà pointé(s)' : ''}'),
        backgroundColor: AppColors.accent,
      ));
      setState(() => _selected.clear());
      await _loadToday();
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

  @override
  Widget build(BuildContext context) {
    final siteName = widget.site?.name ?? 'Site';
    final assignmentsAsync = ref.watch(siteAssignmentsProvider(widget.siteId));
    final done = _alreadyDone;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Départ — $siteName'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Heure de départ · ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Glissez vers la droite pour retirer ou marquer absent.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (_photo != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_photo!,
                            width: 56, height: 56, fit: BoxFit.cover),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => setState(() => _photo = null),
                      ),
                    ],
                    OutlinedButton.icon(
                      onPressed: () => _pickPhoto(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt, size: 18),
                      label: const Text('Photo'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: assignmentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text(err.toString())),
              data: (assignments) {
                final active = assignments.where((a) {
                  if (_hiddenIds.contains(a.agentId)) return false;
                  if (done.contains(a.agentId)) return false;
                  return a.status == 'CONFIRMED' ||
                      a.status == 'LOCKED' ||
                      a.status == 'PENDING_CONFIRMATION';
                }).toList();

                if (active.isEmpty) {
                  return const Center(
                    child: Text('Tous les départs / absences sont enregistrés'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: active.length,
                  itemBuilder: (context, index) {
                    final a = active[index];
                    final selected = _selected.contains(a.agentId);
                    return Dismissible(
                      key: ValueKey(a.id),
                      direction: DismissDirection.startToEnd,
                      confirmDismiss: (_) => _onSwipe(a),
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 20),
                        child: const Icon(Icons.swipe_right_alt,
                            color: AppColors.warning),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: selected
                              ? AppColors.accent.withOpacity(0.08)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              setState(() {
                                if (selected) {
                                  _selected.remove(a.agentId);
                                } else {
                                  _selected.add(a.agentId);
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected
                                      ? AppColors.accent
                                      : AppColors.border,
                                  width: selected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor:
                                        AppColors.primary.withOpacity(0.12),
                                    child: Text(
                                      a.agentName.isNotEmpty
                                          ? a.agentName[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(a.agentName,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600)),
                                        Text(a.agentPhone,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium),
                                      ],
                                    ),
                                  ),
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
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_today.isNotEmpty)
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'Aujourd\'hui : ${_today.length} enregistrement(s)',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () {
                      final assignments = ref
                          .read(siteAssignmentsProvider(widget.siteId))
                          .valueOrNull;
                      if (assignments == null) return;
                      setState(() {
                        _selected
                          ..clear()
                          ..addAll(assignments
                              .where((a) =>
                                  !_hiddenIds.contains(a.agentId) &&
                                  !done.contains(a.agentId))
                              .map((a) => a.agentId));
                      });
                    },
                    child: const Text('Tout sélectionner'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          _selected.isEmpty || _submitting ? null : _submitDepart,
                      child: _submitting
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white),
                            )
                          : Text(
                              'Enregistrer les départs${_selected.isEmpty ? '' : ' (${_selected.length})'}',
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
