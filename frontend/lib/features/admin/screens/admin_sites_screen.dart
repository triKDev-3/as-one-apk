import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/network/api_client.dart';
import '../../chef/repositories/sites_repository.dart';

final adminSitesListProvider = FutureProvider.autoDispose<List<SiteModel>>((ref) {
  return ref.watch(sitesRepositoryProvider).getSites();
});

class AdminSitesScreen extends ConsumerWidget {
  const AdminSitesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sitesAsync = ref.watch(adminSitesListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Gestion des sites'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/admin/sites/create').then((_) => ref.invalidate(adminSitesListProvider)),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: sitesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(err.toString())),
        data: (sites) {
          if (sites.isEmpty) {
            return const Center(child: Text('Aucun site.'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(adminSitesListProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sites.length,
              itemBuilder: (context, i) {
                final site = sites[i];
                return _AdminSiteTile(site: site);
              },
            ),
          );
        },
      ),
    );
  }
}

class _AdminSiteTile extends ConsumerWidget {
  final SiteModel site;
  const _AdminSiteTile({required this.site});

  Future<void> _showAssignChefDialog(BuildContext context, WidgetRef ref) async {
    final api = ref.read(apiClientProvider);
    try {
      final response = await api.dio.get('/users');
      final users = response.data as List<dynamic>;
      final chefs = users.where((u) => u['role'] == 'CHEF' && u['isActive'] == true).toList();
      
      if (!context.mounted) return;

      if (chefs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucun chef actif trouvé.'), backgroundColor: AppColors.warning),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Assigner un chef'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: chefs.length,
                itemBuilder: (context, i) {
                  final chef = chefs[i];
                  final name = '${chef['firstName'] ?? ''} ${chef['lastName'] ?? ''}'.trim();
                  return ListTile(
                    title: Text(name),
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      try {
                        await api.dio.post('/sites/${site.id}/chefs/${chef['id']}');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$name assigné au site ${site.name}'), backgroundColor: AppColors.accent),
                          );
                        }
                        ref.invalidate(adminSitesListProvider);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.danger),
                          );
                        }
                      }
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Annuler'),
              ),
            ],
          );
        }
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPermanence = site.isPermanence;
    final color = isPermanence ? AppColors.secondary : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isPermanence ? Icons.home_work_outlined : Icons.construction,
            color: color,
            size: 24,
          ),
        ),
        title: Text(
          site.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(site.address ?? site.typeLabel),
        trailing: IconButton(
          icon: const Icon(Icons.person_add, color: AppColors.primary),
          tooltip: 'Assigner un chef',
          onPressed: () => _showAssignChefDialog(context, ref),
        ),
      ),
    );
  }
}
