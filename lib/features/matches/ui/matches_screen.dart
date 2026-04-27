import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../herd/providers/selected_animal_provider.dart';
import '../domain/match_item.dart';
import '../providers/match_provider.dart';

// ─── Screen ───────────────────────────────────────────────────────────────────

class MatchesScreen extends ConsumerWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedAnimalProvider);

    if (selected == null) {
      return Scaffold(
        appBar: _appBar(context),
        body: _NoAnimalSelected(),
      );
    }

    final matchesAsync = ref.watch(matchesProvider(selected.id));

    return Scaffold(
      appBar: _appBar(context),
      body: matchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _ErrorState(),
        data: (matches) {
          if (matches.isEmpty) return _EmptyState();
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: matches.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                _MatchCard(match: matches[index]),
          );
        },
      ),
    );
  }

  AppBar _appBar(BuildContext context) => AppBar(
        title: Text('Matches', style: Theme.of(context).textTheme.titleLarge),
      );
}

// ─── Match card ───────────────────────────────────────────────────────────────

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match});

  final MatchItem match;

  @override
  Widget build(BuildContext context) {
    final isConfirmed = match.status == MatchStatus.confirmado;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: isConfirmed
            ? () => context.push(AppRoutes.matchDetail, extra: match)
            : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _animalPhoto(match.theirAnimal.imagePath, size: 80),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      match.theirAnimal.name,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      match.theirAnimal.breed,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      match.timeLabel,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _StatusBadge(status: match.status),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isConfirmed)
                const Icon(Icons.chevron_right,
                    color: AppColors.muted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _animalPhoto(String path, {required double size}) {
  if (path.isNotEmpty) {
    return Image.asset(path, width: size, height: size, fit: BoxFit.cover);
  }
  return Container(
    width: size,
    height: size,
    color: AppColors.primary.withValues(alpha: 0.06),
    child: Icon(
      Icons.image_outlined,
      size: size * 0.42,
      color: AppColors.primary.withValues(alpha: 0.30),
    ),
  );
}

// ─── Status badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final MatchStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, icon, bg, fg) = switch (status) {
      MatchStatus.confirmado => (
          'Confirmado',
          Icons.check_circle_rounded,
          const Color(0xFFDCFCE7),
          const Color(0xFF16A34A),
        ),
      MatchStatus.pendente => (
          'Pendente',
          Icons.hourglass_top_rounded,
          const Color(0xFFFEF9C3),
          const Color(0xFFB45309),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty states ─────────────────────────────────────────────────────────────

class _NoAnimalSelected extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_tree_outlined,
                size: 64, color: AppColors.muted.withValues(alpha: 0.4)),
            const SizedBox(height: 20),
            Text('Escolha um animal',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Vá para Meu Rebanho e selecione o animal para ver seus matches.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => context.go(AppRoutes.herd),
              icon: const Icon(Icons.format_list_bulleted_outlined),
              label: const Text('Meu Rebanho'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_border_rounded,
              size: 64, color: AppColors.muted.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text('Nenhum match ainda',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Continue explorando para encontrar pares.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded,
                size: 64, color: AppColors.muted.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text('Não foi possível carregar os matches',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Verifique sua conexão e tente novamente.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

