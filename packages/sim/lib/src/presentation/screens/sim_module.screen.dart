import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
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
import 'package:sim/src/presentation/screens/sim_home.view.dart';
import 'package:sim/src/presentation/widgets/sim_assurance_card_flip.widget.dart';
import 'package:sim/src/presentation/widgets/sim_peyapay_logo.widget.dart';
import 'package:sim/src/presentation/widgets/sim_my_cards.view.dart';
import 'package:sim/src/presentation/widgets/sim_shared_widgets.dart';
import 'package:sim/src/presentation/widgets/sim_toast.widget.dart';
import 'package:sim/src/shared/utils/sim_idempotency.util.dart';
import 'package:sim/src/shared/utils/sim_peyapay_payment.util.dart';
import 'package:sim/src/shared/utils/sim_profile.util.dart';

/// Runs off the UI isolate — KYC images can be several MB before base64.
String simKycEncodeDataUrl((String mime, Uint8List bytes) input) {
  return 'data:${input.$1};base64,${base64Encode(input.$2)}';
}

/// Parcours SIM Assurances — 4 étapes (même structure que Leadway).
class SimModuleScreen extends StatefulWidget {
  const SimModuleScreen({super.key});

  @override
  State<SimModuleScreen> createState() => _SimModuleScreenState();
}

class _SimModuleScreenState extends State<SimModuleScreen> {
  static const _steps = ['Devis', 'Souscription', 'Paiement'];

  final _api = SimApiService();
  final _carteService = SimCarteService();
  final _picker = ImagePicker();
  final _uuid = const Uuid();

  int _step = 0;

