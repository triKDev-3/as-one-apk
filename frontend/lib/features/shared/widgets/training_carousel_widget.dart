import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/asone_loader.dart';
import '../repositories/training_video_repository.dart';
import '../models/training_video.dart';

final activeTrainingVideosProvider = FutureProvider.autoDispose<List<TrainingVideo>>((ref) {
  return ref.watch(trainingVideoRepositoryProvider).findAll(activeOnly: true);
});

class TrainingCarouselWidget extends ConsumerStatefulWidget {
  const TrainingCarouselWidget({super.key});

  @override
  ConsumerState<TrainingCarouselWidget> createState() => _TrainingCarouselWidgetState();
}

class _TrainingCarouselWidgetState extends ConsumerState<TrainingCarouselWidget> {
  int _currentIndex = 0;
  final CarouselSliderController _carouselController = CarouselSliderController();
  
  @override
  Widget build(BuildContext context) {
    final async = ref.watch(activeTrainingVideosProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
      data: (videos) {
        if (videos.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
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
                  video: video,
                  isActive: _currentIndex == index,
                  onViewMore: () {
                    context.push('/agent/lesson', extra: video);
                  },
                );
              },
              options: CarouselOptions(
                height: 280,
                viewportFraction: 0.85,
                enableInfiniteScroll: false,
                enlargeCenterPage: true,
                onPageChanged: (index, reason) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
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

  const _VideoCard({
    required this.video,
    required this.isActive,
    required this.onViewMore,
  });

  @override
  State<_VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<_VideoCard> {
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
          mute: true, // "mode muet" as requested
          hideControls: true,
        ),
      );
    }
  }

  @override
  void didUpdateWidget(covariant _VideoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller?.play();
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller?.pause();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _controller != null
                ? YoutubePlayer(
                    controller: _controller!,
                    showVideoProgressIndicator: false,
                  )
                : Container(
                    color: Colors.black12,
                    child: const Center(child: Text('Vidéo indisponible')),
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.video.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.video.description != null)
                        Text(
                          widget.video.description!,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
