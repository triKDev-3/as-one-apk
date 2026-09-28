import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/network/api_client.dart';
import '../../chef/repositories/sites_repository.dart';

class CreateSiteScreen extends ConsumerStatefulWidget {
  final SiteModel? site;

  const CreateSiteScreen({super.key, this.site});

  @override
  ConsumerState<CreateSiteScreen> createState() => _CreateSiteScreenState();
}

class _CreateSiteScreenState extends ConsumerState<CreateSiteScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _dailyRateCtrl;
  late final TextEditingController _nightRateCtrl;
  late final TextEditingController _sundayRateCtrl;
  late final TextEditingController _bonusCtrl;
  late final TextEditingController _monthlyCtrl;
  late final TextEditingController _fixedAmountCtrl;
  late String _type;
  bool _loading = false;

  bool get isEdit => widget.site != null;

  @override
  void initState() {
    super.initState();
    final s = widget.site;
    _nameCtrl = TextEditingController(text: s?.name ?? '');
    _addressCtrl = TextEditingController(text: s?.address ?? '');
    _dailyRateCtrl = TextEditingController(
      text: s?.dailyRate != null ? s!.dailyRate!.toStringAsFixed(0) : '',
    );
    _nightRateCtrl = TextEditingController(
      text: s?.nightRate != null ? s!.nightRate!.toStringAsFixed(0) : '4500',
    );
    _sundayRateCtrl = TextEditingController(
      text: s?.sundayRate != null ? s!.sundayRate!.toStringAsFixed(0) : '5000',
    );
    _bonusCtrl = TextEditingController(
      text: s?.bonusAmount != null ? s!.bonusAmount!.toStringAsFixed(0) : '',
    );
    _monthlyCtrl = TextEditingController(
      text:
          s?.monthlySalary != null ? s!.monthlySalary!.toStringAsFixed(0) : '',
    );
    _fixedAmountCtrl = TextEditingController(
      text: s?.fixedAmount != null ? s!.fixedAmount!.toStringAsFixed(0) : '',
    );
    _type = s?.type ?? 'CHANTIER';
  }

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
      final repo = ref.read(sitesRepositoryProvider);
      final data = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'type': _type,
        if (_addressCtrl.text.trim().isNotEmpty)
          'address': _addressCtrl.text.trim()
        else if (isEdit)
          'address': null,
        if (_dailyRateCtrl.text.isNotEmpty)
          'dailyRate': double.tryParse(_dailyRateCtrl.text),
        if (_nightRateCtrl.text.isNotEmpty)
          'nightRate': double.tryParse(_nightRateCtrl.text),
        if (_sundayRateCtrl.text.isNotEmpty)
          'sundayRate': double.tryParse(_sundayRateCtrl.text),
        if (_type == 'CHANTIER' && _bonusCtrl.text.isNotEmpty)
          'bonusAmount': double.tryParse(_bonusCtrl.text),
        if (_type == 'CHANTIER' && _fixedAmountCtrl.text.isNotEmpty)
          'fixedAmount': double.tryParse(_fixedAmountCtrl.text),
        if (_type == 'PERMANENCE' && _monthlyCtrl.text.isNotEmpty)
          'monthlySalary': double.tryParse(_monthlyCtrl.text),
      };

      if (isEdit) {
        await repo.updateSite(widget.site!.id, data);
      } else {
        await repo.createSite(data);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEdit ? 'Site mis à jour' : 'Site créé avec succès'),
          backgroundColor: AppColors.accent,
        ),
      );
      context.pop(true);
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiClient.extractError(e)),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
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
        title: Text(isEdit ? 'Modifier le site' : 'Nouveau site'),
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
            const SizedBox(height: 20),
            _sectionTitle('Tarification'),
            const SizedBox(height: 8),
            _field(
              controller: _dailyRateCtrl,
              label: 'Tarif journalier (FCFA)',
              isNumber: true,
            ),
            const SizedBox(height: 12),
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
            if (isPermanence) ...[
              const SizedBox(height: 12),
              _field(
                controller: _monthlyCtrl,
                label: 'Salaire mensuel (FCFA)',
                isNumber: true,
              ),
            ],
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
                  : Text(isEdit ? 'Enregistrer les modifications' : 'Enregistrer le site'),
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
