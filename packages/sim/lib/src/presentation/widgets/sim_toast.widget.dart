import 'package:flutter/material.dart';
import 'package:sim/src/presentation/constants/sim.brand.dart';

enum SimToastType { success, error, info }

abstract final class SimToast {
  SimToast._();

  static Future<void> show(
    BuildContext context, {
    required String message,
    required SimToastType type,
    String? title,
    String confirmLabel = 'OK',
  }) {
    if (!context.mounted) return Future.value();
    return showSimResultDialog(
      context,
      title: title ?? _titleFor(type),
      message: message,
      type: type,
      confirmLabel: confirmLabel,
    );
  }

  static String _titleFor(SimToastType type) => switch (type) {
        SimToastType.success => 'Succès',
        SimToastType.error => 'Erreur',
        SimToastType.info => 'Information',
      };
}

Future<void> showSimResultDialog(
  BuildContext context, {
  required String title,
  required String message,
  SimToastType type = SimToastType.info,
  String confirmLabel = 'OK',
}) {
  final palette = SimBrand.of(context);
  final (icon, iconColor, iconBg) = switch (type) {
    SimToastType.success => (
        Icons.check_rounded,
        const Color(0xFF059669),
        const Color(0xFF059669).withValues(alpha: 0.12),
      ),
    SimToastType.error => (
        Icons.error_outline_rounded,
        palette.danger,
        palette.danger.withValues(alpha: 0.12),
      ),
    SimToastType.info => (
        Icons.info_outline_rounded,
        palette.primaryDark,
        palette.primarySoft.withValues(alpha: 0.55),
      ),
  };

  return showDialog<void>(
    context: context,
    barrierDismissible: type != SimToastType.error,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: palette.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: palette.muted, height: 1.35),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: palette.primaryDark,
                foregroundColor: palette.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(confirmLabel),
            ),
          ),
        ],
      );
    },
  );
}
