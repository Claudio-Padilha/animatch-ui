import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../domain/breeder_association.dart';

class BreederAssociationsCard extends StatelessWidget {
  const BreederAssociationsCard({super.key, required this.associations});

  final List<BreederAssociation> associations;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Associações', style: theme.textTheme.titleSmall),
          const SizedBox(height: 14),
          BreederAssociationsList(associations: associations),
        ],
      ),
    );
  }
}

class BreederAssociationsList extends StatelessWidget {
  const BreederAssociationsList({super.key, required this.associations});

  final List<BreederAssociation> associations;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < associations.length; i++) ...[
          if (i > 0) const Divider(height: 24),
          _AssociationRow(association: associations[i]),
        ],
      ],
    );
  }
}

class _AssociationRow extends StatelessWidget {
  const _AssociationRow({required this.association});

  final BreederAssociation association;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            association.code,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(association.name, style: theme.textTheme.bodyMedium),
              if (association.registrationNumber != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Registro: ${association.registrationNumber}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.muted),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
