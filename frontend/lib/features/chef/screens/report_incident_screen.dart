import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
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
    final selected = await showModalBottomSheet<SiteModel>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        builder: (_, scroll) => ListView.builder(
          controller: scroll,
          itemCount: sites.length,
          itemBuilder: (_, i) {
            final s = sites[i];
            return ListTile(
              title: Text(s.name),
              subtitle: Text(s.typeLabel),
              onTap: () => Navigator.pop(ctx, s),
            );
          },
        ),
      ),
    );
    if (selected != null) setState(() => _site = selected);
  }

  Future<void> _pickPhoto() async {
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
                      ? AppColors.danger.withOpacity(0.2)
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
