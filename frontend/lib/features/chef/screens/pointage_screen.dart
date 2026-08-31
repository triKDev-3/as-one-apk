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



final pointagesByDateProvider = FutureProvider.family<List<dynamic>, String>((ref, siteAndDate) async {
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
  final Set<String> _hiddenIds = {};
  bool _submitting = false;
<<<<<<< HEAD
  final String _type = 'DEPART'; // ARRIVEE | DEPART | PRESENCE_PERMANENCE
  File? _photo;
  final _picker = ImagePicker();
  List<Map<String, dynamic>>? _lastPointedAgents;

  DateTime _selectedDate = DateTime.now();
  final List<Map<String, dynamic>> _extraAgents = [];

=======
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
>>>>>>> 51b4f09b50968039e245b160ef0c0599e4abb71b

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
            notedAt: DateFormat('yyyy-MM-dd').format(_selectedDate),
          );
      if (!mounted) return;
      final success = result['successCount'] ?? 0;
      final skipped = result['skippedCount'] ?? 0;
<<<<<<< HEAD

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pointage terminé : $success OK'
            '${skipped > 0 ? ', $skipped déjà pointé(s)' : ''}',
          ),
          backgroundColor: AppColors.accent,
        ),
      );

      final assignments = ref.read(siteAssignmentsProvider(widget.siteId)).valueOrNull ?? [];
      final pointedAgentsInfo = assignments
          .where((a) => _selected.contains(a.agentId))
          .map<Map<String, dynamic>>((a) => {'name': a.agentName, 'phone': a.agentPhone})
          .toList();

      setState(() {
        _lastPointedAgents = pointedAgentsInfo;
        _selected.clear();
      });
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      ref.invalidate(pointagesByDateProvider('${widget.siteId}|$dateStr'));
      ref.invalidate(siteAssignmentsProvider(widget.siteId));
=======
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Départs : $success OK${skipped > 0 ? ', $skipped déjà pointé(s)' : ''}'),
        backgroundColor: AppColors.accent,
      ));
      setState(() => _selected.clear());
      await _loadToday();
>>>>>>> 51b4f09b50968039e245b160ef0c0599e4abb71b
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


  void _showAddAgentModal() async {
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
<<<<<<< HEAD
    final assignmentsAsync =
        ref.watch(siteAssignmentsProvider(widget.siteId));
=======
    final assignmentsAsync = ref.watch(siteAssignmentsProvider(widget.siteId));
    final done = _alreadyDone;
>>>>>>> 51b4f09b50968039e245b160ef0c0599e4abb71b

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
<<<<<<< HEAD
          // Photo & Date
          if (_photo != null)
            Stack(
              children: [
                Image.file(
                  _photo!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
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
              ],
            ),
=======
>>>>>>> 51b4f09b50968039e245b160ef0c0599e4abb71b
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
<<<<<<< HEAD
                GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        _selectedDate = date;
                        _selected.clear();
                      });
                    }
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Date: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.primary,
                              decoration: TextDecoration.underline,
                            ),
                      ),
                    ],
                  ),
