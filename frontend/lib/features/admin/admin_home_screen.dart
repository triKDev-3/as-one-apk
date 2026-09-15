import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/hero_banner.dart';
import '../../core/widgets/action_grid_card.dart';

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      // Nav bas fournie par RoleShell (persistante)
      body: Column(
        children: [
          HeroBanner(
            userName: user?.firstName != null
                ? '${user!.firstName} ${user.lastName}'
                : 'Direction AS ONE',
            roleName: 'Administrateur',
            subtitle:
                'Pilotage global du personnel, des sites d\'intervention et des accès.',
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
                  'Gestion & Paramètres',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ).animate().fadeIn().slideX(begin: -0.05, end: 0),
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
                      icon: Icons.person_add_rounded,
                      title: 'Créer compte',
                      subtitle: 'Agent, Chef, Staff',
                      accentColor: AppColors.primary,
                      onTap: () => context.push('/admin/users/create'),
                    ),
                    ActionGridCard(
                      icon: Icons.badge_rounded,
                      title: 'Utilisateurs',
                      subtitle: 'Liste & suspensions',
                      accentColor: AppColors.secondary,
                      onTap: () => context.push('/admin/users'),
                    ),
                    ActionGridCard(
                      icon: Icons.add_business_rounded,
                      title: 'Nouveau site',
                      subtitle: 'Chantier & permanence',
                      accentColor: AppColors.accent,
                      onTap: () => context.push('/admin/sites/create'),
                    ),
                    ActionGridCard(
                      icon: Icons.domain_rounded,
                      title: 'Tous les sites',
                      subtitle: 'Vue d\'ensemble réseau',
                      accentColor: AppColors.primaryDark,
                      onTap: () => context.push('/admin/sites'),
                    ),
                  ],
                ).animate().fadeIn(delay: 150.ms),
                const SizedBox(height: 20),
                CustomCard(
                  onTap: () => context.push('/admin/interventions'),
                  padding: const EdgeInsets.all(18),
                  child: const Row(
                    children: [
                      Icon(Icons.history_edu_rounded, color: AppColors.primary),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text('Historique interventions',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                      Icon(Icons.file_download_outlined,
                          color: AppColors.textTertiary, size: 18),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_ios_rounded,
                          color: AppColors.textTertiary, size: 14),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                CustomCard(
                  onTap: () => context.push('/admin/pointages'),
                  padding: const EdgeInsets.all(18),
                  child: const Row(
                    children: [
                      Icon(Icons.fingerprint_rounded, color: AppColors.accent),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text('Historique pointages',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded,
                          color: AppColors.textTertiary, size: 14),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                CustomCard(
                  onTap: () => context.push('/admin/incidents'),
                  padding: const EdgeInsets.all(18),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: AppColors.danger),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text('Incidents',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded,
                          color: AppColors.textTertiary, size: 14),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                CustomCard(
                  onTap: () => context.push('/admin/damages'),
                  padding: const EdgeInsets.all(18),
                  child: const Row(
                    children: [
                      Icon(Icons.handyman_rounded, color: AppColors.danger),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text('Dommages matériel & sanctions',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded,
                          color: AppColors.textTertiary, size: 14),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                CustomCard(
                  onTap: () => context.push('/admin/catalog'),
                  padding: const EdgeInsets.all(18),
                  child: const Row(
                    children: [
                      Icon(Icons.inventory_2_rounded, color: AppColors.primary),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text('Catalogue matériel',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded,
                          color: AppColors.textTertiary, size: 14),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                CustomCard(
                  onTap: () => context.push('/admin/training-videos'),
                  padding: const EdgeInsets.all(18),
                  child: const Row(
                    children: [
                      Icon(Icons.play_lesson_rounded, color: AppColors.secondary),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text('Vidéos de formation',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded,
                          color: AppColors.textTertiary, size: 14),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                CustomCard(
                  onTap: () => context.push('/admin/ranking'),
                  padding: const EdgeInsets.all(18),
                  child: const Row(
                    children: [
                      Icon(Icons.leaderboard_rounded, color: AppColors.warning),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text('Classement des agents',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
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
