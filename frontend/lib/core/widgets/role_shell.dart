import 'package:flutter/material.dart';
import 'asone_bottom_nav.dart';

/// Coque avec barre de navigation bas **persistante** pendant la navigation.
class RoleShell extends StatelessWidget {
  final Widget child;
  final String location;

  const RoleShell({
    super.key,
    required this.child,
    required this.location,
  });

  static String roleFromPath(String path) {
    if (path.startsWith('/admin')) return 'ADMIN';
    if (path.startsWith('/chef')) return 'CHEF';
    if (path.startsWith('/magasinier')) return 'MAGASINIER';
    if (path.startsWith('/comptable')) return 'COMPTABLE';
    if (path.startsWith('/agent')) return 'AGENT';
    return 'AGENT';
  }

  /// Accueil n'est sélectionné que sur la racine du rôle.
  /// Les sous-pages gardent l'onglet de la section en cours.
  static int indexFromPath(String path, String role) {
    if (role == 'CHEF') {
      if (path == '/chef' || path == '/chef/') return 0; // Accueil
      if (path.startsWith('/chef/notifications')) return 3;
      if (path.startsWith('/chef/profile')) return 4;
      // Historique (pluriels AVANT les singuliers)
      if (path.startsWith('/chef/calendar') ||
          path.startsWith('/chef/pointages') ||
          path.startsWith('/chef/incidents') ||
          path.startsWith('/chef/interventions') ||
          path.startsWith('/chef/transfers') ||
          path.startsWith('/chef/ranking')) {
        return 1;
      }
      // Sites + opérations du site
      if (path.startsWith('/chef/select-site') ||
          path.startsWith('/chef/site') ||
          path.startsWith('/chef/compose') ||
          path.startsWith('/chef/pointage') ||
          path.startsWith('/chef/rate') ||
          path.startsWith('/chef/tasks') ||
          path.startsWith('/chef/report') ||
          path.startsWith('/chef/permanence') ||
          path.startsWith('/chef/incident') ||
          path.startsWith('/chef/material') ||
          path.startsWith('/chef/fiches')) {
        return 2;
      }
      return 0;
    }

    final items = AsOneBottomNav.routesFor(role);
    int best = 0;
    int bestLen = -1;
    for (var i = 0; i < items.length; i++) {
      final r = items[i];
      final isHome = r == '/agent' ||
          r == '/admin' ||
          r == '/magasinier' ||
          r == '/comptable' ||
          r == '/chef';
      if (isHome) {
        if (path == r || path == '$r/') {
          if (r.length >= bestLen) {
            best = i;
            bestLen = r.length;
          }
        }
        continue;
      }
      if (path == r || path.startsWith('$r/')) {
        if (r.length > bestLen) {
          best = i;
          bestLen = r.length;
        }
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final role = roleFromPath(location);
    final index = indexFromPath(location, role);

    return Scaffold(
      body: child,
      bottomNavigationBar: AsOneBottomNav(
        role: role,
        currentIndex: index,
      ),
    );
  }
}
