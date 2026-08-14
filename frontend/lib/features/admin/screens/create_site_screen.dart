import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/network/api_client.dart';

class CreateSiteScreen extends ConsumerStatefulWidget {
  const CreateSiteScreen({super.key});

  @override
  ConsumerState<CreateSiteScreen> createState() => _CreateSiteScreenState();
}

class _CreateSiteScreenState extends ConsumerState<CreateSiteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _exceptionalCtrl = TextEditingController();
  final _bonusCtrl = TextEditingController();
  String _type = 'CHANTIER';
  bool _loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      final data = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'type': _type,
        if (_addressCtrl.text.trim().isNotEmpty)
          'address': _addressCtrl.text.trim(),
        if (_rateCtrl.text.isNotEmpty)
          'dailyRate': double.tryParse(_rateCtrl.text),
        if (_exceptionalCtrl.text.isNotEmpty)
          'exceptionalRate': double.tryParse(_exceptionalCtrl.text),
        if (_bonusCtrl.text.isNotEmpty)
          'bonusAmount': double.tryParse(_bonusCtrl.text),
      };
      await api.dio.post('/sites', data: data);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Site créé'),
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
        title: const Text('Nouveau site'),
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
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nom du site'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Obligatoire' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(value: 'CHANTIER', child: Text('Chantier')),
                DropdownMenuItem(
                  value: 'PERMANENCE',
                  child: Text('Site de permanence'),
                ),
              ],
              onChanged: (v) => setState(() => _type = v ?? 'CHANTIER'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressCtrl,
              decoration: const InputDecoration(labelText: 'Adresse'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _rateCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Tarif journalier (FCFA)',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _exceptionalCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Tarif exceptionnel (FCFA)',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bonusCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Bonus (FCFA)',
              ),
            ),
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
                  : const Text('Enregistrer le site'),
            ),
          ],
        ),
      ),
    );
  }
}
