import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/services/cloudinary_uploader.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/domain/breeder_association.dart';
import '../../../shared/widgets/address_form_fields.dart';
import '../../../shared/widgets/associations_picker.dart';
import '../domain/breeder_profile.dart';
import '../providers/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _farmName;
  late final TextEditingController _cpf;
  late final TextEditingController _street;
  late final TextEditingController _city;
  late final TextEditingController _state;
  late final TextEditingController _zip;

  List<BreederAssociation> _associations = [];
  bool _isLoading = false;
  String? _pictureUrl;
  bool _isUploadingAvatar = false;

  Future<void> _pickPhoto() async {
    final source = await _showSourceChooser();
    if (source == null) return;
    setState(() => _isUploadingAvatar = true);
    try {
      final url = await ref
          .read(cloudinaryUploaderProvider)
          .pickAndUpload(folder: 'breeders', source: source);
      if (url != null && mounted) setState(() => _pictureUrl = url);
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<ImageSource?> _showSourceChooser() => showModalBottomSheet<ImageSource>(
        context: context,
        builder: (_) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Tirar foto'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Escolher da galeria'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

  @override
  void initState() {
    super.initState();
    ref.listenManual(currentBreederProvider, (_, next) {
      next.whenData((b) {
        ref.read(authNotifierProvider.notifier).updateBreeder(b);
        if (mounted) setState(() => _pictureUrl = b.avatarUrl);
      });
    });
    _pictureUrl = ref.read(authNotifierProvider)?.avatarUrl;
    final p = ref.read(profileProvider);
    _name = TextEditingController(text: p.name);
    _phone = TextEditingController(text: p.phone);
    _farmName = TextEditingController(text: p.farmName);
    _cpf = TextEditingController();
    _street = TextEditingController();
    _city = TextEditingController(text: p.city);
    _state = TextEditingController(text: p.state);
    _zip = TextEditingController();
    _associations = List.of(p.associations);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _farmName.dispose();
    _cpf.dispose();
    _street.dispose();
    _city.dispose();
    _state.dispose();
    _zip.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(profileProvider.notifier).updateProfile(
            name: _name.text.trim(),
            phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
            farmName:
                _farmName.text.trim().isEmpty ? null : _farmName.text.trim(),
            associations: _associations,
            pictureUrl: _pictureUrl,
            directions:
                _street.text.trim().isEmpty ? null : _street.text.trim(),
            zipCode: _zip.text.trim().isEmpty ? null : _zip.text.trim(),
            city: _city.text.trim().isEmpty ? null : _city.text.trim(),
            state: _state.text.trim().isEmpty ? null : _state.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil atualizado')),
      );
      context.go(AppRoutes.profile);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao salvar. Tente novamente.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: Text(
              'Salvar',
              style: GoogleFonts.inter(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            _AvatarSection(
              pictureUrl: _pictureUrl,
              isLoading: _isUploadingAvatar,
              onTap: _isUploadingAvatar ? null : _pickPhoto,
            ),
            const SizedBox(height: 28),
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
              controller: _phone,
              label: 'Telefone / WhatsApp',
              hint: '(00) 90000-0000',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            _Field(
              controller: _farmName,
              label: 'Nome da fazenda',
              icon: Icons.agriculture_outlined,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 28),
            _SectionLabel('Associações'),
            const SizedBox(height: 12),
            AssociationsPicker(
              initialValue: _associations,
              onChanged: (list) => setState(() => _associations = list),
            ),
            const SizedBox(height: 28),
            _SectionLabel('CPF'),
            const SizedBox(height: 12),
            _Field(
              controller: _cpf,
              label: 'CPF',
              hint: '000.000.000-00',
              icon: Icons.badge_outlined,
              readOnly: true,
            ),
            const SizedBox(height: 28),
            _SectionLabel('Endereço'),
            const SizedBox(height: 12),
            AddressFormFields(
              streetController: _street,
              cityController: _city,
              stateController: _state,
              zipController: _zip,
            ),
            const SizedBox(height: 28),
            _SectionLabel('Plano'),
            const SizedBox(height: 12),
            _PlanCard(profile: ref.watch(profileProvider)),
            const SizedBox(height: 36),
            FilledButton(
              onPressed: _isLoading ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Salvar alterações'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _isLoading ? null : () => context.go(AppRoutes.profile),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null;
}

// ─── Avatar section ───────────────────────────────────────────────────────────

class _AvatarSection extends StatelessWidget {
  const _AvatarSection({
    required this.pictureUrl,
    required this.isLoading,
    required this.onTap,
  });

  final String? pictureUrl;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.primary.withValues(alpha: 0.08),
            child: pictureUrl != null
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: pictureUrl!,
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 2),
                      errorWidget: (context, url, err) => Icon(
                        Icons.person_rounded,
                        size: 48,
                        color: AppColors.primary.withValues(alpha: 0.4),
                      ),
                    ),
                  )
                : Icon(
                    Icons.person_rounded,
                    size: 48,
                    color: AppColors.primary.withValues(alpha: 0.4),
                  ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.camera_alt_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
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
    this.readOnly = false,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      readOnly: readOnly,
      style: readOnly
          ? TextStyle(color: Theme.of(context).disabledColor)
          : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: readOnly,
        fillColor: readOnly ? Colors.grey.shade100 : null,
      ),
    );
  }
}

// ─── Plan card ────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.profile});

  final BreederProfile profile;

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
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFFD4A017),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                profile.plan,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Renova em ${profile.planRenewal}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
              child: const Text('Gerenciar plano'),
            ),
          ),
        ],
      ),
    );
  }
}

