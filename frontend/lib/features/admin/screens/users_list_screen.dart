import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/network/api_client.dart';

final usersListProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final response = await api.dio.get('/users');
    return response.data as List<dynamic>;
  } on DioException catch (e) {
    throw ApiClient.extractError(e);
  }
});

class UsersListScreen extends ConsumerWidget {
  const UsersListScreen({super.key});

  Future<void> _toggleActive(
    WidgetRef ref,
    BuildContext context,
    String id,
    bool currentlyActive,
  ) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.dio.patch('/users/$id/active', data: {
        'isActive': !currentlyActive,
      });
      ref.invalidate(usersListProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentlyActive ? 'Compte suspendu' : 'Compte réactivé',
            ),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    } on DioException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.extractError(e)),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _updateRole(
    WidgetRef ref,
    BuildContext context,
    String id,
    String newRole,
  ) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.dio.patch('/users/$id/role', data: {
        'role': newRole,
      });
      ref.invalidate(usersListProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rôle mis à jour: $newRole'),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    } on DioException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.extractError(e)),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _resetPassword(
    WidgetRef ref,
    BuildContext context,
    String id,
  ) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.dio.patch('/users/$id/reset-password');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mot de passe réinitialisé avec succès'),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    } on DioException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.extractError(e)),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Utilisateurs'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => context.push('/admin/users/create'),
          ),
        ],
      ),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (users) {
          if (users.isEmpty) {
            return const Center(child: Text('Aucun utilisateur'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(usersListProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: users.length,
              itemBuilder: (context, i) {
                final u = users[i] as Map<String, dynamic>;
                final name =
                    '${u['firstName'] ?? ''} ${u['lastName'] ?? ''}'.trim();
                final role = u['role'] as String? ?? '';
                final active = u['isActive'] as bool? ?? true;
                final phone = u['phone'] as String? ?? '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: active ? AppColors.border : AppColors.danger.withOpacity(0.4),
                    ),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: active
                          ? AppColors.primary.withOpacity(0.12)
                          : AppColors.danger.withOpacity(0.12),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: active ? AppColors.primary : AppColors.danger,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        decoration:
                            active ? null : TextDecoration.lineThrough,
                      ),
                    ),
                    subtitle: Text('$role · $phone'),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        if (value == 'toggle') {
                          _toggleActive(ref, context, u['id'] as String, active);
                        } else if (value == 'reset_password') {
                          _resetPassword(ref, context, u['id'] as String);
                        } else if (value == 'AGENT' || value == 'CHEF') {
                          _updateRole(ref, context, u['id'] as String, value);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'toggle',
                          child: Row(
                            children: [
                              Icon(
                                active ? Icons.block : Icons.check_circle,
                                color: active ? AppColors.danger : AppColors.accent,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(active ? 'Désactiver' : 'Activer'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'reset_password',
                          child: Row(
                            children: [
                              Icon(Icons.lock_reset, size: 20),
                              SizedBox(width: 12),
                              Text('Réinitialiser MDP'),
                            ],
                          ),
                        ),
                        if (role != 'ADMIN' && role != 'AGENT')
                          const PopupMenuItem(
                            value: 'AGENT',
                            child: Row(
                              children: [
                                Icon(Icons.person_outline, size: 20),
                                SizedBox(width: 12),
                                Text('Rétrograder (Agent)'),
                              ],
                            ),
                          ),
                        if (role != 'ADMIN' && role != 'CHEF')
                          const PopupMenuItem(
                            value: 'CHEF',
                            child: Row(
                              children: [
                                Icon(Icons.star_outline, size: 20),
                                SizedBox(width: 12),
                                Text('Promouvoir (Chef)'),
                              ],
                            ),
                          ),
                      ],
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
