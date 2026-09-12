import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Central cache invalidation manager
/// Used to coordinate invalidations across multiple providers
final cacheInvalidationProvider = StateNotifierProvider<CacheInvalidationNotifier, void>((ref) {
  return CacheInvalidationNotifier(ref);
});

class CacheInvalidationNotifier extends StateNotifier<void> {
  final Ref ref;

  CacheInvalidationNotifier(this.ref) : super(null);

  /// Invalidate all assignment-related caches
  void invalidateAssignments() {
    // Implementation will reference actual provider names
    // ref.invalidate(myAssignmentsProvider);
    // ref.invalidate(assignmentsByStatusProvider);
  }

  /// Invalidate all pointage-related caches
  void invalidatePointages() {
    // ref.invalidate(todayPointagesProvider);
    // ref.invalidate(pointagesForAssignmentProvider);
  }

  /// Invalidate all notification caches
  void invalidateNotifications() {
    // ref.invalidate(unreadNotificationsProvider);
    // ref.invalidate(notificationBadgeCountProvider);
  }

  /// Invalidate all caches (full refresh)
  void invalidateAll() {
    invalidateAssignments();
    invalidatePointages();
    invalidateNotifications();
  }
}
