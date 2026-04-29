import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/breeder_associations_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/breeder_profile.dart';
import '../providers/profile_provider.dart';

// ─── Screen ───────────────────────────────────────────────────────────────────

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch GET /breeders/:id on load and sync result into auth state so
    // profileProvider (which derives from authNotifierProvider) rebuilds with fresh data.
    ref.listen(currentBreederProvider, (_, next) {
      next.whenData(
        (b) => ref.read(authNotifierProvider.notifier).updateBreeder(b),
      );
    });

    final profile = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        actions: [
          TextButton(
            onPressed: () => context.push(AppRoutes.editProfile),
            child: Text(
              'Editar',
              style: GoogleFonts.inter(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          _HeaderCard(profile: profile),
          const SizedBox(height: 16),
          const _StatsCard(),
          const SizedBox(height: 32),
          _SignOutButton(),
        ],
      ),
    );
  }
}

// ─── Header card ─────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.profile});

  final BreederProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 44,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: profile.avatarUrl != null
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: profile.avatarUrl!,
                      width: 88,
                      height: 88,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 2),
                      errorWidget: (context, url, err) => Icon(
                        Icons.person_rounded,
                        size: 44,
                        color: AppColors.primary.withValues(alpha: 0.6),
                      ),
                    ),
                  )
                : Icon(
                    Icons.person_rounded,
                    size: 44,
                    color: AppColors.primary.withValues(alpha: 0.6),
                  ),
          ),
          const SizedBox(height: 14),

          // Name
          Text(profile.name, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),

          // Farm
          if (profile.farmName.isNotEmpty) ...[
            Text(
              profile.farmName,
              style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 2),
          ],

          // Email
          if (profile.email.isNotEmpty)
            Text(
              profile.email,
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
            ),
          const SizedBox(height: 2),

          const SizedBox(height: 16),

          // Verified badge or verification CTA
          if (profile.isActive)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Criador Verificado',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  if (profile.location.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on_outlined, size: 13, color: AppColors.muted),
                        const SizedBox(width: 3),
                        Text(profile.location, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ],
                  if (profile.associations.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    BreederAssociationsList(associations: profile.associations),
                  ],
                ],
              ),
            )
          else
            _VerificationCta(),
        ],
      ),
    );
  }
}

// ─── Stats card ───────────────────────────────────────────────────────────────

class _StatsCard extends ConsumerWidget {
  const _StatsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final stats = ref.watch(breederStatisticsProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Estatísticas', style: theme.textTheme.titleSmall),
          const SizedBox(height: 16),
          stats.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, _) => const Text('Não foi possível carregar estatísticas.'),
            data: (s) => Column(
              children: [
                _StatRow(
                  icon: const Icon(Icons.assignment_ind_outlined, size: 20),
                  label: 'Animais ativos',
                  value: '${s.activeAnimals}',
                ),
                const Divider(height: 24),
                _StatRow(
                  icon: Icon(Icons.favorite_rounded, size: 18, color: AppColors.primary),
                  label: 'Matches confirmados',
                  value: '${s.breederMatches}',
                ),
                const Divider(height: 24),
                _StatRow(
                  icon: Icon(Icons.thumb_up_rounded, size: 18, color: AppColors.primary),
                  label: 'Curtidas recebidas',
                  value: '${s.likes}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final Widget icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        icon,
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}

// ─── Verification CTA ────────────────────────────────────────────────────────

class _VerificationCta extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => context.push(AppRoutes.profileVerification),
      icon: const Icon(Icons.shield_outlined, size: 18),
      label: const Text('Verificar perfil de criador'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ─── Sign out button ──────────────────────────────────────────────────────────

class _SignOutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () => _confirmSignOut(context),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.error,
        side: const BorderSide(color: AppColors.error),
        minimumSize: const Size.fromHeight(52),
      ),
      child: const Text('Sair da conta'),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da conta'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go(AppRoutes.login);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}
