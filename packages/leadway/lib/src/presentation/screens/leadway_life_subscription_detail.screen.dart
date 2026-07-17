import 'package:flutter/material.dart';

import 'package:leadway/src/core/constants/leadway_life.constants.dart';
import 'package:leadway/src/data/models/leadway_api.exception.dart';
import 'package:leadway/src/data/models/leadway_life_list.model.dart';
import 'package:leadway/src/data/models/leadway_life_subscription.model.dart';
import 'package:leadway/src/data/services/leadway_life_api.service.dart';
import 'package:leadway/src/presentation/constants/leadway.brand.dart';
import 'package:leadway/src/presentation/widgets/leadway_toast.widget.dart';

/// Détail souscription Vie + statut disponibilité police (issue).
class LeadwayLifeSubscriptionDetailScreen extends StatefulWidget {
  const LeadwayLifeSubscriptionDetailScreen({
    super.key,
    required this.subscriptionRef,
    this.preview,
  });

  final String subscriptionRef;
  final LeadwayLifeSubscriptionItem? preview;

  @override
  State<LeadwayLifeSubscriptionDetailScreen> createState() => _LeadwayLifeSubscriptionDetailScreenState();
}

class _LeadwayLifeSubscriptionDetailScreenState extends State<LeadwayLifeSubscriptionDetailScreen> {
  final _api = LeadwayLifeApiService();

  bool _loadingDetail = true;
  bool _loadingIssue = false;
  LeadwayLifeSubscriptionData? _detail;
  LeadwayLifeIssueResult? _issue;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _loadingDetail = true;
      _error = null;
    });
    try {
      final result = await _api.getSubscription(widget.subscriptionRef);
      if (!mounted) return;
      setState(() {
        _detail = result.data;
        _loadingDetail = false;
      });
    } on LeadwayApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingDetail = false;
        _error = e.displayMessage;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingDetail = false;
        _error = '$e';
      });
    }
  }

  Future<void> _loadIssue() async {
    setState(() {
      _loadingIssue = true;
      _issue = null;
    });
    try {
      final result = await _api.getIssueStatus(widget.subscriptionRef);
      if (!mounted) return;
      setState(() {
        _issue = result;
        _loadingIssue = false;
      });
      LeadwayToast.show(
        context,
        message: result.data.message.isNotEmpty ? result.data.message : 'Statut police récupéré.',
        type: result.data.isAvailable ? LeadwayToastType.success : LeadwayToastType.info,
      );
    } on LeadwayApiException catch (e) {
      if (!mounted) return;
      setState(() => _loadingIssue = false);
      LeadwayToast.show(context, message: e.displayMessage, type: LeadwayToastType.error);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingIssue = false);
      LeadwayToast.show(context, message: 'Erreur statut police : $e', type: LeadwayToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = widget.preview;
    final d = _detail;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.chevron_left)),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Détail souscription', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: LeadwayBrand.textDark)),
                        Text('Leadway Assurance Vie', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Actualiser',
                    onPressed: _loadingDetail ? null : _loadDetail,
                    icon: const Icon(Icons.refresh, color: LeadwayBrand.primary),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loadingDetail && d == null
                  ? const Center(child: CircularProgressIndicator(color: LeadwayBrand.primary))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        if (_error != null && d == null)
                          _card(
                            title: 'Erreur',
                            children: [Text(_error!, style: TextStyle(color: Colors.red[700]))],
                          )
                        else ...[
                          _card(
                            title: 'Souscription',
                            children: [
                              _row('Référence', d?.subscriptionRef ?? widget.subscriptionRef),
                              _row('Produit', d?.productCode ?? preview?.productCode ?? '—'),
                              _row('Police', (d?.policyNumber.isNotEmpty == true) ? d!.policyNumber : (preview?.policyNumber ?? '—')),
                              _row('Statut', _statusLabel(d?.status ?? preview?.status ?? '')),
                              if (d?.createdAt != null && d!.createdAt!.isNotEmpty) _row('Créée le', d.createdAt!),
                              if (preview?.customerId.isNotEmpty == true) _row('Client', preview!.customerId),
                            ],
                          ),
                          if (preview != null)
                            _card(
                              title: 'Prime',
                              children: [
                                _row('TTC', '${preview.premium.gross.amountRounded} ${preview.premium.gross.currency}'),
                                _row('Nette', '${preview.premium.net.amountRounded} ${preview.premium.net.currency}'),
                                _row('Taxe', '${preview.premium.tax.amountRounded} ${preview.premium.tax.currency}'),
                                if (preview.premium.frequency.isNotEmpty)
                                  _row(
                                    'Fréquence',
                                    LeadwayLifePaymentFrequency.fromCode(preview.premium.frequency)?.label ??
                                        preview.premium.frequency,
                                  ),
                              ],
                            ),
                          _card(
                            title: 'Disponibilité de la police',
                            children: [
                              if (_issue != null) ...[
                                _row('Statut police', _issue!.data.policyStatus),
                                _row('Statut', _issue!.data.status),
                                if (_issue!.data.message.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4, bottom: 8),
                                    child: Text(
                                      _issue!.data.message,
                                      style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.4),
                                    ),
                                  ),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _issue!.data.isAvailable ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _issue!.data.isAvailable
                                        ? 'Police disponible'
                                        : 'Police non encore disponible',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: _issue!.data.isAvailable ? const Color(0xFF1B5E20) : const Color(0xFFF57F17),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                              SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: ElevatedButton.icon(
                                  onPressed: _loadingIssue ? null : _loadIssue,
                                  icon: _loadingIssue
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Icon(Icons.verified_outlined, size: 20),
                                  label: Text(
                                    _issue == null ? 'Vérifier la disponibilité' : 'Revérifier',
                                    style: const TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: LeadwayBrand.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                            ],
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

  String _statusLabel(String status) {
    return LeadwayLifeSubscriptionStatus.fromCode(status)?.label ?? (status.isEmpty ? '—' : status);
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
          SizedBox(width: 110, child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600]))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}
