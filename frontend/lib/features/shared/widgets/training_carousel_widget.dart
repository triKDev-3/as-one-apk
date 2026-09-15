import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
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
                  isActive: _currentIndex == index,
                  onViewMore: () {
                    context.push('/agent/lesson', extra: video);
                  },
                  onEnded: () {
                    if (index < videos.length - 1) {
                      _carouselController.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOut,
                      );
                    } else {
                      _carouselController.animateToPage(
                        0,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                );
              },
              options: CarouselOptions(
                height: 280,
                viewportFraction: 0.88,
                enableInfiniteScroll: videos.length > 1,
                enlargeCenterPage: true,
                autoPlay: false,
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

class _VideoCard extends StatefulWidget {
  final TrainingVideo video;
  final bool isActive;
  final VoidCallback onViewMore;
  final VoidCallback? onEnded;

  const _VideoCard({
    super.key,
    required this.video,
    required this.isActive,
    required this.onViewMore,
    this.onEnded,
  });

  @override
  State<_VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<_VideoCard> {
  YoutubePlayerController? _controller;
  String? _videoId;

  @override
  void initState() {
    super.initState();
    _videoId = extractYoutubeId(widget.video.youtubeUrl);
    if (_videoId != null) {
      _controller = YoutubePlayerController.fromVideoId(
        videoId: _videoId!,
        autoPlay: widget.isActive,
        params: const YoutubePlayerParams(
          mute: true,
          showControls: false,
          showFullscreenButton: false,
          loop: false,
          enableCaption: false,
        ),
      );
      _controller!.listen((event) {
        // Fin de vidéo → slide suivante
        if (event.playerState == PlayerState.ended) {
          widget.onEnded?.call();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant _VideoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final c = _controller;
    if (c == null) return;
    if (widget.isActive && !oldWidget.isActive) {
      c.playVideo();
    } else if (!widget.isActive && oldWidget.isActive) {
      c.pauseVideo();
    }
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _controller != null
                ? YoutubePlayer(
                    controller: _controller!,
                    aspectRatio: 16 / 9,
                  )
                : Container(
                    color: Colors.black12,
                    child: const Center(
                      child: Text('Vidéo indisponible',
                          style: TextStyle(color: AppColors.textSecondary)),
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
                        widget.video.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.video.description != null &&
                          widget.video.description!.isNotEmpty)
                        Text(
                          widget.video.description!,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: widget.onViewMore,
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
