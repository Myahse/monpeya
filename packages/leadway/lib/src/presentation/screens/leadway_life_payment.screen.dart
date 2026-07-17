import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:leadway/src/core/constants/leadway_api.constants.dart';
import 'package:leadway/src/data/models/leadway_api.exception.dart';
import 'package:leadway/src/data/models/leadway_life_payment.model.dart';
import 'package:leadway/src/data/services/leadway_api.service.dart';
import 'package:leadway/src/data/services/leadway_life_api.service.dart';
import 'package:leadway/src/presentation/constants/leadway.brand.dart';
import 'package:leadway/src/presentation/widgets/leadway_toast.widget.dart';

/// Paiement Assurance Vie — Orange / Wave / Peya Pay + vérification check-paiement.
class LeadwayLifePaymentScreen extends StatefulWidget {
  const LeadwayLifePaymentScreen({
    super.key,
    required this.subscriptionRef,
    required this.productLabel,
    required this.telephone,
    this.policyNumber,
    this.premiumLabel,
  });

  final String subscriptionRef;
  final String productLabel;
  final String telephone;
  final String? policyNumber;
  final String? premiumLabel;

  @override
  State<LeadwayLifePaymentScreen> createState() => _LeadwayLifePaymentScreenState();
}

class _LeadwayLifePaymentScreenState extends State<LeadwayLifePaymentScreen> {
  final _api = LeadwayLifeApiService();
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  String _method = LeadwayPaymentOperator.orange;
  bool _loading = false;
  bool _polling = false;
  bool _paid = false;
  int _pollAttempts = 0;
  Timer? _pollTimer;
  String? _transactionId;
  LeadwayLifePaymentResult? _initResult;
  LeadwayLifePaymentCheckResult? _checkResult;

  static const _maxPollAttempts = 120;

  bool get _isOrange => _method == LeadwayPaymentOperator.orange;
  bool get _isWave => _method == LeadwayPaymentOperator.wave;
  bool get _isPeyaPay => _method == LeadwayPaymentOperator.peyapay;

  /// Codes API Vie en majuscules (ex. WAVE, ORANGE).
  String get _apiMethod => _method.toUpperCase();

  @override
  void initState() {
    super.initState();
    _phoneCtrl.text = widget.telephone;
    _method = LeadwayApiConfig.enablePeyaPay
        ? LeadwayPaymentOperator.peyapay
        : LeadwayPaymentOperator.orange;
  }

