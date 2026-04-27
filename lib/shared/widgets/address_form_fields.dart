import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── Shared widget ────────────────────────────────────────────────────────────

class AddressFormFields extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
        Row(
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
