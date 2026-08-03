import 'package:flutter/material.dart';

import 'package:immo/src/features/rental/creation/theme/themes/creation.theme.dart';

/// Top-left **Enregistrer et quitter** — RN `Save and exit`.
class CreationSaveExitHeader extends StatelessWidget {
  const CreationSaveExitHeader({
    super.key,
    required this.onSaveAndExit,
    this.showBorder = false,
  });

  final VoidCallback onSaveAndExit;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final child = SafeArea(
      bottom: false,
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: onSaveAndExit,
          child: const Text(
            'Enregistrer et quitter',
            style: TextStyle(
              color: CreationTheme.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
    if (!showBorder) return child;
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: child,
    );
  }
}

/// RN `FormHeader` — title + optional subtitle (tenant step progress).
class CreationFormHeader extends StatelessWidget {
  const CreationFormHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.mandatoryHint = false,
  });

  final String title;
  final String? subtitle;
  final bool mandatoryHint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: CreationTheme.textPrimary,
          ),
        ),
        if (mandatoryHint) ...[
          const SizedBox(height: 4),
          const Text(
            '*Informations obligatoires',
            style: TextStyle(fontSize: 12, color: CreationTheme.textMuted),
          ),
        ],
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: const TextStyle(fontSize: 14, color: CreationTheme.textSecondary),
          ),
        ],
      ],
    );
  }
}

/// RN footer: **Retour** text + green pill **Suivant** / **Ça me va**.
class CreationNavButtons extends StatelessWidget {
  const CreationNavButtons({
    super.key,
    required this.onBack,
    required this.onNext,
    this.nextLabel = 'Ça me va',
    this.nextEnabled = true,
    this.isTenant = false,
    this.loading = false,
  });

  final VoidCallback onBack;
  final VoidCallback onNext;
  final String nextLabel;
  final bool nextEnabled;
  final bool isTenant;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          CreationTheme.spacingLg,
          CreationTheme.spacingSm,
          CreationTheme.spacingLg,
          CreationTheme.spacingMd,
        ),
        child: Row(
          children: [
            TextButton(
              onPressed: onBack,
              child: const Text(
                'Retour',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: CreationTheme.textPrimary,
                ),
              ),
            ),
            const Spacer(),
            Opacity(
              opacity: nextEnabled ? 1 : 0.5,
              child: IgnorePointer(
                ignoring: !nextEnabled || loading,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    gradient: isTenant
                        ? CreationTheme.tenantCtaGradient
                        : CreationTheme.listingCtaGradient,
                    color: !nextEnabled ? CreationTheme.disabled : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onNext,
                      borderRadius: BorderRadius.circular(25),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 12,
                        ),
                        child: loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                nextLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen step shell: save header + scroll body + nav footer.
class CreationStepShell extends StatelessWidget {
  const CreationStepShell({
    super.key,
    required this.onSaveAndExit,
    required this.onBack,
    required this.onNext,
    required this.body,
    this.nextLabel = 'Ça me va',
    this.nextEnabled = true,
    this.isTenant = false,
    this.loading = false,
    this.headerBorder = false,
  });

  final VoidCallback onSaveAndExit;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final Widget body;
  final String nextLabel;
  final bool nextEnabled;
  final bool isTenant;
  final bool loading;
  final bool headerBorder;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CreationSaveExitHeader(
          onSaveAndExit: onSaveAndExit,
          showBorder: headerBorder,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              CreationTheme.spacingLg,
              CreationTheme.spacingLg,
              CreationTheme.spacingLg,
              96,
            ),
            child: body,
          ),
        ),
        CreationNavButtons(
          onBack: onBack,
          onNext: onNext,
          nextLabel: nextLabel,
          nextEnabled: nextEnabled,
          isTenant: isTenant,
          loading: loading,
        ),
      ],
    );
  }
}

/// Labeled bordered text field — RN `TenantInputField` style.
class CreationTextField extends StatelessWidget {
  const CreationTextField({
    super.key,
    required this.label,
    this.controller,
    this.onChanged,
    this.required = false,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.hint,
    this.helper,
  });

  final String label;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final bool required;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int maxLines;
  final String? hint;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: CreationTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: CreationTheme.textPrimary,
              ),
              children: [
                if (required)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: CreationTheme.error),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: keyboardType,
            obscureText: obscureText,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              helperText: helper,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: CreationTheme.borderInput),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: CreationTheme.borderInput),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dashed upload zone.
class CreationDashedUpload extends StatelessWidget {
  const CreationDashedUpload({
    super.key,
    required this.onTap,
    this.height = 200,
    this.icon = Icons.add_photo_alternate_outlined,
    this.title = 'Ajouter des photos',
    this.subtitle = 'PNG, JPG jusqu\'à 10 Mo',
  });

  final VoidCallback onTap;
  final double height;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CreationTheme.uploadBg,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: CreationTheme.borderInput, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: CreationTheme.textSecondary),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: CreationTheme.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

Future<bool?> showCreationSaveExitDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Enregistrer la progression ?'),
      content: const Text(
        'Votre progression sera enregistrée et vous pourrez continuer plus tard.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: CreationTheme.listingGreen),
          child: const Text('Enregistrer et quitter'),
        ),
      ],
    ),
  );
}

Future<void> showCreationSuccessDialog(
  BuildContext context, {
  required String title,
  required String message,
  String actionLabel = 'OK',
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: CreationTheme.listingGreen, size: 36),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          style: FilledButton.styleFrom(backgroundColor: CreationTheme.listingGreen),
          child: Text(actionLabel),
        ),
      ],
    ),
  );
}
