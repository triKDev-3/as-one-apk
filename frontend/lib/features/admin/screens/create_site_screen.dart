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
  final _dailyRateCtrl = TextEditingController();
  final _nightRateCtrl = TextEditingController(text: '4500');
  final _sundayRateCtrl = TextEditingController(text: '5000');
  final _bonusCtrl = TextEditingController();
  final _monthlyCtrl = TextEditingController();
  final _fixedAmountCtrl = TextEditingController();
  String _type = 'CHANTIER';
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _dailyRateCtrl.dispose();
    _nightRateCtrl.dispose();
    _sundayRateCtrl.dispose();
    _bonusCtrl.dispose();
    _monthlyCtrl.dispose();
    _fixedAmountCtrl.dispose();
    super.dispose();
  }

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
        if (_dailyRateCtrl.text.isNotEmpty)
          'dailyRate': double.tryParse(_dailyRateCtrl.text),
        // Night & Sunday rates always sent
        if (_nightRateCtrl.text.isNotEmpty)
          'nightRate': double.tryParse(_nightRateCtrl.text),
        if (_sundayRateCtrl.text.isNotEmpty)
          'sundayRate': double.tryParse(_sundayRateCtrl.text),
        // Type-specific fields
        if (_type == 'CHANTIER' && _bonusCtrl.text.isNotEmpty)
          'bonusAmount': double.tryParse(_bonusCtrl.text),
        if (_type == 'CHANTIER' && _fixedAmountCtrl.text.isNotEmpty)
          'fixedAmount': double.tryParse(_fixedAmountCtrl.text),
        if (_type == 'PERMANENCE' && _monthlyCtrl.text.isNotEmpty)
          'monthlySalary': double.tryParse(_monthlyCtrl.text),
      };
      await api.dio.post('/sites', data: data);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Site créé avec succès'),
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

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool isNumber = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(labelText: label, hintText: hint),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isChantier = _type == 'CHANTIER';
    final isPermanence = _type == 'PERMANENCE';
    final isRoutine = _type == 'ROUTINE';

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
            // ── Informations générales ──
            _sectionTitle('Informations générales'),
            const SizedBox(height: 8),
            _field(
              controller: _nameCtrl,
              label: 'Nom du site',
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Obligatoire' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Type de site'),
              items: const [
                DropdownMenuItem(value: 'CHANTIER', child: Text('Chantier')),
                DropdownMenuItem(
                  value: 'PERMANENCE',
                  child: Text('Site permanent'),
                ),
                DropdownMenuItem(
                  value: 'ROUTINE',
                  child: Text('Routine (hebdomadaire)'),
                ),
              ],
              onChanged: (v) => setState(() => _type = v ?? 'CHANTIER'),
            ),
            const SizedBox(height: 12),
            _field(controller: _addressCtrl, label: 'Adresse'),

            // ── Tarification ──
            const SizedBox(height: 20),
            _sectionTitle('Tarification'),
            const SizedBox(height: 8),

            // Tarif journalier — visible pour tous les types
            _field(
              controller: _dailyRateCtrl,
              label: 'Tarif journalier (FCFA)',
              isNumber: true,
            ),
            const SizedBox(height: 12),

            // Tarif nuit & dimanche — visibles pour tous
            _field(
              controller: _nightRateCtrl,
              label: 'Tarif de nuit (FCFA)',
              hint: 'Par défaut : 4 500',
              isNumber: true,
            ),
            const SizedBox(height: 12),
            _field(
              controller: _sundayRateCtrl,
              label: 'Tarif dimanche (FCFA)',
              hint: 'Par défaut : 5 000',
              isNumber: true,
            ),

            // PERMANENCE — Salaire mensuel
            if (isPermanence) ...[
              const SizedBox(height: 12),
              _field(
                controller: _monthlyCtrl,
                label: 'Salaire mensuel (FCFA)',
                isNumber: true,
              ),
            ],

            // CHANTIER — Bonus + Montant fixe (forfait)
            if (isChantier) ...[
              const SizedBox(height: 12),
              _field(
                controller: _bonusCtrl,
                label: 'Bonus (FCFA)',
                isNumber: true,
              ),
              const SizedBox(height: 12),
              _field(
                controller: _fixedAmountCtrl,
                label: 'Montant fixe / Forfait (FCFA)',
                hint: 'Optionnel — si montant forfaitaire défini',
                isNumber: true,
              ),
            ],

            // ROUTINE — Aucun champ supplémentaire
            if (isRoutine) ...[
              const SizedBox(height: 8),
              const Text(
                'Les sites de routine sont pointés simplement, sans bonus ni exception.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
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
                  : const Text('Enregistrer le site'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: AppColors.accent,
      ),
    );
  }
}
