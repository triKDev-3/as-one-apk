import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

/// Navigation bas type mobile — un jeu d'onglets par rôle.
class AsOneBottomNav extends StatelessWidget {
  final String role;
  final int currentIndex;

  const AsOneBottomNav({
    super.key,
    required this.role,
    required this.currentIndex,
  });

  static List<String> routesFor(String role) {
    return _itemsFor(role).map((e) => e.route).toList();
  }

  static List<_NavItem> _itemsFor(String role) {
    switch (role) {
      case 'CHEF':
        return const [
          _NavItem(Icons.dashboard_rounded, 'Accueil', '/chef'),
          _NavItem(Icons.calendar_month_rounded, 'Agenda', '/chef/calendar'),
          _NavItem(Icons.apartment_rounded, 'Sites', '/chef/select-site'),
          _NavItem(Icons.notifications_rounded, 'Notifs', '/chef/notifications'),
          _NavItem(Icons.person_rounded, 'Profil', '/chef/profile'),
        ];
      case 'MAGASINIER':
        return const [
          _NavItem(Icons.dashboard_rounded, 'Accueil', '/magasinier'),
          _NavItem(Icons.outbox_rounded, 'Sortie', '/magasinier/out'),
          _NavItem(Icons.move_to_inbox_rounded, 'Retour', '/magasinier/return'),
          _NavItem(Icons.notifications_rounded, 'Notifs', '/magasinier/notifications'),
          _NavItem(Icons.warning_amber_rounded, 'Incidents', '/magasinier/incidents'),
        ];
      case 'COMPTABLE':
        return const [
          _NavItem(Icons.dashboard_rounded, 'Accueil', '/comptable'),
          _NavItem(Icons.fingerprint_rounded, 'Pointages', '/comptable/pointages'),
          _NavItem(Icons.notifications_rounded, 'Notifs', '/comptable/notifications'),
          _NavItem(Icons.warning_amber_rounded, 'Incidents', '/comptable/incidents'),
        ];
      case 'ADMIN':
        return const [
          _NavItem(Icons.dashboard_rounded, 'Accueil', '/admin'),
          _NavItem(Icons.calendar_month_rounded, 'Agenda', '/admin/calendar'),
          _NavItem(Icons.badge_rounded, 'Utilisateurs', '/admin/users'),
          _NavItem(Icons.notifications_rounded, 'Notifs', '/admin/notifications'),
          _NavItem(Icons.domain_rounded, 'Sites', '/admin/sites'),
        ];
      default:
        return const [
          _NavItem(Icons.home_rounded, 'Accueil', '/agent'),
          _NavItem(Icons.calendar_month_rounded, 'Planning', '/agent/planning'),
          _NavItem(Icons.notifications_rounded, 'Notifs', '/agent/notifications'),
          _NavItem(Icons.leaderboard_rounded, 'Classement', '/agent/ranking'),
          _NavItem(Icons.person_rounded, 'Profil', '/agent/profile'),
        ];
    }
  }

  List<_NavItem> get _items => _itemsFor(role);

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final idx = currentIndex.clamp(0, items.length - 1);
    return NavigationBar(
      selectedIndex: idx,
      height: 68,
      backgroundColor: Colors.white,
      elevation: 8,
      shadowColor: Colors.black26,
      // Indicateur plus marqué pour l'onglet actif
      indicatorColor: AppColors.primary.withValues(alpha: 0.18),
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      onDestinationSelected: (i) {
        final dest = items[i].route;
        final current = GoRouterState.of(context).uri.path;
        if (current == dest) return;
        context.go(dest);
      },
      destinations: [
        for (var i = 0; i < items.length; i++)
          NavigationDestination(
            icon: Icon(
              items[i].icon,
              color: AppColors.textSecondary,
              size: 22,
            ),
            selectedIcon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                items[i].icon,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            label: items[i].label,
          ),
      ],
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;
  const _NavItem(this.icon, this.label, this.route);
}
