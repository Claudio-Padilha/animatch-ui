import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';

/// A chip-styled popup-menu dropdown for use in horizontal filter bars.
///
/// [label]      — text shown when nothing is selected.
/// [options]    — list of option strings shown in the popup menu.
/// [value]      — currently selected option; null means "no filter".
/// [onSelected] — called with the chosen string, or null when cleared.
class FilterDropdown extends StatelessWidget {
  const FilterDropdown({
    super.key,
    required this.label,
    required this.options,
    this.value,
    this.onSelected,
  });

  final String label;
  final List<String> options;
  final String? value;
  final ValueChanged<String?>? onSelected;

  bool get _active => value != null;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String?>(
      onSelected: onSelected,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      itemBuilder: (_) => [
        // Clear option — only shown when a value is active
        if (_active)
          PopupMenuItem<String?>(
            value: null,
            child: Row(
              children: [
                const Icon(Icons.clear_rounded, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Limpar filtro',
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.red.shade400),
                ),
              ],
            ),
          ),
        if (_active) const PopupMenuDivider(height: 1),
        ...options.map(
          (opt) => PopupMenuItem<String?>(
            value: opt,
            child: Row(
              children: [
                if (opt == value) ...[
                  Icon(Icons.check_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                ],
                if (opt != value) const SizedBox(width: 24),
                Text(opt, style: GoogleFonts.inter(fontSize: 14)),
              ],
            ),
          ),
        ),
      ],
      child: _ChipContent(
        label: value ?? label,
        active: _active,
      ),
    );
  }
}

class _ChipContent extends StatelessWidget {
  const _ChipContent({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active ? AppColors.primary : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: active ? Colors.white : AppColors.onSurface,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            active ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            size: 16,
            color: active ? Colors.white : AppColors.muted,
          ),
        ],
      ),
    );
  }
}
