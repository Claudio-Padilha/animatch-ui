import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../domain/animal_detail_data.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/circle_action_button.dart';

class AnimalDetailScreen extends StatefulWidget {
  const AnimalDetailScreen({super.key, required this.animal, this.showCtas = true});

  final AnimalDetailData animal;
  final bool showCtas;

  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen> {
  int _currentPhoto = 0;
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animal = widget.animal;
    return Scaffold(
      backgroundColor: AppColors.surface,
      bottomNavigationBar: const AppBottomNav(),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _PhotoHeader(
                animal: animal,
                currentPhoto: _currentPhoto,
                pageController: _pageController,
                onPageChanged: (i) => setState(() => _currentPhoto = i),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 130),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AnimalHeader(animal: animal),
                      const SizedBox(height: 20),
                      _LocationSection(animal: animal),
                      if (animal.description != null &&
                          animal.description!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _InfoSection(
                          title: 'Sobre',
                          children: [
                            Text(
                              animal.description!,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.onSurface,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (animal.registrationCode != null &&
                          animal.registrationCode!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _InfoSection(
                          title: 'Registro',
                          children: [
                            _InfoRow(
                              icon: Icons.badge_outlined,
                              text: animal.registrationCode!,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 4,
            left: 8,
            child: _BackButton(),
          ),
          if (widget.showCtas)
            Positioned(
              left: 0,
              right: 0,
              bottom: 4,
              child: _FloatingCta(animal: animal),
            ),
        ],
      ),
    );
  }
}

// ─── Photo header ─────────────────────────────────────────────────────────────

class _PhotoHeader extends StatelessWidget {
  const _PhotoHeader({
    required this.animal,
    required this.currentPhoto,
    required this.pageController,
    required this.onPageChanged,
  });

  final AnimalDetailData animal;
  final int currentPhoto;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 360,
        child: Stack(
          children: [
            animal.photoUrls.isEmpty
                ? _PhotoPlaceholder(species: animal.species)
                : PageView.builder(
                    controller: pageController,
                    onPageChanged: onPageChanged,
                    itemCount: animal.photoUrls.length,
                    scrollBehavior: const MaterialScrollBehavior().copyWith(
                      dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                      },
                    ),
                    itemBuilder: (_, i) => Container(
                      color: Colors.black,
                      child: CachedNetworkImage(
                        imageUrl: animal.photoUrls[i],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (_, _) =>
                            const ColoredBox(color: Colors.black26),
                        errorWidget: (_, _, _) => const Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white30,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
            if (animal.photoUrls.length > 1)
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: _DotIndicator(
                  count: animal.photoUrls.length,
                  current: currentPhoto,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder({required this.species});

  final String species;

  @override
  Widget build(BuildContext context) {
    final asset = species == 'horse'
        ? 'assets/images/horse.png'
        : 'assets/images/cow.png';
    return Container(
      color: AppColors.primary.withValues(alpha: 0.06),
      child: Center(
        child: Image.asset(asset, width: 160, height: 160, fit: BoxFit.contain),
      ),
    );
  }
}

class _DotIndicator extends StatelessWidget {
  const _DotIndicator({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary
                : Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ─── Animal header ────────────────────────────────────────────────────────────

class _AnimalHeader extends StatelessWidget {
  const _AnimalHeader({required this.animal});

  final AnimalDetailData animal;

  @override
  Widget build(BuildContext context) {
    final parts = [
      animal.breed,
      if (animal.sex.isNotEmpty) animal.sex,
      if (animal.ageLabel.isNotEmpty) animal.ageLabel,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          animal.name,
          style: GoogleFonts.merriweather(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          parts.join(' · '),
          style: GoogleFonts.inter(fontSize: 15, color: AppColors.muted),
        ),
        const SizedBox(height: 10),
        _ScoreBadge(score: animal.score),
      ],
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score});

  final int score;

  Color get _color {
    if (score >= 90) return const Color(0xFFD4A017);
    if (score >= 75) return AppColors.primaryLight;
    return AppColors.muted;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: _color, size: 16),
          const SizedBox(width: 5),
          Text(
            'Qualidade: $score/100',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Location section ─────────────────────────────────────────────────────────

class _LocationSection extends StatelessWidget {
  const _LocationSection({required this.animal});

  final AnimalDetailData animal;

  @override
  Widget build(BuildContext context) {
    final hasLocation = animal.locationFull.isNotEmpty;
    final hasDirections = animal.locationDirections?.isNotEmpty == true;
    if (!hasLocation && !hasDirections) return const SizedBox.shrink();

    return _InfoSection(
      title: 'Localização',
      children: [
        if (hasLocation)
          _InfoRow(icon: Icons.location_on_outlined, text: animal.locationFull),
        if (hasDirections)
          _InfoRow(icon: Icons.map_outlined, text: animal.locationDirections!),
      ],
    );
  }
}

// ─── Shared section / row ─────────────────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 17, color: AppColors.muted),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Back button ──────────────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pop(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}

// ─── Floating CTAs (only shown in discovery context) ─────────────────────────

class _FloatingCta extends StatelessWidget {
  const _FloatingCta({required this.animal});

  final AnimalDetailData animal;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        CircleActionButton(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${animal.name} passou.'),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
            context.pop();
          },
          icon: Icons.close_rounded,
          iconColor: AppColors.error,
          borderColor: AppColors.error.withValues(alpha: 0.3),
          size: 64,
          iconSize: 30,
          label: 'Passar',
        ),
        CircleActionButton(
          onTap: () => _showMatchDialog(context, animal),
          icon: Icons.favorite_rounded,
          iconColor: AppColors.primary,
          borderColor: AppColors.primary.withValues(alpha: 0.3),
          size: 72,
          iconSize: 34,
          label: 'Curtir',
        ),
      ],
    );
  }

  void _showMatchDialog(BuildContext context, AnimalDetailData animal) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.favorite_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Curtiu!',
              style: GoogleFonts.merriweather(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Seu interesse em ${animal.name} foi registrado. Você será notificado quando o criador responder.',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop();
            },
            child: const Text('Ok'),
          ),
        ],
      ),
    );
  }
}
