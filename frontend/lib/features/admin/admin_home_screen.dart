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
      body: Column(
        children: [
          HeroBanner(
            userName: user?.firstName != null ? '${user!.firstName} ${user.lastName}' : 'Direction AS ONE',
            roleName: 'Administrateur',
            subtitle: 'Pilotage global du personnel, des sites d\'intervention et des accès.',
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
                      'Gestion & Paramètres',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Accès Superviseur',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ).animate().fadeIn().slideX(begin: -0.05, end: 0),

                const SizedBox(height: 14),

                // 2x2 Admin Grid
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
                ).animate().fadeIn(delay: 150.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),

                const SizedBox(height: 20),

                // Performance Ranking Hero Card
                CustomCard(
                  onTap: () => context.push('/admin/ranking'),
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.warning.withValues(alpha: 0.2),
                              AppColors.warning.withValues(alpha: 0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3), width: 1),
                        ),
                        child: const Icon(Icons.leaderboard_rounded, color: AppColors.warning, size: 26),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Classement des agents',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Notes moyennes, ponctualité et performances chantiers',
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
