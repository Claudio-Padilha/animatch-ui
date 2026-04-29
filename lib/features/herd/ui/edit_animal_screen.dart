import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/services/cloudinary_uploader.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/address_form_fields.dart';
import '../../../shared/widgets/animal_photo_strip.dart';
import '../domain/animal_enums.dart';
import '../domain/herd_animal.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../providers/herd_provider.dart';

class EditAnimalScreen extends ConsumerStatefulWidget {
  const EditAnimalScreen({super.key, required this.animal});

  final HerdAnimal animal;

  @override
  ConsumerState<EditAnimalScreen> createState() => _EditAnimalScreenState();
}

class _EditAnimalScreenState extends ConsumerState<EditAnimalScreen> {
  final _formKey = GlobalKey<FormState>();

  // Basic info
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _qualityScoreController;
  late final TextEditingController _ageController;
  late final TextEditingController _registrationController;

  // Address
  late final TextEditingController _propertyNameController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _zipCodeController;

  // Genetic indices
  late final TextEditingController _birthWeightController;
  late final TextEditingController _milkRestrictionWeightController;
  late final TextEditingController _weight18mController;
  late final TextEditingController _fertilityIndexController;

  late AnimalSpecies _selectedSpecies;
  late AnimalBreed? _selectedBreed;
  late String? _selectedSexLabel;
  late bool _available;
  late bool _showDep;
  late List<String> _photoUrls;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    final a = widget.animal;
    final indices = a.geneticIndices;

    _selectedSpecies = a.species;
    _selectedBreed = _breedFromLabel(a.breed);
    _selectedSexLabel = a.sex; // stored as 'Macho' / 'Fêmea'
    _available = a.available;
    _showDep = indices != null && !indices.isEmpty;
    _photoUrls = List<String>.from(a.imagePaths);

    _nameController = TextEditingController(text: a.name);
    _descriptionController = TextEditingController(text: a.description ?? '');
    _qualityScoreController = TextEditingController(
        text: a.score > 0 ? '${a.score}' : '');
    _ageController =
        TextEditingController(text: a.age != null ? '${a.age}' : '');
    _registrationController =
        TextEditingController(text: a.registration ?? '');

    _propertyNameController = TextEditingController(text: a.propertyName ?? '');
    _cityController = TextEditingController(text: a.city ?? '');
    _stateController = TextEditingController(text: a.state ?? '');
    _zipCodeController = TextEditingController(text: a.zipCode ?? '');

