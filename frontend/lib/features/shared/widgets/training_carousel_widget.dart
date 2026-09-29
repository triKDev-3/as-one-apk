import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../repositories/training_video_repository.dart';
import '../models/training_video.dart';

/// Extrait l'ID YouTube d'une URL ou d'un ID brut.
String? extractYoutubeId(String url) {
  final u = url.trim();
  if (RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(u)) return u;
  final patterns = [
    RegExp(r'youtu\.be/([a-zA-Z0-9_-]{11})'),
    RegExp(r'youtube\.com/watch\?v=([a-zA-Z0-9_-]{11})'),
    RegExp(r'youtube\.com/embed/([a-zA-Z0-9_-]{11})'),
    RegExp(r'youtube\.com/shorts/([a-zA-Z0-9_-]{11})'),
    RegExp(r'youtube\.com/live/([a-zA-Z0-9_-]{11})'),
    RegExp(r'v=([a-zA-Z0-9_-]{11})'),
  ];
  for (final p in patterns) {
    final m = p.firstMatch(u);
    if (m != null) return m.group(1);
  }
  return null;
}

final activeTrainingVideosProvider =
    FutureProvider.autoDispose<List<TrainingVideo>>((ref) {
  return ref.watch(trainingVideoRepositoryProvider).findAll(activeOnly: true);
});

class TrainingCarouselWidget extends ConsumerStatefulWidget {
  const TrainingCarouselWidget({super.key});

  @override
  ConsumerState<TrainingCarouselWidget> createState() =>
      _TrainingCarouselWidgetState();
}

class _TrainingCarouselWidgetState
    extends ConsumerState<TrainingCarouselWidget> {
  int _currentIndex = 0;
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(activeTrainingVideosProvider);

    return async.when(
      loading: () => const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text('Formation indisponible: $e',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ),
      data: (videos) {
        if (videos.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Formation',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            CarouselSlider.builder(
              carouselController: _carouselController,
              itemCount: videos.length,
              itemBuilder: (context, index, realIndex) {
                final video = videos[index];
                return _VideoCard(
                  key: ValueKey(video.id),
                  video: video,
                  onViewMore: () {
                    context.push('/agent/lesson', extra: video);
                  },
                );
              },
              options: CarouselOptions(
                height: 220,
                viewportFraction: 0.88,
                enableInfiniteScroll: videos.length > 1,
                enlargeCenterPage: true,
                autoPlay: videos.length > 1,
                autoPlayInterval: const Duration(seconds: 6),
                onPageChanged: (index, reason) {
                  setState(() => _currentIndex = index);
                },
              ),
            ),
            if (videos.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    videos.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _currentIndex == i ? 16 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _currentIndex == i
                            ? AppColors.primary
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _VideoCard extends StatelessWidget {
  final TrainingVideo video;
  final VoidCallback onViewMore;

  const _VideoCard({
    super.key,
    required this.video,
    required this.onViewMore,
  });

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
    final thumb = id != null
        ? 'https://img.youtube.com/vi/$id/hqdefault.jpg'
        : null;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
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
                      child: const Center(
                        child: Icon(Icons.play_circle_outline, size: 48),
                      ),
                    ),
                  Container(
                    color: Colors.black26,
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_filled_rounded,
                        color: Colors.white,
                        size: 56,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (video.description != null &&
                          video.description!.isNotEmpty)
                        Text(
                          video.description!,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onViewMore,
                  child: const Text('Voir plus'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
