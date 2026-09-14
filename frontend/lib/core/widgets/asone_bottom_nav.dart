import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

/// Navigation bas type mobile — un jeu d'onglets par rôle.
/// L'onglet sélectionné se démarque nettement (pilule bleue + label gras).
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
          _NavItem(Icons.history_rounded, 'Historique', '/chef/calendar'),
          _NavItem(Icons.apartment_rounded, 'Sites', '/chef/select-site'),
          _NavItem(Icons.notifications_rounded, 'Notifs', '/chef/notifications'),
          _NavItem(Icons.person_rounded, 'Profil', '/chef/profile'),
        ];
      case 'MAGASINIER':
        return const [
          _NavItem(Icons.dashboard_rounded, 'Accueil', '/magasinier'),
          _NavItem(Icons.inventory_2_rounded, 'Fiches', '/magasinier/fiches'),
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

    return Material(
      elevation: 12,
      shadowColor: Colors.black38,
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Container(
          height: 64,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _NavTab(
                    item: items[i],
                    selected: i == idx,
                    onTap: () {
                      final dest = items[i].route;
                      final current = GoRouterState.of(context).uri.path;
                      if (current == dest) return;
                      context.go(dest);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavTab({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textTertiary;

    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: selected
              ? Border.all(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  width: 1.2,
                )
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.icon,
              size: selected ? 24 : 22,
              color: color,
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: selected ? 11.5 : 10.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                color: color,
                letterSpacing: selected ? -0.2 : 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;
  const _NavItem(this.icon, this.label, this.route);
}
