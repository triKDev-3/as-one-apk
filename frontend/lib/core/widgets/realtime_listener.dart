import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../network/realtime_service.dart';
import '../theme/app_colors.dart';
import '../../features/agent/agent_home_screen.dart';

/// Écoute les événements Socket.io et affiche des SnackBars.
/// À placer sous le MaterialApp (ou dans chaque écran principal).
class RealtimeListener extends ConsumerStatefulWidget {
  final Widget child;

  const RealtimeListener({super.key, required this.child});

  @override
  ConsumerState<RealtimeListener> createState() => _RealtimeListenerState();
}

class _RealtimeListenerState extends ConsumerState<RealtimeListener> {
  StreamSubscription<RealtimeEvent>? _sub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _listen());
  }

  void _listen() {
    final service = ref.read(realtimeServiceProvider);
    _sub?.cancel();
    _sub = service.events.listen((event) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) return;

      switch (event.type) {
        case 'assignment:new':
          final site = event.data['site'] as Map?;
          final name = site?['name'] ?? 'un site';
          messenger.showSnackBar(
            SnackBar(
              content: Text('Nouvelle affectation : $name — confirmez avant 22h'),
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Voir',
                textColor: Colors.white,
                onPressed: () {
                  ref.invalidate(agentDashboardProvider);
                },
              ),
            ),
          );
          ref.invalidate(agentDashboardProvider);
          break;
        case 'assignment:response':
          final accepted = event.data['accepted'] == true;
          final agentName = event.data['agentName'] ?? 'Un agent';
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                accepted
                    ? '$agentName a confirmé l\'affectation'
                    : '$agentName a refusé l\'affectation',
              ),
              backgroundColor: accepted ? AppColors.accent : AppColors.danger,
            ),
          );
          break;
        case 'pointage:done':
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Votre pointage a été enregistré'),
              backgroundColor: AppColors.accent,
            ),
          );
          break;
        case 'incident:new':
          final msg = event.data['message'] ?? 'Nouvel incident signalé';
          messenger.showSnackBar(
            SnackBar(
              content: Text(msg.toString()),
              backgroundColor: AppColors.danger,
              duration: const Duration(seconds: 5),
            ),
          );
          break;
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
