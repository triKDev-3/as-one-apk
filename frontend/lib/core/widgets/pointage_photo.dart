import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Affiche une photo de pointage (URL http ou data:image base64).
class PointagePhoto extends StatelessWidget {
  final String? photoUrl;
  final double size;
  final BoxFit fit;

  const PointagePhoto({
    super.key,
    required this.photoUrl,
    this.size = 56,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final url = photoUrl?.trim() ?? '';
    if (url.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.photo_outlined,
            color: AppColors.textTertiary, size: size * 0.4),
      );
    }

    Widget image;
    if (url.startsWith('data:image')) {
      try {
        final b64 = url.split(',').last;
        final bytes = base64Decode(b64);
        image = Image.memory(bytes, width: size, height: size, fit: fit);
      } catch (_) {
        image = Icon(Icons.broken_image, size: size * 0.4);
      }
    } else {
      image = Image.network(
        url,
        width: size,
        height: size,
        fit: fit,
        errorBuilder: (_, __, ___) =>
            Icon(Icons.broken_image, size: size * 0.4),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(width: size, height: size, child: image),
    );
  }
}

/// Plein écran pour revoir la photo
void showPointagePhotoFull(BuildContext context, String photoUrl) {
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.black,
      insetPadding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          InteractiveViewer(
            child: Center(
              child: PointagePhoto(
                photoUrl: photoUrl,
                size: MediaQuery.of(context).size.width * 0.9,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(ctx),
            ),
          ),
        ],
      ),
    ),
  );
}