  /// Product choice (SIM home) before the 4 steps.
  bool _choosing = true;
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
  String? _idempotencyCreateFingerprint;
  String? _idempotencyConfirm;
  String? _idempotencyConfirmFingerprint;
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
  Uint8List? _pieceIdentiteBytes;
  Uint8List? _selfieBytes;
  bool _kycImageBusy = false;

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
    setState(() => _savedCards = cards);
  }

  void _resetSubscriptionFlow() {
    _step = 0;
    _paid = false;
    _devis = null;
    _souscriptionId = null;
    _montantAPercevoir = null;
    _paymentReference = null;
    _numeroPolice = null;
    _dateDebut = null;
    _dateFin = null;
    _cartePng = null;
    _pieceIdentiteDataUrl = null;
    _selfieDataUrl = null;
    _pieceIdentiteBytes = null;
    _selfieBytes = null;
    _kycImageBusy = false;
    _resetCreateIdempotency();
    _resetConfirmIdempotency();
  }

  Future<void> _returnToSimHomeAfterSubscription({required String toastMessage}) async {
    await _persistActiveCard();
    if (!mounted) return;
    _resetSubscriptionFlow();
    setState(() {
      _choosing = true;
      _viewingMyCards = false;
    });
    await _showToast(toastMessage, SimToastType.success);
  }

  /// The policy being subscribed, as a card record.
  SimAssuranceCardRecord _activeRecord({String? id, String? police}) {
    final sid = id ?? _souscriptionId ?? '';
    return SimAssuranceCardRecord(
      id: sid,
      souscriptionId: sid,
      numeroPolice: police ?? _numeroPolice?.trim() ?? '',
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
  }

  Future<void> _persistActiveCard() async {
    final id = _souscriptionId;
    final police = _numeroPolice?.trim();
    if (id == null || id.isEmpty || police == null || police.isEmpty) return;

    final record = _activeRecord(id: id, police: police);
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
              SimAssuranceCardFlip(record: record, pngBytes: record.cartePngBytes),
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

  void _resetCreateIdempotency() {
    _idempotencyCreate = null;
    _idempotencyCreateFingerprint = null;
  }

  void _resetConfirmIdempotency() {
    _idempotencyConfirm = null;
    _idempotencyConfirmFingerprint = null;
  }

  String _idempotencyKeyForCreate(SimSouscriptionRequest request, {bool forceNew = false}) {
    final fingerprint = SimIdempotency.fingerprintJson(request.toJson());
    if (forceNew) {
      _idempotencyCreateFingerprint = fingerprint;
      _idempotencyCreate = _uuid.v4();
      return _idempotencyCreate!;
    }
    final key = SimIdempotency.resolveKey(
      currentKey: _idempotencyCreate,
      currentFingerprint: _idempotencyCreateFingerprint,
      fingerprint: fingerprint,
      newKey: _uuid.v4(),
    );
    _idempotencyCreate = key;
    _idempotencyCreateFingerprint = fingerprint;
    return key;
  }

  String _idempotencyKeyForConfirm(SimConfirmPaymentRequest request, {bool forceNew = false}) {
    final fingerprint = SimIdempotency.fingerprintJson(request.toJson());
    if (forceNew) {
      _idempotencyConfirmFingerprint = fingerprint;
      _idempotencyConfirm = _uuid.v4();
      return _idempotencyConfirm!;
    }
    final key = SimIdempotency.resolveKey(
      currentKey: _idempotencyConfirm,
      currentFingerprint: _idempotencyConfirmFingerprint,
      fingerprint: fingerprint,
      newKey: _uuid.v4(),
    );
    _idempotencyConfirm = key;
    _idempotencyConfirmFingerprint = fingerprint;
    return key;
  }

  void _handleModuleBack() {
    if (_step > 0) {
      setState(() => _step -= 1);
      return;
    }
    if (!_choosing) {
      setState(() => _choosing = true);
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
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _pickImage(isSelfie, ImageSource.camera);
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choisir depuis la galerie'),
              onTap: () {
                Navigator.pop(ctx);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _pickImage(isSelfie, ImageSource.gallery);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(bool isSelfie, ImageSource source) async {
    if (_kycImageBusy) return;
    setState(() => _kycImageBusy = true);
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 68,
        preferredCameraDevice: isSelfie ? CameraDevice.front : CameraDevice.rear,
      );
      if (file == null) return;
      if (!mounted) return;

      final bytes = await file.readAsBytes();
      if (!mounted) return;

      const maxBytes = 900 * 1024;
      if (bytes.length > maxBytes) {
        await _showToast('Image trop volumineuse (max 900 Ko). Réessayez avec moins de zoom.', SimToastType.error);
        return;
      }
      final ext = file.path.split('.').last.toLowerCase();
      final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
      final dataUrl = await compute(simKycEncodeDataUrl, (mime, bytes));
      if (!mounted) return;

      setState(() {
        if (isSelfie) {
          _selfieBytes = bytes;
          _selfieDataUrl = dataUrl;
        } else {
          _pieceIdentiteBytes = bytes;
          _pieceIdentiteDataUrl = dataUrl;
        }
      });
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[SIM] pickImage failed ($source): $e\n$st');
      }
      if (!mounted) return;
      final message = source == ImageSource.camera
          ? 'Impossible d\'ouvrir la caméra. Autorisez Caméra pour Mon Peya dans les réglages du téléphone, puis réessayez.'
          : 'Impossible d\'accéder à la galerie. Vérifiez les autorisations Photos.';
      await _showToast(message, SimToastType.error);
    } finally {
      if (mounted) setState(() => _kycImageBusy = false);
    }
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
      setState(() {
        _devis = result;
        _resetCreateIdempotency();
        _souscriptionId = null;
        _montantAPercevoir = null;
      });
      await _showToast('Devis calculé avec succès.', SimToastType.success);
    } on SimApiException catch (e) {
      await _showToast(e.displayMessage, SimToastType.error);
    } catch (e) {
      await _showToast('Erreur devis : $e', SimToastType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createSouscription({bool forceNewIdempotencyKey = false}) async {
    if (_devis == null) {
      await _showToast('Calculez d\'abord le devis.', SimToastType.error);
      return;
    }
    if (_nomCtrl.text.trim().isEmpty || _prenomCtrl.text.trim().isEmpty || _telephoneCtrl.text.trim().isEmpty) {
      await _showToast('Renseignez nom, prénom et téléphone.', SimToastType.error);
      return;
    }
    if (_pieceIdentiteBytes == null ||
        _selfieBytes == null ||
        _pieceIdentiteDataUrl == null ||
        _selfieDataUrl == null) {
      await _showToast('Pièce d\'identité et selfie obligatoires.', SimToastType.error);
      return;
    }

    setState(() => _loading = true);
    final request = SimSouscriptionRequest(
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
    );
    final idempotencyKey = _idempotencyKeyForCreate(request, forceNew: forceNewIdempotencyKey);
    try {
      final result = await _api.createSouscription(
        request,
        idempotencyKey: idempotencyKey,
      );
      setState(() {
        _souscriptionId = result.id;
        _montantAPercevoir = result.montantAPercevoir;
        _resetConfirmIdempotency();
      });
      await _showToast('Souscription créée — en attente de paiement.', SimToastType.success);
      setState(() => _step = 2);
    } on SimApiException catch (e) {
      if (!forceNewIdempotencyKey && SimIdempotency.isBodyMismatch(e)) {
        if (mounted) setState(() => _loading = false);
        await _createSouscription(forceNewIdempotencyKey: true);
        return;
      }
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
      final confirmRequest = SimConfirmPaymentRequest(
        referencePaiement: _paymentReference!,
        montantPercu: amount,
        datePaiement: DateTime.now().toUtc().toIso8601String(),
      );
      final confirmKey = _idempotencyKeyForConfirm(confirmRequest);

      final confirm = await _api.confirmPayment(
        id,
        confirmRequest,
        idempotencyKey: confirmKey,
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

      if (mounted) {
        await _returnToSimHomeAfterSubscription(
          toastMessage: 'Paiement confirmé — carte enregistrée dans Mes cartes.',
        );
      }
    } on SimApiException catch (e) {
      if (e.code == 'deja_confirmee') {
        setState(() => _paid = true);
        await _ensureCartePng();
        if (mounted) {
          await _returnToSimHomeAfterSubscription(
            toastMessage: 'Paiement déjà confirmé — carte disponible dans Mes cartes.',
          );
        }
      } else if (SimIdempotency.isBodyMismatch(e)) {
        _resetConfirmIdempotency();
        await _showToast(
          'Conflit d\'idempotence — réessayez de confirmer le paiement.',
          SimToastType.error,
        );
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
        await _returnToSimHomeAfterSubscription(
          toastMessage: 'Carte disponible dans Mes cartes.',
        );
      } else {
        await _payAndConfirm();
      }
      return;
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
      2 => _paid ? 'Retour à l\'accueil SIM' : 'Payer avec Peya Pay',
      _ => 'Continuer',
    };
  }

  String? get _amountLabel => switch (_step) {
        0 => _devis == null ? 'Prime estimée' : 'Prime à payer',
        1 || 2 => 'Montant à payer',
        _ => null,
      };

  String? get _amountText {
    if (_step == 0 && _devis == null) {
      final prime = _formuleOptions.where((o) => o.value == _formule).firstOrNull?.prime;
      if (prime == null || prime <= 0) return null;
      return _formatAmount(prime * (_isMotoAuto ? _nombrePeriodes : 1));
    }
    final amount = _montantAPercevoir ?? _devis?.prime;
    return amount == null ? null : _formatAmount(amount);
  }

  Widget _buildStepContent() {
    return switch (_step) {
      0 => _buildDevisStep(),
      1 => _buildSouscriptionStep(),
      2 => _buildPaymentStep(),
      _ => _buildPaymentStep(),
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

    final formuleOptions = _formuleOptions;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      children: [
        const SimHeroCard(
          icon: Icons.calculate_outlined,
          title: 'Calcul de prime',
          subtitle: 'Choisissez votre formule et obtenez votre devis immédiatement.',
        ),
        const SizedBox(height: 16),
        const SizedBox(height: 18),
        Text(
          _isMotoAuto ? 'Choisissez votre formule' : 'Choisissez votre variante',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        if (formuleOptions.isEmpty)
          const Text(
            'Aucune formule disponible pour ce produit.',
            style: TextStyle(fontSize: 13, color: SimBrand.muted),
          )
        else
          for (final (i, o) in formuleOptions.indexed)
            SimRise(
              delay: Duration(milliseconds: 60 * i),
              child: SimChoiceCard(
                selected: o.value == _formule,
                title: o.label,
                trailing: o.prime != null && o.prime! > 0 ? _formatAmount(o.prime!) : null,
                onTap: () => setState(() {
                  _formule = o.value;
                  _devis = null;
                  _resetCreateIdempotency();
                }),
              ),
            ),
        if (_isMotoAuto) ...[
          const SizedBox(height: 4),
          SimStepper(
            title: 'Durée',
            subtitle: '$_nombrePeriodes période${_nombrePeriodes > 1 ? 's' : ''} de couverture',
            value: _nombrePeriodes,
            min: 1,
            max: 12,
            onChanged: (v) => setState(() {
              _nombrePeriodes = v;
              _devis = null;
              _resetCreateIdempotency();
            }),
          ),
        ],
        const SizedBox(height: 14),
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
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
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
            SimKycDocumentPreview(
              label: 'Pièce d\'identité',
              icon: Icons.badge_outlined,
              imageBytes: _pieceIdentiteBytes,
              busy: _kycImageBusy,
              onTap: () => _pickImageSheet(false),
            ),
            const SizedBox(height: 12),
            SimKycDocumentPreview(
              label: 'Selfie',
              icon: Icons.face_outlined,
              imageBytes: _selfieBytes,
              previewHeight: 200,
              busy: _kycImageBusy,
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
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
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
              leading: const SimPeyapayLogo(),
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

  @override
  Widget build(BuildContext context) {
    if (_viewingMyCards) {
      return SimTheme(
        child: SimMyCardsView(
          cards: _savedCards,
          onBack: () => setState(() => _viewingMyCards = false),
          onNewSubscription: () => setState(() {
            _viewingMyCards = false;
            _choosing = true;
            _resetSubscriptionFlow();
            unawaited(_prefillFromSession());
          }),
          onOpenCard: _showSavedCardDetails,
        ),
      );
    }

    if (_choosing) {
      return SimTheme(
        child: SimHomeView(
          products: _activeProducts,
          loading: _catalogueLoading,
          configured: SimApiConfig.isConfigured,
          hasCards: _savedCards.isNotEmpty,
          onBack: _handleModuleBack,
          onOpenCards: () => setState(() => _viewingMyCards = true),
          onSelect: (p) => setState(() {
            _produit = p.code;
            _resetSubscriptionFlow();
            _syncFormuleForProduct();
            _choosing = false;
          }),
          onRetry: () {
            setState(() => _catalogueLoading = true);
            _loadCatalogue();
          },
        ),
      );
    }

    return SimTheme(
      child: Scaffold(
        backgroundColor: SimBrand.background,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SimHeader(
              onBack: _handleModuleBack,
              productLabel: _productLabel,
              steps: _steps,
              current: _step,
              trailing: _savedCards.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Mes cartes',
                      onPressed: () => setState(() => _viewingMyCards = true),
                      icon: const Icon(Icons.credit_card_rounded, color: Colors.white),
                    ),
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
                      position: Tween(begin: const Offset(0.06, 0), end: Offset.zero).animate(a),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(key: ValueKey(_step), child: _buildStepContent()),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: SimBottomBar(
          label: _primaryLabel,
          loading: _loading,
          onPrimary: _onPrimaryAction,
          amountLabel: _amountLabel,
          amount: _amountText,
          footnote: 'Payé avec\nPeya Pay',
        ),
      ),
    );
  }
}
