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

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Re-sync the breeder on load so server-side changes (e.g. a verification
    // approval) land in auth state; profileProvider derives from it and rebuilds.
    ref.read(authNotifierProvider.notifier).refreshBreeder();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final isVerified = ref.watch(authNotifierProvider)?.verifiedBreeder ?? false;
    // Separate from `isVerified` (profile activation) above — this reflects
    // whether an admin has approved at least one association's document.
    final associationVerified =
        ref.watch(authNotifierProvider)?.associationVerified ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        actions: [
          if (isVerified)
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
          _HeaderCard(profile: profile, associationVerified: associationVerified),
          const SizedBox(height: 16),
          const _StatsCard(),
          const SizedBox(height: 32),
          _SignOutButton(),
          const SizedBox(height: 12),
          _DeleteAccountButton(),
        ],
      ),
    );
  }
}

// ─── Header card ─────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.profile, required this.associationVerified});

  final BreederProfile profile;
  final bool associationVerified;

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
                  if (associationVerified) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.workspace_premium_rounded,
                            color: AppColors.secondary, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Associação Verificada',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
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

class _SignOutButton extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SignOutButton> createState() => _SignOutButtonState();
}

class _SignOutButtonState extends ConsumerState<_SignOutButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: _isLoading ? null : () => _confirmSignOut(context),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.error,
        side: const BorderSide(color: AppColors.error),
        minimumSize: const Size.fromHeight(52),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.error),
            )
          : const Text('Sair da conta'),
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
            onPressed: () async {
              Navigator.of(ctx).pop();
              setState(() => _isLoading = true);
              await ref.read(authNotifierProvider.notifier).logout();
              if (mounted) setState(() => _isLoading = false);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}

// ─── Delete account button ─────────────────────────────────────────────────

class _DeleteAccountButton extends ConsumerStatefulWidget {
  @override
  ConsumerState<_DeleteAccountButton> createState() =>
      _DeleteAccountButtonState();
}

class _DeleteAccountButtonState extends ConsumerState<_DeleteAccountButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: _isLoading ? null : () => _confirmDelete(context),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.error,
        minimumSize: const Size.fromHeight(52),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.error),
            )
          : const Text('Excluir conta'),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir conta'),
        content: const Text(
          'Isso excluirá permanentemente sua conta e todos os seus dados no '
          'Animatch (animais, matches, conversas e documentos enviados). '
          'Essa ação não pode ser desfeita.\n\n'
          'Seu login continuará ativo — se entrar novamente, um novo perfil '
          'será criado do zero.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              setState(() => _isLoading = true);
              try {
                await ref.read(authNotifierProvider.notifier).deleteAccount();
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Erro ao excluir conta. Tente novamente.'),
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}