    _birthWeightController = TextEditingController(
        text: indices?.birthWeight != null ? '${indices!.birthWeight}' : '');
    _milkRestrictionWeightController = TextEditingController(
        text: indices?.milkRestrictionWeight != null
            ? '${indices!.milkRestrictionWeight}'
            : '');
    _weight18mController = TextEditingController(
        text: indices?.weight18m != null ? '${indices!.weight18m}' : '');
    _fertilityIndexController = TextEditingController(
        text: indices?.fertilityIndex != null
            ? '${indices!.fertilityIndex}'
            : '');
  }

  AnimalBreed? _breedFromLabel(String label) {
    try {
      return AnimalBreed.fromLabel(label);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _qualityScoreController.dispose();
    _ageController.dispose();
    _registrationController.dispose();
    _propertyNameController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _birthWeightController.dispose();
    _milkRestrictionWeightController.dispose();
    _weight18mController.dispose();
    _fertilityIndexController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(BuildContext ctx, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      ctx,
      title: 'Apagar animal',
      message:
          'Tem certeza que deseja apagar ${widget.animal.name}? Esta ação não pode ser desfeita.',
      confirmLabel: 'Apagar',
      cancelLabel: 'Cancelar',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    await ref
        .read(deleteAnimalProvider.notifier)
        .deleteAnimal(widget.animal.id);

    if (!mounted) return;
    final deleteState = ref.read(deleteAnimalProvider);
    if (deleteState is AsyncError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao apagar. Tente novamente.')),
      );
      return;
    }
    context.go(AppRoutes.herd);
  }

  Future<void> _toggle(BuildContext ctx, WidgetRef ref) async {
    final isActive = _available;
    final confirmed = await showConfirmDialog(
      ctx,
      title: isActive ? 'Pausar perfil' : 'Ativar perfil',
      message: isActive
          ? 'Ao pausar, ${widget.animal.name} não aparecerá nas buscas de outros criadores. Deseja continuar?'
          : 'Ao ativar, ${widget.animal.name} voltará a aparecer nas buscas de outros criadores. Deseja continuar?',
      confirmLabel: isActive ? 'Pausar' : 'Ativar',
      cancelLabel: 'Cancelar',
      destructive: isActive,
    );
    if (!confirmed || !mounted) return;

    await ref
        .read(toggleAnimalProvider.notifier)
        .toggle(widget.animal.id, currentlyActive: isActive);

    if (!mounted) return;
    final toggleState = ref.read(toggleAnimalProvider);
    if (toggleState is AsyncError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Erro ao atualizar status. Tente novamente.')),
      );
      return;
    }
    setState(() => _available = !isActive);
  }

  Future<void> _handlePhotoPick() async {
    setState(() => _isUploadingPhoto = true);
    try {
      final url = await ref
          .read(cloudinaryUploaderProvider)
          .pickAndUpload(folder: 'animals');
      if (url != null) setState(() => _photoUrls.add(url));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao fazer upload: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  void _onSpeciesChanged(String? label) {
    if (label == null) return;
    setState(() {
      _selectedSpecies = AnimalSpecies.fromLabel(label);
      _selectedBreed = null;
      _selectedSexLabel = null;
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedBreed == null || _selectedSexLabel == null) return;

    final qualityScore = int.tryParse(_qualityScoreController.text.trim());
    final age = int.tryParse(_ageController.text.trim());

    await ref.read(updateAnimalProvider.notifier).updateAnimal(
          id: widget.animal.id,
          name: _nameController.text.trim(),
          species: _selectedSpecies,
          breed: _selectedBreed!,
          sexLabel: _selectedSexLabel!,
          propertyName: _propertyNameController.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          zipCode: _zipCodeController.text.trim(),
          description: _descriptionController.text.trim(),
          qualityScore: qualityScore,
          age: age,
          registrationNumber: _registrationController.text.trim(),
          available: _available,
          imageUrls: _photoUrls,
          geneticIndices: {
            'birth_weight':
                double.tryParse(_birthWeightController.text.trim()),
            'milk_restriction_weight': double.tryParse(
                _milkRestrictionWeightController.text.trim()),
            'weight_18m':
                double.tryParse(_weight18mController.text.trim()),
            'fertility_index':
                double.tryParse(_fertilityIndexController.text.trim()),
          },
        );

    if (!mounted) return;
    final updateState = ref.read(updateAnimalProvider);
    if (updateState is AsyncError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao salvar. Tente novamente.')),
      );
      return;
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final breeds = breedsBySpecies[_selectedSpecies]!;
    final sexLabels = sexLabelsBySpecies[_selectedSpecies]!;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Editar ${widget.animal.name}',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          Consumer(
            builder: (_, ref, _) {
              final saving = ref.watch(updateAnimalProvider) is AsyncLoading;
              return TextButton(
                onPressed: saving ? null : _submit,
                child: const Text(
                  'Salvar',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + bottomInset),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Photo ─────────────────────────────────────────────────
              _SectionLabel('Fotos'),
              const SizedBox(height: 8),
              AnimalPhotoStrip(
                photoUrls: _photoUrls,
                isLoading: _isUploadingPhoto,
                onAdd: _handlePhotoPick,
                onRemove: (i) => setState(() => _photoUrls.removeAt(i)),
              ),
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
                          initialValue: _selectedSpecies.label,
                          items: AnimalSpecies.values
                              .map((e) => e.label)
                              .toList(),
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
                          key: ValueKey('breed-${_selectedSpecies.name}'),
                          initialValue: _selectedBreed?.label,
                          hint: 'Selecionar',
                          items: breeds.map((b) => b.label).toList(),
                          onChanged: (v) => setState(() => _selectedBreed =
                              v != null ? AnimalBreed.fromLabel(v) : null),
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
                          key: ValueKey('sex-${_selectedSpecies.name}'),
                          initialValue: _selectedSexLabel,
                          hint: 'Selecionar',
                          items: sexLabels,
                          onChanged: (v) =>
                              setState(() => _selectedSexLabel = v),
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
                          decoration:
                              const InputDecoration(hintText: 'Ex: 4'),
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
                controller: _registrationController,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.next,
                decoration:
                    const InputDecoration(hintText: 'Ex: 4521-MG'),
              ),
              const SizedBox(height: 16),

              // ── Pontuação de qualidade ───────────────────────────────
              _SectionLabel('Pontuação de qualidade (0–100)'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _qualityScoreController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(hintText: 'Ex: 87'),
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  final n = int.tryParse(v);
                  if (n == null || n < 0 || n > 100) {
                    return 'Digite um valor entre 0 e 100';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Descrição ────────────────────────────────────────────
              _SectionLabel('Descrição'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descriptionController,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.newline,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText:
                      'Ex: Touro com DEP de crescimento acima da média, certificado CEIP',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),

              // ── Endereço ─────────────────────────────────────────────
              _SectionLabel('Localização *'),
              const SizedBox(height: 10),
              TextFormField(
                controller: _propertyNameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nome da propriedade',
                  hintText: 'Ex: Fazenda Santa Luzia',
                  prefixIcon: Icon(Icons.agriculture_outlined, size: 20),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              AddressFormFields(
                cityController: _cityController,
                stateController: _stateController,
                zipController: _zipCodeController,
                required: true,
              ),
              const SizedBox(height: 16),

              // ── Disponível para match ────────────────────────────────

              // ── DEP / Índices (collapsible) ──────────────────────────
              _DepSection(
                expanded: _showDep,
                onToggle: () =>
                    setState(() => _showDep = !_showDep),
                birthWeightController: _birthWeightController,
                milkRestrictionWeightController:
                    _milkRestrictionWeightController,
                weight18mController: _weight18mController,
                fertilityIndexController: _fertilityIndexController,
              ),
              const SizedBox(height: 28),

              // ── Save ─────────────────────────────────────────────────
              Consumer(
                builder: (_, ref, _) {
                  final saving =
                      ref.watch(updateAnimalProvider) is AsyncLoading;
                  return FilledButton(
                    onPressed: saving ? null : _submit,
                    child: saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Salvar alterações'),
                  );
                },
              ),
              const SizedBox(height: 12),

              // ── Toggle status ─────────────────────────────────────────
              Consumer(
                builder: (ctx, ref, _) {
                  final toggling =
                      ref.watch(toggleAnimalProvider) is AsyncLoading;
                  final isActive = _available;
                  return OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isActive
                          ? AppColors.muted
                          : AppColors.primary,
                      side: BorderSide(
                        color: isActive
                            ? AppColors.muted
                            : AppColors.primary,
                      ),
                    ),
                    onPressed: toggling ? null : () => _toggle(ctx, ref),
                    icon: toggling
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: isActive
                                  ? AppColors.muted
                                  : AppColors.primary,
                            ),
                          )
                        : Icon(isActive
                            ? Icons.pause_circle_outline
                            : Icons.play_circle_outline),
                    label: Text(
                        isActive ? 'Pausar perfil' : 'Ativar perfil'),
                  );
                },
              ),
              const SizedBox(height: 12),

              // ── Delete ────────────────────────────────────────────────
              Consumer(
                builder: (ctx, ref, _) {
                  final deleting =
                      ref.watch(deleteAnimalProvider) is AsyncLoading;
                  return OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error),
                    ),
                    onPressed: deleting ? null : () => _confirmDelete(ctx, ref),
                    child: deleting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.error),
                          )
                        : const Text('Apagar animal'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DEP / Índices collapsible section
// ---------------------------------------------------------------------------

class _DepSection extends StatelessWidget {
  const _DepSection({
    required this.expanded,
    required this.onToggle,
    required this.birthWeightController,
    required this.milkRestrictionWeightController,
    required this.weight18mController,
    required this.fertilityIndexController,
  });

  final bool expanded;
  final VoidCallback onToggle;
  final TextEditingController birthWeightController;
  final TextEditingController milkRestrictionWeightController;
  final TextEditingController weight18mController;
  final TextEditingController fertilityIndexController;

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
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
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
                  Text('Opcional', style: theme.textTheme.labelSmall),
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
                  _DepField(
                    label: 'DEP Peso ao Nascer (PN)',
                    hint: 'kg',
                    controller: birthWeightController,
                  ),
                  const SizedBox(height: 12),
                  _DepField(
                    label: 'DEP Peso ao Desmame (PD)',
                    hint: 'kg',
                    controller: milkRestrictionWeightController,
                  ),
                  const SizedBox(height: 12),
                  _DepField(
                    label: 'DEP Peso aos 18 meses (P18)',
                    hint: 'kg',
                    controller: weight18mController,
                  ),
                  const SizedBox(height: 12),
                  _DepField(
                    label: 'Índice de Fertilidade',
                    hint: '%',
                    controller: fertilityIndexController,
                  ),
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
  const _DepField({
    required this.label,
    required this.hint,
    required this.controller,
  });

  final String label;
  final String hint;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(labelText: label, suffixText: hint),
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
