import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

Future<bool?> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = 'Ya, Hapus',
  bool isDestructive = true,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: isDestructive
              ? FilledButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.white,
                )
              : null,
          child: Text(confirmText),
        ),
      ],
    ),
  );
}
