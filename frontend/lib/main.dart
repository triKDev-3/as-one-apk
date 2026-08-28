import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/widgets/realtime_listener.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');
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
      ),
    );
  }
}
