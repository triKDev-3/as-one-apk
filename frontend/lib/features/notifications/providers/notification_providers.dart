import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/notification_model.dart';

final apiClientProvider = Provider((ref) => ApiClient());

// Unread notifications list
final unreadNotificationsProvider = FutureProvider<List<NotificationModel>>((ref) async {
  final api = ref.watch(apiClientProvider);
  return api.getUnreadNotifications();
});

// Notification badge count (unread count)
final notificationBadgeCountProvider = FutureProvider<int>((ref) async {
  final notifications = await ref.watch(unreadNotificationsProvider.future);
  return notifications.length;
});

// Sync status - indicates if notifications are synced with backend
final notificationSyncStatusProvider = StateProvider<bool>((ref) => true);

// Mark notification as read
final markNotificationAsReadProvider = FutureProvider.family<void, String>((ref, notificationId) async {
  final api = ref.watch(apiClientProvider);
  
  try {
    await api.markNotificationAsRead(notificationId);
    
    // Invalidate cache
    ref.invalidate(unreadNotificationsProvider);
    ref.invalidate(notificationBadgeCountProvider);
  } catch (e) {
    rethrow;
  }
});

// Pending notifications queue (from backend)
final pendingNotificationsProvider = FutureProvider<List<NotificationModel>>((ref) async {
  final api = ref.watch(apiClientProvider);
  return api.getPendingNotifications();
});
