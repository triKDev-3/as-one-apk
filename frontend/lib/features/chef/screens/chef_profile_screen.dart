import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/network/api_client.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ChefProfileScreen extends ConsumerStatefulWidget {
  const ChefProfileScreen({super.key});

  @override
  ConsumerState<ChefProfileScreen> createState() => _ChefProfileScreenState();
}

class _ChefProfileScreenState extends ConsumerState<ChefProfileScreen> {
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  bool _saving = false;
  bool _changingPass = false;
  bool _pairing = false;
  String? _pairingCode;

  bool _filled = false;
  String _originalPhone = '';
  
  bool _waConnected = false;
  Timer? _statusTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_filled) {
      final u = ref.read(authProvider).user;
      if (u != null) {
        _firstCtrl.text = u.firstName;
        _lastCtrl.text = u.lastName;
        _phoneCtrl.text = u.phone;
        _originalPhone = u.phone;
      }
      _filled = true;
      _checkWhatsappStatus();
    }
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkWhatsappStatus() async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.dio.get('/whatsapp/status');
      if (mounted) {
        setState(() {
          _waConnected = res.data['connected'] ?? false;
          if (_waConnected) {
            _pairingCode = null;
            _statusTimer?.cancel();
          }
        });
      }
    } catch (_) {}
  }

  void _startStatusPolling() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      _checkWhatsappStatus();
    });
  }

  Future<void> _saveProfile() async {
    final newPhone = _phoneCtrl.text.trim();
    if (newPhone != _originalPhone && _waConnected) {
      // Disconnect WhatsApp if phone changes
      try {
        final api = ref.read(apiClientProvider);
        await api.dio.post('/whatsapp/disconnect');
        setState(() => _waConnected = false);
      } catch (_) {}
    }

    setState(() => _saving = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.dio.patch('/users/me/profile', data: {
        'firstName': _firstCtrl.text.trim(),
        'lastName': _lastCtrl.text.trim(),
        'phone': newPhone,
      });
      _originalPhone = newPhone;
      // Optionally update local user state if needed
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
            content: Text('Mot de passe modifié avec succès'),
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

  Future<void> _pairWhatsapp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez renseigner votre numéro de téléphone d\'abord')),
      );
      return;
    }

    setState(() {
      _pairing = true;
      _pairingCode = null;
    });

    try {
      final api = ref.read(apiClientProvider);
      final res = await api.dio.post('/whatsapp/pair', data: {'phone': phone});
      final code = res.data['code'];
      if (mounted) {
        setState(() => _pairingCode = code);
        _startStatusPolling();
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
      if (mounted) setState(() => _pairing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mon Profil Chef'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── WhatsApp Section ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF25D366).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF25D366).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.wechat_rounded, color: Color(0xFF25D366)),
                    const SizedBox(width: 8),
                    const Text(
                      'Connexion WhatsApp',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1DA851),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Associez votre propre numéro WhatsApp pour envoyer les convocations aux agents.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                if (_waConnected) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.check_circle_rounded, color: Color(0xFF25D366)),
                        SizedBox(width: 8),
                        Text('WhatsApp connecté', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1DA851))),
                      ],
                    ),
                  ).animate().fadeIn(),
                  const SizedBox(height: 8),
                  const Text('Si vous changez de numéro ci-dessous, WhatsApp sera automatiquement déconnecté.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ] else if (_pairingCode != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Code de couplage (valable 60s)',
                          style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _pairingCode!,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _pairingCode!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Code copié !')),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          label: const Text('Copier le code'),
                        ),
                        const SizedBox(height: 8),
                        const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                        const SizedBox(height: 8),
                        const Text('En attente de connexion...', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ).animate().fadeIn().scale(),
                  const SizedBox(height: 12),
                  const Text(
                    'Sur votre téléphone : WhatsApp > Appareils liés > Lier un appareil > Lier avec un numéro de téléphone.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                  ),
                ] else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _pairing ? null : _pairWhatsapp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                      ),
                      icon: _pairing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.link_rounded),
                      label: const Text('Générer un code WhatsApp'),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          Text('Informations personnelles', style: Theme.of(context).textTheme.titleLarge),
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
                : const Text('Enregistrer les infos'),
          ),

          const SizedBox(height: 32),
          Text('Sécurité', style: Theme.of(context).textTheme.titleLarge),
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
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
