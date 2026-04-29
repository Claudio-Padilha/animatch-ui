import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../domain/animal_enums.dart';
import '../domain/herd_animal.dart';
import '../providers/herd_provider.dart';

class MyAnimalDetailScreen extends ConsumerStatefulWidget {
  const MyAnimalDetailScreen({super.key, required this.animalId});

  final String animalId;

  @override
  ConsumerState<MyAnimalDetailScreen> createState() =>
      _MyAnimalDetailScreenState();
}

class _MyAnimalDetailScreenState extends ConsumerState<MyAnimalDetailScreen> {
  int _currentPhoto = 0;
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animalAsync = ref.watch(herdProvider).whenData(
          (list) => list.firstWhere((a) => a.id == widget.animalId),
        );

    return Scaffold(
      backgroundColor: AppColors.surface,
      bottomNavigationBar: const AppBottomNav(),
      body: animalAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text('Erro ao carregar animal',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => ref.invalidate(herdProvider),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
        data: (animal) => Stack(
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
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _AnimalHeader(animal: animal),
                        const SizedBox(height: 20),
                        _InfoSection(
                          title: 'IDENTIFICAÇÃO',
                          children: [
                            _InfoRow(
                              icon: Icons.badge_outlined,
                              text: animal.registration ?? 'Sem registro',
                            ),
                            if (animal.age != null)
                              _InfoRow(
                                icon: Icons.calendar_today_outlined,
                                text: '${animal.age} anos',
                              ),
                            _InfoRow(
                              icon: Icons.category_outlined,
                              text: '${animal.breed} · ${animal.sex}',
                            ),
                          ],
                        ),
                        if (animal.description != null &&
                            animal.description!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _InfoSection(
                            title: 'DESCRIÇÃO',
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
                        if (animal.location != null) ...[
                          const SizedBox(height: 16),
                          _InfoSection(
                            title: 'LOCALIZAÇÃO',
                            children: [
                              _InfoRow(
                                icon: Icons.location_on_outlined,
                                text: animal.location!,
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        _InfoSection(
                          title: 'STATUS',
                          children: [
                            _StatusRow(available: animal.available),
                            _InfoRow(
                              icon: Icons.star_rounded,
                              text: 'Pontuação genética: ${animal.score}/100',
                            ),
                          ],
                        ),
                        if (animal.geneticIndices != null &&
                            !animal.geneticIndices!.isEmpty) ...[
                          const SizedBox(height: 16),
                          _GeneticIndicesSection(
                              indices: animal.geneticIndices!),
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
              child: const _BackButton(),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 4,
              right: 8,
              child: _EditButton(
                onTap: () =>
                    context.push(AppRoutes.editAnimal, extra: animal),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Genetic indices section ──────────────────────────────────────────────────

class _GeneticIndicesSection extends StatelessWidget {
  const _GeneticIndicesSection({required this.indices});

  final GeneticIndices indices;

  @override
  Widget build(BuildContext context) {
    return _InfoSection(
      title: 'DEP / ÍNDICES GENÉTICOS',
      children: [
        if (indices.birthWeight != null)
          _InfoRow(
            icon: Icons.monitor_weight_outlined,
            text: 'DEP Peso ao Nascer: ${indices.birthWeight} kg',
          ),
        if (indices.milkRestrictionWeight != null)
          _InfoRow(
            icon: Icons.monitor_weight_outlined,
            text: 'DEP Peso ao Desmame: ${indices.milkRestrictionWeight} kg',
          ),
        if (indices.weight18m != null)
          _InfoRow(
            icon: Icons.monitor_weight_outlined,
            text: 'DEP Peso 18 meses: ${indices.weight18m} kg',
          ),
        if (indices.fertilityIndex != null)
          _InfoRow(
            icon: Icons.favorite_border_outlined,
            text: 'Índice de Fertilidade: ${indices.fertilityIndex}%',
          ),
      ],
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

  final HerdAnimal animal;
  final int currentPhoto;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final paths = animal.imagePaths;
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 400,
        child: Stack(
          fit: StackFit.expand,
          children: [
            paths.isEmpty
                ? Container(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    child: Center(
                      child: Image.asset(
                        animal.species == AnimalSpecies.cattle
                            ? 'assets/images/cow.png'
                            : 'assets/images/horse.png',
                        width: 180,
                        height: 180,
                      ),
                    ),
                  )
                : PageView.builder(
                    controller: pageController,
                    itemCount: paths.length,
                    onPageChanged: onPageChanged,
                    scrollBehavior: const MaterialScrollBehavior().copyWith(
                      dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                      },
                    ),
                    itemBuilder: (_, i) => Container(
                      color: Colors.black,
                      child: CachedNetworkImage(
                        imageUrl: paths[i],
                        fit: BoxFit.contain,
                        width: double.infinity,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                        errorWidget: (context, url, err) => Center(
                          child: Icon(Icons.broken_image_outlined,
                              color: Colors.white54, size: 48),
                        ),
                      ),
                    ),
                  ),
            if (paths.length > 1)
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    paths.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == currentPhoto ? 20 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: i == currentPhoto
                            ? Colors.white
                            : Colors.white.withAlpha(120),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Animal header ────────────────────────────────────────────────────────────

class _AnimalHeader extends StatelessWidget {
  const _AnimalHeader({required this.animal});

  final HerdAnimal animal;

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
          '${animal.breed} · ${animal.sex}${animal.age != null ? ' · ${animal.age} anos' : ''}',
          style: GoogleFonts.inter(fontSize: 15, color: AppColors.muted),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _ScoreBadge(score: animal.score),
            const SizedBox(width: 8),
            _AvailabilityBadge(available: animal.available),
          ],
        ),
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

class _AvailabilityBadge extends StatelessWidget {
  const _AvailabilityBadge({required this.available});

  final bool available;

  @override
  Widget build(BuildContext context) {
    final color = available ? AppColors.primary : AppColors.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        available ? 'Disponível' : 'Indisponível',
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
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
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 17, color: AppColors.muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.available});

  final bool available;

  @override
  Widget build(BuildContext context) {
    final color = available ? AppColors.primary : AppColors.muted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            available ? Icons.check_circle_outline : Icons.cancel_outlined,
            size: 17,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            available
                ? 'Disponível para matching'
                : 'Indisponível para matching',
            style: GoogleFonts.inter(fontSize: 14, color: color),
          ),
        ],
      ),
    );
  }
}

// ─── Back button ──────────────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
  const _BackButton();

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

// ─── Edit button ──────────────────────────────────────────────────────────────

class _EditButton extends StatelessWidget {
  const _EditButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text(
        'Editar',
        style: GoogleFonts.inter(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