  @override
  void dispose() {
    _stopPolling();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _cancelPayment() {
    _stopPolling();
    setState(() {
      _polling = false;
      _loading = false;
      _pollAttempts = 0;
      _transactionId = null;
      _initResult = null;
      _checkResult = null;
      _paid = false;
      _otpCtrl.clear();
    });
    LeadwayToast.show(context, message: 'Paiement annulé. Choisissez un moyen de paiement.', type: LeadwayToastType.info);
  }

  Future<void> _pay() async {
    if (!_isPeyaPay && _phoneCtrl.text.trim().isEmpty) {
      LeadwayToast.show(
        context,
        message: 'Veuillez saisir le numéro de téléphone du payeur.',
        type: LeadwayToastType.error,
      );
      return;
    }
    if (_isOrange && _otpCtrl.text.trim().isEmpty) {
      LeadwayToast.show(
        context,
        message: 'Le code OTP Orange Money est requis (#144*82#).',
        type: LeadwayToastType.error,
      );
      return;
    }

    _stopPolling();
    setState(() {
      _loading = true;
      _paid = false;
      _polling = false;
      _pollAttempts = 0;
      _initResult = null;
      _checkResult = null;
      _transactionId = null;
    });

    try {
      final request = LeadwayLifePaymentRequest(
        method: _apiMethod,
        payerPhone: _isPeyaPay ? '' : _phoneCtrl.text.trim(),
        returnUrl: 'monpeya://leadway/life/payment',
        otp: _isOrange ? _otpCtrl.text.trim() : '',
      );

      debugPrint('[Leadway Vie] Paiement — requête: ${request.toJson()}');

      final result = await _api.initiatePayment(
        subscriptionRef: widget.subscriptionRef,
        request: request,
      );

      debugPrint('[Leadway Vie] Paiement — retour: ${result.raw}');

      if (!mounted) return;

      final txId = result.data.transactionId;
      if (txId.isEmpty) {
        throw const LeadwayApiException(message: 'Identifiant de transaction manquant.');
      }

      setState(() {
        _initResult = result;
        _transactionId = txId;
        _loading = false;
        _polling = true;
      });

      if (result.data.redirectUrl.isNotEmpty) {
        await _openRedirect(result.data.redirectUrl);
      }

      if (!mounted) return;
      LeadwayToast.show(
        context,
        message: 'Paiement initié. Vérification en cours…',
        type: LeadwayToastType.info,
      );
      _startPolling();
    } on LeadwayApiException catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        LeadwayToast.show(context, message: e.displayMessage, type: LeadwayToastType.error);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        LeadwayToast.show(context, message: 'Erreur paiement : $e', type: LeadwayToastType.error);
      }
    }
  }

  void _startPolling() {
    _stopPolling();
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      unawaited(_pollOnce());
    });
    unawaited(_pollOnce());
  }

  Future<void> _pollOnce() async {
    if (!mounted || _paid || _transactionId == null || !_polling) return;

    _pollAttempts++;
    if (_pollAttempts > _maxPollAttempts) {
      _stopPolling();
      if (!mounted) return;
      setState(() => _polling = false);
      LeadwayToast.show(
        context,
        message: 'Délai de vérification dépassé. Réessayez le paiement.',
        type: LeadwayToastType.error,
      );
      return;
    }

    try {
      final check = await _api.checkPayment(
        LeadwayLifePaymentCheckRequest(transactionId: _transactionId!),
      );

      debugPrint('[Leadway Vie] check-paiement — ${check.data.status} (${check.data.transactionId})');

      if (!mounted) return;
      setState(() => _checkResult = check);

      if (check.data.isFailed) {
        _stopPolling();
        setState(() => _polling = false);
        LeadwayToast.show(
          context,
          message: 'Paiement échoué (${check.data.status}).',
          type: LeadwayToastType.error,
        );
        return;
      }

      if (!check.data.isPaid) return;

      _stopPolling();
      setState(() {
        _paid = true;
        _polling = false;
      });
      LeadwayToast.show(context, message: 'Paiement validé avec succès.', type: LeadwayToastType.success);
    } catch (e) {
      debugPrint('[Leadway Vie] Erreur check-paiement: $e');
    }
  }

  Future<void> _openRedirect(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        LeadwayToast.show(
          context,
          message: 'Impossible d\'ouvrir le lien de paiement Wave.',
          type: LeadwayToastType.error,
        );
      }
    } catch (e) {
      if (mounted) {
        LeadwayToast.show(context, message: 'Ouverture Wave impossible : $e', type: LeadwayToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final showForm = !_paid && !_polling && !_loading;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _card(
                    title: 'Récapitulatif',
                    children: [
                      _row('Produit', widget.productLabel),
                      _row('Référence', widget.subscriptionRef),
                      if (widget.policyNumber != null && widget.policyNumber!.isNotEmpty)
                        _row('Police', widget.policyNumber!),
                      if (widget.premiumLabel != null && widget.premiumLabel!.isNotEmpty)
                        _row('Prime', widget.premiumLabel!),
                    ],
                  ),
                  if (showForm)
                    _card(
                      title: 'Moyen de paiement',
                      children: [
                        if (LeadwayApiConfig.enablePeyaPay) ...[
                          _methodTile(
                            code: LeadwayPaymentOperator.peyapay,
                            title: 'Peya Pay',
                            subtitle: 'Paiement via votre Wallet Peya Pay',
                            icon: Icons.account_balance_wallet_outlined,
                          ),
                          const SizedBox(height: 8),
                        ],
                        _methodTile(
                          code: LeadwayPaymentOperator.orange,
                          title: 'Orange Money',
                          subtitle: 'Numéro + code OTP (#144*82#)',
                          icon: Icons.phone_android,
                        ),
                        if (_isOrange) ...[
                          const SizedBox(height: 12),
                          _field('Numéro de téléphone *', _phoneCtrl, 'Ex. 0707070707', TextInputType.phone),
                          const SizedBox(height: 12),
                          _field('Code OTP *', _otpCtrl, 'Ex. 123456', TextInputType.number),
                          const SizedBox(height: 6),
                          Text(
                            'Composez #144*82# pour obtenir votre code OTP.',
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                          ),
                        ],
                        const SizedBox(height: 8),
                        _methodTile(
                          code: LeadwayPaymentOperator.wave,
                          title: 'Wave',
                          subtitle: 'Paiement via Wave (redirection possible)',
                          icon: Icons.waves,
                        ),
                        if (_isWave) ...[
                          const SizedBox(height: 12),
                          _field('Numéro de téléphone *', _phoneCtrl, 'Ex. 0707070707', TextInputType.phone),
                        ],
                      ],
                    ),
                  if (_polling) _pollingCard(),
                  if (_paid && _checkResult != null) _paidCard(_checkResult!),
                  if (!_paid && _initResult != null && !_polling) _initCard(_initResult!),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading || _polling
                          ? null
                          : _paid
                              ? () => Navigator.of(context).popUntil((r) => r.isFirst)
                              : _pay,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LeadwayBrand.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _loading || _polling
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            )
                          : Text(
                              _paid ? 'Accéder à la police' : 'Payer maintenant',
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                    ),
                  ),
                  if (_polling || (_initResult != null && !_paid)) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _cancelPayment,
                        icon: Icon(Icons.close, size: 18, color: Colors.grey[700]),
                        label: Text(
                          'Annuler le paiement',
                          style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (_polling) {
                _cancelPayment();
              } else {
                Navigator.of(context).pop();
              }
            },
            icon: const Icon(Icons.chevron_left),
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paiement Assurance Vie',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: LeadwayBrand.textDark),
                ),
                Text(
                  'Leadway Assurance',
                  style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required String title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: LeadwayBrand.primary)),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600]))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  Widget _methodTile({
    required String code,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final selected = _method == code;
    return InkWell(
      onTap: () => setState(() {
        _method = code;
        _otpCtrl.clear();
        _initResult = null;
        _checkResult = null;
      }),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? LeadwayBrand.primary : const Color(0xFFE0E0E0),
            width: selected ? 1.5 : 1,
          ),
          color: selected ? LeadwayBrand.primary.withValues(alpha: 0.06) : Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? LeadwayBrand.primary : Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: selected ? LeadwayBrand.primary : LeadwayBrand.textDark)),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? LeadwayBrand.primary : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, String hint, TextInputType keyboard) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF555555))),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboard,
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

  Widget _pollingCard() {
    final status = _checkResult?.data.status ?? _initResult?.data.paymentStatus ?? 'PENDING';
    final redirect = _initResult?.data.redirectUrl ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
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
          const Text(
            'Vérification du paiement…',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: LeadwayBrand.textDark),
          ),
          const SizedBox(height: 8),
          Text(
            _isWave
                ? 'Validez le paiement Wave puis revenez ici. Statut : $status'
                : 'Confirmez la transaction sur votre téléphone. Statut : $status',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          if (_transactionId != null) ...[
            const SizedBox(height: 12),
            _row('Transaction', _transactionId!),
          ],
          if (redirect.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _openRedirect(redirect),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Rouvrir Wave'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _paidCard(LeadwayLifePaymentCheckResult check) {
    final d = check.data;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC8E6C9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle, color: Color(0xFF2E7D32)),
              SizedBox(width: 8),
              Text(
                'Paiement validé',
                style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1B5E20)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _row('Statut', d.status),
          _row('Transaction', d.transactionId),
          if (d.amount > 0) _row('Montant', '${d.amount} ${d.currency}'),
          if (d.payerRef.isNotEmpty) _row('Payeur', d.payerRef),
        ],
      ),
    );
  }

  Widget _initCard(LeadwayLifePaymentResult result) {
    final d = result.data;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pending, color: LeadwayBrand.primary),
              SizedBox(width: 8),
              Text('Paiement initié', style: TextStyle(fontWeight: FontWeight.w800, color: LeadwayBrand.textDark)),
            ],
          ),
          const SizedBox(height: 12),
          _row('Statut', d.paymentStatus),
          _row('Transaction', d.transactionId),
        ],
      ),
    );
  }
}
