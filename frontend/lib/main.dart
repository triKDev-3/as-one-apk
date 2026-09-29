import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/widgets/realtime_listener.dart';
import 'core/services/local_notification_service.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/app_update_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');
  await LocalNotificationService.instance.init();
  await PushNotificationService.instance.init();
  runApp(const ProviderScope(child: AsOneApp()));
}

class AsOneApp extends StatelessWidget {
  const AsOneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RealtimeListener(
      child: MaterialApp.router(
        title: 'AS ONE',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: AppRouter.router,
        builder: (context, child) {
          return _UpdateGate(child: child ?? const SizedBox.shrink());
        },
      ),
    );
  }
}

/// Lance le check version une fois le routeur prêt.
class _UpdateGate extends StatefulWidget {
  final Widget child;
  const _UpdateGate({required this.child});

  @override
  State<_UpdateGate> createState() => _UpdateGateState();
}

class _UpdateGateState extends State<_UpdateGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          AppUpdateService.instance.checkAndPrompt(context);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
