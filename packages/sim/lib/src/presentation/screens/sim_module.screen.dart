import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import 'package:sim/src/core/constants/sim_api.constants.dart';
import 'package:sim/src/core/host/sim_host.bridge.dart';
import 'package:sim/src/data/errors/sim_api.exception.dart';
import 'package:sim/src/data/models/sim_catalogue.model.dart';
import 'package:sim/src/data/models/sim_confirm_payment.model.dart';
import 'package:sim/src/data/models/sim_devis.model.dart';
import 'package:sim/src/data/models/sim_assurance_card.model.dart';
import 'package:sim/src/data/models/sim_souscription.model.dart';
import 'package:sim/src/data/services/sim_api.service.dart';
import 'package:sim/src/data/services/sim_carte.service.dart';
import 'package:sim/src/data/storage/sim_assurance_card.store.dart';
import 'package:sim/src/presentation/constants/sim.brand.dart';
import 'package:sim/src/presentation/widgets/sim_assurance_card_flip.widget.dart';
import 'package:sim/src/presentation/widgets/sim_my_cards.view.dart';
import 'package:sim/src/presentation/widgets/sim_shared_widgets.dart';
import 'package:sim/src/presentation/widgets/sim_toast.widget.dart';
import 'package:sim/src/shared/utils/sim_peyapay_payment.util.dart';
import 'package:sim/src/shared/utils/sim_profile.util.dart';

/// Parcours SIM Assurances — 4 étapes (même structure que Leadway).
class SimModuleScreen extends StatefulWidget {
  const SimModuleScreen({super.key});

  @override
  State<SimModuleScreen> createState() => _SimModuleScreenState();
}

class _SimModuleScreenState extends State<SimModuleScreen> {
  static const _steps = ['Devis', 'Souscription', 'Paiement', 'Documents'];

  final _api = SimApiService();
  final _carteService = SimCarteService();
  final _picker = ImagePicker();
  final _uuid = const Uuid();

  int _step = 0;
  bool _loading = false;
  bool _catalogueLoading = true;

  List<SimProduitCatalogue> _catalogue = const [];
  String _produit = SimApiProducts.relaxmoto;
  String? _formule;
  int _nombrePeriodes = 1;

  SimDevisResult? _devis;
  String? _souscriptionId;
  int? _montantAPercevoir;
  String? _idempotencyCreate;
  String? _idempotencyConfirm;
  String? _paymentReference;

  bool _paid = false;
  String? _numeroPolice;
  String? _dateDebut;
  String? _dateFin;
  Uint8List? _cartePng;

  List<SimAssuranceCardRecord> _savedCards = const [];
  bool _viewingMyCards = false;

  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _telephoneCtrl = TextEditingController();
  String? _pieceIdentiteDataUrl;
  String? _selfieDataUrl;
  String? _pieceIdentiteName;
  String? _selfieName;

  @override
  void initState() {
    super.initState();
    _prefillFromSession();
    _loadCatalogue();
    unawaited(_loadSavedCards());
  }

  Future<void> _loadSavedCards() async {
    final cards = await SimAssuranceCardStore.loadAll();
    if (!mounted) return;
    setState(() {
      _savedCards = cards;
      if (cards.isNotEmpty && _step == 0 && !_paid) {
        _viewingMyCards = true;
      }
    });
  }

  Future<void> _persistActiveCard() async {
    final id = _souscriptionId;
    final police = _numeroPolice?.trim();
    if (id == null || id.isEmpty || police == null || police.isEmpty) return;

    final record = SimAssuranceCardRecord(
      id: id,
      souscriptionId: id,
      numeroPolice: police,
      productCode: _produit,
      productLabel: _productLabel,
      dateDebut: _dateDebut ?? '',
      dateFin: _dateFin ?? '',
      holderName: '${_prenomCtrl.text.trim()} ${_nomCtrl.text.trim()}'.trim(),
      primeAmount: _montantAPercevoir ?? _devis?.prime,
      paymentReference: _paymentReference,
      cartePngBase64: _cartePng != null ? base64Encode(_cartePng!) : null,
      savedAt: DateTime.now().toUtc().toIso8601String(),
    );
    await SimAssuranceCardStore.upsert(record);
    await _loadSavedCards();
  }

