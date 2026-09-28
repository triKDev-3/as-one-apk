import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/asone_loader.dart';
import '../../core/widgets/pointage_photo.dart';
import '../../core/utils/whatsapp_helper.dart';

final pointagesLogProvider =
    FutureProvider.autoDispose.family<List<dynamic>, String?>((ref, date) {
  return ref.watch(pointageRepositoryProvider).list(date: date);
});

class PointagesLogScreen extends ConsumerWidget {
  final String? date;

  const PointagesLogScreen({super.key, this.date});

  String _label(String type) {
    switch (type) {
      case 'DEPART':
        return 'Présent';
      case 'ABSENT':
        return 'Absent';
      case 'PRESENCE_PERMANENCE':
        return 'Présence';
      case 'ARRIVEE':
        return 'Arrivée';
      default:
        return type;
    }
  }

  Color _color(String type) {
    switch (type) {
      case 'DEPART':
        return AppColors.accent;
      case 'ABSENT':
        return AppColors.danger;
      default:
        return AppColors.primary;
    }
  }

  Future<void> _share(BuildContext context, List<dynamic> rows) async {
    final dateLabel = date == null
        ? 'Tous les pointages'
        : DateFormat('dd/MM/yyyy').format(DateTime.parse(date!));
    final maps =
        rows.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final text = WhatsAppHelper.dailyPointagesReport(
      dateLabel: dateLabel,
      rows: maps,
    );

    final action = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Exporter le rapport',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.chat, color: Color(0xFF25D366)),
              title: const Text('WhatsApp (texte)'),
              onTap: () => Navigator.pop(ctx, 'wa'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Partager texte + photos'),
              subtitle: const Text('Ouvre le menu de partage système'),
              onTap: () => Navigator.pop(ctx, 'photos'),
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('Copier le texte'),
              onTap: () => Navigator.pop(ctx, 'copy'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (action == 'wa') {
      await WhatsAppHelper.openWhatsApp(message: text);
    } else if (action == 'copy') {
      await WhatsAppHelper.copyMessage(text);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rapport copié')),
        );
      }
    } else if (action == 'photos') {
      await _shareWithPhotos(context, text, maps);
    }
  }

  Future<void> _shareWithPhotos(
    BuildContext context,
    String text,
    List<Map<String, dynamic>> maps,
  ) async {
    try {
      final dir = await getTemporaryDirectory();
      final files = <XFile>[];
      var i = 0;
      for (final p in maps) {
        final url = p['photoUrl'] as String?;
        if (url == null || url.isEmpty) continue;
        if (url.startsWith('data:image')) {
          final b64 = url.split(',').last;
          final bytes = base64Decode(b64);
          final path = '${dir.path}/pointage_${i++}.jpg';
          final f = File(path);
          await f.writeAsBytes(bytes);
          files.add(XFile(path));
        } else if (url.startsWith('http')) {
          // Lien distant : on laisse le texte mentionner
        }
      }

      if (files.isEmpty) {
        await WhatsAppHelper.openWhatsApp(message: text);
        return;
      }

      await Share.shareXFiles(
        files,
        text: text,
        subject: 'Rapport pointages AS ONE',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Partage photos : $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(pointagesLogProvider(date));
    final title = date == null
        ? 'Historique des pointages'
        : 'Pointages du ${DateFormat('dd/MM/yyyy').format(DateTime.parse(date!))}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          async.maybeWhen(
            data: (rows) => rows.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.ios_share_rounded),
                    tooltip: 'Exporter / WhatsApp',
                    onPressed: () => _share(context, rows),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: async.when(
        loading: () => const AsOneLoader(message: 'Chargement des pointages…'),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(e.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(pointagesLogProvider(date)),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (rows) {
          if (rows.isEmpty) {
            return Center(
              child: Text(
                date == null
                    ? 'Aucun pointage enregistré'
                    : 'Aucun pointage pour cette journée',
              ),
            );
          }

          final Map<String, List<Map<String, dynamic>>> bySite = {};
          for (final raw in rows) {
            final p = Map<String, dynamic>.from(raw as Map);
            final site = p['site'] as Map<String, dynamic>? ?? {};
            final siteName = site['name'] as String? ?? 'Site inconnu';
            bySite.putIfAbsent(siteName, () => []).add(p);
          }

          final siteNames = bySite.keys.toList()..sort();

          return Column(
            children: [
              Material(
                color: Colors.white,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _share(context, rows),
                          icon: const Icon(Icons.chat, size: 18),
                          label: const Text('WhatsApp'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final dateLabel = date == null
                                ? 'Tous'
                                : DateFormat('dd/MM/yyyy')
                                    .format(DateTime.parse(date!));
                            final text = WhatsAppHelper.dailyPointagesReport(
                              dateLabel: dateLabel,
                              rows: rows
                                  .map((e) =>
                                      Map<String, dynamic>.from(e as Map))
                                  .toList(),
                            );
                            await WhatsAppHelper.copyMessage(text);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Rapport copié')),
                              );
                            }
                          },
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          label: const Text('Copier'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(pointagesLogProvider(date)),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: siteNames.length,
                    itemBuilder: (_, i) {
                      final siteName = siteNames[i];
                      final list = bySite[siteName]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8, top: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '$siteName · ${list.length} pointage(s)',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...list.map((p) {
                            final agent =
                                p['agent'] as Map<String, dynamic>? ?? {};
                            final type = p['type'] as String? ?? 'DEPART';
                            final name =
                                '${agent['firstName'] ?? ''} ${agent['lastName'] ?? ''}'
                                    .trim();
                            final noted = DateTime.tryParse(
                                p['notedAt'] as String? ?? '');
                            final photoUrl = p['photoUrl'] as String?;
                            final color = _color(type);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  if (photoUrl != null &&
                                      photoUrl.isNotEmpty)
                                    GestureDetector(
                                      onTap: () => showPointagePhotoFull(
                                          context, photoUrl),
                                      child: PointagePhoto(
                                          photoUrl: photoUrl, size: 52),
                                    )
                                  else
                                    CircleAvatar(
                                      backgroundColor:
                                          color.withValues(alpha: 0.12),
                                      child: Icon(Icons.fingerprint,
                                          color: color, size: 20),
                                    ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name.isEmpty ? 'Agent' : name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700),
                                        ),
                                        if (noted != null)
                                          Text(
                                            DateFormat('dd/MM/yyyy HH:mm')
                                                .format(noted.toLocal()),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textTertiary,
                                            ),
                                          ),
                                        if (photoUrl != null &&
                                            photoUrl.isNotEmpty)
                                          const Text(
                                            '📷 Photo jointe — appuyer pour agrandir',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _label(type),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
