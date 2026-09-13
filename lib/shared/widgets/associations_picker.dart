import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/services/cloudinary_uploader.dart';
import '../../core/theme/app_theme.dart';
import '../../features/profile/providers/profile_provider.dart';
import '../domain/association.dart';
import '../domain/breeder_association.dart';

// ─── Public widget ────────────────────────────────────────────────────────────

class AssociationsPicker extends ConsumerStatefulWidget {
  const AssociationsPicker({
    super.key,
    this.initialValue = const [],
    required this.onChanged,
  });

  final List<BreederAssociation> initialValue;
  final ValueChanged<List<BreederAssociation>> onChanged;

  @override
  ConsumerState<AssociationsPicker> createState() => _AssociationsPickerState();
}

class _AssociationsPickerState extends ConsumerState<AssociationsPicker> {
  final List<_Entry> _entries = [];

  @override
  void initState() {
    super.initState();
    for (final a in widget.initialValue) {
      _entries.add(_Entry(
        code: a.code,
        name: a.name,
        initialText: a.registrationNumber ?? '',
        documentUrl: a.documentUrl,
      ));
    }
  }

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
                documentUrl: e.documentUrl,
              ))
          .toList(),
    );
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

  Future<void> _pickDocument(int index) async {
    final source = await _showSourceChooser();
    if (source == null) return;

    setState(() => _entries[index].isUploadingDocument = true);
    try {
      final url = await ref
          .read(cloudinaryUploaderProvider)
          .pickAndUpload(folder: 'breeder-documents', source: source);
      if (url != null) {
        setState(() => _entries[index].documentUrl = url);
        _notify();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar documento: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _entries[index].isUploadingDocument = false);
      }
    }
  }

  void _removeDocument(int index) {
    setState(() => _entries[index].documentUrl = null);
    _notify();
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
                  documentUrl: entry.documentUrl,
                  isUploadingDocument: entry.isUploadingDocument,
                  onRemove: () => _remove(i),
                  onChanged: (_) => _notify(),
                  onPickDocument: () => _pickDocument(i),
                  onRemoveDocument: () => _removeDocument(i),
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
    required this.documentUrl,
    required this.isUploadingDocument,
    required this.onRemove,
    required this.onChanged,
    required this.onPickDocument,
    required this.onRemoveDocument,
  });

  final String code;
  final TextEditingController controller;
  final String? documentUrl;
  final bool isUploadingDocument;
  final VoidCallback onRemove;
  final ValueChanged<String> onChanged;
  final VoidCallback onPickDocument;
  final VoidCallback onRemoveDocument;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Code chip
            Container(
              margin: const EdgeInsets.only(top: 14),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
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
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Campo obrigatório'
                    : null,
                decoration: InputDecoration(
                  labelText: 'Nº de registro',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
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
        ),
        const SizedBox(height: 8),
        _DocumentAttachment(
          documentUrl: documentUrl,
          isUploading: isUploadingDocument,
          onPick: onPickDocument,
          onRemove: onRemoveDocument,
        ),
      ],
    );
  }
}

// ─── Document attachment (carteirinha / CRG) ──────────────────────────────────

/// Lets the breeder attach a photo of the association's membership card
/// ("carteirinha") or an animal's Certificado de Registro Genealógico, as
/// evidence backing the registration number typed above.
class _DocumentAttachment extends StatelessWidget {
  const _DocumentAttachment({
    required this.documentUrl,
    required this.isUploading,
    required this.onPick,
    required this.onRemove,
  });

  final String? documentUrl;
  final bool isUploading;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    if (isUploading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: SizedBox(
          height: 16,
          width: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (documentUrl == null) {
      return TextButton.icon(
        onPressed: onPick,
        icon: const Icon(Icons.attach_file_rounded, size: 16),
        label: const Text('Anexar carteirinha ou certificado'),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    }

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: CachedNetworkImage(
            imageUrl: documentUrl!,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Documento anexado',
            style: TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ),
        TextButton(
          onPressed: onPick,
          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
          child: const Text('Trocar'),
        ),
        IconButton(
          onPressed: onRemove,
          icon: const Icon(Icons.delete_outline_rounded, size: 18),
          color: Colors.grey.shade500,
          tooltip: 'Remover documento',
          visualDensity: VisualDensity.compact,
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
  _Entry({
    required this.code,
    required this.name,
    String initialText = '',
    this.documentUrl,
  }) : controller = TextEditingController(text: initialText);

  final String code;
  final String name;
  final TextEditingController controller;
  String? documentUrl;
  bool isUploadingDocument = false;
}
