import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:immo/src/features/rental/auth/scopes/rental_session.scope.dart';
import 'package:immo/src/features/rental/models/create_tenant.draft.dart';
import 'package:immo/src/features/rental/models/rental.property.dart';
import 'package:immo/src/features/rental/creation/theme/themes/creation.theme.dart';
import 'package:immo/src/features/rental/creation/widgets/creation_shell.widget.dart';

/// 4-step tenant creation — mirrors rental-app `CreateTenantScreen`.
class CreateTenantWizard extends StatefulWidget {
  const CreateTenantWizard({
    super.key,
    required this.onClose,
    this.onCreated,
  });

  final VoidCallback onClose;
  final VoidCallback? onCreated;

  @override
  State<CreateTenantWizard> createState() => _CreateTenantWizardState();
}

class _CreateTenantWizardState extends State<CreateTenantWizard> {
  final _draft = CreateTenantDraft();
  final _page = PageController();
  int _step = 0;
  bool _submitting = false;
  bool _loadingProperties = true;
  List<RentalProperty> _properties = const [];
  bool _showContractPreview = false;

  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _cniCtrl;
  late final TextEditingController _birthCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _professionCtrl;
  late final TextEditingController _incomeCtrl;
  late final TextEditingController _rentCtrl;
  late final TextEditingController _leaseStartCtrl;
  late final TextEditingController _leaseEndCtrl;
  late final TextEditingController _paymentDayCtrl;

