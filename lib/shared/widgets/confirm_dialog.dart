import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Shows a confirmation dialog and returns `true` if the user taps "Sim".
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String message,
  String title = 'Confirmar',
  String confirmLabel = 'Sim',
  String cancelLabel = 'Não',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => ConfirmDialog(
      message: message,
      title: title,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      destructive: destructive,
    ),
  );
  return result ?? false;
}

class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.message,
    this.title = 'Confirmar',
    this.confirmLabel = 'Sim',
    this.cancelLabel = 'Não',
    this.destructive = false,
  });

  final String message;
  final String title;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final confirmColor = destructive ? AppColors.error : AppColors.primary;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: theme.textTheme.titleMedium),
      content: Text(message, style: theme.textTheme.bodyMedium),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: confirmColor),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
