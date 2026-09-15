import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/asone_loader.dart';
import '../../shared/repositories/training_video_repository.dart';
import '../../shared/models/training_video.dart';

final trainingVideosProvider = FutureProvider.autoDispose<List<TrainingVideo>>((ref) {
  return ref.watch(trainingVideoRepositoryProvider).findAll();
});

class AdminTrainingVideosScreen extends ConsumerWidget {
  const AdminTrainingVideosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(trainingVideosProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Vidéos de formation')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(context, ref, null),
        child: const Icon(Icons.add),
      ),
      body: async.when(
        loading: () => const AsOneLoader(),
        error: (e, _) => Center(child: Text('$e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Aucune vidéo.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (ctx, i) {
              final v = items[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(v.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    'Ordre: ${v.orderIndex}${v.isActive ? '' : ' (Inactif)'}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _edit(context, ref, v),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                        onPressed: () => _delete(context, ref, v),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, TrainingVideo? v) async {
    final title = TextEditingController(text: v?.title ?? '');
    final desc = TextEditingController(text: v?.description ?? '');
    final url = TextEditingController(text: v?.youtubeUrl ?? '');
    final lesson = TextEditingController(text: v?.lessonContent ?? '');
    final order = TextEditingController(text: v?.orderIndex.toString() ?? '0');
    bool isActive = v?.isActive ?? true;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (ctx, setSt) => SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(v == null ? 'Nouvelle vidéo' : 'Modifier la vidéo',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  TextField(controller: title, decoration: const InputDecoration(labelText: 'Titre')),
                  TextField(controller: desc, decoration: const InputDecoration(labelText: 'Description courte')),
                  TextField(controller: url, decoration: const InputDecoration(labelText: 'URL YouTube')),
                  TextField(
                    controller: lesson,
                    decoration: const InputDecoration(labelText: 'Leçon (Markdown autorisé)'),
                    maxLines: 4,
                  ),
                  TextField(controller: order, decoration: const InputDecoration(labelText: 'Ordre d\'affichage'), keyboardType: TextInputType.number),
                  SwitchListTile(
                    title: const Text('Actif'),
                    value: isActive,
                    onChanged: (val) => setSt(() => isActive = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(v == null ? 'Créer' : 'Enregistrer'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (ok != true) return;
    
    final data = {
      'title': title.text.trim(),
      'description': desc.text.trim(),
      'youtubeUrl': url.text.trim(),
      'lessonContent': lesson.text.trim(),
      'orderIndex': int.tryParse(order.text.trim()) ?? 0,
      'isActive': isActive,
    };
    
    try {
      final repo = ref.read(trainingVideoRepositoryProvider);
      if (v == null) {
        await repo.create(data);
      } else {
        await repo.update(v.id, data);
      }
      ref.invalidate(trainingVideosProvider);
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, TrainingVideo v) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer'),
        content: Text('Voulez-vous supprimer la vidéo "${v.title}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ref.read(trainingVideoRepositoryProvider).remove(v.id);
        ref.invalidate(trainingVideosProvider);
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }
}
