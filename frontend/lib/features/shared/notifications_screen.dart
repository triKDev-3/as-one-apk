import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/providers.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/notification_navigation.dart';
import 'package:dio/dio.dart';

final notificationsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final res = await api.dio.get('/notifications');
    final list = res.data as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  } on DioException catch (e) {
    throw ApiClient.extractError(e);
  }
});

final unreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final res = await api.dio.get('/notifications/unread-count');
    return (res.data['count'] as num?)?.toInt() ?? 0;
  } on DioException catch (e) {
    throw ApiClient.extractError(e);
  }
});

/// Pattern AS ONE : une page = liste + actions (tout lire / marquer lu).
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _markRead(WidgetRef ref, String id) async {
    final api = ref.read(apiClientProvider);
    await api.dio.patch('/notifications/$id/read');
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadCountProvider);
  }

  Future<void> _markAll(WidgetRef ref, BuildContext context) async {
    final api = ref.read(apiClientProvider);
    await api.dio.patch('/notifications/read-all');
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadCountProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Toutes les notifications sont lues'),
          backgroundColor: AppColors.accent,
        ),
      );
    }
  }

  IconData _iconFor(String type) {
    if (type.contains('assignment')) return Icons.assignment_ind_rounded;
    if (type.contains('transfer')) return Icons.swap_horiz_rounded;
    if (type.contains('pointage')) return Icons.fingerprint_rounded;
    if (type.contains('incident') || type.contains('penalty')) {
      return Icons.warning_amber_rounded;
    }
    if (type.contains('payroll') || type.contains('paie')) {
      return Icons.payments_rounded;
    }
    if (type.contains('site')) return Icons.location_on_rounded;
    return Icons.notifications_rounded;
  }

  Map<String, dynamic>? _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  void _open(BuildContext context, WidgetRef ref, Map<String, dynamic> n) {
    final type = n['type'] as String? ?? '';
    final data = _asMap(n['data']);
    final role = ref.read(authProvider).user?.role ?? 'AGENT';
    NotificationNavigation.open(
      context,
      type: type,
      role: role,
      data: data,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => _markAll(ref, context),
            child: const Text(
              'Tout lire',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(e.toString()),
              ElevatedButton(
                onPressed: () => ref.invalidate(notificationsProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none_rounded,
                      size: 48, color: AppColors.textTertiary),
                  SizedBox(height: 12),
                  Text('Aucune notification',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(notificationsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final n = items[i];
                final id = n['id'] as String? ?? '';
                final title = n['title'] as String? ?? 'Notification';
                final body = n['body'] as String? ?? '';
                final type = n['type'] as String? ?? '';
                final readAt = n['readAt'];
                final isUnread = readAt == null;
                final created =
                    DateTime.tryParse(n['createdAt'] as String? ?? '') ??
                        DateTime.now();

                return Material(
                  color: isUnread
                      ? AppColors.primary.withValues(alpha: 0.06)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      if (isUnread && id.isNotEmpty) {
                        _markRead(ref, id);
                      }
                      _open(context, ref, n);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isUnread
                              ? AppColors.primary.withValues(alpha: 0.25)
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(_iconFor(type),
                                color: AppColors.primary, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: TextStyle(
                                          fontWeight: isUnread
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    if (isUnread)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  body,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  DateFormat('dd/MM/yyyy HH:mm').format(created),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right,
                              color: AppColors.textTertiary, size: 20),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
