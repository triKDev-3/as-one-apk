import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notification_providers.dart';

class RealtimeListener extends ConsumerStatefulWidget {
  final Widget child;

  const RealtimeListener({required this.child, Key? key}) : super(key: key);

  @override
  ConsumerState<RealtimeListener> createState() => _RealtimeListenerState();
}

class _RealtimeListenerState extends ConsumerState<RealtimeListener> {
  @override
  void initState() {
    super.initState();
    _initializeRealtime();
  }

  Future<void> _initializeRealtime() async {
    // Load pending notifications from backend queue on app start
    await ref.read(pendingNotificationsProvider.future);
    
    // Set up periodic sync in case of connection drops
    Future.delayed(Duration(seconds: 30), () {
      if (mounted) {
        ref.invalidate(unreadNotificationsProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch sync status
    ref.watch(notificationSyncStatusProvider);
    
    return widget.child;
  }
}
