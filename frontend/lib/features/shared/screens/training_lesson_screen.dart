import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../models/training_video.dart';
import '../widgets/training_carousel_widget.dart';

class TrainingLessonScreen extends StatelessWidget {
  final TrainingVideo video;
  const TrainingLessonScreen({super.key, required this.video});

  Future<void> _openYoutube() async {
    final id = extractYoutubeId(video.youtubeUrl);
    final uri = id != null
        ? Uri.parse('https://www.youtube.com/watch?v=$id')
        : Uri.tryParse(video.youtubeUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final id = extractYoutubeId(video.youtubeUrl);
    final thumb =
        id != null ? 'https://img.youtube.com/vi/$id/hqdefault.jpg' : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(video.title)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: InkWell(
                onTap: _openYoutube,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (thumb != null)
                      Image.network(
                        thumb,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.black12,
                          child: const Icon(Icons.play_circle_outline, size: 48),
                        ),
                      )
                    else
                      Container(
                        color: Colors.black12,
                        child: const Center(child: Text('Vidéo indisponible')),
                      ),
                    Container(
                      color: Colors.black26,
                      child: const Center(
                        child: Icon(
                          Icons.play_circle_filled_rounded,
                          color: Colors.white,
                          size: 64,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  if (video.description != null &&
                      video.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      video.description!,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openYoutube,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Lire sur YouTube'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  if (video.lessonContent != null &&
                      video.lessonContent!.isNotEmpty)
                    MarkdownBody(data: video.lessonContent!)
                  else
                    const Text(
                      'Aucune leçon détaillée pour cette vidéo.',
                      style: TextStyle(color: AppColors.textTertiary),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