  @override
  void initState() {
    super.initState();
    _lastNameCtrl = TextEditingController();
    _firstNameCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _passwordCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _cniCtrl = TextEditingController();
    _birthCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _professionCtrl = TextEditingController();
    _incomeCtrl = TextEditingController();
    _rentCtrl = TextEditingController();
    _leaseStartCtrl = TextEditingController();
    _leaseEndCtrl = TextEditingController();
    _paymentDayCtrl = TextEditingController(text: '1');
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProperties());
  }

  @override
  void dispose() {
    _page.dispose();
    _lastNameCtrl.dispose();
    _firstNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    _cniCtrl.dispose();
    _birthCtrl.dispose();
    _addressCtrl.dispose();
    _professionCtrl.dispose();
    _incomeCtrl.dispose();
    _rentCtrl.dispose();
    _leaseStartCtrl.dispose();
    _leaseEndCtrl.dispose();
    _paymentDayCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProperties() async {
    try {
      final session = RentalSessionScope.of(context);
      final items = await session.api.properties.fetchProperties();
      if (!mounted) return;
      setState(() {
        _properties = items;
        _loadingProperties = false;
        if (_draft.propertyId == null && items.isNotEmpty) {
          _draft.propertyId = items.first.id;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _loadingProperties = false);
    }
  }

  void _syncDraft() {
    _draft.lastName = _lastNameCtrl.text;
    _draft.firstName = _firstNameCtrl.text;
    _draft.email = _emailCtrl.text;
    _draft.password = _passwordCtrl.text;
    _draft.phone = _phoneCtrl.text;
    _draft.nationalId = _cniCtrl.text;
    _draft.birthDate = _birthCtrl.text;
    _draft.address = _addressCtrl.text;
    _draft.profession = _professionCtrl.text;
    _draft.monthlyIncome = _incomeCtrl.text;
    _draft.monthlyRent = _rentCtrl.text;
    _draft.leaseStartDate = _leaseStartCtrl.text;
    _draft.leaseEndDate = _leaseEndCtrl.text;
    _draft.paymentDay = _paymentDayCtrl.text;
  }

  Future<void> _saveAndExit() async {
    final save = await showCreationSaveExitDialog(context);
    if (save == true && mounted) widget.onClose();
  }

  bool _validateStep(int step) {
    _syncDraft();
    switch (step) {
      case 0:
        if (_draft.lastName.trim().isEmpty ||
            _draft.firstName.trim().isEmpty ||
            _draft.email.trim().isEmpty ||
            _draft.password.length < 8) {
          _error('Nom, prénom, email et mot de passe (8+ car.) requis.');
          return false;
        }
        if (!_draft.email.contains('@')) {
          _error('Email invalide.');
          return false;
        }
        return true;
      case 1:
        if (_draft.phone.trim().length < 8 || _draft.nationalId.trim().isEmpty) {
          _error('Téléphone et CNI requis.');
          return false;
        }
        return true;
      case 2:
        if (_draft.propertyId == null ||
            _draft.monthlyRent.trim().isEmpty ||
            _draft.leaseStartDate.trim().isEmpty) {
          _error('Bien, loyer et date de début requis.');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _next() {
    if (!_validateStep(_step)) return;
    if (_step >= 3) return;
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

  Future<void> _pickPhoto(ImageSource source) async {
    final file = await ImagePicker().pickImage(source: source, imageQuality: 80);
    if (file == null) return;
    setState(() => _draft.photoPath = file.path);
  }

  Future<void> _pickPhotoSheet() async {
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
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galerie'),
              onTap: () {
                Navigator.pop(ctx);
                _pickPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_validateStep(0) || !_validateStep(1) || !_validateStep(2)) return;
    setState(() => _submitting = true);
    try {
      final session = RentalSessionScope.of(context);
      final userId = session.userId;
      if (userId == null || userId.isEmpty) throw Exception('Session invalide.');
      await session.api.tenants.createTenant(_draft, utilisateursId: userId);
      if (!mounted) return;
      await showCreationSuccessDialog(
        context,
        title: 'Succès !',
        message: 'Le locataire a été créé avec succès.',
      );
      widget.onCreated?.call();
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

  bool _nextEnabledFor(int step) => switch (step) {
        0 =>
          _lastNameCtrl.text.isNotEmpty &&
              _firstNameCtrl.text.isNotEmpty &&
              _emailCtrl.text.isNotEmpty &&
              _passwordCtrl.text.length >= 8,
        1 => _phoneCtrl.text.length >= 8 && _cniCtrl.text.isNotEmpty,
        2 =>
          !_loadingProperties &&
              _properties.isNotEmpty &&
              _draft.propertyId != null &&
              _rentCtrl.text.isNotEmpty &&
              _leaseStartCtrl.text.isNotEmpty,
        _ => true,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: PageView(
        controller: _page,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _buildStep(0, _stepPersonal()),
          _buildStep(1, _stepContact()),
          _buildStep(2, _stepProperty()),
          _buildStep(3, _stepPhoto(), isLast: true),
        ],
      ),
    );
  }

  Widget _buildStep(int stepIndex, Widget body, {bool isLast = false}) {
    return CreationStepShell(
      onSaveAndExit: _saveAndExit,
      onBack: _back,
      onNext: isLast ? _submit : _next,
      nextLabel: isLast ? 'Créer le locataire' : 'Suivant',
      nextEnabled: _nextEnabledFor(stepIndex),
      isTenant: true,
      loading: isLast && _submitting,
      headerBorder: true,
      body: body,
    );
  }

  Widget _stepPersonal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CreationFormHeader(
          title: 'Informations personnelles',
          subtitle: 'Étape 1 sur 4 • Informations de base',
        ),
        const SizedBox(height: CreationTheme.spacingLg),
        _idScanSection(),
        CreationTextField(label: 'Nom', controller: _lastNameCtrl, required: true, onChanged: (_) => setState(() {})),
        CreationTextField(label: 'Prénom(s)', controller: _firstNameCtrl, required: true, onChanged: (_) => setState(() {})),
        CreationTextField(
          label: 'Email',
          controller: _emailCtrl,
          required: true,
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) => setState(() {}),
        ),
        CreationTextField(
          label: 'Mot de passe',
          controller: _passwordCtrl,
          required: true,
          obscureText: true,
          helper: 'Min. 8 car., majuscule, minuscule, chiffre',
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _stepContact() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CreationFormHeader(
          title: 'Contact & pièce d\'identité',
          subtitle: 'Étape 2 sur 4 • Vérification',
        ),
        const SizedBox(height: CreationTheme.spacingLg),
        _idScanSection(),
        CreationTextField(
          label: 'Téléphone',
          controller: _phoneCtrl,
          required: true,
          keyboardType: TextInputType.phone,
          onChanged: (_) => setState(() {}),
        ),
        CreationTextField(label: 'CNI', controller: _cniCtrl, required: true, onChanged: (_) => setState(() {})),
        CreationTextField(
          label: 'Date de naissance (AAAA-MM-JJ)',
          controller: _birthCtrl,
          hint: 'Doit avoir 18 ans ou plus',
        ),
        CreationTextField(label: 'Adresse', controller: _addressCtrl, maxLines: 2),
        CreationTextField(label: 'Profession', controller: _professionCtrl),
        CreationTextField(
          label: 'Revenu mensuel (FCFA)',
          controller: _incomeCtrl,
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _stepProperty() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CreationFormHeader(
          title: 'Bien & conditions de location',
          subtitle: 'Étape 3 sur 4 • Contrat',
        ),
        const SizedBox(height: CreationTheme.spacingLg),
        if (_loadingProperties)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: CreationTheme.tenantGreen),
            ),
          )
        else if (_properties.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Aucun bien disponible. Créez d\'abord une annonce.',
              style: TextStyle(color: Color(0xFFF59E0B)),
            ),
          )
        else ...[
          const Text('Bien & statut', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _draft.propertyId,
            decoration: InputDecoration(
              labelText: 'Bien associé *',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: [
              for (final p in _properties)
                DropdownMenuItem(
                  value: p.id,
                  child: Text('${p.title.isNotEmpty ? p.title : p.address} — ${p.city}'),
                ),
            ],
            onChanged: (v) => setState(() => _draft.propertyId = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _draft.status,
            decoration: InputDecoration(
              labelText: 'Statut *',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: const [
              DropdownMenuItem(value: 'actif', child: Text('Actif')),
              DropdownMenuItem(value: 'inactif', child: Text('Inactif')),
              DropdownMenuItem(value: 'en_attente', child: Text('En attente')),
            ],
            onChanged: (v) => setState(() => _draft.status = v ?? 'actif'),
          ),
          const SizedBox(height: 20),
          const Text('Conditions de location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          CreationTextField(
            label: 'Loyer mensuel (FCFA)',
            controller: _rentCtrl,
            required: true,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
          DropdownButtonFormField<String>(
            initialValue: _draft.paymentFrequency,
            decoration: InputDecoration(
              labelText: 'Fréquence de paiement',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: const [
              DropdownMenuItem(value: 'daily', child: Text('Journalier')),
              DropdownMenuItem(value: 'monthly', child: Text('Mensuel')),
              DropdownMenuItem(value: 'yearly', child: Text('Annuel')),
            ],
            onChanged: (v) => setState(() => _draft.paymentFrequency = v ?? 'monthly'),
          ),
          const SizedBox(height: 8),
          CreationTextField(
            label: 'Début du bail (AAAA-MM-JJ)',
            controller: _leaseStartCtrl,
            required: true,
            onChanged: (_) => setState(() {}),
          ),
          CreationTextField(
            label: 'Fin du bail (AAAA-MM-JJ)',
            controller: _leaseEndCtrl,
          ),
          CreationTextField(
            label: 'Jour de paiement (1-31)',
            controller: _paymentDayCtrl,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => setState(() => _showContractPreview = !_showContractPreview),
            child: Text(_showContractPreview ? 'Masquer l\'aperçu' : 'Aperçu du contrat'),
          ),
          if (_showContractPreview)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(16),
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: CreationTheme.borderInput),
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFFF0F9FF),
              ),
              child: SingleChildScrollView(
                child: Text(
                  'Contrat de location\n'
                  'Locataire: ${_firstNameCtrl.text} ${_lastNameCtrl.text}\n'
                  'Loyer: ${_rentCtrl.text} FCFA\n'
                  'Période: ${_leaseStartCtrl.text} → ${_leaseEndCtrl.text.isEmpty ? '—' : _leaseEndCtrl.text}',
                  style: const TextStyle(fontSize: 13, height: 1.5),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _stepPhoto() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CreationFormHeader(
          title: 'Photo du locataire',
          subtitle: 'Étape 4 sur 4 • Photo (optionnel)',
        ),
        const SizedBox(height: 8),
        const Text(
          'Ajoutez une photo de profil pour le locataire.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: CreationTheme.textSecondary),
        ),
        const SizedBox(height: 24),
        Center(
          child: _draft.photoPath == null
              ? CreationDashedUpload(
                  height: 250,
                  icon: Icons.person_outline,
                  title: 'Ajouter une photo',
                  subtitle: 'Optionnel • Appuyez pour téléverser',
                  onTap: _pickPhotoSheet,
                )
              : Column(
                  children: [
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: CreationTheme.tenantGreen, width: 3),
                        image: DecorationImage(
                          image: FileImage(File(_draft.photoPath!)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(onPressed: _pickPhotoSheet, child: const Text('Changer la photo')),
                    TextButton(
                      onPressed: () => setState(() => _draft.photoPath = null),
                      child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _idScanSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: CreationTheme.spacingLg),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pièce d\'identité', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _idCardPlaceholder('Recto')),
              const SizedBox(width: 12),
              Expanded(child: _idCardPlaceholder('Verso')),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Scannez la CNI pour remplir automatiquement (bientôt)',
            style: TextStyle(fontSize: 12, color: CreationTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _idCardPlaceholder(String label) {
    return AspectRatio(
      aspectRatio: 1.586,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: CreationTheme.borderInput, width: 2, style: BorderStyle.solid),
        ),
        child: InkWell(
          onTap: () {},
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.document_scanner_outlined, color: Colors.grey.shade500),
              const SizedBox(height: 4),
              Text('Scanner $label', style: const TextStyle(fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}
