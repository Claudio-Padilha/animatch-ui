import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/animatch_logo.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  bool _isLoading = false;

  Future<void> _signUp() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authNotifierProvider.notifier).signUp();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[SignUp] ERROR: $e\n$st');
      }
      if (!mounted) return;
      final cancelled = e.toString().contains('UserCancelled') ||
          e.toString().contains('user_cancelled');
      if (!cancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível criar a conta. Tente novamente.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(28, 8, 28, 24 + bottomInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AnimatchLogo(),
            const SizedBox(height: 32),
            Text('Criar sua conta', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Acesse a maior rede de genética de elite do Brasil.',
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _isLoading ? null : _signUp,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Criar conta'),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Já tem uma conta? ',
                  style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                ),
                GestureDetector(
                  onTap: _isLoading ? null : () => context.go(AppRoutes.login),
                  child: Text(
                    'Entrar',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
