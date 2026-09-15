import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../core/theme/app_colors.dart';
import '../models/training_video.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class TrainingLessonScreen extends StatefulWidget {
  final TrainingVideo video;
  const TrainingLessonScreen({super.key, required this.video});

  @override
  State<TrainingLessonScreen> createState() => _TrainingLessonScreenState();
}

class _TrainingLessonScreenState extends State<TrainingLessonScreen> {
  YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
    final videoId = YoutubePlayer.convertUrlToId(widget.video.youtubeUrl);
    if (videoId != null) {
      _controller = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(widget.video.title)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_controller != null)
              YoutubePlayer(
                controller: _controller!,
                showVideoProgressIndicator: true,
              )
            else
              Container(
                height: 200,
                color: Colors.black12,
                child: const Center(child: Text('Vidéo indisponible')),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.video.title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  if (widget.video.description != null && widget.video.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.video.description!,
                      style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  if (widget.video.lessonContent != null && widget.video.lessonContent!.isNotEmpty)
                    MarkdownBody(
                      data: widget.video.lessonContent!,
                    )
                  else
                    const Text('Aucune leçon détaillée pour cette vidéo.', style: TextStyle(color: AppColors.textTertiary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
