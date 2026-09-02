import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../network/realtime_service.dart';
import '../theme/app_colors.dart';
import '../../features/agent/agent_home_screen.dart';

class RealtimeListener extends ConsumerStatefulWidget {
  final Widget child;

  const RealtimeListener({super.key, required this.child});

  @override
  ConsumerState<RealtimeListener> createState() => _RealtimeListenerState();
}

class _RealtimeListenerState extends ConsumerState<RealtimeListener> {
  StreamSubscription<RealtimeEvent>? _sub;
  final Set<String> _seen = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _listen());
  }

  void _show(String title, String body, Color color) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            if (body.isNotEmpty) Text(body),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _colorFor(String type) {
    if (type.contains('incident') ||
        type.contains('penalty') ||
        type.contains('refus') ||
        type.contains('suspend')) {
      return AppColors.danger;
    }
    if (type.contains('pointage') ||
        type.contains('valid') ||
        type.contains('confirm')) {
      return AppColors.accent;
    }
    return AppColors.primary;
  }

  void _listen() {
    final service = ref.read(realtimeServiceProvider);
    _sub?.cancel();
    _sub = service.events.listen((event) {
      if (!mounted) return;

      if (event.type == 'notification') {
        final id = event.data['id'] as String? ?? '';
        if (id.isNotEmpty) {
          if (_seen.contains(id)) return;
          _seen.add(id);
        }
        final title = event.data['title'] as String? ?? 'AS ONE';
        final body = event.data['body'] as String? ?? '';
        final type = event.data['type'] as String? ?? '';
        _show(title, body, _colorFor(type));
        if (type.startsWith('assignment')) {
          ref.invalidate(agentDashboardProvider);
        }
        return;
      }

      switch (event.type) {
        case 'assignment:new':
          final site = event.data['site'] as Map?;
          final name = site?['name'] ?? 'un site';
          _show('Nouvelle affectation', '$name — confirmez avant 22h',
              AppColors.primary);
          ref.invalidate(agentDashboardProvider);
          break;
        case 'assignment:response':
          final accepted = event.data['accepted'] == true;
          final agentName = event.data['agentName'] ?? 'Un agent';
          _show(
            accepted ? 'Confirmation' : 'Refus',
            accepted
                ? '$agentName a confirmé l\'affectation'
                : '$agentName a refusé l\'affectation',
            accepted ? AppColors.accent : AppColors.danger,
          );
          break;
        case 'pointage:done':
          _show(
            'Pointage',
            event.data['message']?.toString() ?? 'Pointage enregistré',
            AppColors.accent,
          );
          break;
        case 'incident:new':
          _show(
            'Incident',
            event.data['message']?.toString() ?? 'Nouvel incident',
            AppColors.danger,
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
