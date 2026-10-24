import 'package:flutter/material.dart';

import 'package:immo/src/core/constants/immo.brand.dart';

/// Bottom sheet in the Location frame (handle, bold title). Sheets open on the
/// app's navigator, above the module theme, so the accent is re-applied here.
Future<T?> showImmoSheet<T>(
  BuildContext context, {
  required String title,
  required WidgetBuilder builder,
}) {
  final palette = ImmoBrand.rentalOf(context);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: palette.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) => ImmoRentalTheme(
      accent: palette.primary,
      child: Builder(
        builder: (ctx) {
          final b = ImmoBrand.rentalOf(ctx);
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                24 + MediaQuery.viewInsetsOf(ctx).bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: b.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: b.text,
                      ),
                    ),
                    const SizedBox(height: 12),
                    builder(ctx),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

/// Yes/no confirmation in the module accent.
Future<bool> showImmoConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final accent = ImmoBrand.rentalOf(context).primary;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => ImmoRentalTheme(
      accent: accent,
      child: Builder(
        builder: (ctx) {
          final b = ImmoBrand.rentalOf(ctx);
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Annuler', style: TextStyle(color: b.text)),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(confirmLabel),
              ),
            ],
          );
        },
      ),
    ),
  );
  return ok ?? false;
}

/// Field label as in the Location forms (14, medium).
class ImmoFieldLabel extends StatelessWidget {
  const ImmoFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: b.text),
      ),
    );
  }
}

/// Text field decoration as in the Location forms (filled card, 8 radius).
InputDecoration immoFieldDecoration(
  BuildContext context, {
  String? hintText,
  String? suffixText,
}) {
  final b = ImmoBrand.rentalOf(context);
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: b.border),
  );
  return InputDecoration(
    hintText: hintText,
    suffixText: suffixText,
    filled: true,
    fillColor: b.card,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    border: border,
    enabledBorder: border,
  );
}
