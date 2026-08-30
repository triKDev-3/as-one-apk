import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../repositories/sites_repository.dart';

class ReportIncidentScreen extends ConsumerStatefulWidget {
  const ReportIncidentScreen({super.key});

  @override
  ConsumerState<ReportIncidentScreen> createState() =>
      _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends ConsumerState<ReportIncidentScreen> {
  SiteModel? _site;
  final _descCtrl = TextEditingController();
  String _type = 'DEGAT';
  String _severity = 'MOYENNE';
  File? _photo;
  bool _loading = false;
  final _picker = ImagePicker();

  Future<void> _pickSite() async {
    final sites = await ref.read(sitesRepositoryProvider).getSites();
    if (!mounted) return;
    final myId = ref.read(authProvider).user?.id ?? '';

    // Trier pour mettre "Mes sites" en premier
    sites.sort((a, b) {
      final aMine = a.chefIds.contains(myId);
      final bMine = b.chefIds.contains(myId);
      if (aMine && !bMine) return -1;
      if (!aMine && bMine) return 1;
      return a.name.compareTo(b.name);
    });

    final selected = await showModalBottomSheet<SiteModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, scroll) => Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Sélectionner un site',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scroll,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: sites.length,
                itemBuilder: (_, i) {
                  final s = sites[i];
                  final isMine = s.chefIds.contains(myId);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isMine ? AppColors.primary : AppColors.border,
                        width: isMine ? 1.5 : 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              s.name,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (isMine)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Mon site',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(s.typeLabel),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                      onTap: () => Navigator.pop(ctx, s),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (selected != null) setState(() => _site = selected);
  }

  Future<void> _pickPhoto() async {
    final status = await Permission.camera.request();
    if (status.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez autoriser l\'accès à l\'appareil photo dans les paramètres.')),
        );
        openAppSettings();
      }
      return;
    }
    if (!status.isGranted) return;

    final x = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1600,
      imageQuality: 75,
    );
    if (x != null) setState(() => _photo = File(x.path));
  }

  Future<void> _submit() async {
    if (_site == null || _descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Site et description obligatoires')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      String? photoUrl;
      if (_photo != null) {
        photoUrl =
            await ref.read(pointageRepositoryProvider).uploadPhoto(_photo!);
      }
      final api = ref.read(apiClientProvider);
      await api.dio.post('/incidents', data: {
        'siteId': _site!.id,
        'description': _descCtrl.text.trim(),
        'type': _type,
        'severity': _severity,
        if (photoUrl != null) 'photoUrl': photoUrl,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incident signalé'),
          backgroundColor: AppColors.accent,
        ),
      );
      context.pop();
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
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Signaler un incident'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Site concerné'),
            subtitle: Text(_site?.name ?? 'Sélectionner…'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickSite,
          ),
          const Divider(),
          const SizedBox(height: 8),
          Text('Type', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final t in [
                ('DEGAT', 'Dégât'),
                ('MATERIEL', 'Matériel'),
                ('SECURITE', 'Sécurité'),
                ('AUTRE', 'Autre'),
              ])
                ChoiceChip(
                  label: Text(t.$2),
                  selected: _type == t.$1,
                  onSelected: (_) => setState(() => _type = t.$1),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Gravité', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final s in [
                ('BASSE', 'Basse'),
                ('MOYENNE', 'Moyenne'),
                ('HAUTE', 'Haute'),
              ])
                ChoiceChip(
                  label: Text(s.$2),
                  selected: _severity == s.$1,
                  selectedColor: s.$1 == 'HAUTE'
                      ? AppColors.danger.withValues(alpha: 0.2)
                      : null,
                  onSelected: (_) => setState(() => _severity = s.$1),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Description',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (_photo != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_photo!, width: 64, height: 64, fit: BoxFit.cover),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _photo = null),
                ),
              ],
              OutlinedButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Photo'),
              ),
            ],
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: _loading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            child: _loading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Text('Envoyer le signalement'),
          ),
        ],
      ),
    );
  }
}
