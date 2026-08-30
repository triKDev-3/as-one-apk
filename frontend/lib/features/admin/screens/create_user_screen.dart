import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/network/api_client.dart';

class CreateUserScreen extends ConsumerStatefulWidget {
  const CreateUserScreen({super.key});

  @override
  ConsumerState<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends ConsumerState<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  String _role = 'AGENT';
  String _agentType = 'TEMPORAIRE';
  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      final data = {
        'phone': _phoneCtrl.text.trim(),
        'firstName': _firstCtrl.text.trim(),
        'lastName': _lastCtrl.text.trim(),
        'role': _role,
        if (_role == 'AGENT') 'agentType': _agentType,
      };
      await api.dio.post('/users', data: data);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Compte créé'),
          backgroundColor: AppColors.accent,
        ),
      );
      context.pop();
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
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Créer un compte'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _firstCtrl,
              decoration: const InputDecoration(labelText: 'Prénom'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Obligatoire' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lastCtrl,
              decoration: const InputDecoration(labelText: 'Nom'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Obligatoire' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                hintText: '+22890…',
              ),
              validator: (v) =>
                  v == null || v.trim().length < 8 ? 'Invalide' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _role,
              decoration: const InputDecoration(labelText: 'Rôle'),
              items: const [
                DropdownMenuItem(value: 'AGENT', child: Text('Agent')),
                DropdownMenuItem(value: 'CHEF', child: Text('Chef')),
                DropdownMenuItem(value: 'MAGASINIER', child: Text('Magasinier')),
                DropdownMenuItem(value: 'COMPTABLE', child: Text('Comptable')),
                DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
              ],
              onChanged: (v) => setState(() => _role = v ?? 'AGENT'),
            ),
            if (_role == 'AGENT') ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _agentType,
                decoration: const InputDecoration(labelText: 'Type agent'),
                items: const [
                  DropdownMenuItem(
                    value: 'TEMPORAIRE',
                    child: Text('Temporaire'),
                  ),
                  DropdownMenuItem(
                    value: 'PERMANENT',
                    child: Text('Permanent'),
                  ),
                ],
                onChanged: (v) => setState(() => _agentType = v ?? 'TEMPORAIRE'),
              ),
            ],
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Créer le compte'),
            ),
          ],
        ),
      ),
    );
  }
}
