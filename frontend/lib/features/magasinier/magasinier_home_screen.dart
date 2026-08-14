import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/providers.dart';

class MagasinierHomeScreen extends ConsumerWidget {
  const MagasinierHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Magasin'),
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
            'Bonjour, ${user?.firstName ?? 'Magasinier'}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Gestion du matériel et des alertes',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          _ActionCard(
            icon: Icons.outbox_outlined,
            title: 'Sortie de matériel',
            subtitle: 'Affecter au chantier',
            color: AppColors.primary,
            onTap: () => context.push('/magasinier/out'),
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.move_to_inbox_outlined,
            title: 'Retour de matériel',
            subtitle: 'État + retenues',
            color: AppColors.secondary,
            onTap: () => context.push('/magasinier/return'),
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.inventory_2_outlined,
            title: 'Catalogue',
            subtitle: 'Articles consignables / consommables',
            color: AppColors.accent,
            onTap: () => context.push('/magasinier/catalog'),
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.warning_amber_outlined,
            title: 'Alertes véhicules',
            subtitle: 'Assurance, vidange…',
            color: AppColors.warning,
            onTap: () => context.push('/magasinier/alerts'),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
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
