import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/domain/animal_detail_data.dart';
import '../domain/match_item.dart';
import '../providers/match_provider.dart';

Widget _photoPlaceholder(double size, {String species = 'cattle'}) {
  final asset = species == 'horse'
      ? 'assets/images/horse.png'
      : 'assets/images/cow.png';
  return Container(
    width: size,
    height: size,
    color: AppColors.primary.withValues(alpha: 0.08),
    child: Padding(
      padding: EdgeInsets.all(size * 0.12),
      child: Image.asset(asset, fit: BoxFit.contain),
    ),
  );
}

Widget _animalPhoto(String path, {required double size, String species = 'cattle'}) {
  if (path.startsWith('http')) {
    return CachedNetworkImage(
      imageUrl: path,
      width: size,
      height: size,
      fit: BoxFit.cover,
      placeholder: (_, _) => Container(
        width: size,
        height: size,
        color: AppColors.primary.withValues(alpha: 0.08),
      ),
      errorWidget: (_, _, _) => _photoPlaceholder(size, species: species),
    );
  }
  if (path.isNotEmpty) {
    return Image.asset(path, width: size, height: size, fit: BoxFit.cover);
  }
  return _photoPlaceholder(size, species: species);
}

class MatchDetailScreen extends ConsumerWidget {
  const MatchDetailScreen({super.key, required this.match});

  final MatchItem match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Match Confirmado', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: 6),
            const Text('✅', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            _AnimalPairWidget(match: match),
            const SizedBox(height: 28),
            _AnimalInfoSection(match: match),
            const SizedBox(height: 28),
            _ContactCard(contact: match.contact),
            const SizedBox(height: 20),
            _ActionButtons(match: match),
            const SizedBox(height: 32),
            _UnmatchButton(match: match),
          ],
        ),
      ),
    );
  }
}

// ─── Animal pair header ───────────────────────────────────────────────────────

class _AnimalPairWidget extends StatelessWidget {
  const _AnimalPairWidget({required this.match});

  final MatchItem match;

  void _openDetail(BuildContext context, MatchAnimal animal) {
    context.push(
      AppRoutes.matchAnimalDetail,
      extra: AnimalDetailData.fromMatchAnimal(animal),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AnimalPhotoWithName(
          animal: match.yourAnimal,
          onTap: () => _openDetail(context, match.yourAnimal),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 42),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite, color: Colors.white, size: 18),
          ),
        ),
        _AnimalPhotoWithName(
          animal: match.theirAnimal,
          onTap: () => _openDetail(context, match.theirAnimal),
        ),
      ],
    );
  }
}

class _AnimalPhotoWithName extends StatelessWidget {
  const _AnimalPhotoWithName({required this.animal, required this.onTap});

  final MatchAnimal animal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _animalPhoto(animal.imagePath, size: 120, species: animal.species),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            animal.name,
            style: Theme.of(context).textTheme.titleSmall,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            animal.breed,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}


// ─── Animal info section ──────────────────────────────────────────────────────

class _AnimalInfoSection extends StatelessWidget {
  const _AnimalInfoSection({required this.match});

  final MatchItem match;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionDivider(label: 'Animais'),
        const SizedBox(height: 16),
        _AnimalCard(animal: match.yourAnimal, label: 'Seu animal'),
        const SizedBox(height: 12),
        _AnimalCard(animal: match.theirAnimal, label: 'Match'),
      ],
    );
  }
}

class _AnimalCard extends StatelessWidget {
  const _AnimalCard({required this.animal, required this.label});

