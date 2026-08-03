import 'package:flutter/material.dart';

import 'package:leadway/src/presentation/constants/leadway.brand.dart';

enum LeadwayToastType { success, error, info }

/// Leadway feedback — modal dialogs (replaces Sonner-style overlay toasts).
abstract final class LeadwayToast {
  LeadwayToast._();

  static Future<void> show(
    BuildContext context, {
    required String message,
    required LeadwayToastType type,
    String? title,
    String confirmLabel = 'OK',
  }) {
    if (!context.mounted) return Future.value();
    return showLeadwayResultDialog(
      context,
      title: title ?? _titleFor(type),
      message: message,
      type: type,
      confirmLabel: confirmLabel,
    );
  }

  static String _titleFor(LeadwayToastType type) => switch (type) {
        LeadwayToastType.success => 'Succès',
        LeadwayToastType.error => 'Erreur',
        LeadwayToastType.info => 'Information',
      };
}

Future<void> showLeadwayResultDialog(
  BuildContext context, {
  required String title,
  required String message,
  LeadwayToastType type = LeadwayToastType.info,
  String confirmLabel = 'OK',
  LeadwayPalette? brand,
}) {
  final palette = brand ?? LeadwayBrand.of(context);
  final (icon, iconColor, iconBg) = switch (type) {
    LeadwayToastType.success => (
        Icons.check_rounded,
        const Color(0xFF059669),
        const Color(0xFF059669).withValues(alpha: 0.12),
      ),
    LeadwayToastType.error => (
        Icons.error_outline_rounded,
        palette.danger,
        palette.danger.withValues(alpha: 0.12),
      ),
    LeadwayToastType.info => (
        Icons.info_outline_rounded,
        palette.primaryDark,
        palette.primarySoft.withValues(alpha: 0.55),
      ),
  };

  return showDialog<void>(
    context: context,
    barrierDismissible: type != LeadwayToastType.error,
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
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(dialogContext).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: palette.text,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w400,
                    fontSize: 13,
                    color: palette.muted,
                    height: 1.35,
                  ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(confirmLabel),
            ),
          ),
        ],
      );
    },
  );
}
