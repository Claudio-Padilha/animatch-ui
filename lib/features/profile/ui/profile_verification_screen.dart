import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/local/profile_picture_store.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/domain/breeder_association.dart';
import '../../../shared/widgets/address_form_fields.dart';
import '../../../shared/widgets/associations_picker.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

// ─── Screen ───────────────────────────────────────────────────────────────────

class ProfileVerificationScreen extends ConsumerStatefulWidget {
  const ProfileVerificationScreen({super.key});

  @override
  ConsumerState<ProfileVerificationScreen> createState() =>
      _ProfileVerificationScreenState();
}

class _ProfileVerificationScreenState
    extends ConsumerState<ProfileVerificationScreen> {
  final _formKey = GlobalKey<FormState>();

  List<BreederAssociation> _associations = [];
  final _name = TextEditingController();
  final _farmName = TextEditingController();
  final _phone = TextEditingController();
  final _cpf = TextEditingController();
  final _street = TextEditingController();
  final _city = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _zip = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final breeder = ref.read(authNotifierProvider);
    if (breeder != null) _name.text = breeder.name;
  }

  @override
  void dispose() {
    _name.dispose();
    _farmName.dispose();
    _phone.dispose();
    _cpf.dispose();
    _street.dispose();
    _city.dispose();
    _stateCtrl.dispose();
    _zip.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    await ref.read(profilePictureProvider.notifier).save(File(picked.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await ref.read(profileProvider.notifier).activate(
            name: _name.text.trim(),
            phone: _phone.text.trim(),
            cpf: _cpf.text.trim().isEmpty ? null : _cpf.text.trim(),
            farmName: _farmName.text.trim().isEmpty ? null : _farmName.text.trim(),
            associations: _associations,
            pictureUrl: ref.read(profilePictureProvider).value?.path,
            directions: _street.text.trim(),
            zipCode: _zip.text.trim(),
            city: _city.text.trim(),
            state: _stateCtrl.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitação enviada! Aguarde a análise da equipe.'),
        ),
      );
      context.go(AppRoutes.profile);
    } catch (e, st) {
      debugPrint('ProfileVerificationScreen.activate error: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao enviar solicitação. Tente novamente.')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final picture = ref.watch(profilePictureProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Verificar Perfil')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            _SectionLabel('Foto de perfil'),
          const SizedBox(height: 16),
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                  backgroundImage:
                      picture != null ? FileImage(picture) : null,
                  child: picture == null
                      ? Icon(
                          Icons.person_rounded,
                          size: 52,
                          color: AppColors.primary.withValues(alpha: 0.4),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickPhoto,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _pickPhoto,
              child: const Text('Carregar foto'),
            ),
          ),
          const SizedBox(height: 20),
          _SectionLabel('Dados pessoais'),
          const SizedBox(height: 12),
          _Field(
            controller: _name,
            label: 'Nome completo',
            icon: Icons.person_outline_rounded,
            textCapitalization: TextCapitalization.words,
            validator: _required,
          ),
          const SizedBox(height: 16),
          _Field(
            controller: _farmName,
            label: 'Nome da fazenda (opcional)',
            icon: Icons.agriculture_outlined,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          _Field(
            controller: _phone,
            label: 'Telefone / WhatsApp',
            hint: '(00) 90000-0000',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: _required,
          ),
          const SizedBox(height: 28),
          _SectionLabel('Associações'),
            const SizedBox(height: 12),
            AssociationsPicker(
              onChanged: (list) => setState(() => _associations = list),
            ),
            const SizedBox(height: 28),
            _SectionLabel('CPF'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cpf,
              keyboardType: TextInputType.number,
              inputFormatters: [CpfInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'CPF',
                hintText: '000.000.000-00',
                prefixIcon: Icon(Icons.badge_outlined, size: 20),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Campo obrigatório';
                final digits = v.replaceAll(RegExp(r'\D'), '');
                if (digits.length != 11) return 'CPF inválido';
                return null;
              },
            ),
            const SizedBox(height: 28),
            _SectionLabel('Endereço'),
            const SizedBox(height: 12),
            AddressFormFields(
              streetController: _street,
              cityController: _city,
              stateController: _stateCtrl,
              zipController: _zip,
              required: true,
            ),
            const SizedBox(height: 36),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Enviar solicitação'),
            ),
          ],
        ),
      ),
    );
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null;
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.muted,
        letterSpacing: 0.4,
      ),
    );
  }
}

// ─── Field ────────────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.validator,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