  final MatchAnimal animal;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.muted.withAlpha(40)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label + name
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  animal.name,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              if (animal.score != null) _ScorePill(score: animal.score!),
            ],
          ),
          const SizedBox(height: 2),
          Text(animal.breed, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          // Details grid
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              if (animal.age != null)
                _InfoChip(icon: Icons.cake_outlined, text: '${animal.age} anos'),
              if (animal.registry != null)
                _InfoChip(icon: Icons.badge_outlined, text: animal.registry!),
              if (animal.location != null)
                _InfoChip(icon: Icons.location_on_outlined, text: animal.location!),
              if (animal.locationDirections != null)
                _InfoChip(icon: Icons.map_outlined, text: animal.locationDirections!),
            ],
          ),
          if (animal.depPeso != null || animal.depConf != null) ...[
            const SizedBox(height: 12),
            _DepRow(label: 'DEP Peso Desmame', value: animal.depPeso),
            if (animal.depConf != null) const SizedBox(height: 6),
            _DepRow(label: 'DEP Conformação', value: animal.depConf),
          ],
        ],
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    if (score >= 90) {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFFD4A017);
    } else if (score >= 75) {
      bg = const Color(0xFFDCFCE7);
      fg = AppColors.primary;
    } else {
      bg = const Color(0xFFF3F4F6);
      fg = AppColors.muted;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        '⭐ $score',
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.muted),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurface),
        ),
      ],
    );
  }
}

class _DepRow extends StatelessWidget {
  const _DepRow({required this.label, required this.value});

  final String label;
  final double? value;

  @override
  Widget build(BuildContext context) {
    if (value == null) return const SizedBox.shrink();
    final isPositive = value! >= 0;
    final pillBg = isPositive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2);
    final pillFg = isPositive ? const Color(0xFF16A34A) : const Color(0xFFB91C1C);
    final valueText = isPositive ? '+${value!.toStringAsFixed(1)}' : value!.toStringAsFixed(1);

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: pillBg, borderRadius: BorderRadius.circular(12)),
          child: Text(
            valueText,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: pillFg,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Contact card ─────────────────────────────────────────────────────────────

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.contact});

  final MatchContact contact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionDivider(label: 'Contato'),
        const SizedBox(height: 16),
        _ContactRow(
          icon: Icons.person_outline_rounded,
          text: contact.breederName,
        ),
        if (contact.email != null) ...[
          const SizedBox(height: 12),
          _ContactRow(
            icon: Icons.email_outlined,
            text: contact.email!,
            onTap: () => _launch('mailto:${contact.email}'),
          ),
        ],
      ],
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.icon, required this.text, this.onTap});

  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      children: [
        Icon(icon, size: 18, color: AppColors.muted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: onTap != null ? AppColors.primary : AppColors.onSurface,
              decoration: onTap != null ? TextDecoration.underline : null,
              decorationColor: AppColors.primary,
            ),
          ),
        ),
      ],
    );

    if (onTap == null) return content;
    return GestureDetector(onTap: onTap, child: content);
  }
}

// ─── Action buttons ───────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.match});

  final MatchItem match;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => context.push(AppRoutes.chat, extra: match),
        icon: const Icon(Icons.chat_rounded, size: 20),
        label: const Text('Chat'),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ─── Unmatch button ───────────────────────────────────────────────────────────

class _UnmatchButton extends ConsumerWidget {
  const _UnmatchButton({required this.match});

  final MatchItem match;

  Future<void> _confirmUnmatch(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar match?'),
        content: const Text(
          'O contato será removido e esta conexão será desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Voltar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancelar match'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final animalId = match.yourAnimal.id ?? '';
    await ref
        .read(deleteMatchProvider.notifier)
        .deleteMatch(match.id, animalId: animalId);

    if (context.mounted) context.go(AppRoutes.matches);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDeleting = ref.watch(deleteMatchProvider).isLoading;

    return TextButton(
      onPressed: isDeleting ? null : () => _confirmUnmatch(context, ref),
      child: isDeleting
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              'Cancelar match',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.red.shade400,
              ),
            ),
    );
  }
}

// ─── Section divider ──────────────────────────────────────────────────────────

class _SectionDivider extends StatelessWidget {
  const _SectionDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.muted.withAlpha(80))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(child: Divider(color: AppColors.muted.withAlpha(80))),
      ],
    );
  }
}
