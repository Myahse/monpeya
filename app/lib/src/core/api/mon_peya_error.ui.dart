import 'package:flutter/material.dart';

import 'package:app/src/core/api/mon_peya_api.exception.dart';
import 'package:app/src/core/api/mon_peya_error.messages.dart';

Future<void> showMonPeyaErrorDialog(
  BuildContext context,
  Object error, {
  VoidCallback? onRetry,
}) async {
  if (!context.mounted) return;

  final title = MonPeyaErrorMessages.dialogTitleFor(error);
  final message = error is MonPeyaApiException
      ? MonPeyaErrorMessages.forException(error)
      : MonPeyaErrorMessages.forUnknown(error);

  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      final cs = Theme.of(dialogContext).colorScheme;
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 40,
                color: cs.primary,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    onRetry?.call();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF006D56),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(onRetry != null ? 'Réessayer' : 'OK'),
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Fermer'),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

String monPeyaUserMessage(Object error) {
  if (error is MonPeyaApiException) {
    return MonPeyaErrorMessages.forException(error);
  }
  return MonPeyaErrorMessages.forUnknown(error);
}
