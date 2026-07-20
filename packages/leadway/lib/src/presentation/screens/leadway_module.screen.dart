import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

import 'package:leadway/src/core/constants/leadway_api.constants.dart';
import 'package:leadway/src/core/constants/leadway_life.constants.dart';
import 'package:leadway/src/core/host/leadway_host.bridge.dart';
import 'package:leadway/src/presentation/constants/leadway.brand.dart';
import 'package:leadway/src/data/models/leadway_api.exception.dart';
import 'package:leadway/src/data/models/leadway_premium_request.model.dart';
import 'package:leadway/src/data/models/leadway_premium_response.model.dart';
import 'package:leadway/src/data/services/leadway_api.service.dart';
import 'package:leadway/src/data/services/leadway_life_api.service.dart';
import 'package:leadway/src/data/services/leadway_pdf.service.dart';
import 'package:leadway/src/presentation/screens/leadway_life_recurring_payments.screen.dart';
import 'package:leadway/src/presentation/screens/leadway_life_subscription.screen.dart';
import 'package:leadway/src/presentation/screens/leadway_life_subscriptions.screen.dart';
import 'package:leadway/src/presentation/screens/leadway_pdf_viewer.screen.dart';
import 'package:leadway/src/presentation/widgets/leadway_toast.widget.dart';
import 'package:leadway/src/data/models/leadway_quote_request.model.dart';
import 'package:leadway/src/data/models/leadway_quote_response.model.dart';
import 'package:leadway/src/data/models/leadway_api_payment_init_request.model.dart';
import 'package:leadway/src/data/models/leadway_api_payment_request.model.dart';
import 'package:leadway/src/data/models/leadway_api_payment_check_request.model.dart';

enum LeadwayServiceType {
  none,
  life,
  nonLife,
}

/// Parcours assurance Leadway — 4 étapes.
class LeadwayModuleScreen extends StatefulWidget {
  const LeadwayModuleScreen({
    super.key,
    this.vehicleType = LeadwayVehicleType.moto,
  });

  final LeadwayVehicleType vehicleType;

  @override
  State<LeadwayModuleScreen> createState() => _LeadwayModuleScreenState();
}

class _LeadwayModuleScreenState extends State<LeadwayModuleScreen> {
  static const _steps = [
    'Calcule de prime',
    'Faire un devis',
    'Paiement',
    'Télécharger l\'assurance',
  ];

  int _step = 0;
  LeadwayServiceType _selectedService = LeadwayServiceType.none;
  List<LeadwayLifeEnumItem> _lifeProducts = [];
  bool _lifeProductsLoading = false;

  List<Map<String, dynamic>> _subscriptions = [];
  bool _viewingSubscriptions = false;
  final ScrollController _premiumScrollController = ScrollController();
  late LeadwayVehicleType _vehicleType;

  @override
  void initState() {
    super.initState();
    _vehicleType = widget.vehicleType;
    _codeProduit = LeadwayProductCode.tiersSimple;
    _categorieVehicule = _vehicleType == LeadwayVehicleType.auto
        ? LeadwayVehicleCategory.particular
        : LeadwayVehicleCategory.moto;
    _paymentOperator = LeadwayApiConfig.enablePeyaPay ? LeadwayPaymentOperator.peyapay : LeadwayPaymentOperator.orange;
    _loadSubscriptions();
    _prefillFromMonPeyaAuth();
  }

