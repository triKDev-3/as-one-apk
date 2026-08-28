import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/custom_card.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  String _dialCode = '+228';

  // Country codes for the region
  static const _countries = [
    ('🇹🇬', '+228', 'Togo'),
    ('🇧🇯', '+229', 'Bénin'),
    ('🇨🇮', '+225', "Côte d'Ivoire"),
    ('🇸🇳', '+221', 'Sénégal'),
    ('🇨🇲', '+237', 'Cameroun'),
    ('🇬🇭', '+233', 'Ghana'),
    ('🇳🇬', '+234', 'Nigéria'),
    ('🇫🇷', '+33', 'France'),
  ];

  Future<void> _login() async {
    final localNumber = _phoneController.text.trim();
    final password = _passwordController.text;
    // Combine dial code + local number
    final phone = '$_dialCode$localNumber';

    if (localNumber.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    final success =
        await ref.read(authProvider.notifier).login(phone, password);

    if (!mounted) return;

    if (success) {
      final user = ref.read(authProvider).user!;
      _redirectByRole(user.role);
    } else {
      final error = ref.read(authProvider).error ?? 'Erreur de connexion';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _redirectByRole(String role) {
    switch (role) {
      case 'AGENT':
        context.go('/agent');
        break;
      case 'CHEF':
        context.go('/chef');
        break;
      case 'MAGASINIER':
        context.go('/magasinier');
        break;
      case 'COMPTABLE':
        context.go('/comptable');
        break;
      case 'ADMIN':
        context.go('/admin');
        break;
      default:
        context.go('/agent');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (authState.isAuthenticated && !authState.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _redirectByRole(authState.user!.role);
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          // Background Mesh with subtle geometric aura
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF1F5F9),
                  Color(0xFFE2E8F0),
                  Color(0xFFE0F2FE),
                ],
              ),
            ),
          ),
          // Glowing Ambient Orbs
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withOpacity(0.18),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.12),
              ),
            ),
          ),
          // Main Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Brand Logo with Glowing Squircle Container
                    Container(
                      width: 96,
                      height: 96,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: AppColors.glowShadow(AppColors.primary),
                      ),
                      child: SvgPicture.asset(
                        'assets/images/logo.svg',
                        placeholderBuilder: (_) => const Icon(
                          Icons.corporate_fare_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .scale(delay: 150.ms, duration: 450.ms, curve: Curves.easeOutBack),

                    const SizedBox(height: 20),

                    Text(
                      'AS ONE',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                    ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 6),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.accent.withOpacity(0.25), width: 1),
                      ),
                      child: const Text(
                        'FACILITY MANAGEMENT',
                        style: TextStyle(
                          color: AppColors.accentDark,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 36),

                    // Frosted Glass Login Card
                    CustomCard(
                      isGlassmorphic: true,
                      padding: const EdgeInsets.all(24),
                      borderRadius: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Connexion',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Entrez vos identifiants pour accéder à votre espace',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Phone field with country code selector
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                // Country code button
                                GestureDetector(
                                  onTap: () async {
                                    final selected = await showModalBottomSheet<String>(
                                      context: context,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                      ),
                                      builder: (_) => ListView(
                                        shrinkWrap: true,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        children: [
                                          const Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                            child: Text('Choisir un indicatif', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                          ),
                                          const Divider(height: 1),
                                          ..._countries.map((c) => ListTile(
                                            leading: Text(c.$1, style: const TextStyle(fontSize: 24)),
                                            title: Text(c.$3),
                                            trailing: Text(c.$2, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
                                            onTap: () => Navigator.pop(context, c.$2),
                                          )),
                                        ],
                                      ),
                                    );
                                    if (selected != null) setState(() => _dialCode = selected);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                    decoration: BoxDecoration(
                                      border: Border(right: BorderSide(color: AppColors.border)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(_countries.firstWhere((c) => c.$2 == _dialCode, orElse: () => _countries.first).$1,
                                            style: const TextStyle(fontSize: 20)),
                                        const SizedBox(width: 6),
                                        Text(_dialCode, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 14)),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.expand_more_rounded, size: 16, color: AppColors.textSecondary),
                                      ],
                                    ),
                                  ),
                                ),
                                // Number input
                                Expanded(
                                  child: TextField(
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    textInputAction: TextInputAction.next,
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                      hintText: '90 00 00 00',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscure,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _login(),
                            decoration: InputDecoration(
                              labelText: 'Mot de passe',
                              prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.8),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          // Custom Gradient Elevated Action Button
                          Container(
                            height: 54,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: AppColors.glowShadow(AppColors.primary),
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: authState.isLoading ? null : _login,
                              child: authState.isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Se connecter',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 450.ms, duration: 600.ms).slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 28),

                    // Security note with Shield icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          size: 16,
                          color: AppColors.textSecondary.withOpacity(0.7),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Espace sécurisé • Direction AS ONE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 700.ms),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