  Future<Uint8List?> _pngBytesForRecord(SimAssuranceCardRecord record) async {
    final cached = record.cartePngBytes;
    if (cached != null) return cached;

    if (record.souscriptionId.isEmpty) return null;
    try {
      final png = await _api.fetchCartePng(record.souscriptionId);
      final bytes = Uint8List.fromList(png);
      await SimAssuranceCardStore.upsert(
        record.copyWith(cartePngBase64: base64Encode(bytes)),
      );
      await _loadSavedCards();
      return bytes;
    } catch (_) {
      return null;
    }
  }

  void _showSavedCardDetails(SimAssuranceCardRecord record) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFFF8F8F8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SimAssuranceCardFlip(record: record),
              const SizedBox(height: 12),
              Text(
                record.validityLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700, color: SimBrand.textDark),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => unawaited(_exportSavedCardPdf(record)),
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                      label: const Text('PDF'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => unawaited(_shareSavedCardPdf(record)),
                      icon: const Icon(Icons.share_outlined, size: 18),
                      label: const Text('Partager'),
                      style: FilledButton.styleFrom(backgroundColor: SimBrand.primary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _exportSavedCardPdf(SimAssuranceCardRecord record) async {
    setState(() => _loading = true);
    try {
      final pngBytes = await _pngBytesForRecord(record);
      if (pngBytes == null) {
        await _showToast('Carte indisponible.', SimToastType.error);
        return;
      }
      final pdfBytes = await _carteService.buildPdfFromPng(
        pngBytes,
        numeroPolice: record.numeroPolice,
        productLabel: record.productLabel,
        dateDebut: record.dateDebut,
        dateFin: record.dateFin,
      );
      final fileName = _carteService.pdfFileName(record.numeroPolice, record.souscriptionId);
      final file = await _carteService.saveToDevice(pdfBytes, fileName);
      await _showToast('PDF enregistré : ${file.path}', SimToastType.success);
    } catch (e) {
      await _showToast('Erreur export PDF : $e', SimToastType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _shareSavedCardPdf(SimAssuranceCardRecord record) async {
    setState(() => _loading = true);
    try {
      final pngBytes = await _pngBytesForRecord(record);
      if (pngBytes == null) {
        await _showToast('Carte indisponible.', SimToastType.error);
        return;
      }
      final pdfBytes = await _carteService.buildPdfFromPng(
        pngBytes,
        numeroPolice: record.numeroPolice,
        productLabel: record.productLabel,
        dateDebut: record.dateDebut,
        dateFin: record.dateFin,
      );
      final fileName = _carteService.pdfFileName(record.numeroPolice, record.souscriptionId);
      final file = await _carteService.writeToTemp(pdfBytes, fileName);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf', name: fileName)],
        text: 'Carte SIM — ${record.numeroPolice}',
      );
    } catch (e) {
      await _showToast('Erreur partage : $e', SimToastType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _handleModuleBack() {
    if (_step > 0) {
      setState(() => _step -= 1);
      return;
    }
    if (_savedCards.isNotEmpty) {
      setState(() => _viewingMyCards = true);
      return;
    }
    SimHostBridge.exitModule(context);
  }

  List<SimProduitCatalogue> get _activeProducts => _catalogue
      .where((p) => p.actifPourPartenaire && SimApiProducts.subscriptionSupported.contains(p.code))
      .toList();

  SimProduitCatalogue? get _selectedProduct {
    for (final p in _activeProducts) {
      if (p.code == _produit) return p;
    }
    return _activeProducts.isNotEmpty ? _activeProducts.first : null;
  }

  List<SimFormuleOption> get _formuleOptions => _selectedProduct?.formuleOptions() ?? const [];

  String get _formuleLabel {
    for (final o in _formuleOptions) {
      if (o.value == _formule) return o.label;
    }
    return _formule ?? '—';
  }

  void _syncFormuleForProduct() {
    final options = _formuleOptions;
    if (options.isEmpty) {
      _formule = null;
      return;
    }
    if (_formule == null || !options.any((o) => o.value == _formule)) {
      _formule = options.first.value;
    }
  }

  Future<void> _loadCatalogue() async {
    if (!SimApiConfig.isConfigured) {
      if (mounted) {
        setState(() {
          _catalogueLoading = false;
          _syncFormuleForProduct();
        });
      }
      return;
    }

    try {
      final items = await _api.catalogue();
      if (!mounted) return;
      setState(() {
        _catalogue = items;
        if (_activeProducts.isNotEmpty &&
            !_activeProducts.any((p) => p.code == _produit)) {
          _produit = _activeProducts.first.code;
        }
        _syncFormuleForProduct();
        _catalogueLoading = false;
      });
    } on SimApiException catch (e) {
      if (mounted) {
        setState(() => _catalogueLoading = false);
        await _showToast(e.displayMessage, SimToastType.error);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _catalogueLoading = false);
        await _showToast('Impossible de charger le catalogue : $e', SimToastType.error);
      }
    }
  }

  Future<void> _prefillFromSession() async {
    final auth = SimHostBridge.auth;
    if (auth == null) return;

    try {
      if (!await auth.isSessionActive()) return;

      final phone = await auth.getPhone();
      final displayName = await auth.displayName();
      if (!mounted) return;

      if (phone != null && phone.trim().isNotEmpty && _telephoneCtrl.text.trim().isEmpty) {
        _telephoneCtrl.text = phone.trim();
      }

      final parts = SimProfileUtil.splitDisplayName(displayName);
      if (parts.nom != null && parts.nom!.trim().isNotEmpty && _nomCtrl.text.trim().isEmpty) {
        _nomCtrl.text = parts.nom!.trim();
      }
      if (parts.prenom != null && parts.prenom!.trim().isNotEmpty && _prenomCtrl.text.trim().isEmpty) {
        _prenomCtrl.text = parts.prenom!.trim();
      }

      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _telephoneCtrl.dispose();
    super.dispose();
  }

  String _formatAmount(int amount) {
    final s = amount.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final idxFromEnd = s.length - i;
      buf.write(s[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buf.write(' ');
    }
    return '${buf.toString()} FCFA';
  }

  String get _productLabel => switch (_produit) {
        SimApiProducts.relaxmoto => 'RelaxMoto',
        SimApiProducts.relaxauto => 'RelaxAuto',
        SimApiProducts.relaxaccidentsFraisMedicaux => 'RelaxAccidents',
        _ => 'SIM Assurances',
      };

  bool get _isMotoAuto => _selectedProduct?.isMotoAuto ?? false;

  Future<void> _showToast(String message, SimToastType type) {
    return SimToast.show(context, message: message, type: type);
  }

  String get _carteFileName => _carteService.fileName(_numeroPolice, _souscriptionId);

  String get _cartePdfFileName => _carteService.pdfFileName(_numeroPolice, _souscriptionId);

  Future<Uint8List?> _ensureCartePng() async {
    if (_cartePng != null) return _cartePng;

    final id = _souscriptionId;
    if (id == null || id.isEmpty) return null;

    try {
      final png = await _api.fetchCartePng(id);
      final bytes = Uint8List.fromList(png);
      if (mounted) setState(() => _cartePng = bytes);
      if (_numeroPolice != null && _numeroPolice!.isNotEmpty) {
        unawaited(_persistActiveCard());
      }
      return bytes;
    } catch (_) {
      return null;
    }
  }

  Future<void> _shareCarte() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final bytes = await _ensureCartePng();
      if (bytes == null) {
        await _showToast('Carte indisponible pour le moment.', SimToastType.error);
        return;
      }

      final fileName = _carteFileName;
      final file = await _carteService.writeToTemp(bytes, fileName);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png', name: fileName)],
        text: 'Ma carte de prise en charge SIM — ${_numeroPolice ?? ''}',
      );
    } catch (e) {
      await _showToast('Erreur partage : $e', SimToastType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveCarte() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final bytes = await _ensureCartePng();
      if (bytes == null) {
        await _showToast('Carte indisponible pour le moment.', SimToastType.error);
        return;
      }

      final fileName = _carteFileName;
      final file = await _carteService.saveToDevice(bytes, fileName);
      await _showToast('Carte enregistrée : ${file.path}', SimToastType.success);
    } catch (e) {
      await _showToast('Erreur enregistrement : $e', SimToastType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<Uint8List?> _buildCartePdfBytes(Uint8List pngBytes) async {
    final police = _numeroPolice?.trim();
    if (police == null || police.isEmpty) return null;

    return _carteService.buildPdfFromPng(
      pngBytes,
      numeroPolice: police,
      productLabel: _productLabel,
      dateDebut: _dateDebut,
      dateFin: _dateFin,
    );
  }

  Future<void> _shareCartePdf() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final pngBytes = await _ensureCartePng();
      if (pngBytes == null) {
        await _showToast('Carte indisponible pour le moment.', SimToastType.error);
        return;
      }

      final pdfBytes = await _buildCartePdfBytes(pngBytes);
      if (pdfBytes == null) {
        await _showToast('Numéro de police indisponible.', SimToastType.error);
        return;
      }

      final fileName = _cartePdfFileName;
      final file = await _carteService.writeToTemp(pdfBytes, fileName);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf', name: fileName)],
        text: 'Carte de prise en charge SIM (PDF) — ${_numeroPolice ?? ''}',
      );
    } catch (e) {
      await _showToast('Erreur export PDF : $e', SimToastType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveCartePdf() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final pngBytes = await _ensureCartePng();
      if (pngBytes == null) {
        await _showToast('Carte indisponible pour le moment.', SimToastType.error);
        return;
      }

      final pdfBytes = await _buildCartePdfBytes(pngBytes);
      if (pdfBytes == null) {
        await _showToast('Numéro de police indisponible.', SimToastType.error);
        return;
      }

      final fileName = _cartePdfFileName;
      final file = await _carteService.saveToDevice(pdfBytes, fileName);
      await _showToast('PDF enregistré : ${file.path}', SimToastType.success);
    } catch (e) {
      await _showToast('Erreur export PDF : $e', SimToastType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickImageSheet(bool isSelfie) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(isSelfie ? 'Prendre un selfie' : 'Prendre une photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(isSelfie, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choisir depuis la galerie'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(isSelfie, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(bool isSelfie, ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      maxWidth: 1600,
      imageQuality: 85,
      preferredCameraDevice: isSelfie ? CameraDevice.front : CameraDevice.rear,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (bytes.length > 2 * 1024 * 1024) {
      await _showToast('Image trop volumineuse (max 2 Mo).', SimToastType.error);
      return;
    }
    final ext = file.path.split('.').last.toLowerCase();
    final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
    final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';
    setState(() {
      if (isSelfie) {
        _selfieDataUrl = dataUrl;
        _selfieName = file.name;
      } else {
        _pieceIdentiteDataUrl = dataUrl;
        _pieceIdentiteName = file.name;
      }
    });
  }

  Future<void> _runDevis() async {
    if (!SimApiConfig.isConfigured) {
      await _showToast('Clé API manquante (SIM_API_KEY)', SimToastType.error);
      return;
    }
    if (_formule == null || _formule!.isEmpty) {
      await _showToast('Sélectionnez une formule disponible.', SimToastType.error);
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await _api.devis(
        SimDevisRequest(
          produit: _produit,
          formule: _formule!,
          nombrePeriodes: _isMotoAuto ? _nombrePeriodes : null,
        ),
      );
      setState(() => _devis = result);
      await _showToast('Devis calculé avec succès.', SimToastType.success);
    } on SimApiException catch (e) {
      await _showToast(e.displayMessage, SimToastType.error);
    } catch (e) {
      await _showToast('Erreur devis : $e', SimToastType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createSouscription() async {
    if (_devis == null) {
      await _showToast('Calculez d\'abord le devis.', SimToastType.error);
      return;
    }
    if (_nomCtrl.text.trim().isEmpty || _prenomCtrl.text.trim().isEmpty || _telephoneCtrl.text.trim().isEmpty) {
      await _showToast('Renseignez nom, prénom et téléphone.', SimToastType.error);
      return;
    }
    if (_pieceIdentiteDataUrl == null || _selfieDataUrl == null) {
      await _showToast('Pièce d\'identité et selfie obligatoires.', SimToastType.error);
      return;
    }

    setState(() => _loading = true);
    _idempotencyCreate ??= _uuid.v4();
    try {
      final result = await _api.createSouscription(
        SimSouscriptionRequest(
          produit: _produit,
          formule: _formule!,
          nombrePeriodes: _isMotoAuto ? _nombrePeriodes : null,
          prospect: SimProspect(
            nom: _nomCtrl.text.trim().toUpperCase(),
            prenom: _prenomCtrl.text.trim(),
            telephone: _telephoneCtrl.text.trim(),
          ),
          pieceIdentiteUrl: _pieceIdentiteDataUrl!,
          selfieUrl: _selfieDataUrl!,
        ),
        idempotencyKey: _idempotencyCreate!,
      );
      setState(() {
        _souscriptionId = result.id;
        _montantAPercevoir = result.montantAPercevoir;
      });
      await _showToast('Souscription créée — en attente de paiement.', SimToastType.success);
      setState(() => _step = 2);
    } on SimApiException catch (e) {
      await _showToast(e.displayMessage, SimToastType.error);
    } catch (e) {
      await _showToast('Erreur souscription : $e', SimToastType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _payAndConfirm() async {
    final amount = _montantAPercevoir ?? _devis?.prime;
    final id = _souscriptionId;
    if (amount == null || id == null) {
      await _showToast('Souscription invalide.', SimToastType.error);
      return;
    }

    setState(() => _loading = true);
    try {
      final paid = await SimPeyapayPaymentUtil.collectPremium(
        context,
        amount: amount,
        label: 'Prime $_productLabel',
        reference: id,
      );
      if (!paid || !mounted) {
        setState(() => _loading = false);
        return;
      }

      _paymentReference = 'PEYAPAY-${DateTime.now().millisecondsSinceEpoch}';
      _idempotencyConfirm ??= _uuid.v4();

      final confirm = await _api.confirmPayment(
        id,
        SimConfirmPaymentRequest(
          referencePaiement: _paymentReference!,
          montantPercu: amount,
          datePaiement: DateTime.now().toUtc().toIso8601String(),
        ),
        idempotencyKey: _idempotencyConfirm!,
      );

      setState(() {
        _paid = true;
        _numeroPolice = confirm.numeroPolice;
        _dateDebut = confirm.dateDebut;
        _dateFin = confirm.dateFin;
      });

      try {
        final png = await _api.fetchCartePng(id);
        if (mounted) setState(() => _cartePng = Uint8List.fromList(png));
      } catch (_) {}
      unawaited(_persistActiveCard());

      await _showToast('Paiement confirmé — police émise.', SimToastType.success);
      if (mounted) setState(() => _step = 3);
    } on SimApiException catch (e) {
      if (e.code == 'deja_confirmee') {
        setState(() => _paid = true);
        unawaited(_ensureCartePng());
        await _showToast('Paiement déjà confirmé.', SimToastType.info);
        if (mounted) setState(() => _step = 3);
      } else {
        await _showToast(e.displayMessage, SimToastType.error);
      }
    } catch (e) {
      await _showToast('Erreur paiement : $e', SimToastType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onPrimaryAction() async {
    if (_loading) return;

    if (_step == 0) {
      if (_devis == null) {
        await _runDevis();
      } else {
        await _prefillFromSession();
        setState(() => _step = 1);
      }
      return;
    }
    if (_step == 1) {
      await _createSouscription();
      return;
    }
    if (_step == 2) {
      if (_paid) {
        unawaited(_ensureCartePng());
        setState(() => _step = 3);
      } else {
        await _payAndConfirm();
      }
      return;
    }
    if (_step == 3) {
      SimHostBridge.exitModule(context);
    }
  }

  String get _primaryLabel {
    if (_loading) {
      return switch (_step) {
        2 => 'Traitement du paiement…',
        _ => 'Veuillez patienter…',
      };
    }
    return switch (_step) {
      0 => _devis == null ? 'Calculer le devis' : 'Continuer',
      1 => 'Confirmer la souscription',
      2 => _paid ? 'Continuer' : 'Payer avec Peya Pay',
      3 => 'Fermer la souscription',
      _ => 'Continuer',
    };
  }

  IconData _productIcon(String code) {
    final c = code.toLowerCase();
    if (c.contains('moto')) return Icons.two_wheeler_rounded;
    if (c.contains('auto')) return Icons.directions_car_rounded;
    if (c.contains('accident')) return Icons.health_and_safety_rounded;
    return Icons.shield_rounded;
  }

  String? _productTagline(String code) {
    final c = code.toLowerCase();
    if (c.contains('moto')) return 'Responsabilité civile moto';
    if (c.contains('auto')) return 'Votre véhicule protégé';
    if (c.contains('accident')) return 'Frais médicaux après accident';
    return null;
  }

  Widget _buildStepContent() {
    return switch (_step) {
      0 => _buildDevisStep(),
      1 => _buildSouscriptionStep(),
      2 => _buildPaymentStep(),
      3 => _buildDocumentsStep(),
      _ => _buildDocumentsStep(),
    };
  }

  Widget _buildDevisStep() {
    if (_catalogueLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: SimBrand.primary),
              SizedBox(height: 16),
              Text('Chargement des produits et formules…', style: TextStyle(color: SimBrand.textDark)),
            ],
          ),
        ),
      );
    }

    final products = _activeProducts;
    final formuleOptions = _formuleOptions;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 24),
      children: [
        const SimHeroCard(
          icon: Icons.calculate_outlined,
          title: 'Calcul de prime',
          subtitle: 'Choisissez le produit et obtenez votre devis SIM Assurances.',
        ),
        const SizedBox(height: 16),
        if (products.isEmpty)
          SimUnavailableCard(
            message: SimApiConfig.isConfigured
                ? 'Les produits SIM Assurances ne répondent pas. Vérifiez votre connexion.'
                : 'Le service SIM Assurances n’est pas encore configuré sur cette version.',
            onRetry: () {
              setState(() => _catalogueLoading = true);
              _loadCatalogue();
            },
          )
        else ...[
          const _SimSectionLabel('Choisissez votre assurance'),
          for (final p in products)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SimChoiceCard(
                selected: p.code == _produit,
                title: p.libelle.isNotEmpty ? p.libelle : p.code,
                subtitle: _productTagline(p.code),
                icon: _productIcon(p.code),
                onTap: () => setState(() {
                  _produit = p.code;
                  _devis = null;
                  _syncFormuleForProduct();
                }),
              ),
            ),
          const SizedBox(height: 12),
          _SimSectionLabel(_isMotoAuto ? 'Formule' : 'Variante'),
          if (formuleOptions.isEmpty)
            const Text(
              'Aucune formule disponible pour ce produit.',
              style: TextStyle(fontSize: 13, color: SimBrand.muted),
            )
          else
            for (final o in formuleOptions)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SimChoiceCard(
                  selected: o.value == _formule,
                  title: o.label,
                  icon: Icons.workspace_premium_outlined,
                  price: o.prime != null && o.prime! > 0 ? _formatAmount(o.prime!) : null,
                  onTap: () => setState(() {
                    _formule = o.value;
                    _devis = null;
                  }),
                ),
              ),
          if (_isMotoAuto) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 10, 10, 10),
              decoration: simCardDecoration(),
              child: SimStepper(
                label: 'Nombre de périodes',
                value: _nombrePeriodes,
                min: 1,
                max: 12,
                onChanged: (v) => setState(() {
                  _nombrePeriodes = v;
                  _devis = null;
                }),
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
        if (_devis != null) ...[
          SimResultCard(
            title: 'Prime à payer',
            value: _formatAmount(_devis!.prime),
            subtitle: 'Commission ${_formatAmount(_devis!.commissionMontant)} · '
                'À reverser ${_formatAmount(_devis!.montantAReverser)}',
          ),
          if (_devis!.delaiAttente72h) ...[
            const SizedBox(height: 12),
            const SimSuccessBanner(
              title: 'Délai d\'attente 72h',
              message: 'Couverture effective 72 heures après confirmation du paiement.',
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildSouscriptionStep() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 24),
      children: [
        const SimHeroCard(
          icon: Icons.person_outline,
          title: 'Informations du souscripteur',
          subtitle: 'KYC obligatoire — pièce d\'identité et selfie.',
        ),
        const SizedBox(height: 16),
        simCardSection(
          title: '1. Identité',
          children: [
            SimField(label: 'Nom', controller: _nomCtrl, hint: 'KOUAME'),
            const SizedBox(height: 12),
            SimField(label: 'Prénom', controller: _prenomCtrl, hint: 'Ama'),
            const SizedBox(height: 12),
            SimField(label: 'Téléphone', controller: _telephoneCtrl, hint: '+2250700000000', keyboard: TextInputType.phone),
          ],
        ),
        simCardSection(
          title: '2. Documents KYC',
          children: [
            SimUploadTile(
              icon: Icons.badge_outlined,
              label: 'Pièce d\'identité',
              fileName: _pieceIdentiteName,
              onTap: () => _pickImageSheet(false),
            ),
            SimUploadTile(
              icon: Icons.face_outlined,
              label: 'Selfie',
              fileName: _selfieName,
              onTap: () => _pickImageSheet(true),
            ),
          ],
        ),
        if (_devis != null)
          SimSummaryCard(
            rows: [
              ('Prime', _formatAmount(_devis!.prime)),
              ('Produit', _productLabel),
              ('Formule', _formuleLabel),
            ],
          ),
      ],
    );
  }

  Widget _buildPaymentStep() {
    final amount = _montantAPercevoir ?? _devis?.prime ?? 0;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 24),
      children: [
        const SimHeroCard(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Paiement de la prime',
          subtitle: 'Encaissement Peya Pay puis confirmation SIM Assurances.',
        ),
        const SizedBox(height: 16),
        SimResultCard(
          title: 'Montant à encaisser',
          value: _formatAmount(amount),
          subtitle: '$_productLabel — $_formuleLabel',
        ),
        const SizedBox(height: 16),
        simCardSection(
          title: '1. Moyen de paiement',
          children: [
            SimPaymentTile(
              selected: true,
              title: 'Peya Pay',
              subtitle: 'Portefeuille Mon Peya',
              icon: Icons.account_balance_wallet_outlined,
              onTap: () {},
            ),
          ],
        ),
        if (_paid)
          const SimSuccessBanner(
            title: 'Paiement validé !',
            message: 'Votre paiement a été confirmé auprès de SIM Assurances.',
          ),
      ],
    );
  }

  Widget _buildDocumentsStep() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 24),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: SimBrand.gradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Icon(Icons.verified_user, color: Colors.white, size: 48),
              const SizedBox(height: 12),
              const Text(
                'Assurance active',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                _numeroPolice ?? '—',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SimSummaryCard(
          rows: [
            ('Assureur', SimBrand.title),
            ('Produit', _productLabel),
            ('Prime', _formatAmount(_montantAPercevoir ?? _devis?.prime ?? 0)),
            ('Début', _dateDebut ?? '—'),
            ('Fin', _dateFin ?? '—'),
            ('Réf. paiement', _paymentReference ?? '—'),
          ],
        ),
        const SizedBox(height: 16),
        if (_cartePng != null) ...[
          const Text(
            'CARTE DE PRISE EN CHARGE',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: SimBrand.primary, letterSpacing: 0.5),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.memory(_cartePng!, fit: BoxFit.contain),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _saveCarte,
                  icon: const Icon(Icons.download_outlined, size: 18),
                  label: const Text('Enregistrer'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SimBrand.primary,
                    side: BorderSide(color: SimBrand.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _loading ? null : _shareCarte,
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: const Text('Partager'),
                  style: FilledButton.styleFrom(
                    backgroundColor: SimBrand.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _saveCartePdf,
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  label: const Text('PDF'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SimBrand.primary,
                    side: BorderSide(color: SimBrand.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _loading ? null : _shareCartePdf,
                  icon: const Icon(Icons.ios_share_outlined, size: 18),
                  label: const Text('Partager PDF'),
                  style: FilledButton.styleFrom(
                    backgroundColor: SimBrand.primaryDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ] else
          simCardSection(
            title: 'Documents',
            children: [
              const Text(
                'La carte sera disponible quelques instants après confirmation.',
                style: TextStyle(fontSize: 13, color: SimBrand.textDark),
              ),
              if (_souscriptionId != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _loading ? null : () => unawaited(_ensureCartePng()),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Actualiser la carte'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SimBrand.primary,
                    side: BorderSide(color: SimBrand.primary),
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_viewingMyCards) {
      return SimTheme(
        child: SimMyCardsView(
          cards: _savedCards,
          onBack: () {
            if (_step == 0 && !_loading) {
              SimHostBridge.exitModule(context);
            } else {
              setState(() => _viewingMyCards = false);
            }
          },
          onNewSubscription: () => setState(() => _viewingMyCards = false),
          onOpenCard: _showSavedCardDetails,
        ),
      );
    }

    final catalogueMissing =
        _step == 0 && !_catalogueLoading && _activeProducts.isEmpty;

    return SimTheme(
      child: Scaffold(
        backgroundColor: SimBrand.background,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SimHeroHeader(
              onBack: _handleModuleBack,
              productLabel: _productLabel,
              steps: _steps,
              current: _step,
              onOpenCards: _savedCards.isEmpty
                  ? null
                  : () => setState(() => _viewingMyCards = true),
            ),
            Expanded(
              child: SimSheet(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 380),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, a) => FadeTransition(
                    opacity: a,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0.08, 0),
                        end: Offset.zero,
                      ).animate(a),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: _buildStepContent(),
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: catalogueMissing
            ? null
            : SimBottomBar(
                label: _primaryLabel,
                loading: _loading,
                onPrimary: _onPrimaryAction,
              ),
      ),
    );
  }
}

class _SimSectionLabel extends StatelessWidget {
  const _SimSectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: SimBrand.textDark,
        ),
      ),
    );
  }
}
