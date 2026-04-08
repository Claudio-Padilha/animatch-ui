import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Domain options
// ---------------------------------------------------------------------------

const _species = ['Bovino', 'Equino'];

const _breedsBySpecies = {
  'Bovino': [
    'Nelore',
    'Angus',
    'Brahman',
    'Gir',
    'Guzerá',
    'Senepol',
    'Tabapuã',
    'Simental',
    'Limousin',
  ],
  'Equino': [
    'Mangalarga Marchador',
    'Quarto de Milha',
    'Crioulo',
    'Lusitano',
    'Campolina',
  ],
};

const _sexBySpecies = {
  'Bovino': ['Touro', 'Vaca', 'Novilho', 'Novilha'],
  'Equino': ['Garanhão', 'Égua', 'Potro', 'Potranca'],
};

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class AddAnimalScreen extends StatefulWidget {
  const AddAnimalScreen({super.key});

  @override
  State<AddAnimalScreen> createState() => _AddAnimalScreenState();
}

class _AddAnimalScreenState extends State<AddAnimalScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _registroController = TextEditingController();
  final _locationController = TextEditingController();
  final _ageController = TextEditingController();

  String _selectedSpecies = 'Bovino';
  bool _available = true;
  bool _showDep = false;

  @override
  void dispose() {
    _nameController.dispose();
    _registroController.dispose();
    _locationController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _onSpeciesChanged(String? value) {
    if (value == null) return;
    setState(() => _selectedSpecies = value);
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      // TODO: call animal repository
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final breeds = _breedsBySpecies[_selectedSpecies]!;
    final sexOptions = _sexBySpecies[_selectedSpecies]!;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Novo Animal'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + bottomInset),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Photo upload area ────────────────────────────────────
              _PhotoUploadArea(),
              const SizedBox(height: 24),

              // ── Nome ─────────────────────────────────────────────────
              _SectionLabel('Nome do animal *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration:
                    const InputDecoration(hintText: 'Ex: Imperador da Serra'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),

              // ── Espécie + Raça ───────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel('Espécie *'),
                        const SizedBox(height: 6),
                        _Dropdown(
                          initialValue: _selectedSpecies,
                          items: _species,
                          onChanged: _onSpeciesChanged,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel('Raça *'),
                        const SizedBox(height: 6),
                        _Dropdown(
                          key: ValueKey('breed-$_selectedSpecies'),
                          hint: 'Selecionar',
                          items: breeds,
                          onChanged: (_) {},
                          validator: (v) =>
                              v == null ? 'Campo obrigatório' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Sexo + Idade ─────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel('Sexo *'),
                        const SizedBox(height: 6),
                        _Dropdown(
                          key: ValueKey('sex-$_selectedSpecies'),
                          hint: 'Selecionar',
                          items: sexOptions,
                          onChanged: (_) {},
                          validator: (v) =>
                              v == null ? 'Campo obrigatório' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel('Idade (anos)'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(hintText: 'Ex: 4'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Registro ─────────────────────────────────────────────
              _SectionLabel('Registro (ABCZ / ABQM / etc.)'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _registroController,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.next,
                decoration:
                    const InputDecoration(hintText: 'Ex: 4521-MG'),
              ),
              const SizedBox(height: 16),

              // ── Localização ──────────────────────────────────────────
              _SectionLabel('Localização *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _locationController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'Município, UF',
                  prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),

              // ── Disponível para match ────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Disponível para match',
                    style: theme.textTheme.bodyMedium,
                  ),
                  value: _available,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) => setState(() => _available = v),
                ),
              ),
              const SizedBox(height: 16),

              // ── DEP / Índices (collapsible) ──────────────────────────
              _DepSection(
                expanded: _showDep,
                onToggle: () => setState(() => _showDep = !_showDep),
              ),
              const SizedBox(height: 28),

              // ── Save ─────────────────────────────────────────────────
              FilledButton(
                onPressed: _submit,
                child: const Text('Salvar animal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Photo upload placeholder
// ---------------------------------------------------------------------------

class _PhotoUploadArea extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: open image_picker
      },
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            style: BorderStyle.solid,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 40,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Adicionar fotos',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.primary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Toque para selecionar da galeria',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DEP / Índices collapsible section
// ---------------------------------------------------------------------------

class _DepSection extends StatelessWidget {
  const _DepSection({required this.expanded, required this.onToggle});

  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.bar_chart_outlined,
                      size: 20, color: AppColors.muted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'DEP / Índices genéticos',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    'Opcional',
                    style: theme.textTheme.labelSmall,
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.muted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _DepField(label: 'DEP Peso ao Nascer (PN)', hint: 'kg'),
                  const SizedBox(height: 12),
                  _DepField(label: 'DEP Peso ao Desmame (PD)', hint: 'kg'),
                  const SizedBox(height: 12),
                  _DepField(label: 'DEP Peso aos 18 meses (P18)', hint: 'kg'),
                  const SizedBox(height: 12),
                  _DepField(label: 'Índice de Fertilidade', hint: '%'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DepField extends StatelessWidget {
  const _DepField({required this.label, required this.hint});

  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        suffixText: hint,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({
    super.key,
    required this.items,
    required this.onChanged,
    this.initialValue,
    this.hint,
    this.validator,
  });

  final String? initialValue;
  final String? hint;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: initialValue,
      isExpanded: true,
      decoration: InputDecoration(
        hintText: hint,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }
}
