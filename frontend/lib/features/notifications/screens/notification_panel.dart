import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/notifications/providers/notification_providers.dart';

class NotificationPanel extends ConsumerWidget {
  const NotificationPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadAsync = ref.watch(unreadNotificationsProvider);

    return unreadAsync.when(
      data: (notifications) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Notifications'),
            backgroundColor: Color(0xFF005C9C),
            elevation: 0,
          ),
          body: notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none,
                          size: 64, color: Colors.grey[400]),
                      SizedBox(height: 16),
                      Text(
                        'Aucune notification',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => Divider(height: 1),
                  itemBuilder: (context, index) {
                    final notif = notifications[index];
                    return _NotificationTile(
                      notification: notif,
                      onTap: () {
                        ref.read(
                          markNotificationAsReadProvider(
                            notif.id,
                          ) as FutureProvider,
                        );
                      },
                    );
                  },
                ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(title: Text('Notifications')),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: Text('Notifications')),
        body: Center(child: Text('Erreur: $error')),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final dynamic notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(notification.title ?? 'Notification'),
      subtitle: Text(notification.body ?? ''),
      trailing: notification.readAt == null
          ? Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Color(0xFF005C9C),
                shape: BoxShape.circle,
              ),
            )
          : null,
      isThreeLine: true,
    );
  }
}
