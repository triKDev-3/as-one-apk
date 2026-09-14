import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/hero_banner.dart';
import '../../core/widgets/action_grid_card.dart';

class MagasinierHomeScreen extends ConsumerWidget {
  const MagasinierHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          HeroBanner(
            userName: user?.firstName != null
                ? '${user!.firstName} ${user.lastName}'
                : 'Gestionnaire Stock',
            roleName: 'Magasinier & Parc',
            subtitle:
                'Suivi du matériel de chantier, des dotations et de la flotte automobile.',
            onLogout: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                const Text(
                  'Stock & Équipements',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ).animate().fadeIn(),
                const SizedBox(height: 14),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.1,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    ActionGridCard(
                      icon: Icons.description_rounded,
                      title: 'Fiches F-ACH-07',
                      subtitle: 'Demandes & livraisons',
                      accentColor: AppColors.primary,
                      onTap: () => context.push('/magasinier/fiches'),
                    ),
                    ActionGridCard(
                      icon: Icons.move_to_inbox_rounded,
                      title: 'Retour & Contrôle',
                      subtitle: 'Cochez, pertes, dommages',
                      accentColor: AppColors.secondary,
                      onTap: () => context.push('/magasinier/fiches'),
                    ),
                    ActionGridCard(
                      icon: Icons.inventory_2_rounded,
                      title: 'Catalogue',
                      subtitle: 'CRUD + liste officielle',
                      accentColor: AppColors.accent,
                      onTap: () => context.push('/magasinier/catalog'),
                    ),
                    ActionGridCard(
                      icon: Icons.directions_car_filled_rounded,
                      title: 'Parc Véhicules',
                      subtitle: 'Kilométrage & suivi',
                      accentColor: AppColors.primaryDark,
                      onTap: () => context.push('/magasinier/alerts'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                CustomCard(
                  onTap: () => context.push('/magasinier/pointages'),
                  padding: const EdgeInsets.all(18),
                  child: const Row(
                    children: [
                      Icon(Icons.fingerprint_rounded, color: AppColors.accent),
                      SizedBox(width: 16),
                      Expanded(
                          child: Text('Historique pointages',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700))),
                      Icon(Icons.arrow_forward_ios_rounded,
                          color: AppColors.textTertiary, size: 14),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                CustomCard(
                  onTap: () => context.push('/magasinier/incidents'),
                  padding: const EdgeInsets.all(18),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: AppColors.danger),
                      SizedBox(width: 16),
                      Expanded(
                          child: Text('Incidents & pénalités',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700))),
                      Icon(Icons.arrow_forward_ios_rounded,
                          color: AppColors.textTertiary, size: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
