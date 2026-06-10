import 'package:flutter/material.dart';

import 'package:immo/src/features/rental/creation/wizards/create_listing.wizard.dart';
import 'package:immo/src/features/rental/creation/theme/themes/creation.theme.dart';
import 'package:immo/src/features/rental/creation/widgets/creation_shell.widget.dart';

/// Intro before 7-step wizard — mirrors `CreateListingScreen.tsx`.
class CreateListingScreen extends StatelessWidget {
  const CreateListingScreen({
    super.key,
    required this.onClose,
    this.onPublished,
  });

  final VoidCallback onClose;
  final VoidCallback? onPublished;

  static const _introSteps = [
    (
      'Étape 1',
      Icons.home_outlined,
      'Présentez votre bien',
      'Localisation, surface et caractéristiques',
    ),
    (
      'Étape 2',
      Icons.photo_library_outlined,
      'Mettez-le en valeur',
      'Photos et équipements qui le distinguent',
    ),
    (
      'Étape 3',
      Icons.payments_outlined,
      'Fixez le loyer',
      'Publiez votre annonce sur Mr Immo',
    ),
  ];

  Future<void> _saveAndExit(BuildContext context) async {
    final save = await showCreationSaveExitDialog(context);
    if (save == true && context.mounted) onClose();
  }

  void _startWizard(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => CreateListingWizard(
          onClose: () => Navigator.of(context).pop(),
          onPublished: onPublished,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CreationSaveExitHeader(onSaveAndExit: () => _saveAndExit(context)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                CreationTheme.spacingLg,
                CreationTheme.spacingLg,
                CreationTheme.spacingLg,
                CreationTheme.spacingXl,
              ),
              children: [
                const Text(
                  'C\'est facile de commencer sur Mr Immo',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: CreationTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: CreationTheme.spacingXl),
                for (var i = 0; i < _introSteps.length; i++) ...[
                  _IntroRow(step: _introSteps[i]),
                  if (i < _introSteps.length - 1)
                    const Divider(height: 32, color: CreationTheme.border),
                ],
                const SizedBox(height: CreationTheme.spacingXl),
                Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      gradient: CreationTheme.listingCtaGradient,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _startWizard(context),
                        borderRadius: BorderRadius.circular(25),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                          child: Text(
                            'Créer mon annonce',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
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
        ],
      ),
    );
  }
}

class _IntroRow extends StatelessWidget {
  const _IntroRow({required this.step});

  final (String label, IconData icon, String title, String description) step;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              step.$1,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E8),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(step.$2, size: 18, color: CreationTheme.listingGreen),
            ),
          ],
        ),
        const SizedBox(width: CreationTheme.spacingMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(step.$3, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                step.$4,
                style: const TextStyle(fontSize: 14, color: CreationTheme.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
