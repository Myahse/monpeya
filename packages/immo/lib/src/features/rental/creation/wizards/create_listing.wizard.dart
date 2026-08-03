import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:immo/src/features/rental/auth/scopes/rental_session.scope.dart';
import 'package:immo/src/features/rental/models/create_listing.draft.dart';
import 'package:immo/src/features/rental/creation/theme/themes/creation.theme.dart';
import 'package:immo/src/features/rental/creation/widgets/creation_shell.widget.dart';

typedef _Amenity = ({String id, String label, String emoji});

/// 7-step create listing — mirrors rental-app steps 1–7.
class CreateListingWizard extends StatefulWidget {
  const CreateListingWizard({super.key, required this.onClose, this.onPublished});

  final VoidCallback onClose;
  final VoidCallback? onPublished;

  @override
  State<CreateListingWizard> createState() => _CreateListingWizardState();
}

class _CreateListingWizardState extends State<CreateListingWizard> {
  final _draft = CreateListingDraft();
  final _page = PageController();
  int _step = 0;
  bool _submitting = false;
  bool _priceExpanded = false;
  bool _showTypeMenu = false;

  late final TextEditingController _addressCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _postalCtrl;
  late final TextEditingController _areaCtrl;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;

  static const _amenitySections = <(String title, String desc, List<_Amenity>)>[
    (
      'Commençons par l\'essentiel.',
      'Les besoins de base pour vos locataires.',
      [
        (id: 'wifi', label: 'WiFi', emoji: '📶'),
        (id: 'tv', label: 'TV', emoji: '📺'),
        (id: 'kitchen', label: 'Cuisine', emoji: '🍳'),
        (id: 'washer', label: 'Lave-linge', emoji: '🧺'),
        (id: 'ac', label: 'Climatisation', emoji: '❄️'),
        (id: 'heating', label: 'Chauffage', emoji: '🔥'),
        (id: 'parking', label: 'Parking', emoji: '🚗'),
        (id: 'elevator', label: 'Ascenseur', emoji: '🛗'),
        (id: 'gym', label: 'Salle de sport', emoji: '💪'),
      ],
    ),
    (
      'Ce qui fait la différence.',
      'Les équipements qui se démarquent.',
      [
        (id: 'pool', label: 'Piscine', emoji: '🏊'),
        (id: 'hot_tub', label: 'Jacuzzi', emoji: '🛁'),
        (id: 'pool_table', label: 'Billard', emoji: '🎱'),
        (id: 'piano', label: 'Piano', emoji: '🎹'),
        (id: 'fireplace', label: 'Cheminée', emoji: '🔥'),
        (id: 'balcony', label: 'Balcon', emoji: '🌅'),
        (id: 'garden', label: 'Jardin', emoji: '🌷'),
        (id: 'bbq', label: 'Barbecue', emoji: '🍖'),
        (id: 'workspace', label: 'Bureau', emoji: '💻'),
      ],
    ),
    (
      'La sécurité.',
      'Équipements de sécurité importants.',
      [
        (id: 'smoke_detector', label: 'Détecteur fumée', emoji: '🚨'),
        (id: 'carbon_monoxide_detector', label: 'Détecteur CO', emoji: '⚠️'),
        (id: 'fire_extinguisher', label: 'Extincteur', emoji: '🧯'),
        (id: 'first_aid_kit', label: 'Trousse secours', emoji: '🏥'),
        (id: 'security_camera', label: 'Caméra', emoji: '📹'),
        (id: 'lockbox', label: 'Coffre à clés', emoji: '🔒'),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _priceCtrl = TextEditingController(text: '350000');
    _draft.price = '350000';
    _addressCtrl = TextEditingController();
    _cityCtrl = TextEditingController();
    _postalCtrl = TextEditingController();
    _areaCtrl = TextEditingController();
    _titleCtrl = TextEditingController();
    _descCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _page.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _postalCtrl.dispose();
    _areaCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveAndExit() async {
    final save = await showCreationSaveExitDialog(context);
    if (save == true && mounted) widget.onClose();
  }

  void _syncDraftFromControllers() {
    _draft.address = _addressCtrl.text;
    _draft.city = _cityCtrl.text;
    _draft.postalCode = _postalCtrl.text;
    _draft.superficie = _areaCtrl.text;
    _draft.title = _titleCtrl.text;
    _draft.description = _descCtrl.text;
    _draft.price = _priceCtrl.text;
  }

  bool _validateStep(int step) {
    _syncDraftFromControllers();
    switch (step) {
      case 1:
        if (_draft.address.trim().isEmpty || _draft.city.trim().isEmpty) {
          _error('Adresse et ville sont requises.');
          return false;
        }
        final area = double.tryParse(_draft.superficie);
        if (area == null || area < 10 || area > 10000) {
          _error('Surface entre 10 et 10 000 m² requise.');
          return false;
        }
        return true;
      case 3:
        if (_draft.photoPaths.length < 5) {
          _error('Sélectionnez au moins 5 photos.');
          return false;
        }
        return true;
      case 4:
        if (_draft.photoPaths.length < 5) {
          _error('Au moins 5 photos requises.');
          return false;
        }
        return true;
      case 5:
        if (_draft.title.trim().length < 3) {
          _error('Le nom doit contenir au moins 3 caractères.');
          return false;
        }
        return true;
      case 6:
        final amount = int.tryParse(_draft.price.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        if (amount < 1000) {
          _error('Le loyer minimum est de 1 000 FCFA.');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _next() {
    if (!_validateStep(_step)) return;
    if (_step >= 6) return;
    setState(() => _step += 1);
    _page.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
  }

  void _back() {
    if (_step == 0) {
      widget.onClose();
      return;
    }
    setState(() => _step -= 1);
    _page.previousPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
  }

  Future<void> _pickPhotos({ImageSource source = ImageSource.gallery}) async {
    final picker = ImagePicker();
    if (source == ImageSource.gallery) {
      final files = await picker.pickMultiImage(imageQuality: 80);
      if (files.isEmpty) return;
      setState(() {
        for (final f in files) {
          if (_draft.photoPaths.length < 99) _draft.photoPaths.add(f.path);
        }
      });
    } else {
      final file = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
      if (file == null) return;
      setState(() {
        if (_draft.photoPaths.length < 99) _draft.photoPaths.add(file.path);
      });
    }
  }

  Future<void> _showPhotoSourcePicker() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Appareil photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhotos(source: ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galerie'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhotos();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_validateStep(5) || !_validateStep(6)) return;
    setState(() => _submitting = true);
    try {
      final session = RentalSessionScope.of(context);
      await session.api.properties.createProperty(_draft, utilisateursId: session.userId);
      if (!mounted) return;
      await showCreationSuccessDialog(
        context,
        title: 'Bien créé !',
        message: 'Votre annonce a été publiée avec succès.',
        actionLabel: 'Voir mes biens',
      );
      widget.onPublished?.call();
      widget.onClose();
    } catch (e) {
      _error('$e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _error(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
    );
  }

  String get _nextLabel => switch (_step) {
        6 => 'Créer le bien',
        _ => 'Ça me va',
      };

  bool get _nextEnabled => switch (_step) {
        3 || 4 => _draft.photoPaths.length >= 5,
        _ => true,
      };

  @override
  Widget build(BuildContext context) {
    final theme = CreationTheme.of(context);
    return Scaffold(
      backgroundColor: theme.bg,
      body: PageView(
        controller: _page,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _stepType(),
          _stepLocation(),
          _stepAmenities(),
          _stepPhotos(),
          _stepPhotoOrder(),
          _stepDetails(),
          _stepPrice(),
        ],
      ),
    );
  }

  Widget _stepType() {
    final theme = CreationTheme.of(context);
    return CreationStepShell(
      onSaveAndExit: _saveAndExit,
      onBack: _back,
      onNext: _next,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CreationFormHeader(
            title: 'Quel type de bien souhaitez-vous louer ?',
            mandatoryHint: true,
          ),
          const SizedBox(height: CreationTheme.spacingLg),
          Center(
            child: Icon(
              _draft.propertyType == 'building' ? Icons.apartment : Icons.home_outlined,
              size: 120,
              color: CreationTheme.listingGreen.withValues(alpha: 0.35),
            ),
          ),
          const SizedBox(height: CreationTheme.spacingLg),
          InkWell(
            onTap: () => setState(() => _showTypeMenu = !_showTypeMenu),
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Type de bien *',
                labelStyle: TextStyle(color: theme.textSecondary),
                hintText: 'Sélectionnez un type',
                filled: true,
                fillColor: theme.card,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.borderInput),
                ),
                suffixIcon: Icon(
                  _showTypeMenu ? Icons.expand_less : Icons.expand_more,
                  color: theme.textSecondary,
                ),
              ),
              child: Text(
                _draft.propertyType == 'building' ? 'Immeuble' : 'Maison',
                style: TextStyle(fontSize: 16, color: theme.textPrimary),
              ),
            ),
          ),
          if (_showTypeMenu) ...[
            ListTile(
              title: const Text('Maison'),
              onTap: () => setState(() {
                _draft.propertyType = 'house';
                _showTypeMenu = false;
              }),
            ),
            ListTile(
              title: const Text('Immeuble'),
              onTap: () => setState(() {
                _draft.propertyType = 'building';
                _showTypeMenu = false;
              }),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'Cette information ne peut pas être modifiée après publication.',
            style: TextStyle(fontSize: 12, color: theme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _stepLocation() {
    final theme = CreationTheme.of(context);
    return CreationStepShell(
      onSaveAndExit: _saveAndExit,
      onBack: _back,
      onNext: _next,
      headerBorder: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CreationFormHeader(
            title: 'Où se situe votre bien ?',
            mandatoryHint: true,
          ),
          const SizedBox(height: CreationTheme.spacingMd),
          Text(
            'Indiquez l\'adresse et la surface du bien',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: theme.greenTint,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.map_outlined, size: 48, color: CreationTheme.listingGreen),
                const SizedBox(height: 8),
                Text(
                  'Carte — saisissez l\'adresse ci-dessous',
                  style: TextStyle(color: theme.textSecondary),
                ),
              ],
            ),
          ),
          CreationTextField(label: 'Adresse', controller: _addressCtrl, required: true),
          CreationTextField(label: 'Ville', controller: _cityCtrl, required: true),
          CreationTextField(label: 'Code postal', controller: _postalCtrl),
          CreationTextField(
            label: 'Surface (m²)',
            controller: _areaCtrl,
            required: true,
            keyboardType: TextInputType.number,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            tileColor: theme.surfaceMuted,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            title: Text(
              'Afficher l\'emplacement exact sur l\'annonce',
              style: TextStyle(color: theme.textPrimary),
            ),
            value: _draft.displayExactLocation,
            activeThumbColor: CreationTheme.listingGreen,
            onChanged: (v) => setState(() => _draft.displayExactLocation = v),
          ),
        ],
      ),
    );
  }

  Widget _stepAmenities() {
    final theme = CreationTheme.of(context);
    return CreationStepShell(
      onSaveAndExit: _saveAndExit,
      onBack: _back,
      onNext: _next,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CreationFormHeader(
            title: 'Qu\'offre votre logement ?',
            subtitle: 'Vous pourrez modifier les équipements après publication.',
          ),
          const SizedBox(height: CreationTheme.spacingLg),
          for (final section in _amenitySections) ...[
            Text(
              section.$1,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: theme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              section.$2,
              style: TextStyle(fontSize: 14, color: theme.textSecondary),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final a in section.$3) _amenityCard(a),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _amenityCard(_Amenity a) {
    final theme = CreationTheme.of(context);
    final selected = _draft.amenities.contains(a.id);
    return SizedBox(
      width: (MediaQuery.sizeOf(context).width - 56) / 2,
      child: Material(
        color: selected ? theme.surfaceMuted : theme.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? theme.textPrimary : theme.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: () => setState(() {
            if (selected) {
              _draft.amenities.remove(a.id);
            } else {
              _draft.amenities.add(a.id);
            }
          }),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(a.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    a.label,
                    style: TextStyle(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 14,
                      color: theme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepPhotos() {
    final theme = CreationTheme.of(context);
    return CreationStepShell(
      onSaveAndExit: _saveAndExit,
      onBack: _back,
      onNext: _next,
      nextEnabled: _nextEnabled,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CreationFormHeader(
            title: 'Ajoutez jusqu\'à 99 photos',
            mandatoryHint: true,
          ),
          const SizedBox(height: CreationTheme.spacingMd),
          CreationDashedUpload(onTap: _showPhotoSourcePicker),
          const SizedBox(height: 12),
          Text(
            'Sélectionnez au moins 5 photos *',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _draft.photoPaths.length >= 5 ? CreationTheme.listingGreen : theme.textSecondary,
            ),
          ),
          if (_draft.photoPaths.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Photos sélectionnées (${_draft.photoPaths.length}/99)',
              style: TextStyle(fontWeight: FontWeight.w600, color: theme.textPrimary),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.2,
              ),
              itemCount: _draft.photoPaths.length,
              itemBuilder: (_, i) => Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(File(_draft.photoPaths[i]), fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => setState(() => _draft.photoPaths.removeAt(i)),
                      child: const CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.red,
                        child: Icon(Icons.close, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stepPhotoOrder() {
    final theme = CreationTheme.of(context);
    return CreationStepShell(
      onSaveAndExit: _saveAndExit,
      onBack: _back,
      onNext: _next,
      nextEnabled: _nextEnabled,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CreationFormHeader(
            title: 'Vos photos',
            subtitle: 'Glissez pour réorganiser',
          ),
          const SizedBox(height: CreationTheme.spacingMd),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _draft.photoPaths.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                final item = _draft.photoPaths.removeAt(oldIndex);
                _draft.photoPaths.insert(newIndex, item);
              });
            },
            itemBuilder: (_, i) {
              return Container(
                key: ValueKey(_draft.photoPaths[i]),
                margin: const EdgeInsets.only(bottom: 8),
                height: 150,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(File(_draft.photoPaths[i]), fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.black54,
                        child: const Icon(Icons.drag_handle, color: Colors.white, size: 16),
                      ),
                    ),
                    if (i == 0)
                      const Positioned(
                        bottom: 8,
                        left: 8,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Text('Couverture', style: TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() => _draft.photoPaths.removeAt(i)),
                        child: const CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.red,
                          child: Icon(Icons.close, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _showPhotoSourcePicker,
            icon: const Icon(Icons.add),
            label: const Text('Ajouter des photos'),
          ),
          Text(
            '${_draft.photoPaths.length} photos • ${_draft.photoPaths.length < 5 ? 'Au moins 5 requises' : 'OK'}',
            style: TextStyle(
              fontSize: 13,
              color: _draft.photoPaths.length < 5 ? theme.error : theme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepDetails() {
    return CreationStepShell(
      onSaveAndExit: _saveAndExit,
      onBack: _back,
      onNext: _next,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CreationFormHeader(
            title: 'Donnez un nom à votre bien',
            subtitle: 'Un bon titre permet de se démarquer',
          ),
          const SizedBox(height: CreationTheme.spacingLg),
          CreationTextField(
            label: 'Nom du bien',
            controller: _titleCtrl,
            required: true,
            hint: 'Ex. Villa moderne à Cocody',
          ),
          CreationTextField(
            label: 'Description (recommandée)',
            controller: _descCtrl,
            maxLines: 5,
            hint: 'Décrivez ce qui rend votre bien unique',
          ),
        ],
      ),
    );
  }

  Widget _stepPrice() {
    final theme = CreationTheme.of(context);
    final amount = int.tryParse(_priceCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final formatted = amount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]} ',
        );

    return CreationStepShell(
      onSaveAndExit: _saveAndExit,
      onBack: _back,
      onNext: _submit,
      nextLabel: _nextLabel,
      loading: _submitting,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CreationFormHeader(
            title: 'Fixez votre loyer mensuel',
            subtitle: 'Montant en FCFA',
          ),
          const SizedBox(height: 32),
          Center(
            child: GestureDetector(
              onTap: () async {
                final result = await showDialog<String>(
                  context: context,
                  builder: (ctx) {
                    final ctrl = TextEditingController(text: _priceCtrl.text);
                    return AlertDialog(
                      title: const Text('Modifier le loyer'),
                      content: TextField(
                        controller: ctrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(suffixText: 'FCFA'),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, ctrl.text),
                          child: const Text('OK'),
                        ),
                      ],
                    );
                  },
                );
                if (result != null) {
                  setState(() => _priceCtrl.text = result.replaceAll(RegExp(r'[^0-9]'), ''));
                }
              },
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        formatted,
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          color: theme.textPrimary,
                          decoration: TextDecoration.underline,
                          decorationColor: CreationTheme.listingGreen,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Fcfa',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: theme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Appuyez sur le prix pour modifier',
                    style: TextStyle(color: theme.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          InkWell(
            onTap: () => setState(() => _priceExpanded = !_priceExpanded),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Voir le détail',
                  style: TextStyle(fontWeight: FontWeight.w600, color: theme.textPrimary),
                ),
                Icon(_priceExpanded ? Icons.expand_less : Icons.expand_more, color: theme.textPrimary),
              ],
            ),
          ),
          if (_priceExpanded) ...[
            const SizedBox(height: 16),
            _priceRow('Loyer de base', amount, theme: theme),
            _priceRow('Caution (1 mois)', amount, theme: theme),
            _priceRow('Frais plateforme (5 %)', (amount * 0.05).round(), theme: theme),
            Divider(color: theme.border),
            _priceRow('Revenu net estimé', (amount * 0.95).round(), bold: true, theme: theme),
          ],
        ],
      ),
    );
  }

  Widget _priceRow(String label, int value, {bool bold = false, required CreationPalette theme}) {
    final s = value.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]} ',
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                color: theme.textPrimary,
              ),
            ),
          ),
          Text(
            '$s Fcfa',
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: theme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
