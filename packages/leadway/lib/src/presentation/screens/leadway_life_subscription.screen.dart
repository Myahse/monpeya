import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:leadway/src/core/constants/leadway_life.constants.dart';
import 'package:leadway/src/core/host/leadway_host.bridge.dart';
import 'package:leadway/src/data/models/leadway_api.exception.dart';
import 'package:leadway/src/data/models/leadway_life_subscription.model.dart';
import 'package:leadway/src/data/services/leadway_life_api.service.dart';
import 'package:leadway/src/presentation/constants/leadway.brand.dart';
import 'package:leadway/src/presentation/screens/leadway_life_cotation.screen.dart';
import 'package:leadway/src/presentation/widgets/leadway_toast.widget.dart';

/// Souscription Assurance Vie — étape 1 (avant cotation).
/// Le `subscriptionRef` est renvoyé par l'API et enregistré en meta.
class LeadwayLifeSubscriptionScreen extends StatefulWidget {
  const LeadwayLifeSubscriptionScreen({
    super.key,
    required this.productCode,
    required this.productLabel,
  });

  final String productCode;
  final String productLabel;

  @override
  State<LeadwayLifeSubscriptionScreen> createState() => _LeadwayLifeSubscriptionScreenState();
}

class _LeadwayLifeSubscriptionScreenState extends State<LeadwayLifeSubscriptionScreen> {
  final _api = LeadwayLifeApiService();
  final _scrollCtrl = ScrollController();
  final _phoneCtrl = TextEditingController();

  List<LeadwayLifeEnumItem> _relationships = [];
  final List<_BeneficiaryDraft> _beneficiaries = [];

  String _customerId = '';
  String _subscriptionRef = '';
  bool _loadingEnums = true;
  bool _loadingMeta = true;
  bool _submitting = false;
  LeadwayLifeSubscriptionResult? _result;

  @override
  void initState() {
    super.initState();
    _beneficiaries.add(
      _BeneficiaryDraft(
        relationship: LeadwayLifeRelationship.spouse.code,
      ),
    );
    _loadEnums();
    _hydrateFromMeta();
  }

