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

  static int indexFromPath(String path, String role) {
    final items = AsOneBottomNav.routesFor(role);
    // Match le plus long préfixe d'abord
    for (var i = 0; i < items.length; i++) {
      final r = items[i];
      if (path == r || path.startsWith('$r/')) return i;
    }
    // Accueil = index 0 si sous-route inconnue
    if (items.isNotEmpty && path.startsWith(items.first.split('/').take(2).join('/'))) {
      return 0;
    }
    return 0;
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