=======
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
>>>>>>> 51b4f09b50968039e245b160ef0c0599e4abb71b
                ),
                if (_photo == null)
                  Row(
                    children: [
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
                        icon: const Icon(Icons.photo_library, color: AppColors.accent),
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
<<<<<<< HEAD
                final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
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
=======
                final active = assignments.where((a) {
                  if (_hiddenIds.contains(a.agentId)) return false;
                  if (done.contains(a.agentId)) return false;
                  return a.status == 'CONFIRMED' ||
                      a.status == 'LOCKED' ||
                      a.status == 'PENDING_CONFIRMATION';
                }).toList();
>>>>>>> 51b4f09b50968039e245b160ef0c0599e4abb71b

                if (active.isEmpty) {
                  return const Center(
                    child: Text('Tous les départs / absences sont enregistrés'),
                  );
                }

                final todayPointagesAsync = ref.watch(pointagesByDateProvider('${widget.siteId}|$dateStr'));
                final pointages = todayPointagesAsync.valueOrNull ?? [];
                final pointesIds = pointages.expand((p) => (p['agentIds'] as List?)?.cast<String>() ?? <String>[]).toSet();

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: active.length,
                  itemBuilder: (context, index) {
                    final a = active[index];
<<<<<<< HEAD
                    final isAlreadyPointed = pointesIds.contains(a['agentId']);
                    final isSelected = _selected.contains(a['agentId']);
                    final isConfirmed = a['status'] == 'CONFIRMED' || a['status'] == 'LOCKED';

                    Widget agentCard = Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: isAlreadyPointed
                            ? AppColors.accent.withValues(alpha: 0.04)
                            : (isSelected
                                ? AppColors.accent.withValues(alpha: 0.08)
                                : (isConfirmed ? Colors.green.withValues(alpha: 0.05) : Colors.white)),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: isAlreadyPointed ? null : () {
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
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isAlreadyPointed
                                    ? Colors.grey.withValues(alpha: 0.5)
                                    : (isSelected ? AppColors.accent : AppColors.border),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor:
                                      AppColors.primary.withValues(alpha: isAlreadyPointed ? 0.05 : 0.12),
                                  child: Text(
                                    a['agentName'].isNotEmpty
                                        ? a['agentName'][0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      color: isAlreadyPointed ? Colors.grey : AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        a['agentName'],
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: isAlreadyPointed ? Colors.grey : null,
                                        ),
                                      ),
                                      Text(
                                        a['agentPhone'],
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium?.copyWith(color: isAlreadyPointed ? Colors.grey : null),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isAlreadyPointed)
                                  const Text('Déjà pointé', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500))
                                else
                                  Icon(
                                    isSelected
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    color: isSelected
                                        ? AppColors.accent
                                        : AppColors.textSecondary,
                                  ),
                              ],
=======
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
>>>>>>> 51b4f09b50968039e245b160ef0c0599e4abb71b
                            ),
                          ),
                        ),
                      ),
                    );

                    if (isAlreadyPointed) return agentCard;

                    return Dismissible(
                      key: ValueKey(a['agentId']),
                      direction: DismissDirection.startToEnd,
                      confirmDismiss: (dir) async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Signaler absent ?'),
                            content: Text(
                              'Signaler ${a['agentName']} comme absent aujourd\'hui et le retirer de la liste ?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Annuler'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Confirmer', style: TextStyle(color: AppColors.danger)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          try {
                            await ref.read(assignmentsRepositoryProvider).releaseAgent(a['id']);
                            ref.invalidate(siteAssignmentsProvider(widget.siteId));
                            return true;
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
                            }
                            return false;
                          }
                        }
                        return false;
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
<<<<<<< HEAD
                  if (_lastPointedAgents != null) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final text = WhatsAppHelper.pointageReportMessage(
                            siteName: siteName,
                            date: DateFormat('dd/MM/yyyy').format(DateTime.now()),
                            type: _type,
                            agents: _lastPointedAgents!,
                          );
                          if (_photo != null) {
                            await SharePlus.instance.share(
                              ShareParams(
                                files: [XFile(_photo!.path)],
                                text: text,
                              ),
                            );
                          } else {
                            await SharePlus.instance.share(
                              ShareParams(text: text),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: const Icon(Icons.share),
                        label: const Text('Partager le rapport WhatsApp', style: TextStyle(fontSize: 16)),
                      ),
=======
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
>>>>>>> 51b4f09b50968039e245b160ef0c0599e4abb71b
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          final assignments = ref
                              .read(siteAssignmentsProvider(widget.siteId))
                              .valueOrNull;
                          if (assignments == null) return;
                          
                          final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
                          final pointages = ref.read(pointagesByDateProvider('${widget.siteId}|$dateStr')).valueOrNull ?? [];
                          final pointesIds = pointages.expand((p) => (p['agentIds'] as List?)?.cast<String>() ?? <String>[]).toSet();

                          setState(() {
                            _selected.clear();
                            for (final a in assignments) {
                              if (!pointesIds.contains(a.agentId) &&
                                  (a.status == 'CONFIRMED' || a.status == 'LOCKED' || a.status == 'PENDING_CONFIRMATION')) {
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
                          onPressed: _selected.isEmpty || _submitting
                              ? null
                              : _submit,
                          child: _submitting
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Pointer ${_selected.isEmpty ? '' : '(${_selected.length})'}',
                                ),
                        ),
                      ),
                    ],
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
<<<<<<< HEAD


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
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Ajouter un agent', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher par nom...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: Text(a.firstName[0], style: const TextStyle(color: AppColors.primary)),
                      ),
                      title: Text('${a.firstName} ${a.lastName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(a.phone),
                      onTap: () => widget.onAgentSelected(a),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
=======
>>>>>>> 51b4f09b50968039e245b160ef0c0599e4abb71b
