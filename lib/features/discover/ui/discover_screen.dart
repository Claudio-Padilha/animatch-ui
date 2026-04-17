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
import '../../herd/providers/selected_animal_provider.dart';

// ─── Stub model ───────────────────────────────────────────────────────────────

class DiscoverAnimal {
  const DiscoverAnimal({
    required this.name,
    required this.breed,
    required this.sex,
    required this.age,
    required this.score,
    required this.distanceLabel,
    required this.locationFull,
    required this.breederName,
    required this.isVerified,
    required this.imagePaths,
    required this.depWeight,
    required this.depConf,
    required this.registrationCode,
  });

  final String name;
  final String breed;
  final String sex;
  final String age;
  final int score;
  final String distanceLabel;
  final String locationFull;
  final String breederName;
  final bool isVerified;
  final List<String> imagePaths;
  final double depWeight;
  final double depConf;
  final String registrationCode;
}

final _stubAnimals = [
  DiscoverAnimal(
    name: 'Imperador da Serra',
    breed: 'Nelore',
    sex: 'Touro',
    age: '4 anos',
    score: 87,
    distanceLabel: '~340 km · MG',
    locationFull: 'Triângulo Mineiro, MG',
    breederName: 'João Mendonça',
    isVerified: true,
    imagePaths: [
      'assets/images/bovino1.jpg',
      'assets/images/bovino1_1.jpg',
      'assets/images/bovino1_2.jpg',
    ],
    depWeight: 12.4,
    depConf: 8.1,
    registrationCode: 'ABCZ: 4521-MG',
  ),
  DiscoverAnimal(
    name: 'Sultão do Cerrado',
    breed: 'Nelore',
    sex: 'Touro',
    age: '5 anos',
    score: 91,
    distanceLabel: '~210 km · GO',
    locationFull: 'Sul Goiano, GO',
    breederName: 'Fazenda Boa Vista',
    isVerified: true,
    imagePaths: ['assets/images/bovino2.jpeg'],
    depWeight: 15.2,
    depConf: 10.3,
    registrationCode: 'ABCZ: 8834-GO',
  ),
  DiscoverAnimal(
    name: 'Baronesa Real',
    breed: 'Nelore',
    sex: 'Vaca',
    age: '3 anos',
    score: 79,
    distanceLabel: '~480 km · MS',
    locationFull: 'Campo Grande, MS',
    breederName: 'Agropecuária Estrela',
    isVerified: false,
    imagePaths: ['assets/images/bovino3.jpeg'],
    depWeight: 8.7,
    depConf: 5.9,
    registrationCode: 'ABCZ: 2210-MS',
  ),
  DiscoverAnimal(
    name: 'Trovoada da Serra',
    breed: 'Nelore',
    sex: 'Vaca',
    age: '4 anos',
    score: 84,
    distanceLabel: '~155 km · SP',
    locationFull: 'Noroeste Paulista, SP',
    breederName: 'Fazenda Horizonte',
    isVerified: true,
    imagePaths: ['assets/images/bovino4.jpeg'],
    depWeight: 10.1,
    depConf: 7.4,
    registrationCode: 'ABCZ: 6612-SP',
  ),
  DiscoverAnimal(
    name: 'Monarca do Planalto',
    breed: 'Nelore',
    sex: 'Touro',
    age: '6 anos',
    score: 95,
    distanceLabel: '~620 km · MT',
    locationFull: 'Planalto Central, MT',
    breederName: 'Agro Santa Clara',
    isVerified: true,
    imagePaths: ['assets/images/bovino5.jpeg'],
    depWeight: 18.6,
    depConf: 13.2,
    registrationCode: 'ABCZ: 9901-MT',
  ),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final _controller = CardSwiperController();
  bool _isEmpty = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSwipe(int oldIndex, int? newIndex, CardSwiperDirection direction) {
    setState(() {
      if (newIndex == null) _isEmpty = true;
    });
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

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _SelectedAnimalBanner(animalName: selected.name),
          _FilterBar(),
          Expanded(
            child: _isEmpty ? _EmptyState() : _buildSwiper(),
          ),
          if (!_isEmpty) _ActionButtons(controller: _controller),
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

  Widget _buildSwiper() {
    return CardSwiper(
      controller: _controller,
      cardsCount: _stubAnimals.length,
      onSwipe: (oldIndex, newIndex, direction) {
        _onSwipe(oldIndex, newIndex, direction);
        return true;
      },
      maxAngle: 20,
      scale: 0.92,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      cardBuilder: (context, index, horizontalOffsetPercentage, verticalOffsetPercentage) {
        return _AnimalSwipeCard(
          animal: _stubAnimals[index],
          onTap: () => context.push(AppRoutes.animalDetail, extra: _stubAnimals[index]),
        );
      },
    );
  }
}

// ─── Filter bar ───────────────────────────────────────────────────────────────

final _distanceOptions =
    DistanceRange.values.map((e) => e.label).toList();

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
            // Dark background so letterbox bars look intentional
            const ColoredBox(color: Colors.black),
            // Photo — contain so the full animal is always visible
            Image.asset(
              animal.imagePaths.first,
              fit: BoxFit.contain,
            ),
            // Gradient overlay at the bottom
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
            ),
          // Content at the bottom
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quality badge
                  _ScoreBadge(score: animal.score),
                  const SizedBox(height: 10),
                  // Name
                  Text(
                    animal.name,
                    style: GoogleFonts.merriweather(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Breed · Sex
                  Text(
                    '${animal.breed} · ${animal.sex}',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Distance
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: Colors.white70, size: 15),
                      const SizedBox(width: 4),
                      Text(
                        animal.distanceLabel,
                        style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Breeder
                  Row(
                    children: [
                      const Icon(Icons.person_outline, color: Colors.white70, size: 15),
                      const SizedBox(width: 4),
                      Text(
                        animal.breederName,
                        style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
                      ),
                      if (animal.isVerified) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
          // Pass
          CircleActionButton(
            onTap: () => controller.swipe(CardSwiperDirection.left),
            icon: Icons.close_rounded,
            iconColor: AppColors.error,
            borderColor: AppColors.error.withValues(alpha: 0.3),
            size: 64,
            iconSize: 30,
            label: 'Passar',
          ),
          // Like
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

// ─── No animal selected state ─────────────────────────────────────────────────

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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted,
                  ),
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

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: AppColors.muted.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'Nenhum animal por aqui',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Tente ajustar os filtros ou volte mais tarde.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
