import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

/// Bouton rond flottant « site » pour le chef.
/// Visible partout sauf écrans de capture photo / pointage actif.
class ChefSiteFab extends StatelessWidget {
  final String location;

  const ChefSiteFab({super.key, required this.location});

  /// Masqué pendant la prise de photo / saisie pointage pour ne pas gêner.
  static bool shouldShow(String path) {
    if (!path.startsWith('/chef')) return false;
    // Capture photo + écran de pointage en cours
    if (path.startsWith('/chef/pointage')) return false;
    // Sélection de site déjà ouverte → pas de double accès
    if (path.startsWith('/chef/select-site')) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (!shouldShow(location)) return const SizedBox.shrink();

    return FloatingActionButton(
      heroTag: 'chef_site_fab',
      onPressed: () => context.push('/chef/select-site'),
      backgroundColor: AppColors.secondary,
      foregroundColor: Colors.white,
      elevation: 6,
      tooltip: 'Changer de site / opérations',
      child: const Icon(Icons.apartment_rounded, size: 28),
    );
  }
}
