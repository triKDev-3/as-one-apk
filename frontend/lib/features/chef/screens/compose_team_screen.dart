import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../repositories/sites_repository.dart';

class ComposeTeamScreen extends ConsumerStatefulWidget {
  final String siteId;
  final SiteModel? site;
  const ComposeTeamScreen({super.key, required this.siteId, this.site});
  @override
  ConsumerState<ComposeTeamScreen> createState() => _ComposeTeamScreenState();
}

class _ComposeTeamScreenState extends ConsumerState<ComposeTeamScreen> {
  @override
  Widget build(BuildContext context) {
    final name = widget.site?.name ?? 'Site';
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.construction, size: 48, color: AppColors.warning),
              const SizedBox(height: 16),
              const Text(
                'Écran Composition — version temporaire.\nLes fonctions renvoyer/rappel/libérer arrivent au prochain push.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text('Site ID: ${widget.siteId}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
