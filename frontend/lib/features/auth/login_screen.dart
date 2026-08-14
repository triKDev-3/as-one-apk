import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  Future<void> _login() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    if (phone.isEmpty || password.isEmpty) {
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/images/logo.svg',
                  height: 72,
                  placeholderBuilder: (_) => const Icon(
                    Icons.business,
                    size: 72,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'AS ONE',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: AppColors.primary,
                        letterSpacing: 1.2,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Facility Management',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 48),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Numéro de téléphone',
                    prefixIcon: Icon(Icons.phone_outlined),
                    hintText: 'ex: +22890123456',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _login(),
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
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
                      : const Text('Se connecter'),
                ),
                const SizedBox(height: 24),
                Text(
                  'Compte créé uniquement par la Direction',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
