import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/circle_action_button.dart';
import 'discover_screen.dart';

class AnimalDetailScreen extends StatefulWidget {
  const AnimalDetailScreen({super.key, required this.animal});

  final DiscoverAnimal animal;

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
                      _InfoSection(
                        title: 'Localização',
                        children: [
                          _InfoRow(
                            icon: Icons.location_on_outlined,
                            text: animal.locationFull,
                          ),
                          _InfoRow(
                            icon: Icons.near_me_outlined,
                            text: animal.distanceLabel.replaceAll(' · ', ' de você · '),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _InfoSection(
                        title: 'Criador',
                        children: [
                          _BreederRow(
                            name: animal.breederName,
                            isVerified: animal.isVerified,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _InfoSection(
                        title: 'Genética',
                        children: [
                          _InfoRow(
                            icon: Icons.account_tree_outlined,
                            text: 'Pedigree: ver no ABCZ',
                            isLink: true,
                          ),
                          _DepRow(label: 'DEP Peso', value: animal.depWeight),
                          _DepRow(label: 'DEP Conf.', value: animal.depConf),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _InfoSection(
                        title: 'Registro',
                        children: [
                          _InfoRow(
                            icon: Icons.badge_outlined,
                            text: animal.registrationCode,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 4,
            left: 8,
            child: _BackButton(),
          ),
          // Floating CTAs
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

  final DiscoverAnimal animal;
  final int currentPhoto;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 440,
        child: Stack(
          children: [
            PageView.builder(
              controller: pageController,
              onPageChanged: onPageChanged,
              itemCount: animal.imagePaths.length,
              itemBuilder: (_, i) => Container(
                color: Colors.black,
                child: Image.asset(
                  animal.imagePaths[i],
                  fit: BoxFit.contain,
                  width: double.infinity,
                ),
              ),
            ),
            if (animal.imagePaths.length > 1)
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: _DotIndicator(
                  count: animal.imagePaths.length,
                  current: currentPhoto,
                ),
              ),
          ],
        ),
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
            color: active ? AppColors.primary : Colors.white.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ─── Animal header (name + badges) ───────────────────────────────────────────

class _AnimalHeader extends StatelessWidget {
  const _AnimalHeader({required this.animal});

  final DiscoverAnimal animal;

  @override
  Widget build(BuildContext context) {
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
          '${animal.breed} · ${animal.sex} · ${animal.age}',
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

// ─── Info section ─────────────────────────────────────────────────────────────

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
  const _InfoRow({required this.icon, required this.text, this.isLink = false});

  final IconData icon;
  final String text;
  final bool isLink;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 17, color: AppColors.muted),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isLink ? AppColors.primary : AppColors.onSurface,
              decoration: isLink ? TextDecoration.underline : null,
              decorationColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BreederRow extends StatelessWidget {
  const _BreederRow({required this.name, required this.isVerified});

  final String name;
  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          child: Text(
            name[0].toUpperCase(),
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              fontSize: 15,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                if (isVerified) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.verified_rounded, size: 16, color: AppColors.verifiedBadge),
                ],
              ],
            ),
            Text(
              isVerified ? 'Produtor Premium' : 'Produtor',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
      ],
    );
  }
}

class _DepRow extends StatelessWidget {
  const _DepRow({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final isPositive = value >= 0;
    final color = isPositive ? AppColors.primaryLight : AppColors.error;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurface)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${isPositive ? '+' : ''}${value.toStringAsFixed(1)}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
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
        child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
      ),
    );
  }
}

// ─── Floating CTAs ────────────────────────────────────────────────────────────

class _FloatingCta extends StatelessWidget {
  const _FloatingCta({required this.animal});

  final DiscoverAnimal animal;

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

  void _showMatchDialog(BuildContext context, DiscoverAnimal animal) {
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