  Future<void> _prefillFromMonPeyaAuth() async {
    final auth = LeadwayHostBridge.auth;
    if (auth == null) return;

    try {
      final phone = await auth.getPhone();
      final name = await auth.displayName();
      if (!mounted) return;

      if (phone != null && phone.trim().isNotEmpty && _phoneNoCtrl.text.trim().isEmpty) {
        _phoneNoCtrl.text = _formatPhoneForLeadway(phone);
      }
      if (name != null && name.trim().isNotEmpty && _fullNameCtrl.text.trim().isEmpty) {
        _fullNameCtrl.text = name.trim();
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }

  static String _formatPhoneForLeadway(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= 10) {
      final local = digits.length > 10 ? digits.substring(digits.length - 10) : digits;
      return '+225 ${local.substring(0, 2)} ${local.substring(2, 4)} '
          '${local.substring(4, 6)} ${local.substring(6, 8)} ${local.substring(8)}';
    }
    return phone.trim();
  }

  Future<void> _loadSubscriptions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('leadway_subscriptions');
      if (data != null) {
        final List<dynamic> decoded = jsonDecode(data);
        setState(() {
          _subscriptions = decoded.map((item) {
            final map = Map<String, dynamic>.from(item as Map);
            if (map['firstDriveDate'] != null) {
              map['firstDriveDate'] = DateTime.parse(map['firstDriveDate'] as String);
            }
            return map;
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading subscriptions from prefs: $e');
    }

    // Injection du mock si aucune souscription sauvegardée et mode simulation activé.
    // NOTE: On ne sauvegarde PAS le mock pour éviter de corrompre les préférences
    // avec un DateTime non-sérialisable lors du premier lancement.
    if (_subscriptions.isEmpty && LeadwayApiConfig.useMock) {
      setState(() {
        _subscriptions = [
          {
            'id': 'mock-sub-1',
            'quoteNo': 'QT-MOTO-2026-10398',
            'fullName': 'KOFFI KOUADIO SÉBASTIEN',
            'email': 'koffi.sebastien@email.com',
            'phoneNo': '+225 07 48 93 28 10',
            'brand': 'YAMAHA',
            'model': 'TMAX 560',
            'carRegNo': '4839 GH 01',
            'premium': 68500,
            'firstDriveDate': DateTime.now().subtract(const Duration(days: 365)),
            'vehicleType': 'moto',
          },
          {
            'id': 'mock-sub-2',
            'quoteNo': 'QT-AUTO-2026-92841',
            'fullName': 'AMANI KOFFI BRUNO',
            'email': 'bruno.amani@email.com',
            'phoneNo': '+225 05 84 92 10 23',
            'brand': 'TOYOTA',
            'model': 'YARIS',
            'carRegNo': '9284 HK 01',
            'premium': 142000,
            'firstDriveDate': DateTime.now().subtract(const Duration(days: 730)),
            'vehicleType': 'auto',
          }
        ];
      });
    }

    // Afficher la liste si on a des souscriptions du type correspondant (toujours exécuté, même en cas d'erreur).
    final hasMatching = _subscriptions.any((sub) => (sub['vehicleType'] ?? 'moto') == _vehicleType.code);
    if (hasMatching) {
      setState(() {
        _viewingSubscriptions = true;
      });
    }
  }

  Future<void> _saveSubscriptions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> serialized = _subscriptions.map((sub) {
        final copy = Map<String, dynamic>.from(sub);
        if (copy['firstDriveDate'] != null) {
          copy['firstDriveDate'] = (copy['firstDriveDate'] as DateTime).toIso8601String();
        }
        return copy;
      }).toList();
      await prefs.setString('leadway_subscriptions', jsonEncode(serialized));
    } catch (e) {
      debugPrint('Error saving subscriptions: $e');
    }
  }

  final _brandCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _ageVehiculeCtrl = TextEditingController(text: '4');
  final _valeurInitialeCtrl = TextEditingController(); // Valeur à neuf
  final _valeurVenaleCtrl = TextEditingController();   // Valeur vénale

  int? _premium;
  LeadwayPremiumResult? _calcResult; // Cache calculated result
  bool _quoteConfirmed = false;
  bool _paid = false;
  String? _policyNumber;
  String? _contractPolicyNo;
  bool _loading = false;
  final _apiService = LeadwayApiService();
  final _pdfService = LeadwayPdfService();
  Uint8List? _cachedContractPdf;
  Uint8List? _cachedQuotePdf;

  // Devis subscriber & vehicle fields
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneNoCtrl = TextEditingController();
  final _carRegNoCtrl = TextEditingController();
  final _puissanceFiscaleCtrl = TextEditingController(text: '7');
  final _nombreDePlacesCtrl = TextEditingController(text: '5');
  DateTime? _firstDriveDate = DateTime.now().subtract(const Duration(days: 3 * 365));
  LeadwayEnergy _energieDevis = LeadwayEnergy.essence;

  // Payment variables
  String? _devisId;
  String? _paymentId;
  String? _paymentToken;
  String _paymentOperator = LeadwayPaymentOperator.peyapay;
  final _paymentPhoneCtrl = TextEditingController();
  final _paymentEmailCtrl = TextEditingController();
  final _paymentOtpCtrl = TextEditingController();
  DateTime? _paymentEffectDate = DateTime.now();
  bool _paymentInitiated = false;
  bool _paymentAwaitingOtp = false;
  bool _paymentPolling = false;
  Timer? _paymentPollTimer;
  int _paymentPollAttempts = 0;
  static const _maxPaymentPollAttempts = 120;

  int _dureeContratEnJour = 30;
  bool _garantieVol = true;
  bool _garantieIncendie = true;
  bool _garantieSecuriteRoutiere = true;
  int _garantieAssistanceAuto = 1;

  LeadwayProductCode _codeProduit = LeadwayProductCode.tiersSimple;
  LeadwayVehicleCategory _categorieVehicule = LeadwayVehicleCategory.moto;
  bool _isVehiculeVTC = false;
  bool _isGPS = false;
  bool _garantieVolAccessoires = false;
  bool _garantieBrisDeGlace = false;
  bool _garantieRecoursAnticipe = true;
  bool _isTransportHydro = false;
  bool _isTracteurRoutier = false;
  bool _withRecoursAnticipe = true;

  final _chargeUtileCtrl = TextEditingController(text: '3500');

  @override
  void dispose() {
    _premiumScrollController.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _ageVehiculeCtrl.dispose();
    _valeurInitialeCtrl.dispose();
    _valeurVenaleCtrl.dispose();
    _chargeUtileCtrl.dispose();
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneNoCtrl.dispose();
    _carRegNoCtrl.dispose();
    _puissanceFiscaleCtrl.dispose();
    _nombreDePlacesCtrl.dispose();
    _paymentPhoneCtrl.dispose();
    _paymentEmailCtrl.dispose();
    _paymentOtpCtrl.dispose();
    _paymentPollTimer?.cancel();
    super.dispose();
  }

  Future<void> _calculatePremium() async {
    final valeurInitiale = int.tryParse(_valeurInitialeCtrl.text.replaceAll(RegExp(r'\s'), '')) ?? 0;
    final valeurVenale = int.tryParse(_valeurVenaleCtrl.text.replaceAll(RegExp(r'\s'), '')) ?? 0;
    final ageVehicule = int.tryParse(_ageVehiculeCtrl.text.trim()) ?? 0;

    if (_ageVehiculeCtrl.text.trim().isNotEmpty) {
      final parsedAge = int.tryParse(_ageVehiculeCtrl.text.trim()) ?? -1;
      if (parsedAge < 0 || parsedAge > 100) {
        _showToast('Veuillez renseigner un âge de véhicule valide (0 à 100 ans).', LeadwayToastType.error);
        return;
      }
    }
    if (_valeurInitialeCtrl.text.replaceAll(RegExp(r'\s'), '').isNotEmpty) {
      final parsedInitiale = int.tryParse(_valeurInitialeCtrl.text.replaceAll(RegExp(r'\s'), '')) ?? -1;
      if (parsedInitiale <= 0) {
        _showToast('La valeur à neuf doit être supérieure à 0.', LeadwayToastType.error);
        return;
      }
    }
    if (_valeurVenaleCtrl.text.replaceAll(RegExp(r'\s'), '').isNotEmpty) {
      final parsedVenale = int.tryParse(_valeurVenaleCtrl.text.replaceAll(RegExp(r'\s'), '')) ?? -1;
      if (parsedVenale <= 0) {
        _showToast('La valeur vénale doit être supérieure à 0.', LeadwayToastType.error);
        return;
      }
    }

    setState(() => _loading = true);
    try {
      final request = LeadwayPremiumRequest.fromForm(
        ageVehicule: ageVehicule,
        valeurInitiale: valeurInitiale,
        valeurVenale: valeurVenale,
        codeProduit: _codeProduit,
        categorieVehicule: _categorieVehicule,
        dureeContratEnJour: _dureeContratEnJour,
        isVehiculeVTC: _isVehiculeVTC,
        isGPS: _isGPS,
        garantieSecuriteRoutiere: _garantieSecuriteRoutiere,
        garantieAssistanceAuto: _garantieAssistanceAuto,
        garantieVol: _garantieVol,
        garantieVolAccessoires: _garantieVolAccessoires,
        garantieIncendie: _garantieIncendie,
        garantieBrisDeGlace: _garantieBrisDeGlace,
        garantieRecoursAnticipe: _garantieRecoursAnticipe,
        chargeUtile: int.tryParse(_chargeUtileCtrl.text.trim()) ?? 3500,
        isTransportHydro: _isTransportHydro,
        isTracteurRoutier: _isTracteurRoutier,
        withRecoursAnticipe: _withRecoursAnticipe,
      );

      final result = await _apiService.calculatePremium(request);
      setState(() {
        _premium = result.primeTtc;
        _calcResult = result;
      });
      _showToast('Prime calculée avec succès !', LeadwayToastType.success);
      FocusScope.of(context).unfocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_premiumScrollController.hasClients) {
          _premiumScrollController.animateTo(
            _premiumScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
          );
        }
      });
    } on LeadwayApiException catch (e) {
      _showToast(e.displayMessage, LeadwayToastType.error);
    } catch (e) {
      _showToast('Erreur lors du calcul de la prime : $e', LeadwayToastType.error);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _confirmQuote() async {
    if (_premium == null || _calcResult == null) {
      _showToast('Calculez d\'abord la prime.', LeadwayToastType.error);
      return;
    }
    if (_brandCtrl.text.trim().isEmpty) {
      _showToast('Veuillez renseigner la marque du véhicule.', LeadwayToastType.error);
      return;
    }
    if (_modelCtrl.text.trim().isEmpty) {
      _showToast('Veuillez renseigner le modèle du véhicule.', LeadwayToastType.error);
      return;
    }
    if (_fullNameCtrl.text.trim().isEmpty) {
      _showToast('Veuillez renseigner le nom complet du souscripteur.', LeadwayToastType.error);
      return;
    }
    if (_emailCtrl.text.trim().isNotEmpty && !_emailCtrl.text.contains('@')) {
      _showToast('Veuillez renseigner une adresse e-mail valide.', LeadwayToastType.error);
      return;
    }
    if (_phoneNoCtrl.text.trim().isEmpty) {
      _showToast('Veuillez renseigner le numéro de téléphone.', LeadwayToastType.error);
      return;
    }
    if (_carRegNoCtrl.text.trim().isEmpty) {
      _showToast('Veuillez renseigner le numéro d\'immatriculation du véhicule.', LeadwayToastType.error);
      return;
    }
    if (_firstDriveDate == null) {
      _showToast('Veuillez renseigner la date de première mise en circulation.', LeadwayToastType.error);
      return;
    }
    if (_vehicleType == LeadwayVehicleType.auto) {
      final power = _puissanceFiscaleCtrl.text.trim();
      if (power.isEmpty || int.tryParse(power) == null || int.parse(power) <= 0) {
        _showToast('Veuillez renseigner une puissance fiscale valide.', LeadwayToastType.error);
        return;
      }
      final seats = int.tryParse(_nombreDePlacesCtrl.text.trim()) ?? 0;
      if (seats <= 0) {
        _showToast('Veuillez renseigner le nombre de places.', LeadwayToastType.error);
        return;
      }
    }

    final formatYMD = '${_firstDriveDate!.year}-'
        '${_firstDriveDate!.month.toString().padLeft(2, '0')}-'
        '${_firstDriveDate!.day.toString().padLeft(2, '0')}';

    setState(() => _loading = true);
    try {
      final request = LeadwayQuoteRequest(
        produit: _codeProduit.code,
        quoteType: 'motor',
        businessType: 'motor',
        fullName: _fullNameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phoneNo: _phoneNoCtrl.text.trim(),
        brand: _brandCtrl.text.trim(),
        model: _modelCtrl.text.trim(),
        power: _vehicleType == LeadwayVehicleType.auto
            ? _puissanceFiscaleCtrl.text.trim()
            : '0',
        energy: _vehicleType == LeadwayVehicleType.auto
            ? _energieDevis.code
            : LeadwayEnergy.essence.code,
        noOfSeat: _vehicleType == LeadwayVehicleType.auto
            ? int.parse(_nombreDePlacesCtrl.text.trim())
            : 2,
        firstDriveDate: formatYMD,
        vtc: _vehicleType == LeadwayVehicleType.auto && _isVehiculeVTC ? 1 : 0,
        carRegNo: _carRegNoCtrl.text.trim(),
        contractDuration: _dureeContratEnJour,
        quoteAmount: _calcResult!.quoteValues.detailsPrime.primeTtc,
        agentCode: '0',
        quoteValues: _calcResult!.quoteValues,
      );

      final response = await _apiService.createQuote(request);
      setState(() {
        _quoteConfirmed = true;
        _policyNumber = response.quoteNo;
        _devisId = response.id;
        if (_paymentEmailCtrl.text.trim().isEmpty) {
          _paymentEmailCtrl.text = _emailCtrl.text.trim();
        }
        _paymentEffectDate ??= DateTime.now();
      });
      _showToast('Devis enregistré sous le N° ${response.quoteNo}', LeadwayToastType.success);
    } on LeadwayApiException catch (e) {
      _showToast(e.displayMessage, LeadwayToastType.error);
    } catch (e) {
      _showToast('Erreur lors du devis : $e', LeadwayToastType.error);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _initiatePayment() async {
    if (_policyNumber == null || _premium == null) {
      _showToast('Informations de devis manquantes.', LeadwayToastType.error);
      return;
    }

    final isPeyaPay = _paymentOperator == LeadwayPaymentOperator.peyapay;
    if (!isPeyaPay && _paymentPhoneCtrl.text.trim().isEmpty) {
      _showToast('Veuillez saisir votre numéro de téléphone de paiement.', LeadwayToastType.error);
      return;
    }
    if (_paymentEmailCtrl.text.trim().isNotEmpty && !_paymentEmailCtrl.text.contains('@')) {
      _showToast('Veuillez renseigner une adresse e-mail valide pour le paiement.', LeadwayToastType.error);
      return;
    }
    if (_paymentEffectDate == null) {
      _showToast('Veuillez sélectionner la date d\'effet du contrat.', LeadwayToastType.error);
      return;
    }

    setState(() => _loading = true);
    try {
      final effectDate =
          '${_paymentEffectDate!.year}-${_paymentEffectDate!.month.toString().padLeft(2, '0')}-${_paymentEffectDate!.day.toString().padLeft(2, '0')}';

      final initRequest = LeadwayApiPaymentInitRequest(
        quoteNo: _policyNumber!,
        amount: _premium!,
        operator: _paymentOperator,
        phoneNo: isPeyaPay ? '' : _paymentPhoneCtrl.text.trim(),
        email: _paymentEmailCtrl.text.trim(),
        effectDate: effectDate,
        agentCode: LeadwayPaymentDefaults.agentCode,
        deliveryLocation: LeadwayPaymentDefaults.deliveryLocation,
      );

      debugPrint('[Leadway] Init paiement — requête: ${jsonEncode(initRequest.toJson())}');

      final initResult = await _apiService.initPayment(initRequest);

      debugPrint('[Leadway] Init paiement — retour: ${jsonEncode(initResult)}');

      final paymentId = _extractPaymentId(initResult);
      if (paymentId == null) {
        throw const LeadwayApiException(message: 'Identifiant de paiement manquant dans la réponse.');
      }
      final token = _extractPaymentToken(initResult);

      if (!mounted) return;
      setState(() {
        _paymentId = paymentId;
        _paymentToken = token;
        _paymentInitiated = true;
      });

      if (isPeyaPay || _paymentOperator == LeadwayPaymentOperator.wave) {
        await _confirmPayment();
        return;
      }

      setState(() => _paymentAwaitingOtp = true);
      _showToast(
        'Paiement initié. Composez #144*82# puis saisissez le code OTP reçu.',
        LeadwayToastType.success,
      );
    } on LeadwayApiException catch (e) {
      _showToast(e.displayMessage, LeadwayToastType.error);
    } catch (e) {
      _showToast('Erreur lors de l\'initialisation du paiement : $e', LeadwayToastType.error);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _confirmPayment() async {
    if (_paymentId == null) {
      _showToast('Paiement non initialisé.', LeadwayToastType.error);
      return;
    }

    final isOrange = _paymentOperator == LeadwayPaymentOperator.orange;
    if (isOrange && _paymentOtpCtrl.text.trim().isEmpty) {
      _showToast('Veuillez saisir le code OTP Orange Money.', LeadwayToastType.error);
      return;
    }

    setState(() => _loading = true);
    try {
      final isPeyaPay = _paymentOperator == LeadwayPaymentOperator.peyapay;

      await _apiService.confirmPayment(
        LeadwayApiPaymentRequest(
          paymentId: _paymentId!,
          operator: _paymentOperator,
          phoneNo: isPeyaPay ? '' : _paymentPhoneCtrl.text.trim(),
          otp: isOrange ? _paymentOtpCtrl.text.trim() : '',
          token: _paymentToken ?? '',
        ),
      );

      if (!mounted) return;
      setState(() {
        _paymentAwaitingOtp = false;
        _paymentPolling = true;
        _paymentPollAttempts = 0;
      });

      _showToast('Paiement confirmé. Vérification en cours…', LeadwayToastType.info);
      _startPaymentPolling();
    } on LeadwayApiException catch (e) {
      _showToast(e.displayMessage, LeadwayToastType.error);
    } catch (e) {
      _showToast('Erreur lors de la confirmation du paiement : $e', LeadwayToastType.error);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String? _extractPaymentId(Map<String, dynamic> result) {
    final direct = result['paymentId'] ?? result['payment_id'] ?? result['id'];
    if (direct != null && '$direct'.isNotEmpty) return '$direct';
    final data = result['data'];
    if (data is Map) {
      final nested = data['paymentId'] ?? data['payment_id'] ?? data['id'];
      if (nested != null && '$nested'.isNotEmpty) return '$nested';
    }
    return null;
  }

  String _extractPaymentToken(Map<String, dynamic> result) {
    final direct = result['token'];
    if (direct != null && '$direct'.isNotEmpty) return '$direct';
    final data = result['data'];
    if (data is Map) {
      final nested = data['token'];
      if (nested != null && '$nested'.isNotEmpty) return '$nested';
    }
    return _paymentToken ?? '';
  }

  bool _isPaymentSuccessful(Map<String, dynamic> result) {
    final status = result['status']?.toString().toUpperCase() ?? '';
    return status == 'SUCCESS' ||
        status == 'PAID' ||
        status == 'COMPLETED' ||
        result['paid'] == true ||
        result['success'] == true;
  }

  void _startPaymentPolling() {
    _paymentPollTimer?.cancel();
    _paymentPollTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      unawaited(_pollPaymentOnce());
    });
  }

  void _stopPaymentPolling() {
    _paymentPollTimer?.cancel();
    _paymentPollTimer = null;
  }

  void _resetPaymentFlow() {
    _stopPaymentPolling();
    setState(() {
      _paymentInitiated = false;
      _paymentAwaitingOtp = false;
      _paymentPolling = false;
      _paymentPollAttempts = 0;
      _paymentId = null;
      _paymentToken = null;
      _paymentOtpCtrl.clear();
    });
  }

  void _cancelPayment() {
    _resetPaymentFlow();
    _showToast('Paiement annulé. Choisissez un opérateur.', LeadwayToastType.info);
  }

  Future<void> _pollPaymentOnce() async {
    if (!mounted || _paid || _paymentId == null) return;

    _paymentPollAttempts++;
    if (_paymentPollAttempts > _maxPaymentPollAttempts) {
      _stopPaymentPolling();
      if (!mounted) return;
      setState(() => _paymentPolling = false);
      _showToast('Délai de vérification dépassé. Réessayez le paiement.', LeadwayToastType.error);
      return;
    }

    try {
      final result = await _apiService.checkPaymentStatus(
        LeadwayApiPaymentCheckRequest(paymentId: _paymentId!),
      );

      if (!_isPaymentSuccessful(result)) return;

      _stopPaymentPolling();
      if (!mounted) return;

      final policyNo = result['policyNo']?.toString();
      setState(() {
        _paid = true;
        _paymentPolling = false;
        if (policyNo != null && policyNo.isNotEmpty) {
          _contractPolicyNo = policyNo;
          _policyNumber = policyNo;
        }
      });
      debugPrint('[Leadway] Paiement validé — policyNo: ${policyNo ?? '—'}');
      _registerAndSaveActivePolicy();
      _showToast('Paiement validé avec succès !', LeadwayToastType.success);
      _next();
    } catch (e) {
      debugPrint('Erreur vérification paiement: $e');
    }
  }

  void _registerAndSaveActivePolicy() {
    final exists = _subscriptions.any((sub) => sub['quoteNo'] == _policyNumber);
    if (!exists) {
      final prefix = _vehicleType == LeadwayVehicleType.auto ? 'AUTO' : 'MOTO';
      setState(() {
        _subscriptions.add({
          'id': _devisId ?? 'sub-${DateTime.now().millisecondsSinceEpoch}',
          'quoteNo': _policyNumber ?? 'QT-$prefix-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch % 100000}',
          'policyNo': _contractPolicyNo ?? _policyNumber,
          'fullName': _fullNameCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'phoneNo': _phoneNoCtrl.text.trim(),
          'brand': _brandCtrl.text.trim(),
          'model': _modelCtrl.text.trim(),
          'carRegNo': _carRegNoCtrl.text.trim(),
          'premium': _premium ?? 35000,
          'firstDriveDate': _firstDriveDate ?? DateTime.now(),
          'vehicleType': _vehicleType.code,
        });
      });
      _saveSubscriptions();
    }
  }

  void _onVehicleTypeChanged(LeadwayVehicleType type) {
    setState(() {
      _vehicleType = type;
      _codeProduit = LeadwayProductCode.tiersSimple;
      _categorieVehicule = type == LeadwayVehicleType.auto
          ? LeadwayVehicleCategory.particular
          : LeadwayVehicleCategory.moto;
      _premium = null; // force recalculate
    });
  }

  void _showMessage(String text) {
    _showToast(text, LeadwayToastType.info);
  }

  void _showToast(String text, LeadwayToastType type) {
    if (mounted) {
      LeadwayToast.show(context, message: text, type: type);
    }
  }

  String? get _activePolicyNo => _contractPolicyNo ?? _policyNumber;

  Future<Uint8List> _fetchPdf(LeadwayPdfDocumentType type) async {
    final policyNo = _activePolicyNo;
    if (policyNo == null || policyNo.isEmpty) {
      throw const LeadwayApiException(message: 'Numéro de police indisponible.');
    }

    if (type == LeadwayPdfDocumentType.contract && _cachedContractPdf != null) {
      return _cachedContractPdf!;
    }
    if (type == LeadwayPdfDocumentType.quote && _cachedQuotePdf != null) {
      return _cachedQuotePdf!;
    }

    final bytes = type == LeadwayPdfDocumentType.contract
        ? await _apiService.downloadContractPdf(policyNo)
        : await _apiService.downloadQuotePdf(policyNo);

    if (type == LeadwayPdfDocumentType.contract) {
      _cachedContractPdf = bytes;
    } else {
      _cachedQuotePdf = bytes;
    }
    return bytes;
  }

  Future<void> _handlePdfDocument(LeadwayPdfDocumentType type, LeadwayPdfAction action) async {
    setState(() => _loading = true);
    try {
      final policyNo = _activePolicyNo;
      if (policyNo == null || policyNo.isEmpty) {
        _showToast('Numéro de police indisponible.', LeadwayToastType.error);
        return;
      }

      final bytes = await _fetchPdf(type);
      final fileName = type.fileName(policyNo);
      final title = type == LeadwayPdfDocumentType.contract ? 'Contrat d\'assurance' : 'Devis assurance';

      switch (action) {
        case LeadwayPdfAction.preview:
          if (!mounted) return;
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              fullscreenDialog: true,
              builder: (context) => LeadwayPdfViewerScreen(
                bytes: bytes,
                title: title,
                onShare: () => unawaited(_sharePdfBytes(type, bytes, fileName)),
                onSave: () => unawaited(_savePdfBytes(type, bytes, fileName)),
              ),
            ),
          );
        case LeadwayPdfAction.share:
          await _sharePdfBytes(type, bytes, fileName);
        case LeadwayPdfAction.save:
          await _savePdfBytes(type, bytes, fileName);
      }
    } on LeadwayApiException catch (e) {
      _showToast(e.displayMessage, LeadwayToastType.error);
    } catch (e) {
      _showToast('Erreur document : $e', LeadwayToastType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sharePdfBytes(LeadwayPdfDocumentType type, Uint8List bytes, String fileName) async {
    final file = await _pdfService.writeToTemp(bytes, fileName);
    final label = type == LeadwayPdfDocumentType.contract ? 'contrat' : 'devis';
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf', name: fileName)],
      text: 'Mon $label d\'assurance Leadway — ${_activePolicyNo ?? ''}',
    );
  }

  Future<void> _savePdfBytes(LeadwayPdfDocumentType type, Uint8List bytes, String fileName) async {
    final file = await _pdfService.saveToDevice(bytes, fileName);
    final label = type == LeadwayPdfDocumentType.contract ? 'Contrat' : 'Devis';
    _showToast('$label enregistré : ${file.path}', LeadwayToastType.success);
  }

  Future<void> _startDownloadAttestation() async {
    await _handlePdfDocument(LeadwayPdfDocumentType.contract, LeadwayPdfAction.share);
  }

  void _showDownloadSuccessDialog() {
    _registerAndSaveActivePolicy();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32), size: 48),
              ),
              const SizedBox(height: 20),
              const Text(
                'Téléchargement réussi !',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: LeadwayBrand.textDark),
              ),
              const SizedBox(height: 12),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(fontSize: 13, color: Color(0xFF666666), height: 1.4),
                  children: [
                    TextSpan(text: 'L\'attestation officielle de votre assurance ${_vehicleType.description.toLowerCase()} a été générée et enregistrée dans votre dossier de téléchargements sous le nom :\n\n'),
                    TextSpan(
                      text: 'attestation_${_policyNumber ?? (_vehicleType == LeadwayVehicleType.auto ? 'AUTO' : 'MOTO')}.pdf\n',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: LeadwayBrand.textDark, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFDDDDDD)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Fermer', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LeadwayBrand.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _openCertificateViewer();
                      },
                      child: const Text('Visualiser', style: TextStyle(fontWeight: FontWeight.bold)),
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

  void _openCertificateViewer() {
    unawaited(_handlePdfDocument(LeadwayPdfDocumentType.contract, LeadwayPdfAction.preview));
  }

  void _next() {
    if (_step < _steps.length - 1) {
      setState(() {
        final nextStep = _step + 1;
        if (nextStep == 2) {
          if (_paymentEmailCtrl.text.trim().isEmpty && _emailCtrl.text.trim().isNotEmpty) {
            _paymentEmailCtrl.text = _emailCtrl.text.trim();
          }
          _paymentEffectDate ??= DateTime.now();
        }
        _step = nextStep;
      });
    }
  }

  void _back() {
    if (_viewingSubscriptions) {
      setState(() {
        _selectedService = LeadwayServiceType.none;
      });
      return;
    }
    if (_step == 0) {
      final hasMatching = _subscriptions.any((sub) => (sub['vehicleType'] ?? 'moto') == _vehicleType.code);
      if (hasMatching) {
        setState(() {
          _viewingSubscriptions = true;
        });
      } else {
        setState(() {
          _selectedService = LeadwayServiceType.none;
        });
      }
      return;
    }
    setState(() => _step -= 1);
  }

  String _formatAmount(int amount) {
    final s = amount.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return '${buf.toString()} FCFA';
  }

  @override
  Widget build(BuildContext context) {
    switch (_selectedService) {
      case LeadwayServiceType.none:
        return _buildServiceSelectionView();
      case LeadwayServiceType.life:
        return _buildLifeInsuranceView();
      case LeadwayServiceType.nonLife:
        return _buildNonLifeView();
    }
  }

  Widget _buildNonLifeView() {
    if (_viewingSubscriptions) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F8F8),
        body: SafeArea(
          child: Column(
            children: [
              _SubscriptionsHeader(onBack: _back),
              Expanded(
                child: _SubscriptionsView(
                  subscriptions: _subscriptions
                      .where((sub) => (sub['vehicleType'] ?? 'moto') == _vehicleType.code)
                      .toList(),
                  onDownload: _downloadSubscription,
                  onView: _viewSubscription,
                  onNewPolicy: () {
                    _resetForm();
                    setState(() {
                      _viewingSubscriptions = false;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: Column(
          children: [
            _LeadwayHeader(onBack: _back, vehicleType: _vehicleType),
            _StepIndicator(
              steps: _steps,
              current: _step,
              onStepTapped: (index) {},
            ),
            Expanded(child: _buildStepContent()),
            _BottomBar(
              step: _step,
              maxStep: _steps.length - 1,
              primaryLabel: _primaryLabel(),
              onPrimary: _primaryAction,
              loading: _loading || _paymentPolling,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceSelectionView() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Retour',
                    onPressed: () => LeadwayHostBridge.exitModule(context),
                    icon: const Icon(Icons.chevron_left, color: LeadwayBrand.textDark),
                  ),
                  Image.asset(
                    'assets/logo/leadway.png',
                    package: 'leadway',
                    height: 40,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.shield_outlined,
                      color: LeadwayBrand.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Leadway Assurance',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: LeadwayBrand.textDark,
                          ),
                        ),
                        Text(
                          'Partenaire de votre sécurité',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      'Nos Solutions d\'Assurance',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: LeadwayBrand.textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sélectionnez une catégorie de service pour simuler vos cotisations et souscrire en toute simplicité.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Card 1: Non-Vie (Moto, Auto)
                    _buildSelectionCard(
                      title: 'Assurance Non-Vie',
                      subtitle: 'Auto & Moto',
                      description: 'Protégez vos véhicules contre les accidents, le vol et les incendies. Calculez votre prime et obtenez votre attestation instantanément.',
                      icon: Icons.two_wheeler_rounded,
                      badgeText: 'Disponible',
                      badgeColor: LeadwayBrand.primary,
                      onTap: () {
                        setState(() {
                          _selectedService = LeadwayServiceType.nonLife;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    // Card 2: Vie
                    _buildSelectionCard(
                      title: 'Assurance Vie',
                      subtitle: 'Famille, Épargne & Retraite',
                      description: 'Sécurisez l\'avenir de vos proches, financez l\'éducation de vos enfants et constituez-vous une épargne retraite sur mesure.',
                      icon: Icons.favorite_rounded,
                      badgeText: 'Nouveau',
                      badgeColor: Colors.blue[700]!,
                      onTap: () {
                        setState(() {
                          _selectedService = LeadwayServiceType.life;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionCard({
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required String badgeText,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: LeadwayBrand.primary.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        color: LeadwayBrand.primary,
                        size: 28,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        badgeText.toUpperCase(),
                        style: TextStyle(
                          color: badgeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: LeadwayBrand.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: LeadwayBrand.primary.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      'Accéder au service',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: LeadwayBrand.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: LeadwayBrand.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadLifeProducts() async {
    if (_lifeProducts.isNotEmpty || _lifeProductsLoading) return;
    setState(() => _lifeProductsLoading = true);
    try {
      final products = await LeadwayLifeApiService().fetchProductCodes();
      if (!mounted) return;
      setState(() {
        _lifeProducts = products.isNotEmpty
            ? products
            : LeadwayLifeProductCode.values
                .map((e) => LeadwayLifeEnumItem(value: e.code, description: e.label))
                .toList();
        _lifeProductsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _lifeProducts = LeadwayLifeProductCode.values
            .map((e) => LeadwayLifeEnumItem(value: e.code, description: e.label))
            .toList();
        _lifeProductsLoading = false;
      });
    }
  }

  void _openLifeSubscription(LeadwayLifeEnumItem product) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LeadwayLifeSubscriptionScreen(
          productCode: product.value,
          productLabel: product.description.isEmpty ? product.value : product.description,
        ),
      ),
    );
  }

  void _openLifeSubscriptions() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const LeadwayLifeSubscriptionsScreen(),
      ),
    );
  }

  void _openLifeRecurringPayments() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const LeadwayLifeRecurringPaymentsScreen(),
      ),
    );
  }

  IconData _lifeProductIcon(String code) {
    if (code.contains('FUNER')) return Icons.volunteer_activism_rounded;
    if (code.contains('BNB') || code.contains('EPARGNE')) return Icons.savings_outlined;
    return Icons.favorite_rounded;
  }

  String _lifeProductDescription(String code) {
    if (code == LeadwayLifeProductCode.funerairesDjogana.code) {
      return 'Couverture funérailles adaptée à votre famille. Souscrivez en quelques minutes.';
    }
    if (code == LeadwayLifeProductCode.bnbDjogana.code) {
      return 'Produit d\'épargne pour constituer un capital à votre rythme.';
    }
    return 'Souscrivez pour démarrer votre parcours Assurance Vie.';
  }

  Widget _buildLifeInsuranceView() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLifeProducts());

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Retour',
                    onPressed: () {
                      setState(() {
                        _selectedService = LeadwayServiceType.none;
                      });
                    },
                    icon: const Icon(Icons.chevron_left, color: LeadwayBrand.textDark),
                  ),
                  Image.asset(
                    'assets/logo/leadway.png',
                    package: 'leadway',
                    height: 40,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.favorite_rounded,
                      color: LeadwayBrand.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Assurance Vie',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: LeadwayBrand.textDark,
                          ),
                        ),
                        Text(
                          'Leadway Assurance',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _lifeProductsLoading && _lifeProducts.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: LeadwayBrand.primary))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LeadwayBrand.gradient,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: LeadwayBrand.primary.withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.family_restroom_rounded,
                                  color: Colors.white,
                                  size: 36,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Protégez ce qui compte le plus',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Choisissez un produit, souscrivez, puis calculez votre cotation.',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: _buildLifeQuickAction(
                                  icon: Icons.folder_shared_outlined,
                                  title: 'Souscriptions',
                                  onTap: _openLifeSubscriptions,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildLifeQuickAction(
                                  icon: Icons.autorenew,
                                  title: 'Paiements récurrents',
                                  onTap: _openLifeRecurringPayments,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Nos produits',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: LeadwayBrand.textDark,
                            ),
                          ),
                          const SizedBox(height: 16),
                          for (final product in _lifeProducts) ...[
                            _buildLifeProductCard(
                              title: product.description.isEmpty ? product.value : product.description,
                              description: _lifeProductDescription(product.value),
                              icon: _lifeProductIcon(product.value),
                              onPressed: () => _openLifeSubscription(product),
                            ),
                            const SizedBox(height: 14),
                          ],
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLifeQuickAction({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: Column(
            children: [
              Icon(icon, color: LeadwayBrand.primary, size: 26),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: LeadwayBrand.textDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLifeProductCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: LeadwayBrand.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: LeadwayBrand.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: LeadwayBrand.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LeadwayBrand.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onPressed: onPressed,
                      child: const Text(
                        'Souscrire',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _primaryLabel() {
    return switch (_step) {
      0 => _premium == null ? 'Calculer la prime' : 'Continuer',
      1 => _quoteConfirmed ? 'Continuer' : 'Confirmer le devis',
      2 => _paid
          ? 'Continuer'
          : _paymentPolling
              ? 'Vérification du paiement…'
              : _paymentAwaitingOtp
                  ? 'Confirmer avec OTP'
                  : 'Initier le paiement',
      _ => 'Fermer la souscription',
    };
  }

  Future<void> _primaryAction() async {
    if (_loading || _paymentPolling) return;
    if (_step == 0 && _premium == null) {
      await _calculatePremium();
      return;
    }
    if (_step == 1 && !_quoteConfirmed) {
      await _confirmQuote();
      if (_quoteConfirmed) _next();
      return;
    }
    if (_step == 2 && !_paid) {
      if (_paymentPolling) return;
      if (_paymentAwaitingOtp) {
        await _confirmPayment();
      } else {
        await _initiatePayment();
      }
      return;
    }
    if (_step == 3) {
      setState(() {
        _viewingSubscriptions = true;
      });
      return;
    }
    _next();
  }

  Widget _buildStepContent() {
    return switch (_step) {
      0 => _PremiumStep(
          scrollController: _premiumScrollController,
          ageVehiculeCtrl: _ageVehiculeCtrl,
          valeurInitialeCtrl: _valeurInitialeCtrl,
          valeurVenaleCtrl: _valeurVenaleCtrl,
          premium: _premium,
          formatAmount: _formatAmount,
          onRecalculate: () => setState(() => _premium = null),
          codeProduit: _codeProduit,
          categorieVehicule: _categorieVehicule,
          dureeContratEnJour: _dureeContratEnJour,
          isVehiculeVTC: _isVehiculeVTC,
          isGPS: _isGPS,
          garantieSecuriteRoutiere: _garantieSecuriteRoutiere,
          garantieAssistanceAuto: _garantieAssistanceAuto,
          garantieVol: _garantieVol,
          garantieVolAccessoires: _garantieVolAccessoires,
          garantieIncendie: _garantieIncendie,
          garantieBrisDeGlace: _garantieBrisDeGlace,
          garantieRecoursAnticipe: _garantieRecoursAnticipe,
          isTransportHydro: _isTransportHydro,
          isTracteurRoutier: _isTracteurRoutier,
          withRecoursAnticipe: _withRecoursAnticipe,
          onProduitChanged: (v) => setState(() {
            if (v != null) {
              _codeProduit = v;
              _premium = null;
            }
          }),
          onCategorieChanged: (v) => setState(() {
            if (v != null) {
              _categorieVehicule = v;
              _premium = null;
            }
          }),
          onDureeChanged: (v) => setState(() {
            _dureeContratEnJour = v;
            _premium = null;
          }),
          onVtcChanged: (v) => setState(() {
            _isVehiculeVTC = v;
            _premium = null;
          }),
          onGpsChanged: (v) => setState(() {
            _isGPS = v;
            _premium = null;
          }),
          onSecuriteChanged: (v) => setState(() {
            _garantieSecuriteRoutiere = v;
            _premium = null;
          }),
          onAssistanceChanged: (v) => setState(() {
            if (v != null) {
              _garantieAssistanceAuto = v;
              _premium = null;
            }
          }),
          onVolChanged: (v) => setState(() {
            _garantieVol = v;
            _premium = null;
          }),
          onVolAccessoiresChanged: (v) => setState(() {
            _garantieVolAccessoires = v;
            _premium = null;
          }),
          onIncendieChanged: (v) => setState(() {
            _garantieIncendie = v;
            _premium = null;
          }),
          onBrisGlaceChanged: (v) => setState(() {
            _garantieBrisDeGlace = v;
            _premium = null;
          }),
          onRecoursAnticipeGarantieChanged: (v) => setState(() {
            _garantieRecoursAnticipe = v;
            _premium = null;
          }),
          onTransportHydroChanged: (v) => setState(() {
            _isTransportHydro = v;
            _premium = null;
          }),
          onTracteurChanged: (v) => setState(() {
            _isTracteurRoutier = v;
            _premium = null;
          }),
          onWithRecoursAnticipeChanged: (v) => setState(() {
            _withRecoursAnticipe = v;
            _premium = null;
          }),
          vehicleType: _vehicleType,
          onVehicleTypeChanged: _onVehicleTypeChanged,
          chargeUtileCtrl: _chargeUtileCtrl,
        ),
      1 => _QuoteStep(
          fullNameCtrl: _fullNameCtrl,
          emailCtrl: _emailCtrl,
          phoneNoCtrl: _phoneNoCtrl,
          carRegNoCtrl: _carRegNoCtrl,
          brandCtrl: _brandCtrl,
          modelCtrl: _modelCtrl,
          puissanceFiscaleCtrl: _puissanceFiscaleCtrl,
          nombreDePlacesCtrl: _nombreDePlacesCtrl,
          energie: _energieDevis,
          onEnergieChanged: (v) => setState(() {
            if (v != null) _energieDevis = v;
          }),
          firstDriveDate: _firstDriveDate,
          onDateChanged: (date) => setState(() {
            _firstDriveDate = date;
          }),
          ageVehicule: _ageVehiculeCtrl.text,
          formule: _codeProduit.name,
          contractDuration: _dureeContratEnJour,
          isVehiculeVTC: _isVehiculeVTC,
          premium: _premium,
          formatAmount: _formatAmount,
          confirmed: _quoteConfirmed,
          vehicleType: _vehicleType,
        ),
      2 => _PaymentStep(
          premium: _premium,
          formatAmount: _formatAmount,
          paid: _paid,
          phoneCtrl: _paymentPhoneCtrl,
          emailCtrl: _paymentEmailCtrl,
          effectDate: _paymentEffectDate,
          onEffectDateChanged: (date) => setState(() => _paymentEffectDate = date),
          otpCtrl: _paymentOtpCtrl,
          operator: _paymentOperator,
          initiated: _paymentInitiated,
          awaitingOtp: _paymentAwaitingOtp,
          polling: _paymentPolling,
          enablePeyaPay: LeadwayApiConfig.enablePeyaPay,
          onOperatorChanged: (v) => setState(() {
            _paymentOperator = v;
            _paymentInitiated = false;
            _paymentAwaitingOtp = false;
            _paymentId = null;
            _paymentToken = null;
            _paymentOtpCtrl.clear();
            _stopPaymentPolling();
            _paymentPolling = false;
          }),
          onCancelPayment: _cancelPayment,
          vehicleType: _vehicleType,
        ),
      _ => _DownloadStep(
          policyNumber: _activePolicyNo,
          formatAmount: _formatAmount,
          premium: _premium,
          brand: _brandCtrl.text,
          model: _modelCtrl.text,
          carRegNo: _carRegNoCtrl.text,
          firstDriveDate: _firstDriveDate,
          onDocumentAction: _handlePdfDocument,
          vehicleType: _vehicleType,
        ),
    };
  }

  Future<void> _downloadSubscription(Map<String, dynamic> sub) async {
    setState(() {
      _policyNumber = sub['policyNo'] as String? ?? sub['quoteNo'] as String?;
      _contractPolicyNo = sub['policyNo'] as String? ?? _policyNumber;
      _cachedContractPdf = null;
      _cachedQuotePdf = null;
      _devisId = sub['id'];
      _fullNameCtrl.text = sub['fullName'];
      _emailCtrl.text = sub['email'] ?? '';
      _phoneNoCtrl.text = sub['phoneNo'];
      _brandCtrl.text = sub['brand'];
      _modelCtrl.text = sub['model'];
      _carRegNoCtrl.text = sub['carRegNo'];
      _premium = sub['premium'];
      _firstDriveDate = sub['firstDriveDate'] as DateTime?;
      _vehicleType = sub['vehicleType'] == 'auto' ? LeadwayVehicleType.auto : LeadwayVehicleType.moto;
    });
    _startDownloadAttestation();
  }

  void _viewSubscription(Map<String, dynamic> sub) {
    setState(() {
      _policyNumber = sub['policyNo'] as String? ?? sub['quoteNo'] as String?;
      _contractPolicyNo = sub['policyNo'] as String? ?? _policyNumber;
      _cachedContractPdf = null;
      _cachedQuotePdf = null;
      _devisId = sub['id'];
      _fullNameCtrl.text = sub['fullName'];
      _emailCtrl.text = sub['email'] ?? '';
      _phoneNoCtrl.text = sub['phoneNo'];
      _brandCtrl.text = sub['brand'];
      _modelCtrl.text = sub['model'];
      _carRegNoCtrl.text = sub['carRegNo'];
      _premium = sub['premium'];
      _firstDriveDate = sub['firstDriveDate'] as DateTime?;
      _vehicleType = sub['vehicleType'] == 'auto' ? LeadwayVehicleType.auto : LeadwayVehicleType.moto;
    });
    _openCertificateViewer();
  }

  void _resetForm() {
    setState(() {
      _step = 0;
      _brandCtrl.clear();
      _modelCtrl.clear();
      _ageVehiculeCtrl.text = '4';
      _valeurInitialeCtrl.clear();
      _valeurVenaleCtrl.clear();
      _premium = null;
      _calcResult = null;
      _quoteConfirmed = false;
      _paid = false;
      _policyNumber = null;
      _contractPolicyNo = null;
      _cachedContractPdf = null;
      _cachedQuotePdf = null;
      _devisId = null;
      _fullNameCtrl.clear();
      _emailCtrl.clear();
      _phoneNoCtrl.clear();
      _carRegNoCtrl.clear();
      _puissanceFiscaleCtrl.text = '7';
      _nombreDePlacesCtrl.text = '5';
      _energieDevis = LeadwayEnergy.essence;
      _firstDriveDate = DateTime.now().subtract(const Duration(days: 3 * 365));
      _paymentId = null;
      _paymentToken = null;
      _stopPaymentPolling();
      _paymentPolling = false;
      _paymentPollAttempts = 0;
      _paymentPhoneCtrl.clear();
      _paymentEmailCtrl.clear();
      _paymentOtpCtrl.clear();
      _paymentEffectDate = DateTime.now();
      _paymentInitiated = false;
      _paymentAwaitingOtp = false;
      _paymentOperator = LeadwayApiConfig.enablePeyaPay ? LeadwayPaymentOperator.peyapay : LeadwayPaymentOperator.orange;
      _dureeContratEnJour = 30;
      _garantieVol = true;
      _garantieIncendie = true;
      _garantieSecuriteRoutiere = true;
      _garantieAssistanceAuto = 1;
      _codeProduit = LeadwayProductCode.tiersSimple;
      _categorieVehicule = _vehicleType == LeadwayVehicleType.auto
          ? LeadwayVehicleCategory.particular
          : LeadwayVehicleCategory.moto;
      _isVehiculeVTC = false;
      _isGPS = false;
      _garantieVolAccessoires = false;
      _garantieBrisDeGlace = false;
      _garantieRecoursAnticipe = true;
      _isTransportHydro = false;
      _isTracteurRoutier = false;
      _chargeUtileCtrl.text = '3500';
      _withRecoursAnticipe = true;
    });
  }
}

class _LeadwayHeader extends StatelessWidget {
  const _LeadwayHeader({required this.onBack, required this.vehicleType});

  final VoidCallback onBack;
  final LeadwayVehicleType vehicleType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Retour',
            onPressed: onBack,
            icon: const Icon(Icons.chevron_left),
          ),
          Image.asset(
            'assets/logo/leadway.png',
            package: 'leadway',
            height: 40,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Icon(
              vehicleType == LeadwayVehicleType.auto ? Icons.directions_car : Icons.two_wheeler,
              color: LeadwayBrand.primary,
              size: 32,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicleType == LeadwayVehicleType.auto ? 'Assurance Auto' : 'Assurance Moto',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: LeadwayBrand.textDark,
                  ),
                ),
                const Text(
                  'Leadway Assurance',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: LeadwayBrand.primary,
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

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.steps,
    required this.current,
    required this.onStepTapped,
  });

  final List<String> steps;
  final int current;
  final ValueChanged<int> onStepTapped;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 2,
                  color: i <= current ? LeadwayBrand.primary : const Color(0xFFE0E0E0),
                ),
              ),
            _StepDot(
              index: i + 1,
              label: steps[i],
              active: i <= current,
              current: i == current,
              onTap: () => onStepTapped(i),
            ),
          ],
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.index,
    required this.label,
    required this.active,
    required this.current,
    required this.onTap,
  });

  final int index;
  final String label;
  final bool active;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? LeadwayBrand.primary : const Color(0xFFE0E0E0),
                border: current ? Border.all(color: LeadwayBrand.gradientBottom, width: 2) : null,
              ),
              child: Text(
                '$index',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: active ? Colors.white : const Color(0xFF9E9E9E),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 8,
                fontWeight: current ? FontWeight.w800 : FontWeight.w600,
                height: 1.1,
                color: active ? LeadwayBrand.primary : const Color(0xFF9E9E9E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumStep extends StatelessWidget {
  const _PremiumStep({
    this.scrollController,
    required this.ageVehiculeCtrl,
    required this.valeurInitialeCtrl,
    required this.valeurVenaleCtrl,
    required this.premium,
    required this.formatAmount,
    required this.onRecalculate,
    required this.codeProduit,
    required this.categorieVehicule,
    required this.dureeContratEnJour,
    required this.isVehiculeVTC,
    required this.isGPS,
    required this.garantieSecuriteRoutiere,
    required this.garantieAssistanceAuto,
    required this.garantieVol,
    required this.garantieVolAccessoires,
    required this.garantieIncendie,
    required this.garantieBrisDeGlace,
    required this.garantieRecoursAnticipe,
    required this.isTransportHydro,
    required this.isTracteurRoutier,
    required this.withRecoursAnticipe,
    required this.onProduitChanged,
    required this.onCategorieChanged,
    required this.onDureeChanged,
    required this.onVtcChanged,
    required this.onGpsChanged,
    required this.onSecuriteChanged,
    required this.onAssistanceChanged,
    required this.onVolChanged,
    required this.onVolAccessoiresChanged,
    required this.onIncendieChanged,
    required this.onBrisGlaceChanged,
    required this.onRecoursAnticipeGarantieChanged,
    required this.onTransportHydroChanged,
    required this.onTracteurChanged,
    required this.onWithRecoursAnticipeChanged,
    required this.vehicleType,
    required this.onVehicleTypeChanged,
    required this.chargeUtileCtrl,
  });

  final ScrollController? scrollController;
  final TextEditingController ageVehiculeCtrl;
  final TextEditingController valeurInitialeCtrl;
  final TextEditingController valeurVenaleCtrl;
  final int? premium;
  final String Function(int) formatAmount;
  final VoidCallback onRecalculate;
  final LeadwayVehicleType vehicleType;
  final ValueChanged<LeadwayVehicleType> onVehicleTypeChanged;
  final TextEditingController chargeUtileCtrl;

  final LeadwayProductCode codeProduit;
  final LeadwayVehicleCategory categorieVehicule;
  final int dureeContratEnJour;
  final bool isVehiculeVTC;
  final bool isGPS;
  final bool garantieSecuriteRoutiere;
  final int garantieAssistanceAuto;
  final bool garantieVol;
  final bool garantieVolAccessoires;
  final bool garantieIncendie;
  final bool garantieBrisDeGlace;
  final bool garantieRecoursAnticipe;
  final bool isTransportHydro;
  final bool isTracteurRoutier;
  final bool withRecoursAnticipe;

  final ValueChanged<LeadwayProductCode?> onProduitChanged;
  final ValueChanged<LeadwayVehicleCategory?> onCategorieChanged;
  final ValueChanged<int> onDureeChanged;
  final ValueChanged<bool> onVtcChanged;
  final ValueChanged<bool> onGpsChanged;
  final ValueChanged<bool> onSecuriteChanged;
  final ValueChanged<int?> onAssistanceChanged;
  final ValueChanged<bool> onVolChanged;
  final ValueChanged<bool> onVolAccessoiresChanged;
  final ValueChanged<bool> onIncendieChanged;
  final ValueChanged<bool> onBrisGlaceChanged;
  final ValueChanged<bool> onRecoursAnticipeGarantieChanged;
  final ValueChanged<bool> onTransportHydroChanged;
  final ValueChanged<bool> onTracteurChanged;
  final ValueChanged<bool> onWithRecoursAnticipeChanged;

  bool get _needsChargeUtile =>
      categorieVehicule.value == 2 ||
      categorieVehicule.value == 3 ||
      categorieVehicule.value == 7 ||
      categorieVehicule.value == 8 ||
      categorieVehicule.value == 10;

  bool get _needsTransportHydro =>
      categorieVehicule.value == 2 ||
      categorieVehicule.value == 3 ||
      categorieVehicule.value == 10;

  bool get _needsTracteurRoutier =>
      categorieVehicule.value == 2 ||
      categorieVehicule.value == 3 ||
      categorieVehicule.value == 8;

  bool get _showsGarantieSecurite =>
      codeProduit == LeadwayProductCode.surMesure ||
      codeProduit == LeadwayProductCode.tousRisques ||
      codeProduit == LeadwayProductCode.tiersComplet;

  bool get _showsSurMesureGaranties => codeProduit == LeadwayProductCode.surMesure;

  Widget _cardSection({required String title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: LeadwayBrand.primary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: LeadwayBrand.primary, width: 1.5),
      ),
    );
  }

  Widget _buildGarantieToggle({
    required String label,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: LeadwayBrand.textDark),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: LeadwayBrand.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        _HeroCard(
          icon: vehicleType == LeadwayVehicleType.auto ? Icons.directions_car : Icons.two_wheeler,
          title: 'Calcul de la prime',
          subtitle: 'Renseignez les critères de cotation requis par Leadway.',
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Type de véhicule *', style: _labelStyle),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      avatar: Icon(
                        Icons.directions_car,
                        color: vehicleType == LeadwayVehicleType.auto
                            ? LeadwayBrand.primary
                            : Colors.grey,
                      ),
                      label: const Center(child: Text('Voiture / Auto')),
                      selected: vehicleType == LeadwayVehicleType.auto,
                      selectedColor: LeadwayBrand.primary.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: vehicleType == LeadwayVehicleType.auto
                            ? LeadwayBrand.primary
                            : LeadwayBrand.textDark,
                      ),
                      side: BorderSide(
                        color: vehicleType == LeadwayVehicleType.auto
                            ? LeadwayBrand.primary
                            : const Color(0xFFE0E0E0),
                      ),
                      onSelected: (selected) {
                        if (selected) onVehicleTypeChanged(LeadwayVehicleType.auto);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      avatar: Icon(
                        Icons.two_wheeler,
                        color: vehicleType == LeadwayVehicleType.moto
                            ? LeadwayBrand.primary
                            : Colors.grey,
                      ),
                      label: const Center(child: Text('Moto')),
                      selected: vehicleType == LeadwayVehicleType.moto,
                      selectedColor: LeadwayBrand.primary.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: vehicleType == LeadwayVehicleType.moto
                            ? LeadwayBrand.primary
                            : LeadwayBrand.textDark,
                      ),
                      side: BorderSide(
                        color: vehicleType == LeadwayVehicleType.moto
                            ? LeadwayBrand.primary
                            : const Color(0xFFE0E0E0),
                      ),
                      onSelected: (selected) {
                        if (selected) onVehicleTypeChanged(LeadwayVehicleType.moto);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _cardSection(
          title: '1. Contrat',
          children: [
            DropdownButtonFormField<LeadwayProductCode>(
              value: codeProduit,
              decoration: _dropdownDecoration('Formule / Code produit *'),
              items: (vehicleType == LeadwayVehicleType.auto
                      ? [
                          LeadwayProductCode.tiersSimple,
                          LeadwayProductCode.tiersComplet,
                          LeadwayProductCode.tousRisques,
                          LeadwayProductCode.surMesure,
                        ]
                      : [LeadwayProductCode.tiersSimple])
                  .map<DropdownMenuItem<LeadwayProductCode>>((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                  .toList(),
              onChanged: onProduitChanged,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<LeadwayVehicleCategory>(
              value: categorieVehicule,
              decoration: _dropdownDecoration('Catégorie de véhicule *'),
              items: (vehicleType == LeadwayVehicleType.auto
                      ? [
                          LeadwayVehicleCategory.particular,
                          LeadwayVehicleCategory.camionLight,
                          LeadwayVehicleCategory.camionMedium,
                          LeadwayVehicleCategory.taxi,
                          LeadwayVehicleCategory.camionnette,
                          LeadwayVehicleCategory.poidsLourd,
                          LeadwayVehicleCategory.remorque,
                          LeadwayVehicleCategory.bus,
                          LeadwayVehicleCategory.professional,
                        ]
                      : [
                          LeadwayVehicleCategory.moto,
                          LeadwayVehicleCategory.motoLight,
                        ])
                  .map<DropdownMenuItem<LeadwayVehicleCategory>>(
                    (v) => DropdownMenuItem(value: v, child: Text('${v.value} - ${v.type}')),
                  )
                  .toList(),
              onChanged: onCategorieChanged,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: LeadwayContractDuration.values.map((d) => d.days).contains(dureeContratEnJour)
                  ? dureeContratEnJour
                  : 30,
              decoration: _dropdownDecoration('Durée du contrat *'),
              items: LeadwayContractDuration.values
                  .map<DropdownMenuItem<int>>((d) => DropdownMenuItem(value: d.days, child: Text(d.label)))
                  .toList(),
              onChanged: (val) {
                if (val != null) onDureeChanged(val);
              },
            ),
          ],
        ),

        _cardSection(
          title: '2. Véhicule',
          children: [
            _Field(
              label: 'Valeur à neuf (FCFA)',
              controller: valeurInitialeCtrl,
              hint: 'Ex. 1 500 000',
              keyboard: TextInputType.number,
              onChanged: (_) => onRecalculate(),
            ),
            const SizedBox(height: 12),
            _Field(
              label: 'Valeur vénale (FCFA)',
              controller: valeurVenaleCtrl,
              hint: 'Ex. 600 000',
              keyboard: TextInputType.number,
              onChanged: (_) => onRecalculate(),
            ),
            const SizedBox(height: 12),
            _Field(
              label: 'Âge du véhicule (ans)',
              controller: ageVehiculeCtrl,
              hint: 'Ex. 4',
              keyboard: TextInputType.number,
              onChanged: (_) => onRecalculate(),
            ),
            if (_needsChargeUtile) ...[
              const SizedBox(height: 12),
              _Field(
                label: 'Charge utile (kg) *',
                controller: chargeUtileCtrl,
                hint: 'Ex. 3500',
                keyboard: TextInputType.number,
                onChanged: (_) => onRecalculate(),
              ),
            ],
          ],
        ),

        _cardSection(
          title: '3. Options',
          children: [
            _buildGarantieToggle(
              label: 'Véhicule VTC',
              description: 'Utilisé pour le transport de personnes',
              value: isVehiculeVTC,
              onChanged: onVtcChanged,
            ),
            const Divider(height: 12),
            _buildGarantieToggle(
              label: 'Équipé GPS',
              description: 'Le véhicule dispose d\'un traceur GPS',
              value: isGPS,
              onChanged: onGpsChanged,
            ),
            const Divider(height: 12),
            DropdownButtonFormField<int>(
              value: garantieAssistanceAuto,
              decoration: _dropdownDecoration('Niveau d\'assistance auto'),
              items: LeadwayAssistanceLevel.values
                  .map<DropdownMenuItem<int>>(
                    (level) => DropdownMenuItem(value: level.value, child: Text(level.description)),
                  )
                  .toList(),
              onChanged: onAssistanceChanged,
            ),
            const Divider(height: 12),
            _buildGarantieToggle(
              label: 'Recours anticipé',
              description: 'Active le recours anticipé sur le contrat',
              value: withRecoursAnticipe,
              onChanged: onWithRecoursAnticipeChanged,
            ),
            if (_needsTransportHydro) ...[
              const Divider(height: 12),
              _buildGarantieToggle(
                label: 'Transport hydro',
                description: 'Transport de matières dangereuses',
                value: isTransportHydro,
                onChanged: onTransportHydroChanged,
              ),
            ],
            if (_needsTracteurRoutier) ...[
              const Divider(height: 12),
              _buildGarantieToggle(
                label: 'Tracteur routier',
                description: 'Véhicule tracteur routier',
                value: isTracteurRoutier,
                onChanged: onTracteurChanged,
              ),
            ],
          ],
        ),

        if (_showsGarantieSecurite)
          _cardSection(
            title: _showsSurMesureGaranties ? '4. Garanties (Sur Mesure)' : '4. Garanties',
            children: [
              if (_showsGarantieSecurite)
                _buildGarantieToggle(
                  label: 'Sécurité routière',
                  description: 'Assistance en cas d\'accident',
                  value: garantieSecuriteRoutiere,
                  onChanged: onSecuriteChanged,
                ),
              if (_showsSurMesureGaranties) ...[
                const Divider(height: 12),
                _buildGarantieToggle(
                  label: 'Vol',
                  description: 'Couvre le vol du véhicule',
                  value: garantieVol,
                  onChanged: onVolChanged,
                ),
                const Divider(height: 12),
                _buildGarantieToggle(
                  label: 'Vol accessoires',
                  description: 'Couvre le vol des accessoires',
                  value: garantieVolAccessoires,
                  onChanged: onVolAccessoiresChanged,
                ),
                const Divider(height: 12),
                _buildGarantieToggle(
                  label: 'Incendie',
                  description: 'Couvre les dégâts causés par le feu',
                  value: garantieIncendie,
                  onChanged: onIncendieChanged,
                ),
                const Divider(height: 12),
                _buildGarantieToggle(
                  label: 'Bris de glace',
                  description: 'Couvre les vitres brisées',
                  value: garantieBrisDeGlace,
                  onChanged: onBrisGlaceChanged,
                ),
                const Divider(height: 12),
                _buildGarantieToggle(
                  label: 'Recours anticipé (garantie)',
                  description: 'Recours rapide contre le tiers',
                  value: garantieRecoursAnticipe,
                  onChanged: onRecoursAnticipeGarantieChanged,
                ),
              ],
            ],
          ),

        if (premium != null) ...[
          const SizedBox(height: 20),
          _ResultCard(
            title: 'Prime estimée',
            value: formatAmount(premium!),
            subtitle: 'Responsabilité civile + garanties sélectionnées',
          ),
        ],
      ],
    );
  }
}

class _QuoteStep extends StatelessWidget {
  const _QuoteStep({
    required this.brandCtrl,
    required this.modelCtrl,
    required this.puissanceFiscaleCtrl,
    required this.nombreDePlacesCtrl,
    required this.energie,
    required this.onEnergieChanged,
    required this.firstDriveDate,
    required this.onDateChanged,
    required this.ageVehicule,
    required this.formule,
    required this.contractDuration,
    required this.isVehiculeVTC,
    required this.premium,
    required this.formatAmount,
    required this.confirmed,
    required this.fullNameCtrl,
    required this.emailCtrl,
    required this.phoneNoCtrl,
    required this.carRegNoCtrl,
    required this.vehicleType,
  });

  final TextEditingController brandCtrl;
  final TextEditingController modelCtrl;
  final TextEditingController puissanceFiscaleCtrl;
  final TextEditingController nombreDePlacesCtrl;
  final LeadwayEnergy energie;
  final ValueChanged<LeadwayEnergy?> onEnergieChanged;
  final DateTime? firstDriveDate;
  final ValueChanged<DateTime> onDateChanged;
  final String ageVehicule;
  final String formule;
  final int contractDuration;
  final bool isVehiculeVTC;
  final int? premium;
  final String Function(int) formatAmount;
  final bool confirmed;
  final TextEditingController fullNameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController phoneNoCtrl;
  final TextEditingController carRegNoCtrl;
  final LeadwayVehicleType vehicleType;

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: LeadwayBrand.primary, width: 1.5),
      ),
    );
  }

  String _contractDurationLabel(int days) {
    for (final d in LeadwayContractDuration.values) {
      if (d.days == days) return d.label;
    }
    return '$days jours';
  }

  Widget _cardSection({required String title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: LeadwayBrand.primary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final typeLabel = vehicleType == LeadwayVehicleType.auto ? 'auto' : 'moto';
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        _HeroCard(
          icon: Icons.description_outlined,
          title: 'Votre devis assurance $typeLabel',
          subtitle: 'Renseignez les informations de souscription et du véhicule.',
        ),
        const SizedBox(height: 16),
        if (!confirmed) ...[
          _cardSection(
            title: '1. Informations du souscripteur',
            children: [
              _Field(
                label: 'Nom complet *',
                controller: fullNameCtrl,
                hint: 'Ex. Jean Dupont',
              ),
              const SizedBox(height: 12),
              _Field(
                label: 'Adresse e-mail',
                controller: emailCtrl,
                hint: 'Ex. jean.dupont@email.com',
                keyboard: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              _Field(
                label: 'Numéro de téléphone *',
                controller: phoneNoCtrl,
                hint: 'Ex. +225 07 00 00 00 00',
                keyboard: TextInputType.phone,
              ),
            ],
          ),
          _cardSection(
            title: '2. Informations du véhicule',
            children: [
              _Field(
                label: 'Marque *',
                controller: brandCtrl,
                hint: 'Toyota, Honda, Yamaha…',
              ),
              const SizedBox(height: 12),
              _Field(
                label: 'Modèle *',
                controller: modelCtrl,
                hint: 'Ex. Corolla, Yaris, CB125F…',
              ),
              const SizedBox(height: 12),
              _DateField(
                label: 'Date de première mise en circulation *',
                selectedDate: firstDriveDate,
                onDateSelected: onDateChanged,
              ),
              const SizedBox(height: 12),
              _Field(
                label: 'Numéro d\'immatriculation *',
                controller: carRegNoCtrl,
                hint: 'Ex. 5678 CD 01',
              ),
              if (vehicleType == LeadwayVehicleType.auto) ...[
                const SizedBox(height: 12),
                _Field(
                  label: 'Puissance fiscale (CV) *',
                  controller: puissanceFiscaleCtrl,
                  hint: 'Ex. 7',
                  keyboard: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<LeadwayEnergy>(
                  value: energie,
                  decoration: _dropdownDecoration('Type d\'énergie *'),
                  items: LeadwayEnergy.values
                      .map<DropdownMenuItem<LeadwayEnergy>>(
                        (e) => DropdownMenuItem(value: e, child: Text(e.name)),
                      )
                      .toList(),
                  onChanged: onEnergieChanged,
                ),
                const SizedBox(height: 12),
                _Field(
                  label: 'Nombre de places *',
                  controller: nombreDePlacesCtrl,
                  hint: 'Ex. 5',
                  keyboard: TextInputType.number,
                ),
              ],
            ],
          ),
        ],
        _cardSection(
          title: '3. Résumé du devis',
          children: [
            _SummaryCard(
              rows: [
                ('Véhicule', '${brandCtrl.text} ${modelCtrl.text}'),
                ('Âge', ageVehicule.isEmpty ? '—' : '$ageVehicule ans'),
                ('Formule', formule),
                ('Durée contrat', _contractDurationLabel(contractDuration)),
                if (vehicleType == LeadwayVehicleType.auto)
                  ('VTC', isVehiculeVTC ? 'Oui' : 'Non'),
                if (vehicleType == LeadwayVehicleType.auto && puissanceFiscaleCtrl.text.isNotEmpty)
                  ('Puissance fiscale', '${puissanceFiscaleCtrl.text} CV'),
                if (vehicleType == LeadwayVehicleType.auto)
                  ('Énergie', energie.name),
                if (vehicleType == LeadwayVehicleType.auto && nombreDePlacesCtrl.text.isNotEmpty)
                  ('Places', nombreDePlacesCtrl.text),
                if (confirmed && carRegNoCtrl.text.isNotEmpty)
                  ('Immatriculation', carRegNoCtrl.text),
                if (confirmed && fullNameCtrl.text.isNotEmpty)
                  ('Souscripteur', fullNameCtrl.text),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (premium != null)
          _ResultCard(
            title: 'Montant du devis',
            value: formatAmount(premium!),
            subtitle: 'Valable 30 jours',
          ),
        if (confirmed) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: LeadwayBrand.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: LeadwayBrand.primary.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: LeadwayBrand.primary),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Devis confirmé — passez au paiement.',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _PaymentStep extends StatelessWidget {
  const _PaymentStep({
    required this.premium,
    required this.formatAmount,
    required this.paid,
    required this.phoneCtrl,
    required this.emailCtrl,
    required this.effectDate,
    required this.onEffectDateChanged,
    required this.otpCtrl,
    required this.operator,
    required this.initiated,
    required this.awaitingOtp,
    required this.polling,
    required this.enablePeyaPay,
    required this.onOperatorChanged,
    required this.onCancelPayment,
    required this.vehicleType,
  });

  final int? premium;
  final String Function(int) formatAmount;
  final bool paid;
  final TextEditingController phoneCtrl;
  final TextEditingController emailCtrl;
  final DateTime? effectDate;
  final ValueChanged<DateTime> onEffectDateChanged;
  final TextEditingController otpCtrl;
  final String operator;
  final bool initiated;
  final bool awaitingOtp;
  final bool polling;
  final bool enablePeyaPay;
  final ValueChanged<String> onOperatorChanged;
  final VoidCallback onCancelPayment;
  final LeadwayVehicleType vehicleType;

  bool get _isPeyaPay => operator == LeadwayPaymentOperator.peyapay;
  bool get _isOrange => operator == LeadwayPaymentOperator.orange;
  bool get _isWave => operator == LeadwayPaymentOperator.wave;

  Widget _buildPhoneField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E5E5)),
        ),
        child: _Field(
          label: 'Numéro de téléphone (Mobile Money) *',
          controller: phoneCtrl,
          hint: 'Ex. 0707070707',
          keyboard: TextInputType.phone,
        ),
      ),
    );
  }

  Widget _buildOtpField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LeadwayBrand.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.sms_outlined, color: LeadwayBrand.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Code OTP Orange Money',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: LeadwayBrand.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Paiement initié sur le ${phoneCtrl.text}. Composez #144*82# pour obtenir votre code OTP.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.4),
          ),
          const SizedBox(height: 16),
          _Field(
            label: 'Code OTP *',
            controller: otpCtrl,
            hint: 'Ex. 123456',
            keyboard: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildCancelButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onCancelPayment,
          icon: Icon(Icons.close, size: 18, color: Colors.grey[700]),
          label: Text(
            'Annuler le paiement',
            style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.grey.shade400),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  Widget _cardSection({required String title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: LeadwayBrand.primary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final typeLabel = vehicleType == LeadwayVehicleType.auto ? 'auto' : 'moto';
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        _HeroCard(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Paiement de la prime',
          subtitle: 'Réglez votre assurance via Mobile Money.',
        ),
        const SizedBox(height: 16),
        if (premium != null)
          _ResultCard(
            title: 'Montant à payer',
            value: formatAmount(premium!),
            subtitle: 'Assurance $typeLabel Leadway — 12 mois',
          ),
        const SizedBox(height: 16),
        if (!paid) ...[
          if (awaitingOtp && _isOrange) ...[
            _buildOtpField(),
            _buildCancelButton(),
          ] else if (!initiated && !polling) ...[
            _cardSection(
              title: '1. Informations de paiement',
              children: [
                _Field(
                  label: 'Adresse e-mail',
                  controller: emailCtrl,
                  hint: 'Ex. bernard@example.com',
                  keyboard: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                _DateField(
                  label: 'Date d\'effet du contrat *',
                  selectedDate: effectDate,
                  onDateSelected: onEffectDateChanged,
                  firstDate: DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                ),
              ],
            ),
            _cardSection(
              title: '2. Choisissez votre opérateur',
              children: [
                if (enablePeyaPay) ...[
                  _PaymentMethodTile(
                    selected: operator == LeadwayPaymentOperator.peyapay,
                    title: 'Peya Pay',
                    subtitle: 'Réglez directement via votre Wallet Peya Pay',
                    icon: Icons.account_balance_wallet_outlined,
                    onTap: () => onOperatorChanged(LeadwayPaymentOperator.peyapay),
                  ),
                  const SizedBox(height: 8),
                ],
                _PaymentMethodTile(
                  selected: operator == LeadwayPaymentOperator.orange,
                  title: 'Orange Money',
                  subtitle: 'Requis : numéro de téléphone',
                  icon: Icons.phone_android,
                  onTap: () => onOperatorChanged(LeadwayPaymentOperator.orange),
                ),
                if (_isOrange) _buildPhoneField(),
                const SizedBox(height: 8),
                _PaymentMethodTile(
                  selected: operator == LeadwayPaymentOperator.wave,
                  title: 'Wave',
                  subtitle: 'Requis : numéro de téléphone',
                  icon: Icons.waves,
                  onTap: () => onOperatorChanged(LeadwayPaymentOperator.wave),
                ),
                if (_isWave) _buildPhoneField(),
                const SizedBox(height: 8),
                _PaymentMethodTile(
                  selected: operator == LeadwayPaymentOperator.mtn,
                  title: 'MTN MoMo',
                  subtitle: 'Validation par notification Push (indisponible)',
                  icon: Icons.phone_android,
                  enabled: false,
                  onTap: () => onOperatorChanged(LeadwayPaymentOperator.mtn),
                ),
                const SizedBox(height: 8),
                _PaymentMethodTile(
                  selected: operator == LeadwayPaymentOperator.moov,
                  title: 'Moov Money',
                  subtitle: 'Validation par USSD (indisponible)',
                  icon: Icons.phone_android,
                  enabled: false,
                  onTap: () => onOperatorChanged(LeadwayPaymentOperator.moov),
                ),
              ],
            ),
          ] else if (polling) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEEEEEE)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(
                    height: 40,
                    width: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(LeadwayBrand.primary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    polling ? 'Vérification du paiement…' : 'Paiement en attente…',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: LeadwayBrand.textDark),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isPeyaPay
                        ? 'Votre paiement Peya Pay est en cours de traitement. Veuillez patienter.'
                        : 'Une demande de validation a été envoyée sur le numéro ${phoneCtrl.text}. Veuillez confirmer la transaction sur votre téléphone.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            _buildCancelButton(),
          ],
        ] else ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFC8E6C9)),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified, color: Color(0xFF2E7D32), size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Paiement validé !',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B5E20)),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Votre paiement a été traité avec succès. Cliquez sur Continuer pour obtenir votre attestation.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF2E7D32)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _DownloadStep extends StatelessWidget {
  const _DownloadStep({
    required this.policyNumber,
    required this.formatAmount,
    required this.premium,
    required this.brand,
    required this.model,
    required this.carRegNo,
    required this.firstDriveDate,
    required this.onDocumentAction,
    required this.vehicleType,
  });

  final String? policyNumber;
  final String Function(int) formatAmount;
  final int? premium;
  final String brand;
  final String model;
  final String carRegNo;
  final DateTime? firstDriveDate;
  final Future<void> Function(LeadwayPdfDocumentType type, LeadwayPdfAction action) onDocumentAction;
  final LeadwayVehicleType vehicleType;

  Widget _buildDocumentCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required LeadwayPdfDocumentType type,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: LeadwayBrand.primary.withValues(alpha: 0.1),
                child: Icon(icon, color: LeadwayBrand.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => onDocumentAction(type, LeadwayPdfAction.preview),
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('Voir'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: LeadwayBrand.primary,
                    side: BorderSide(color: LeadwayBrand.primary.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => onDocumentAction(type, LeadwayPdfAction.share),
                  icon: const Icon(Icons.share_outlined, size: 18),
                  label: const Text('Partager'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => onDocumentAction(type, LeadwayPdfAction.save),
                  icon: const Icon(Icons.download_outlined, size: 18),
                  label: const Text('Sauver'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LeadwayBrand.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLicensePlate(String regNo) {
    if (regNo.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E6), // Soft yellow plate background
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFFFCC00), width: 1.5),
      ),
      child: Text(
        regNo.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: Color(0xFF333333),
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildSummaryRow({required IconData icon, required String label, required String value, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: valueColor ?? LeadwayBrand.textDark,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final driveDateFormatted = firstDriveDate != null
        ? '${firstDriveDate!.day.toString().padLeft(2, '0')}/${firstDriveDate!.month.toString().padLeft(2, '0')}/${firstDriveDate!.year}'
        : '—';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LeadwayBrand.gradient,
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
                policyNumber ?? '—',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEEEEEE)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'RÉSUMÉ DU CONTRAT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: LeadwayBrand.primary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 14),
              
              // --- Section Véhicule ---
              Row(
                children: [
                  Icon(vehicleType == LeadwayVehicleType.auto ? Icons.directions_car_outlined : Icons.two_wheeler_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 10),
                  Text(
                    'Véhicule :',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Text(
                    '$brand $model'.trim().isEmpty ? (vehicleType == LeadwayVehicleType.auto ? 'Voiture' : 'Moto') : '$brand $model'.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: LeadwayBrand.textDark),
                  ),
                ],
              ),
              if (carRegNo.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.pin_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 10),
                    Text(
                      'Immatriculation :',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    _buildLicensePlate(carRegNo),
                  ],
                ),
              ],
              const Divider(height: 24, color: Color(0xFFEEEEEE)),

              // --- Section Détails Contrat ---
              _buildSummaryRow(icon: Icons.shield_outlined, label: 'Assureur', value: 'Leadway Assurance'),
              _buildSummaryRow(icon: Icons.description_outlined, label: 'Produit', value: vehicleType == LeadwayVehicleType.auto ? 'Assurance auto' : 'Assurance moto'),
              _buildSummaryRow(icon: Icons.calendar_today_outlined, label: 'Mise en circulation', value: driveDateFormatted),
              _buildSummaryRow(icon: Icons.history_toggle_off_outlined, label: 'Validité', value: '12 mois'),
              
              const Divider(height: 24, color: Color(0xFFEEEEEE)),

              // --- Section Montant Réglé ---
              if (premium != null) ...[
                Row(
                  children: [
                    const Text(
                      'Montant total réglé',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: LeadwayBrand.textDark),
                    ),
                    const Spacer(),
                    Text(
                      formatAmount(premium!),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'VOS DOCUMENTS PDF',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: LeadwayBrand.primary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        _buildDocumentCard(
          title: 'Contrat d\'assurance',
          subtitle: 'Police ${policyNumber ?? '—'}',
          icon: Icons.description_outlined,
          type: LeadwayPdfDocumentType.contract,
        ),
        _buildDocumentCard(
          title: 'Devis',
          subtitle: 'Document devis ${policyNumber ?? '—'}',
          icon: Icons.request_quote_outlined,
          type: LeadwayPdfDocumentType.quote,
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: LeadwayBrand.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: LeadwayBrand.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: LeadwayBrand.primary,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboard,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboard;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          inputFormatters: keyboard == TextInputType.number ? [FilteringTextInputFormatter.digitsOnly] : null,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: LeadwayBrand.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.title, required this.value, required this.subtitle});

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LeadwayBrand.gradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 20),
            Row(
              children: [
                Expanded(child: Text(rows[i].$1, style: TextStyle(color: Colors.grey.shade600, fontSize: 13))),
                Text(rows[i].$2, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.enabled = true,
    this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? LeadwayBrand.primary : const Color(0xFFE0E0E0),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: selected ? LeadwayBrand.primary : Colors.grey),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              if (selected) const Icon(Icons.radio_button_checked, color: LeadwayBrand.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.step,
    required this.maxStep,
    required this.primaryLabel,
    required this.onPrimary,
    this.loading = false,
  });

  final int step;
  final int maxStep;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -4))],
      ),
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: LeadwayBrand.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: loading ? null : onPrimary,
        child: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(primaryLabel, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.selectedDate,
    required this.onDateSelected,
    this.firstDate,
    this.lastDate,
  });

  final String label;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final DateTime? firstDate;
  final DateTime? lastDate;

  @override
  Widget build(BuildContext context) {
    final formatted = selectedDate != null
        ? '${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.year}'
        : 'Sélectionner une date';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final now = DateTime.now();
            final initial = selectedDate ?? now.subtract(const Duration(days: 3 * 365));
            final minDate = firstDate ?? DateTime(1900);
            final maxDate = lastDate ?? now;
            final picked = await showDatePicker(
              context: context,
              initialDate: initial.isAfter(maxDate)
                  ? maxDate
                  : (initial.isBefore(minDate) ? minDate : initial),
              firstDate: minDate,
              lastDate: maxDate,
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: LeadwayBrand.primary,
                      onPrimary: Colors.white,
                      onSurface: LeadwayBrand.textDark,
                    ),
                    textButtonTheme: TextButtonThemeData(
                      style: TextButton.styleFrom(
                        foregroundColor: LeadwayBrand.primary,
                      ),
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              onDateSelected(picked);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    formatted,
                    style: TextStyle(
                      fontSize: 14,
                      color: selectedDate != null ? LeadwayBrand.textDark : Colors.grey[600],
                    ),
                  ),
                ),
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: LeadwayBrand.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

const _labelStyle = TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: LeadwayBrand.textDark);

class _DownloadProgressDialog extends StatefulWidget {
  const _DownloadProgressDialog({required this.onCompleted});
  final VoidCallback onCompleted;

  @override
  State<_DownloadProgressDialog> createState() => _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<_DownloadProgressDialog> {
  double _progress = 0.0;
  String _status = 'Initialisation...';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    const totalSteps = 20;
    var currentStep = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      currentStep++;
      setState(() {
        _progress = currentStep / totalSteps;
        if (_progress <= 0.25) {
          _status = 'Génération de l\'attestation numérique...';
        } else if (_progress <= 0.50) {
          _status = 'Signature électronique de l\'assureur...';
        } else if (_progress <= 0.75) {
          _status = 'Sécurisation du certificat (chiffrement)...';
        } else if (_progress < 1.0) {
          _status = 'Finalisation du téléchargement PDF...';
        } else {
          _status = 'Fichier enregistré avec succès !';
        }
      });

      if (currentStep >= totalSteps) {
        timer.cancel();
        Future.delayed(const Duration(milliseconds: 300), widget.onCompleted);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 50,
              width: 50,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation<Color>(LeadwayBrand.primary),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '${(_progress * 100).toInt()}%',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: LeadwayBrand.textDark),
            ),
            const SizedBox(height: 8),
            Text(
              _status,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 6,
                backgroundColor: const Color(0xFFEEEEEE),
                valueColor: const AlwaysStoppedAnimation<Color>(LeadwayBrand.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LeadwayCertificateViewerScreen extends StatelessWidget {
  const LeadwayCertificateViewerScreen({
    super.key,
    required this.policyNumber,
    required this.fullName,
    required this.phoneNo,
    required this.carRegNo,
    required this.brand,
    required this.model,
    required this.premium,
    required this.firstDriveDate,
    required this.vehicleType,
  });

  final String policyNumber;
  final String fullName;
  final String phoneNo;
  final String carRegNo;
  final String brand;
  final String model;
  final int premium;
  final DateTime firstDriveDate;
  final LeadwayVehicleType vehicleType;

  String _formatAmount(int amount) {
    final s = amount.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return '${buf.toString()} FCFA';
  }

  @override
  Widget build(BuildContext context) {
    final issueDate = DateTime.now();
    final issueDateFormatted = '${issueDate.day.toString().padLeft(2, '0')}/${issueDate.month.toString().padLeft(2, '0')}/${issueDate.year}';
    final startDateFormatted = '${firstDriveDate.day.toString().padLeft(2, '0')}/${firstDriveDate.month.toString().padLeft(2, '0')}/${firstDriveDate.year}';
    
    final endDate = firstDriveDate.add(const Duration(days: 365));
    final endDateFormatted = '${endDate.day.toString().padLeft(2, '0')}/${endDate.month.toString().padLeft(2, '0')}/${endDate.year}';

    return Scaffold(
      backgroundColor: const Color(0xFFE0E0E0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: LeadwayBrand.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Visualisation Attestation',
          style: TextStyle(color: LeadwayBrand.textDark, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: LeadwayBrand.primary),
            onPressed: () {
              LeadwayToast.show(context, message: 'Attestation partagée avec succès !', type: LeadwayToastType.success);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.03,
                      child: Center(
                        child: Icon(Icons.shield, size: 280, color: Colors.blue.shade900),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF1B5E20), width: 3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Image.asset(
                                  'assets/logo/leadway.png',
                                  package: 'leadway',
                                  height: 36,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) => const Icon(Icons.two_wheeler, color: Color(0xFF1B5E20), size: 28),
                                ),
                                const SizedBox(width: 10),
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'LEADWAY ASSURANCE',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF1B5E20),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    Text(
                                      'CÔTE D\'IVOIRE',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.orange,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFF2E7D32)),
                              ),
                              child: const Text(
                                'CODE: 007',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  color: Color(0xFF1B5E20),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Center(
                          child: Column(
                            children: [
                              Text(
                                'ATTESTATION PROVISOIRE D\'ASSURANCE',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: LeadwayBrand.textDark,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              Text(
                                'DELIVRÉE EN VERTU DE L\'ARTICLE 200 DU CODE CIMA',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 32, thickness: 1.5, color: Color(0xFFEEEEEE)),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildMetaLabel('ATTESTATION N°'),
                                  Text(
                                    policyNumber,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                      color: LeadwayBrand.textDark,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildMetaLabel('ASSUREUR'),
                                  const Text(
                                    'LEADWAY ASSURANCE CI',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              width: 80,
                              height: 80,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: const Color(0xFFDDDDDD)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: CustomPaint(
                                size: const Size(72, 72),
                                painter: _MockQRCodePainter(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildSectionHeader('SOUSCRIPTEUR'),
                        const SizedBox(height: 6),
                        _buildRow('Nom complet :', fullName.toUpperCase()),
                        _buildRow('Téléphone :', phoneNo),
                        const SizedBox(height: 16),
                        _buildSectionHeader('CARACTÉRISTIQUES DU VÉHICULE'),
                        const SizedBox(height: 6),
                        _buildRow('Marque & Modèle :', '$brand $model'.toUpperCase()),
                        _buildRow('Immatriculation :', carRegNo.toUpperCase()),
                        _buildRow('Catégorie/Usage :', vehicleType == LeadwayVehicleType.auto ? 'AUTO (Usage 1)' : 'MOTO (Usage 1)'),
                        const SizedBox(height: 16),
                        _buildSectionHeader('PÉRIODE DE VALIDITÉ'),
                        const SizedBox(height: 6),
                        _buildRow('Date de prise d\'effet :', startDateFormatted),
                        _buildRow('Date d\'échéance :', endDateFormatted),
                        _buildRow('Durée de validité :', '365 JOURS (12 Mois)'),
                        const SizedBox(height: 16),
                        _buildSectionHeader('GARANTIES & FACTURATION'),
                        const SizedBox(height: 6),
                        _buildRow('Garanties souscrites :', 'RC, DEFENSE RECOURS, INCENDIE, VOL, BRIS DE GLACE'),
                        _buildRow(
                          'Prime TTC Réglée :',
                          _formatAmount(premium),
                          valueColor: const Color(0xFF2E7D32),
                        ),
                        const Divider(height: 32, thickness: 1.5, color: Color(0xFFEEEEEE)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Fait à Abidjan, le $issueDateFormatted',
                                  style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Document signé électroniquement',
                                  style: TextStyle(fontSize: 9, color: Color(0xFF2E7D32), fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                const Icon(Icons.verified, color: Color(0xFF1B5E20), size: 32),
                                const SizedBox(height: 4),
                                Text(
                                  'CERTIFIÉ CONFORME',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F5),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: Color(0xFF1B5E20),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: valueColor ?? LeadwayBrand.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MockQRCodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black;
    final cellWidth = size.width / 12;
    final cellHeight = size.height / 12;

    void drawFinder(double x, double y) {
      canvas.drawRect(Rect.fromLTWH(x, y, cellWidth * 3, cellHeight * 3), paint);
      canvas.drawRect(
        Rect.fromLTWH(x + cellWidth * 0.5, y + cellHeight * 0.5, cellWidth * 2, cellHeight * 2),
        Paint()..color = Colors.white,
      );
      canvas.drawRect(
        Rect.fromLTWH(x + cellWidth, y + cellHeight, cellWidth, cellHeight),
        paint,
      );
    }

    drawFinder(0, 0);
    drawFinder(size.width - cellWidth * 3, 0);
    drawFinder(0, size.height - cellHeight * 3);

    for (var r = 0; r < 12; r++) {
      for (var c = 0; c < 12; c++) {
        if ((r < 3 && c < 3) || (r < 3 && c >= 9) || (r >= 9 && c < 3)) continue;
        if (r >= 8 && c >= 8) {
          if (r == 9 && c == 9) continue;
          if (r >= 8 && r <= 10 && c >= 8 && c <= 10) {
            canvas.drawRect(Rect.fromLTWH(c * cellWidth, r * cellHeight, cellWidth, cellHeight), paint);
          }
          continue;
        }
        if (((r * 3 + c * 7) % 5 == 0) || ((r * 11 + c * 13) % 4 == 0)) {
          canvas.drawRect(Rect.fromLTWH(c * cellWidth, r * cellHeight, cellWidth, cellHeight), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _SubscriptionsHeader extends StatelessWidget {
  const _SubscriptionsHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Bouton retour
                IconButton(
                  tooltip: 'Retour',
                  onPressed: onBack,
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: LeadwayBrand.textDark,
                  ),
                ),
                const SizedBox(width: 2),
                // Textes
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Mes Souscriptions',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 19,
                          color: LeadwayBrand.textDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF2E7D32),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'Contrats actifs',
                                  style: TextStyle(
                                    color: Color(0xFF2E7D32),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Logo Leadway dans un container arrondi
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: LeadwayBrand.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: LeadwayBrand.primary.withOpacity(0.15),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Image.asset(
                      'assets/logo/leadway.png',
                      package: 'leadway',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.shield_rounded,
                        color: LeadwayBrand.primary,
                        size: 22,
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


class _SubscriptionsView extends StatelessWidget {
  const _SubscriptionsView({
    required this.subscriptions,
    required this.onDownload,
    required this.onView,
    required this.onNewPolicy,
  });

  final List<Map<String, dynamic>> subscriptions;
  final ValueChanged<Map<String, dynamic>> onDownload;
  final ValueChanged<Map<String, dynamic>> onView;
  final VoidCallback onNewPolicy;

  String _formatDate(DateTime? date) {
    if (date == null) return '--/--/----';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day/$month/$year';
  }

  Widget _buildFeatureItem(IconData icon, String title, String description, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F1F1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: LeadwayBrand.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [LeadwayBrand.gradientTop, LeadwayBrand.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: LeadwayBrand.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            onPressed: onNewPolicy,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text(
              'Souscrire une nouvelle assurance',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (subscriptions.isEmpty) {
      return Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          LeadwayBrand.primary.withOpacity(0.1),
                          LeadwayBrand.gradientBottom.withOpacity(0.05)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          )
                        ],
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        size: 44,
                        color: LeadwayBrand.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Assurez votre moto en 2 min',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: LeadwayBrand.textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Profitez d\'une protection complète et obtenez votre attestation d\'assurance moto instantanément.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildFeatureItem(
                    Icons.bolt_rounded,
                    'Estimation ultra-rapide',
                    'Calculez votre prime sur-mesure en moins d\'une minute.',
                    LeadwayBrand.primary,
                  ),
                  _buildFeatureItem(
                    Icons.payments_outlined,
                    'Paiement 100% sécurisé',
                    'Réglez facilement via PeyaPay ou Mobile Money.',
                    const Color(0xFF2E7D32),
                  ),
                  _buildFeatureItem(
                    Icons.share_outlined,
                    'Attestation instantanée',
                    'Partagez ou visualisez votre police d\'assurance immédiatement après validation.',
                    const Color(0xFF1976D2),
                  ),
                ],
              ),
            ),
          ),
          _buildBottomButton(),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bienvenue sur votre espace',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: LeadwayBrand.textDark,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Retrouvez ci-dessous la liste de vos contrats d\'assurance moto actifs.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            itemCount: subscriptions.length,
            itemBuilder: (context, index) {
              final sub = subscriptions[index];
              final String brand = sub['brand'] ?? '';
              final String model = sub['model'] ?? '';
              final String carRegNo = sub['carRegNo'] ?? '';
              final String fullName = sub['fullName'] ?? '';
              final String quoteNo = sub['quoteNo'] ?? '';
              final int premium = sub['premium'] ?? 0;
              final DateTime? firstDriveDate = sub['firstDriveDate'] as DateTime?;
              final DateTime? expiryDate = firstDriveDate != null
                  ? DateTime(firstDriveDate.year + 1, firstDriveDate.month, firstDriveDate.day)
                  : null;

              final premiumFormatted = _formatAmount(premium);

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Liseré vertical orange à gauche
                        Container(
                          width: 5,
                          color: LeadwayBrand.primary,
                        ),
                        // Carte principale
                        Expanded(
                          child: Material(
                            color: Colors.white,
                            child: InkWell(
                              onTap: () => onView(sub),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: LeadwayBrand.primary.withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(Icons.two_wheeler_rounded, color: LeadwayBrand.primary, size: 22),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '$brand $model',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 15,
                                                  color: LeadwayBrand.textDark,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'N° $quoteNo',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey[500],
                                                  fontFamily: 'monospace',
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE8F5E9),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 6,
                                                height: 6,
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFF2E7D32),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              const Text(
                                                'Actif',
                                                style: TextStyle(
                                                  color: Color(0xFF2E7D32),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                                    child: Column(
                                      children: [
                                        _detailRow(Icons.person_outline, 'Assuré', fullName),
                                        const SizedBox(height: 6),
                                        _detailRow(
                                          Icons.calendar_today_outlined,
                                          'Période',
                                          'Du ${_formatDate(firstDriveDate)} au ${_formatDate(expiryDate)}',
                                        ),
                                        const SizedBox(height: 6),
                                        _detailRow(
                                          Icons.payments_outlined,
                                          'Prime réglée',
                                          premiumFormatted,
                                          isBold: true,
                                          valueColor: const Color(0xFF2E7D32),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF3F4F6),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: const Color(0xFFE5E7EB)),
                                              ),
                                              child: Text(
                                                carRegNo.toUpperCase(),
                                                style: const TextStyle(
                                                  color: Color(0xFF374151),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                  fontFamily: 'monospace',
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                            OutlinedButton.icon(
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: const Color(0xFF2E7D32),
                                                side: const BorderSide(color: Color(0xFF2E7D32)),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                              ),
                                              onPressed: () => onDownload(sub),
                                              icon: const Icon(Icons.share, size: 14),
                                              label: const Text(
                                                'Partager',
                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        _buildBottomButton(),
      ],
    );
  }

  Widget _detailRow(IconData icon, String label, String value, {bool isBold = false, Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.grey[400]),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? LeadwayBrand.textDark,
          ),
        ),
      ],
    );
  }

  String _formatAmount(int amount) {
    final s = amount.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return '${buf.toString()} FCFA';
  }
}
