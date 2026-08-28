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

  const PointageScreen({
    super.key,
    required this.siteId,
    this.site,
  });

  @override
  ConsumerState<PointageScreen> createState() => _PointageScreenState();
}

class _PointageScreenState extends ConsumerState<PointageScreen> {
  final Set<String> _selected = {};
  bool _submitting = false;
  String _type = 'ARRIVEE'; // ARRIVEE | DEPART | PRESENCE_PERMANENCE
  File? _photo;
  final _picker = ImagePicker();

  Future<void> _pickPhoto(ImageSource source) async {
    final permission = source == ImageSource.camera ? Permission.camera : Permission.photos;
    final status = await permission.request();
    if (status.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez autoriser l\'accès dans les paramètres.')),
        );
        openAppSettings();
      }
      return;
    }
    // Storage permission might not be explicitly granted but available via picker in some Android versions.
    // However, handling it gracefully:
    if (source == ImageSource.camera && !status.isGranted) return;

    final x = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 75,
    );
    if (x != null) setState(() => _photo = File(x.path));
  }

  Future<void> _submit() async {
    if (_selected.isEmpty) return;
    setState(() => _submitting = true);
    try {
      String? photoUrl;
      if (_photo != null) {
        photoUrl = await ref
            .read(pointageRepositoryProvider)
            .uploadPhoto(_photo!);
      }
      final result = await ref.read(pointageRepositoryProvider).createPointage(
            siteId: widget.siteId,
            agentIds: _selected.toList(),
            type: _type,
            photoUrl: photoUrl,
          );

      if (!mounted) return;

      final success = result['successCount'] ?? 0;
      final skipped = result['skippedCount'] ?? 0;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pointage terminé : $success OK'
            '${skipped > 0 ? ', $skipped déjà pointé(s)' : ''}',
          ),
          backgroundColor: AppColors.accent,
        ),
      );

      setState(() => _selected.clear());
      ref.invalidate(siteAssignmentsProvider(widget.siteId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final siteName = widget.site?.name ?? 'Site';
    final isPermanence = widget.site?.isPermanence ?? false;
    final assignmentsAsync =
        ref.watch(siteAssignmentsProvider(widget.siteId));

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
          // Type de pointage
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (_photo != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _photo!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => setState(() => _photo = null),
                      ),
                      const SizedBox(width: 8),
                    ],
                    OutlinedButton.icon(
                      onPressed: () => _pickPhoto(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt, size: 18),
                      label: const Text('Photo'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _pickPhoto(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library, size: 18),
                      label: const Text('Galerie'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Liste des agents de l'équipe
          Expanded(
            child: assignmentsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text(err.toString())),
              data: (assignments) {
                final active = assignments
                    .where((a) =>
                        a.status == 'CONFIRMED' ||
                        a.status == 'LOCKED' ||
                        a.status == 'PENDING_CONFIRMATION')
                    .toList();

                if (active.isEmpty) {
                  return const Center(
                    child: Text('Aucun agent assigné sur ce site'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: active.length,
                  itemBuilder: (context, index) {
                    final a = active[index];
                    final selected = _selected.contains(a.agentId);

                    return Container(
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
                              horizontal: 14,
                              vertical: 12,
                            ),
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
                                        a.agentName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        a.agentPhone,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
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
                    );
                  },
                );
              },
            ),
          ),

          // Actions
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
                          ..addAll(assignments.map((a) => a.agentId));
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
            ),
          ),
        ],
      ),
    );
  }
}

