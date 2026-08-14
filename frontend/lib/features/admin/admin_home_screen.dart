import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/providers.dart';

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Administration'),
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
            'Bonjour, ${user?.firstName ?? 'Direction'}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Contrôle total AS ONE',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          _AdminCard(
            icon: Icons.person_add_alt_1,
            title: 'Créer un compte',
            subtitle: 'Agent, Chef, Magasinier, Comptable…',
            color: AppColors.primary,
            onTap: () => context.push('/admin/users/create'),
          ),
          const SizedBox(height: 12),
          _AdminCard(
            icon: Icons.people_outline,
            title: 'Utilisateurs',
            subtitle: 'Liste et suspension',
            color: AppColors.secondary,
            onTap: () => context.push('/admin/users'),
          ),
          const SizedBox(height: 12),
          _AdminCard(
            icon: Icons.add_business,
            title: 'Nouveau site',
            subtitle: 'Chantier ou permanence',
            color: AppColors.accent,
            onTap: () => context.push('/admin/sites/create'),
          ),
          const SizedBox(height: 12),
          _AdminCard(
            icon: Icons.domain,
            title: 'Sites',
            subtitle: 'Chantiers et permanences',
            color: AppColors.primary,
            onTap: () => context.push('/admin/sites'),
          ),
          const SizedBox(height: 12),
          _AdminCard(
            icon: Icons.leaderboard,
            title: 'Classement agents',
            subtitle: 'Moyennes des notes',
            color: AppColors.warning,
            onTap: () => context.push('/admin/ranking'),
          ),
        ],
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AdminCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
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
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
