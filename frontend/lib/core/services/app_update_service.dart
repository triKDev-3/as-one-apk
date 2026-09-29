import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../network/api_client.dart';
import '../theme/app_colors.dart';

class AppVersionInfo {
  final String version;
  final int build;
  final int minBuild;
  final String apkUrl;
  final bool forceUpdate;
  final String notes;

  const AppVersionInfo({
    required this.version,
    required this.build,
    required this.minBuild,
    required this.apkUrl,
    required this.forceUpdate,
    required this.notes,
  });

  factory AppVersionInfo.fromJson(Map<String, dynamic> j) => AppVersionInfo(
        version: j['version'] as String? ?? '0.0.0',
        build: (j['build'] as num?)?.toInt() ?? 0,
        minBuild: (j['minBuild'] as num?)?.toInt() ?? 1,
        apkUrl: j['apkUrl'] as String? ?? '',
        forceUpdate: j['forceUpdate'] as bool? ?? false,
        notes: j['notes'] as String? ?? '',
      );
}

/// Vérifie la version distante et propose le téléchargement de l'APK.
class AppUpdateService {
  AppUpdateService._();
  static final instance = AppUpdateService._();

  bool _alreadyChecked = false;

  Future<void> checkAndPrompt(BuildContext context) async {
    if (_alreadyChecked || !context.mounted) return;
    _alreadyChecked = true;

    try {
      final info = await PackageInfo.fromPlatform();
      final localBuild = int.tryParse(info.buildNumber) ?? 0;

      final dio = Dio(
        BaseOptions(
          baseUrl: ApiClient.baseUrl,
          connectTimeout: const Duration(seconds: 12),
          receiveTimeout: const Duration(seconds: 12),
        ),
      );
      final res = await dio.get('/app/version');
      final remote = AppVersionInfo.fromJson(
        Map<String, dynamic>.from(res.data as Map),
      );

      final needsUpdate = remote.build > localBuild;
      final forced =
          remote.forceUpdate || localBuild < remote.minBuild;

      if (!needsUpdate || !context.mounted) return;
      if (remote.apkUrl.isEmpty) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: !forced,
        builder: (ctx) => AlertDialog(
          title: const Text('Mise à jour disponible'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Version ${remote.version} (build ${remote.build})',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                remote.notes.isNotEmpty
                    ? remote.notes
                    : 'Une nouvelle version de AS ONE est prête.',
              ),
              const SizedBox(height: 8),
              Text(
                'Installée : ${info.version} (${info.buildNumber})',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          actions: [
            if (!forced)
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Plus tard'),
              ),
            ElevatedButton.icon(
              onPressed: () async {
                final uri = Uri.parse(remote.apkUrl);
                await launchUrl(uri, mode: LaunchMode.externalApplication);
                if (!forced && ctx.mounted) Navigator.pop(ctx);
              },
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('Télécharger'),
            ),
          ],
        ),
      );
    } catch (_) {
      // Silencieux : pas de réseau / API en pause → on n'bloque pas l'app
    }
  }
}
