import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/locations/providers/locations_provider.dart';
import '../domain/municipalities.dart';

// ─── Shared widget ────────────────────────────────────────────────────────────

class AddressFormFields extends ConsumerWidget {
  const AddressFormFields({
    super.key,
    required this.cityController,
    required this.stateController,
    required this.zipController,
    this.streetController,
    this.required = false,
  });

  final TextEditingController cityController;
  final TextEditingController stateController;
  final TextEditingController zipController;

  /// When non-null, a "Logradouro" field is shown above city/state/zip.
  final TextEditingController? streetController;

  /// When true, city, state, and zip are validated as required fields.
  final bool required;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final municipalitiesAsync = ref.watch(municipalitiesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (streetController != null) ...[
          TextFormField(
            controller: streetController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Logradouro',
              hintText: 'Ex: Rua das Acácias, 120',
              prefixIcon: Icon(Icons.home_outlined, size: 20),
            ),
            validator: required
                ? (v) =>
                    (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null
                : null,
          ),
          const SizedBox(height: 16),
        ],
        municipalitiesAsync.when(
          data: (municipalities) => _StateCityDropdowns(
            municipalities: municipalities,
            cityController: cityController,
            stateController: stateController,
            required: required,
          ),
          loading: () => const _StateCityLoading(),
          error: (_, _) => _StateCityFreeText(
            cityController: cityController,
            stateController: stateController,
            required: required,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: zipController,
          keyboardType: TextInputType.number,
          inputFormatters: [ZipInputFormatter()],
          decoration: const InputDecoration(
            labelText: 'CEP',
            hintText: '00000-000',
            prefixIcon: Icon(Icons.markunread_mailbox_outlined, size: 20),
          ),
          validator: required
              ? (v) {
                  if (v == null || v.isEmpty) return 'Campo obrigatório';
                  final digits = v.replaceAll(RegExp(r'\D'), '');
                  if (digits.length != 8) return 'CEP inválido';
                  return null;
                }
              : null,
        ),
      ],
    );
  }
}

// ─── State → city dependent dropdowns ─────────────────────────────────────────

class _StateCityDropdowns extends StatefulWidget {
  const _StateCityDropdowns({
    required this.municipalities,
    required this.cityController,
    required this.stateController,
    required this.required,
  });

  final Municipalities municipalities;
  final TextEditingController cityController;
  final TextEditingController stateController;
  final bool required;

  @override
  State<_StateCityDropdowns> createState() => _StateCityDropdownsState();
}

class _StateCityDropdownsState extends State<_StateCityDropdowns> {
  late String? _selectedState =
      widget.municipalities.states.contains(widget.stateController.text)
          ? widget.stateController.text
          : null;

  List<String> get _cityItems {
    if (_selectedState == null) return const [];
    final known = widget.municipalities.citiesOf(_selectedState!);
    final current = widget.cityController.text;
    if (current.isNotEmpty && !known.contains(current)) {
      return [...known, current]..sort();
    }
    return known;
  }

  void _onStateChanged(String? uf) {
    setState(() {
      _selectedState = uf;
      widget.stateController.text = uf ?? '';
      widget.cityController.text = '';
    });
  }

  String? _requiredValidator(String? v) =>
      widget.required && (v == null || v.isEmpty) ? 'Campo obrigatório' : null;

  @override
  Widget build(BuildContext context) {
    final states = widget.municipalities.states;
    final stateValue =
        states.contains(_selectedState) ? _selectedState : null;
    final cityItems = _cityItems;
    final cityValue = widget.cityController.text.isEmpty
        ? null
        : widget.cityController.text;

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: DropdownButtonFormField<String>(
            key: ValueKey('city-$_selectedState'),
            initialValue: cityItems.contains(cityValue) ? cityValue : null,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Cidade',
              prefixIcon: Icon(Icons.location_city_outlined, size: 20),
            ),
            items: cityItems
                .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c, overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: _selectedState == null
                ? null
                : (v) =>
                    setState(() => widget.cityController.text = v ?? ''),
            validator: _requiredValidator,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
            initialValue: stateValue,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Estado',
              prefixIcon: Icon(Icons.map_outlined, size: 20),
            ),
            items: states
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: _onStateChanged,
            validator: _requiredValidator,
          ),
        ),
      ],
    );
  }
}

class _StateCityLoading extends StatelessWidget {
  const _StateCityLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 56,
      child: Center(
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

/// Fallback used when the municipalities list fails to load, so the form
/// stays usable instead of blocking on a network error.
class _StateCityFreeText extends StatelessWidget {
  const _StateCityFreeText({
    required this.cityController,
    required this.stateController,
    required this.required,
  });

  final TextEditingController cityController;
  final TextEditingController stateController;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: cityController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Cidade',
              prefixIcon: Icon(Icons.location_city_outlined, size: 20),
            ),
            validator: required
                ? (v) => (v == null || v.trim().isEmpty)
                    ? 'Campo obrigatório'
                    : null
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: stateController,
            inputFormatters: [
              LengthLimitingTextInputFormatter(2),
              UpperCaseInputFormatter(),
            ],
            decoration: const InputDecoration(
              labelText: 'Estado',
              hintText: 'MG',
              prefixIcon: Icon(Icons.map_outlined, size: 20),
            ),
            validator: required
                ? (v) => (v == null || v.trim().isEmpty)
                    ? 'Campo obrigatório'
                    : null
                : null,
          ),
        ),
      ],
    );
  }
}

// ─── Input formatters ─────────────────────────────────────────────────────────

class ZipInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final capped = digits.length > 8 ? digits.substring(0, 8) : digits;
    final buffer = StringBuffer();
    for (var i = 0; i < capped.length; i++) {
      if (i == 5) buffer.write('-');
      buffer.write(capped[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final capped = digits.length > 11 ? digits.substring(0, 11) : digits;
    final buffer = StringBuffer();
    for (var i = 0; i < capped.length; i++) {
      if (i == 3 || i == 6) buffer.write('.');
      if (i == 9) buffer.write('-');
      buffer.write(capped[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class UpperCaseInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}
