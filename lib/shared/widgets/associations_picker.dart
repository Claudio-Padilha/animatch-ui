import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../features/profile/providers/profile_provider.dart';
import '../domain/association.dart';
import '../domain/breeder_association.dart';

// ─── Public widget ────────────────────────────────────────────────────────────

class AssociationsPicker extends ConsumerStatefulWidget {
  const AssociationsPicker({
    super.key,
    required this.onChanged,
  });

  final ValueChanged<List<BreederAssociation>> onChanged;

  @override
  ConsumerState<AssociationsPicker> createState() => _AssociationsPickerState();
}

class _AssociationsPickerState extends ConsumerState<AssociationsPicker> {
  final List<_Entry> _entries = [];

  Set<String> get _selectedCodes => _entries.map((e) => e.code).toSet();

  void _notify() {
    widget.onChanged(
      _entries
          .map((e) => BreederAssociation(
                code: e.code,
                name: e.name,
                registrationNumber: e.controller.text.trim().isEmpty
                    ? null
                    : e.controller.text.trim(),
              ))
          .toList(),
    );
  }

  Future<void> _addAssociation(List<Association> available) async {
    final remaining =
        available.where((a) => !_selectedCodes.contains(a.code)).toList();
    if (remaining.isEmpty) return;

    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AssociationPickSheet(associations: remaining),
    );
    if (picked == null) return;

    final assoc = available.firstWhere((a) => a.code == picked);
    setState(() => _entries.add(_Entry(code: picked, name: assoc.name)));
    _notify();
  }

  void _remove(int index) {
    final entry = _entries[index];
    entry.controller.dispose();
    setState(() => _entries.removeAt(index));
    _notify();
  }

  @override
  void dispose() {
    for (final e in _entries) {
      e.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final associationsAsync = ref.watch(associationsProvider);

    return associationsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, _) => const Text(
        'Não foi possível carregar associações.',
        style: TextStyle(color: Colors.red),
      ),
      data: (available) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_entries.isNotEmpty) ...[
            ...List.generate(_entries.length, (i) {
              final entry = _entries[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _AssociationRow(
                  code: entry.code,
                  controller: entry.controller,
                  onRemove: () => _remove(i),
                  onChanged: (_) => _notify(),
                ),
              );
            }),
            const SizedBox(height: 4),
          ],
          if (_selectedCodes.length < available.length)
            OutlinedButton.icon(
              onPressed: () => _addAssociation(available),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Adicionar associação'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Single association row ───────────────────────────────────────────────────

class _AssociationRow extends StatelessWidget {
  const _AssociationRow({
    required this.code,
    required this.controller,
    required this.onRemove,
    required this.onChanged,
  });

  final String code;
  final TextEditingController controller;
  final VoidCallback onRemove;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Code chip
        Container(
          margin: const EdgeInsets.only(top: 14),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Text(
            code,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Registration number field
        Expanded(
          child: TextFormField(
            controller: controller,
            onChanged: onChanged,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null,
            decoration: InputDecoration(
              labelText: 'Nº de registro',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 4),

        // Remove button
        IconButton(
          onPressed: onRemove,
          icon: const Icon(Icons.close_rounded, size: 20),
          color: Colors.grey.shade500,
          tooltip: 'Remover',
        ),
      ],
    );
  }
}

// ─── Bottom sheet for picking an association ──────────────────────────────────

class _AssociationPickSheet extends StatelessWidget {
  const _AssociationPickSheet({required this.associations});

  final List<Association> associations;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.4,
      minChildSize: 0.25,
      maxChildSize: 0.75,
      builder: (_, controller) => SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'Selecionar associação',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: associations.length,
                itemBuilder: (_, i) => ListTile(
                  title: Text(associations[i].code),
                  onTap: () => Navigator.of(context).pop(associations[i].code),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Internal entry ───────────────────────────────────────────────────────────

class _Entry {
  _Entry({required this.code, required this.name})
      : controller = TextEditingController();

  final String code;
  final String name;
  final TextEditingController controller;
}
