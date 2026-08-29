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
            userName: user?.firstName != null ? '${user!.firstName} ${user.lastName}' : 'Gestionnaire Stock',
            roleName: 'Magasinier & Parc',
            subtitle: 'Suivi du matériel de chantier, des dotations et de la flotte automobile.',
            onLogout: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Stock & Équipements',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Inventaire actif',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ).animate().fadeIn().slideX(begin: -0.05, end: 0),

                const SizedBox(height: 14),

                // 2x2 Action Grid
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.1,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    ActionGridCard(
                      icon: Icons.outbox_rounded,
                      title: 'Sortie Matériel',
                      subtitle: 'Affecter aux chantiers',
                      accentColor: AppColors.primary,
                      onTap: () => context.push('/magasinier/out'),
                    ),
                    ActionGridCard(
                      icon: Icons.move_to_inbox_rounded,
                      title: 'Retour & Contrôle',
                      subtitle: 'État, dégradations',
                      accentColor: AppColors.secondary,
                      onTap: () => context.push('/magasinier/return'),
                    ),
                    ActionGridCard(
                      icon: Icons.inventory_2_rounded,
                      title: 'Catalogue Stock',
                      subtitle: 'Consommables & EPI',
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
                ).animate().fadeIn(delay: 150.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),

                const SizedBox(height: 20),

                // Vehicle Maintenance Alert Hero Card
                CustomCard(
                  onTap: () => context.push('/magasinier/pointages'),
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.fingerprint_rounded, color: AppColors.accent, size: 26),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Historique pointages', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                            SizedBox(height: 3),
                            Text('Départs enregistrés sur les chantiers', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textTertiary, size: 14),
                    ],
                  ),
                ).animate().fadeIn(delay: 280.ms).slideY(begin: 0.1, end: 0),
                const SizedBox(height: 12),
                CustomCard(
                  onTap: () => context.push('/magasinier/incidents'),
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 26),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Incidents', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                            SizedBox(height: 3),
                            Text('Consulter et appliquer les pénalités', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textTertiary, size: 14),
                    ],
                  ),
                ).animate().fadeIn(delay: 320.ms).slideY(begin: 0.1, end: 0),
                const SizedBox(height: 12),
                CustomCard(
                  onTap: () => context.push('/magasinier/alerts'),
                  padding: const EdgeInsets.all(18),
                  border: Border.all(color: AppColors.warning.withOpacity(0.4), width: 1.2),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.warning.withOpacity(0.2),
                              AppColors.warning.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.warning.withOpacity(0.3), width: 1),
                        ),
                        child: const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 26),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Alertes Maintenance & Échéances',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Assurances, visites techniques, vidanges à planifier',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textTertiary, size: 14),
                    ],
                  ),
                ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1, end: 0),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
