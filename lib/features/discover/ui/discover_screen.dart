import 'dart:async' show unawaited;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/domain/distance_range.dart';
import '../../../shared/widgets/circle_action_button.dart';
import '../../../shared/widgets/filter_dropdown.dart';
import '../../herd/domain/herd_animal.dart';
import '../../herd/providers/selected_animal_provider.dart';
import '../../matches/domain/match_item.dart';
import '../../matches/providers/match_provider.dart';
import '../domain/discover_animal.dart';
import '../providers/discover_provider.dart';

// ─── Screen ───────────────────────────────────────────────────────────────────

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _controller = CardSwiperController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(selectedAnimalProvider);

    if (selected == null) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: _buildAppBar(context),
        body: _NoAnimalSelected(),
      );
    }

    final suggestionsAsync = ref.watch(suggestionsProvider(selected.id));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _SelectedAnimalBanner(animalName: selected.name),
          _FilterBar(),
          Expanded(
            child: suggestionsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, _) => _ErrorState(),
              data: (animals) {
                if (animals.isEmpty) return const _NoSuggestions();
                return _buildSwiper(animals, selected.id);
              },
            ),
          ),
          suggestionsAsync.maybeWhen(
            data: (animals) => animals.isNotEmpty
                ? _ActionButtons(controller: _controller)
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        'Animatch',
        style: GoogleFonts.merriweather(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {},
          tooltip: 'Notificações',
        ),
        IconButton(
          icon: const Icon(Icons.tune_outlined),
          onPressed: () {},
          tooltip: 'Configurações',
        ),
      ],
    );
  }

  Widget _buildSwiper(List<DiscoverAnimal> animals, String selectedAnimalId) {
    return CardSwiper(
      controller: _controller,
      cardsCount: animals.length,
      numberOfCardsDisplayed: animals.length.clamp(1, 2),
      allowedSwipeDirection: const AllowedSwipeDirection.none(),
      onSwipe: (oldIndex, newIndex, direction) {
        if (newIndex == null) {
          ref.invalidate(suggestionsProvider(selectedAnimalId));
        }
        if (direction == CardSwiperDirection.right) {
          unawaited(_onLike(animals[oldIndex], selectedAnimalId));
        } else if (direction == CardSwiperDirection.left) {
          unawaited(_onReject(animals[oldIndex], selectedAnimalId));
        }
        return true;
      },
      maxAngle: 20,
      scale: 0.92,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      cardBuilder: (context, index, _, _) => _AnimalSwipeCard(
        animal: animals[index],
        onTap: () =>
            context.push(AppRoutes.animalDetail, extra: animals[index]),
      ),
    );
  }

  Future<void> _onReject(DiscoverAnimal animal, String selectedAnimalId) async {
    final repo = ref.read(matchRepositoryProvider);
    try {
      if (animal.pendingMatchId != null) {
        await repo.rejectMatch(animal.pendingMatchId!);
      } else {
        await repo.createMatch(
          firstLikeAnimalId: selectedAnimalId,
          secondLikeAnimalId: animal.id,
          status: 'rejected',
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível registrar a rejeição. Tente novamente.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _onLike(DiscoverAnimal animal, String selectedAnimalId) async {
    final repo = ref.read(matchRepositoryProvider);
    try {
      final Map<String, dynamic> data;
      if (animal.pendingMatchId != null) {
        data = await repo.confirmMatch(animal.pendingMatchId!);
      } else {
        data = await repo.createMatch(
          firstLikeAnimalId: selectedAnimalId,
          secondLikeAnimalId: animal.id,
        );
      }
      final status = data['status'] as String? ?? '';
      if (status == 'confirmed' && mounted) {
        final matchId = data['id'] as String? ?? '';
        final selected = ref.read(selectedAnimalProvider);
        if (selected != null) {
          final match = _buildMatchItem(animal, selected, matchId);
          await _showMatchCelebration(match);
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível registrar o like. Tente novamente.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  MatchItem _buildMatchItem(
    DiscoverAnimal animal,
    HerdAnimal selected,
    String matchId,
  ) {
    return MatchItem(
      id: matchId,
      status: MatchStatus.confirmado,
      timeLabel: 'Hoje',
      yourAnimal: MatchAnimal(
        id: selected.id,
        name: selected.name,
        breed: '${selected.breed} · ${selected.sex}',
        imagePath:
            selected.imagePaths.isNotEmpty ? selected.imagePaths.first : '',
        score: selected.score,
        registry: selected.registration,
        location: selected.location,
      ),
      theirAnimal: MatchAnimal(
        id: animal.id,
        name: animal.name,
        breed: '${animal.breed} · ${animal.sex}',
        imagePath: animal.imagePaths.isNotEmpty ? animal.imagePaths.first : '',
        score: animal.score,
        registry:
            animal.registrationCode.isNotEmpty ? animal.registrationCode : null,
        depPeso: animal.depWeight != 0 ? animal.depWeight : null,
        depConf: animal.depConf != 0 ? animal.depConf : null,
        location: animal.locationFull.isNotEmpty ? animal.locationFull : null,
      ),
      contact: MatchContact(
        breederName: animal.breederName,
        phone: '',
      ),
    );
  }

  Future<void> _showMatchCelebration(MatchItem match) => showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Fechar',
        barrierColor: Colors.black87,
        transitionDuration: const Duration(milliseconds: 380),
        transitionBuilder: (ctx, animation, _, child) => ScaleTransition(
          scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: animation, child: child),
        ),
        pageBuilder: (ctx, _, _) => _MatchCelebrationDialog(
          match: match,
          onViewMatch: () {
            Navigator.of(ctx).pop();
            context.push(AppRoutes.matchDetail, extra: match);
          },
        ),
      );
}

// ─── Filter bar ───────────────────────────────────────────────────────────────

final _distanceOptions = DistanceRange.values.map((e) => e.label).toList();

class _FilterBar extends StatefulWidget {
  @override
  State<_FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<_FilterBar> {
  String? _selectedDistance;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          FilterDropdown(
            label: 'Distância',
            options: _distanceOptions,
            value: _selectedDistance,
            onSelected: (v) => setState(() => _selectedDistance = v),
          ),
        ],
      ),
    );
  }
}

// ─── Animal swipe card ────────────────────────────────────────────────────────

class _AnimalSwipeCard extends StatelessWidget {
  const _AnimalSwipeCard({required this.animal, required this.onTap});

  final DiscoverAnimal animal;
  final VoidCallback onTap;

  Widget _photo(String path) {
    if (path.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: path,
        fit: BoxFit.contain,
        placeholder: (_, _) => const ColoredBox(color: Colors.black26),
        errorWidget: (_, _, _) => const Icon(
          Icons.broken_image_outlined,
          color: Colors.white30,
          size: 48,
        ),
      );
    }
    return Image.asset(path, fit: BoxFit.contain);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox.expand(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: Colors.black),
              animal.imagePaths.isNotEmpty
                  ? _photo(animal.imagePaths.first)
                  : const Icon(Icons.pets, color: Colors.white30, size: 64),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.center,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ScoreBadge(score: animal.score),
                      const SizedBox(height: 10),
                      Text(
                        animal.name,
                        style: GoogleFonts.merriweather(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${animal.breed} · ${animal.sex}',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (animal.distanceLabel.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                color: Colors.white70, size: 15),
                            const SizedBox(width: 4),
                            Text(
                              animal.distanceLabel,
                              style: GoogleFonts.inter(
                                  fontSize: 13, color: Colors.white70),
                            ),
                          ],
                        ),
                      const SizedBox(height: 6),
                      if (animal.breederName.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.person_outline,
                                color: Colors.white70, size: 15),
                            const SizedBox(width: 4),
                            Text(
                              animal.breederName,
                              style: GoogleFonts.inter(
                                  fontSize: 13, color: Colors.white70),
                            ),
                            if (animal.isVerified) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.verifiedBadge,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Verificado',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Score badge ──────────────────────────────────────────────────────────────

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            '$score/100',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action buttons ───────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.controller});

  final CardSwiperController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          CircleActionButton(
            onTap: () => controller.swipe(CardSwiperDirection.left),
            icon: Icons.close_rounded,
            iconColor: AppColors.error,
            borderColor: AppColors.error.withValues(alpha: 0.3),
            size: 64,
            iconSize: 30,
            label: 'Passar',
          ),
          CircleActionButton(
            onTap: () => controller.swipe(CardSwiperDirection.right),
            icon: Icons.favorite_rounded,
            iconColor: AppColors.primary,
            borderColor: AppColors.primary.withValues(alpha: 0.3),
            size: 72,
            iconSize: 34,
            label: 'Curtir',
          ),
        ],
      ),
    );
  }
}

