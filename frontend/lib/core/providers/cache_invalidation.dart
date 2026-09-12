import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/chef/screens/select_site_screen.dart';
import '../../features/shared/notifications_screen.dart';
import '../../features/shared/pointages_log_screen.dart';
import 'providers.dart';

/// Invalide les caches Riverpod après une mutation (pointage, équipe, notif).
final cacheInvalidationProvider =
    Provider<CacheInvalidation>((ref) => CacheInvalidation(ref));

class CacheInvalidation {
  final Ref ref;
  CacheInvalidation(this.ref);

  void invalidateAssignments() {
    ref.invalidate(siteAssignmentsProvider);
    ref.invalidate(availableAgentsProvider);
    ref.invalidate(sitesListProvider);
  }

  void invalidatePointages() {
    ref.invalidate(pointagesLogProvider);
  }

  void invalidateNotifications() {
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadCountProvider);
  }

  void invalidateAll() {
    invalidateAssignments();
    invalidatePointages();
    invalidateNotifications();
  }
}
