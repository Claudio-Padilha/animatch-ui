import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';

class UnverifiedProfilePrompt extends StatelessWidget {
  const UnverifiedProfilePrompt({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.verified_user_outlined,
              size: 64,
              color: AppColors.muted.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 20),
            Text(
              'Perfil não verificado',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Verifique seu perfil para começar a usar o Animatch.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => context.go(AppRoutes.profile),
              icon: const Icon(Icons.person_outline_rounded),
              label: const Text('Meu Perfil'),
            ),
          ],
        ),
      ),
    );
  }
}
