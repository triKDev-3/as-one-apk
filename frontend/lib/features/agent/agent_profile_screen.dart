import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/providers.dart';
import '../../core/network/api_client.dart';

class AgentProfileScreen extends ConsumerStatefulWidget {
  const AgentProfileScreen({super.key});

  @override
  ConsumerState<AgentProfileScreen> createState() => _AgentProfileScreenState();
}

class _AgentProfileScreenState extends ConsumerState<AgentProfileScreen> {
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  bool _saving = false;
  bool _changingPass = false;

  bool _filled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_filled) {
      final u = ref.read(authProvider).user;
      if (u != null) {
        _firstCtrl.text = u.firstName;
        _lastCtrl.text = u.lastName;
        _phoneCtrl.text = u.phone;
      }
      _filled = true;
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.dio.patch('/users/me/profile', data: {
        'firstName': _firstCtrl.text.trim(),
        'lastName': _lastCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour'),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.extractError(e)),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePassword() async {
    if (_newPassCtrl.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nouveau mot de passe : min. 6 caractères')),
      );
      return;
    }
    setState(() => _changingPass = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.dio.patch('/users/me/password', data: {
        'currentPassword': _currentPassCtrl.text,
        'newPassword': _newPassCtrl.text,
      });
      _currentPassCtrl.clear();
      _newPassCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mot de passe modifié'),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.extractError(e)),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _changingPass = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mon profil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Informations', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: _firstCtrl,
            decoration: const InputDecoration(labelText: 'Prénom'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _lastCtrl,
            decoration: const InputDecoration(labelText: 'Nom'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Téléphone',
              helperText: 'L’opérateur Mobile Money est détecté automatiquement',
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saving ? null : _saveProfile,
            child: _saving
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Text('Enregistrer'),
          ),
          const SizedBox(height: 32),
          Text('Mot de passe', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: _currentPassCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Mot de passe actuel'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _newPassCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Nouveau mot de passe'),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: _changingPass ? null : _changePassword,
            child: _changingPass
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Text('Changer le mot de passe'),
          ),
        ],
      ),
    );
  }
}
