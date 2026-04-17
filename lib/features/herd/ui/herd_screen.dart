import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/herd_animal.dart';
import '../providers/selected_animal_provider.dart';

const _freeLimit = 5;

// ─── Screen ───────────────────────────────────────────────────────────────────

class HerdScreen extends ConsumerWidget {
  const HerdScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedAnimalProvider);
    final count = stubHerdAnimals.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Rebanho'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Adicionar animal',
            onPressed: () => context.push(AppRoutes.addAnimal),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          _SelectionBanner(selected: selected),
          const SizedBox(height: 16),
          _QuotaBar(count: count, limit: _freeLimit),
          const SizedBox(height: 20),
          ...List.generate(
            stubHerdAnimals.length,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AnimalCard(
                animal: stubHerdAnimals[i],
                isSelected: selected == stubHerdAnimals[i],
                onTap: () => context.push(
                  AppRoutes.myAnimalDetail,
                  extra: stubHerdAnimals[i],
                ),
                onSelect: () {
                  ref.read(selectedAnimalProvider.notifier).state =
                      stubHerdAnimals[i];
                  context.go(AppRoutes.discover);
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addAnimal),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Adicionar animal'),
      ),
    );
  }
}

// ─── Selection banner ─────────────────────────────────────────────────────────

class _SelectionBanner extends StatelessWidget {
  const _SelectionBanner({required this.selected});

  final HerdAnimal? selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (selected == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline,
                color: AppColors.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Selecione um animal para buscar o par ideal.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.favorite_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Buscando par para: ${selected!.name}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quota bar ────────────────────────────────────────────────────────────────

class _QuotaBar extends StatelessWidget {
  const _QuotaBar({required this.count, required this.limit});

  final int count;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fraction = (count / limit).clamp(0.0, 1.0);
    final atLimit = count >= limit;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$count / $limit animais', style: theme.textTheme.titleSmall),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Plano Gratuito',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                atLimit ? AppColors.error : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {},
            child: Text(
              atLimit
                  ? 'Limite atingido — faça upgrade para adicionar mais animais'
                  : 'Upgrade para adicionar animais ilimitados →',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Animal card ──────────────────────────────────────────────────────────────

class _AnimalCard extends StatelessWidget {
  const _AnimalCard({
    required this.animal,
    required this.isSelected,
    required this.onTap,
    required this.onSelect,
  });

  final HerdAnimal animal;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
        color: Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Photo
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: animal.imagePaths.isNotEmpty
                  ? Image.asset(
                      animal.imagePaths.first,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 64,
                      height: 64,
                      color: AppColors.primary.withValues(alpha: 0.08),
                      child: Icon(
                        Icons.pets,
                        color: AppColors.primary.withValues(alpha: 0.4),
                        size: 32,
                      ),
                    ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(animal.name, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    '${animal.breed} · ${animal.sex}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.star_rounded,
                          size: 14, color: AppColors.secondary),
                      const SizedBox(width: 3),
                      Text(
                        '${animal.score}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _AvailabilityChip(available: animal.available),
                    ],
                  ),
                ],
              ),
            ),

            // Select button
            const SizedBox(width: 8),
            _SelectButton(isSelected: isSelected, onSelect: onSelect),
          ],
        ),
      ),
    ),
    );
  }
}

class _SelectButton extends StatelessWidget {
  const _SelectButton({required this.isSelected, required this.onSelect});

  final bool isSelected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    if (isSelected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check, color: Colors.white, size: 14),
            SizedBox(width: 4),
            Text(
              'Selecionado',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: onSelect,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary),
        ),
        child: const Text(
          'Buscar par',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _AvailabilityChip extends StatelessWidget {
  const _AvailabilityChip({required this.available});

  final bool available;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: available
            ? AppColors.primary.withValues(alpha: 0.1)
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        available ? 'Disponível' : 'Indisponível',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: available ? AppColors.primary : AppColors.muted,
        ),
      ),
    );
  }
}
