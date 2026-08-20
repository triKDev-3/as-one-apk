import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/custom_card.dart';

class ChefHomeScreen extends ConsumerWidget {
  const ChefHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Espace Chef'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Bonjour, ${user?.firstName ?? 'Chef'}',
            style: Theme.of(context).textTheme.headlineMedium,
          ).animate().fadeIn().slideX(),
          const SizedBox(height: 8),
          Text(
            'Choisissez un site pour composer votre équipe',
            style: Theme.of(context).textTheme.bodyMedium,
          ).animate().fadeIn(delay: 100.ms).slideX(),
          const SizedBox(height: 24),
          ...[
            _ChefActionCard(
              icon: Icons.domain_add,
              title: 'Choisir un site',
              subtitle: 'Chantier ou permanence',
              color: AppColors.primary,
              onTap: () => context.push('/chef/select-site'),
            ),
            const SizedBox(height: 16),
            _ChefActionCard(
              icon: Icons.group_add,
              title: 'Composer une équipe',
              subtitle: 'Agents disponibles',
              color: AppColors.secondary,
              onTap: () => context.push('/chef/select-site'),
            ),
            const SizedBox(height: 16),
            _ChefActionCard(
              icon: Icons.fact_check,
              title: 'Pointage',
              subtitle: 'Valider la présence',
              color: AppColors.accent,
              onTap: () => context.push('/chef/select-site'),
            ),
            const SizedBox(height: 16),
            _ChefActionCard(
              icon: Icons.star_rate,
              title: 'Noter les agents',
              subtitle: 'Fin de chantier',
              color: AppColors.warning,
              onTap: () => context.push('/chef/select-site'),
            ),
            const SizedBox(height: 16),
            _ChefActionCard(
              icon: Icons.report_problem_outlined,
              title: 'Signaler un incident',
              subtitle: 'Dégât ou matériel manquant',
              color: AppColors.danger,
              onTap: () => context.push('/chef/incident'),
            ),
            const SizedBox(height: 16),
            _ChefActionCard(
              icon: Icons.swap_horiz,
              title: 'Transferts',
              subtitle: 'Demandes entre chefs',
              color: AppColors.secondaryLight,
              onTap: () => context.push('/chef/transfers'),
            ),
          ].animate(interval: 100.ms).fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
        ],
      ),
    );
  }
}

class _ChefActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ChefActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
