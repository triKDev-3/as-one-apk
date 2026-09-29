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

class AsOneApp extends StatefulWidget {
  const AsOneApp({super.key});

  @override
  State<AsOneApp> createState() => _AsOneAppState();
}

class _AsOneAppState extends State<AsOneApp> {
  final _navKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // Après le 1er frame : check version distante
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 2), () {
        final ctx = _navKey.currentContext;
        if (ctx != null) {
          AppUpdateService.instance.checkAndPrompt(ctx);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return RealtimeListener(
      child: MaterialApp.router(
        title: 'AS ONE',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: AppRouter.router,
        builder: (context, child) {
          // Injecte une clé navigateur pour le dialogue de mise à jour
          return Navigator(
            key: _navKey,
            onGenerateRoute: (_) => MaterialPageRoute(
              builder: (_) => child ?? const SizedBox.shrink(),
            ),
          );
        },
      ),
    );
  }
}
