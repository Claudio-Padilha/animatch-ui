import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Mock data — replace with Riverpod provider + repository later
// ---------------------------------------------------------------------------

class _Animal {
  const _Animal({
    required this.name,
    required this.breed,
    required this.sex,
    required this.score,
    required this.available,
  });

  final String name;
  final String breed;
  final String sex;
  final int score;
  final bool available;
}

const _mockAnimals = [
  _Animal(
    name: 'Imperador da Serra',
    breed: 'Nelore',
    sex: 'Touro',
    score: 87,
    available: true,
  ),
  _Animal(
    name: 'Dom Carlos IV',
    breed: 'Nelore',
    sex: 'Touro',
    score: 72,
    available: false,
  ),
  _Animal(
    name: 'Estrela do Sul',
    breed: 'Mangalarga Marchador',
    sex: 'Égua',
    score: 91,
    available: true,
  ),
];

const _freeLimit = 5;

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class HerdScreen extends StatelessWidget {
  const HerdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final count = _mockAnimals.length;

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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _QuotaBar(count: count, limit: _freeLimit),
          const SizedBox(height: 20),
          ...List.generate(
            _mockAnimals.length,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AnimalCard(animal: _mockAnimals[i]),
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

// ---------------------------------------------------------------------------
// Quota bar widget
// ---------------------------------------------------------------------------

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
              Text(
                '$count / $limit animais',
                style: theme.textTheme.titleSmall,
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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
            onTap: () {
              // TODO: navigate to plan upgrade screen
            },
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

// ---------------------------------------------------------------------------
// Animal card widget
// ---------------------------------------------------------------------------

class _AnimalCard extends StatelessWidget {
  const _AnimalCard({required this.animal});

  final _Animal animal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // ── Photo placeholder ────────────────────────────────────
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.pets,
                color: AppColors.primary.withValues(alpha: 0.4),
                size: 32,
              ),
            ),
            const SizedBox(width: 12),

            // ── Info ─────────────────────────────────────────────────
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

            // ── Edit button ──────────────────────────────────────────
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              color: AppColors.muted,
              onPressed: () {
                // TODO: navigate to edit animal screen
              },
            ),
          ],
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