  Future<void> _hydrateFromMeta() async {
    final phone = await LeadwayHostBridge.getMeta(LeadwayMetaKeys.phone);
    final customerId = await LeadwayHostBridge.getMeta(LeadwayMetaKeys.customerId) ?? '';
    if (!mounted) return;
    setState(() {
      if (phone != null && phone.isNotEmpty) _phoneCtrl.text = phone;
      if (customerId.isNotEmpty) _customerId = customerId;
      _loadingMeta = false;
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _phoneCtrl.dispose();
    for (final b in _beneficiaries) {
      b.dispose();
    }
    super.dispose();
  }

  Future<void> _loadEnums() async {
    try {
      final items = await _api.fetchRelationships();
      if (!mounted) return;
      setState(() {
        _relationships = items.where((e) => e.value != 'SELF').toList();
        if (_relationships.isEmpty) {
          _relationships = LeadwayLifeRelationship.values
              .where((e) => e != LeadwayLifeRelationship.self)
              .map((e) => LeadwayLifeEnumItem(value: e.code, description: e.label))
              .toList();
        }
        _loadingEnums = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _relationships = LeadwayLifeRelationship.values
            .where((e) => e != LeadwayLifeRelationship.self)
            .map((e) => LeadwayLifeEnumItem(value: e.code, description: e.label))
            .toList();
        _loadingEnums = false;
      });
    }
  }

  void _addBeneficiary() {
    setState(() {
      _beneficiaries.add(
        _BeneficiaryDraft(
          relationship: _relationships.isNotEmpty
              ? _relationships.first.value
              : LeadwayLifeRelationship.child.code,
        ),
      );
      _result = null;
    });
  }

  void _removeBeneficiary(int index) {
    if (_beneficiaries.length <= 1) {
      LeadwayToast.show(
        context,
        message: 'Au moins un bénéficiaire est requis.',
        type: LeadwayToastType.error,
      );
      return;
    }
    setState(() {
      _beneficiaries[index].dispose();
      _beneficiaries.removeAt(index);
      _result = null;
    });
  }

  Future<void> _submit() async {
    if (_phoneCtrl.text.trim().isEmpty) {
      LeadwayToast.show(context, message: 'Le téléphone est obligatoire.', type: LeadwayToastType.error);
      return;
    }
    if (_customerId.trim().isEmpty) {
      LeadwayToast.show(
        context,
        message: 'Identifiant client indisponible.',
        type: LeadwayToastType.error,
      );
      return;
    }
    if (_beneficiaries.isEmpty) {
      LeadwayToast.show(context, message: 'Ajoutez au moins un bénéficiaire.', type: LeadwayToastType.error);
      return;
    }

    for (var i = 0; i < _beneficiaries.length; i++) {
      final b = _beneficiaries[i];
      if (b.firstNameCtrl.text.trim().isEmpty || b.lastNameCtrl.text.trim().isEmpty) {
        LeadwayToast.show(
          context,
          message: 'Bénéficiaire ${i + 1} : nom et prénom requis.',
          type: LeadwayToastType.error,
        );
        return;
      }
    }

    final request = LeadwayLifeSubscriptionRequest(
      telephone: _phoneCtrl.text.trim(),
      customerId: _customerId.trim(),
      productCode: widget.productCode,
      beneficiaries: _beneficiaries
          .map(
            (b) => LeadwayLifeBeneficiary(
              firstName: b.firstNameCtrl.text.trim(),
              lastName: b.lastNameCtrl.text.trim(),
              relationship: b.relationship,
              percentage: 0,
              phone: b.phoneCtrl.text.trim(),
              email: b.emailCtrl.text.trim(),
            ),
          )
          .toList(),
    );

    setState(() {
      _submitting = true;
      _result = null;
    });

    try {
      final result = await _api.createSubscription(request);
      if (!mounted) return;

      await LeadwayHostBridge.setMeta(LeadwayMetaKeys.customerId, request.customerId);
      await LeadwayHostBridge.setMeta(LeadwayMetaKeys.phone, request.telephone);
      if (result.data.subscriptionRef.isNotEmpty) {
        await LeadwayHostBridge.setMeta(LeadwayMetaKeys.subscriptionRef, result.data.subscriptionRef);
        _subscriptionRef = result.data.subscriptionRef;
      }

      setState(() => _result = result);
      LeadwayToast.show(
        context,
        message: 'Souscription réussie — police ${result.data.policyNumber}',
        type: LeadwayToastType.success,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
          );
        }
      });
    } on LeadwayApiException catch (e) {
      LeadwayToast.show(context, message: e.displayMessage, type: LeadwayToastType.error);
    } catch (e) {
      LeadwayToast.show(context, message: 'Erreur souscription : $e', type: LeadwayToastType.error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LeadwayTheme(
      child: Scaffold(
      backgroundColor: LeadwayBrand.of(context).bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _loadingEnums || _loadingMeta
                  ? const Center(child: CircularProgressIndicator(color: LeadwayBrand.primary))
                  : ListView(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        _card(
                          title: 'Récapitulatif',
                          children: [
                            _infoRow('Produit', widget.productLabel),
                            _infoRow('Code', widget.productCode),
                            if (_customerId.isNotEmpty) _infoRow('Client', _customerId),
                          ],
                        ),
                        _card(
                          title: '1. Contact',
                          children: [
                            _textField('Téléphone *', _phoneCtrl, 'Ex. 0707070707', keyboard: TextInputType.phone),
                          ],
                        ),
                        _card(
                          title: '2. Bénéficiaires',
                          children: [
                            for (var i = 0; i < _beneficiaries.length; i++) ...[
                              if (i > 0) const Divider(height: 28),
                              _buildBeneficiaryCard(i),
                            ],
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _result != null ? null : _addBeneficiary,
                              icon: const Icon(Icons.person_add_alt_1, size: 18),
                              label: const Text('Ajouter un bénéficiaire'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: LeadwayBrand.primary,
                                side: BorderSide(color: LeadwayBrand.primary.withValues(alpha: 0.4)),
                              ),
                            ),
                          ],
                        ),
                        if (_result != null) _buildSuccessCard(_result!),
                      ],
                    ),
            ),
            if (_result == null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _submitting || _loadingEnums ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: LeadwayBrand.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Text('Souscrire', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildHeader() {
    final brand = LeadwayBrand.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Retour',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Souscription Assurance Vie',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: brand.text),
                ),
                Text(
                  'Leadway Assurance',
                  style: TextStyle(fontSize: 11, color: brand.muted, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required String title, required List<Widget> children}) {
    final brand = LeadwayBrand.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: brand.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: brand.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: LeadwayBrand.primary),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    final brand = LeadwayBrand.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: TextStyle(fontSize: 12, color: brand.muted)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: brand.text)),
          ),
        ],
      ),
    );
  }

  Widget _textField(
    String label,
    TextEditingController ctrl,
    String hint, {
    TextInputType? keyboard,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final brand = LeadwayBrand.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: brand.muted)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboard,
          inputFormatters: inputFormatters,
          enabled: _result == null,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: brand.card,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: brand.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: brand.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _dropdownDecoration(String label) {
    final brand = LeadwayBrand.of(context);
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: brand.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: brand.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: brand.primary, width: 1.5),
      ),
    );
  }

  Widget _buildBeneficiaryCard(int index) {
    final b = _beneficiaries[index];
    final relValue = _relationships.any((e) => e.value == b.relationship)
        ? b.relationship
        : (_relationships.isNotEmpty ? _relationships.first.value : b.relationship);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Bénéficiaire ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w700)),
            const Spacer(),
            if (_result == null)
              IconButton(
                tooltip: 'Retirer',
                onPressed: () => _removeBeneficiary(index),
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              ),
          ],
        ),
        DropdownButtonFormField<String>(
          initialValue: relValue,
          decoration: _dropdownDecoration('Lien de parenté *'),
          items: _relationships
              .map((e) => DropdownMenuItem(
                    value: e.value,
                    child: Text(e.description.isEmpty ? e.value : e.description),
                  ))
              .toList(),
          onChanged: _result != null
              ? null
              : (v) {
                  if (v != null) setState(() => b.relationship = v);
                },
        ),
        const SizedBox(height: 12),
        _textField('Prénom *', b.firstNameCtrl, 'Prénom'),
        const SizedBox(height: 12),
        _textField('Nom *', b.lastNameCtrl, 'Nom'),
        const SizedBox(height: 12),
        _textField('Téléphone', b.phoneCtrl, 'Optionnel', keyboard: TextInputType.phone),
        const SizedBox(height: 12),
        _textField('E-mail', b.emailCtrl, 'Optionnel', keyboard: TextInputType.emailAddress),
      ],
    );
  }

  Widget _buildSuccessCard(LeadwayLifeSubscriptionResult result) {
    final d = result.data;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(18),
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
                'Souscription confirmée',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1B5E20)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _successLine('N° de police', d.policyNumber),
          _successLine('Référence', d.subscriptionRef),
          _successLine('Statut', d.status),
          _successLine('ID', d.id),
          if (d.createdAt != null && d.createdAt!.isNotEmpty) _successLine('Créée le', d.createdAt!),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final ref = d.subscriptionRef.isNotEmpty ? d.subscriptionRef : _subscriptionRef;
                if (ref.isEmpty) {
                  LeadwayToast.show(
                    context,
                    message: 'Référence de souscription manquante.',
                    type: LeadwayToastType.error,
                  );
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => LeadwayLifeCotationScreen(
                      productCode: widget.productCode,
                      productLabel: widget.productLabel,
                      subscriptionRef: ref,
                      telephone: _phoneCtrl.text.trim(),
                      policyNumber: d.policyNumber,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: LeadwayBrand.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Continuer vers la cotation', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _successLine(String label, String value) {
    final brand = LeadwayBrand.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(fontSize: 12, color: brand.muted))),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1B5E20))),
          ),
        ],
      ),
    );
  }
}

class _BeneficiaryDraft {
  _BeneficiaryDraft({
    required this.relationship,
  });

  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  String relationship;

  void dispose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
  }
}