// ─── Selected animal banner ───────────────────────────────────────────────────

class _SelectedAnimalBanner extends StatelessWidget {
  const _SelectedAnimalBanner({required this.animalName});

  final String animalName;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.favorite_rounded, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Buscando par para: $animalName',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => context.go(AppRoutes.herd),
            child: Text(
              'Trocar',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── No animal selected ───────────────────────────────────────────────────────

class _NoAnimalSelected extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.pets,
              size: 64,
              color: AppColors.muted.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 20),
            Text(
              'Escolha um animal',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Vá para Meu Rebanho e selecione o animal que você quer parear.',
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

// ─── No suggestions state ─────────────────────────────────────────────────────

class _NoSuggestions extends StatelessWidget {
  const _NoSuggestions();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: AppColors.muted.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 20),
            Text(
              'Sem sugestões de match no momento',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Volte mais tarde ou tente selecionar outro animal.',
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

// ─── Error state ──────────────────────────────────────────────────────────────

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
            Text(
              'Não foi possível carregar sugestões',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
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

// ─── Match celebration dialog ─────────────────────────────────────────────────

class _MatchCelebrationDialog extends StatefulWidget {
  const _MatchCelebrationDialog({
    required this.match,
    required this.onViewMatch,
  });

  final MatchItem match;
  final VoidCallback onViewMatch;

  @override
  State<_MatchCelebrationDialog> createState() =>
      _MatchCelebrationDialogState();
}

class _MatchCelebrationDialogState extends State<_MatchCelebrationDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 36, 28, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, _) => Transform.scale(
                    scale: 1.0 + _pulse.value * 0.12,
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: AppColors.primary,
                        size: 44,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'É um Match!',
                  style: GoogleFonts.merriweather(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${widget.match.yourAnimal.name} e ${widget.match.theirAnimal.name} são compatíveis!',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.muted,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: widget.onViewMatch,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text('Ver Match'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Continuar explorando',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
