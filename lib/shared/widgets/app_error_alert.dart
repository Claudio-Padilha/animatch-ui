import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class AppErrorAlert extends StatelessWidget {
  const AppErrorAlert({super.key, required this.message});

  final String message;

  /// Convenience method — shows the alert as a dialog.
  static Future<void> show(BuildContext context, String message) {
    return showDialog<void>(
      context: context,
      builder: (_) => AppErrorAlert(message: message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      icon: const Icon(Icons.error_outline, color: AppColors.error, size: 32),
      title: const Text('Ops, algo deu errado'),
      content: Text(message, style: theme.textTheme.bodyMedium),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
