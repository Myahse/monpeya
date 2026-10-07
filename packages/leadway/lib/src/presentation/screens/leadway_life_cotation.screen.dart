import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:leadway/src/core/constants/leadway_life.constants.dart';
import 'package:leadway/src/core/host/leadway_host.bridge.dart';
import 'package:leadway/src/data/models/leadway_api.exception.dart';
import 'package:leadway/src/data/models/leadway_life_cotation_request.model.dart';
import 'package:leadway/src/data/models/leadway_life_cotation_response.model.dart';
import 'package:leadway/src/data/services/leadway_life_api.service.dart';
import 'package:leadway/src/presentation/constants/leadway.brand.dart';
import 'package:leadway/src/presentation/screens/leadway_life_payment.screen.dart';
import 'package:leadway/src/presentation/widgets/leadway_toast.widget.dart';

/// Cotation Assurance Vie — étape 2 (après souscription).
/// Utilise le `subscriptionRef` renvoyé par l'API souscription.
class LeadwayLifeCotationScreen extends StatefulWidget {
  const LeadwayLifeCotationScreen({
    super.key,
    required this.productCode,
    required this.productLabel,
    required this.subscriptionRef,
    this.telephone = '',
    this.policyNumber,
  });

  final String productCode;
  final String productLabel;
  final String subscriptionRef;
  final String telephone;
  final String? policyNumber;

  @override
  State<LeadwayLifeCotationScreen> createState() => _LeadwayLifeCotationScreenState();
}

class _LeadwayLifeCotationScreenState extends State<LeadwayLifeCotationScreen> {
  final _api = LeadwayLifeApiService();
  final _scrollCtrl = ScrollController();

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _amountCtrl = TextEditingController(text: '5000');

  DateTime? _birthDate;
  DateTime? _effectiveDate = DateTime.now();
  LeadwayLifeGender _gender = LeadwayLifeGender.male;
  String _frequencyCode = LeadwayLifePaymentFrequency.monthly.code;

  List<LeadwayLifeEnumItem> _relationships = [];
  List<LeadwayLifeEnumItem> _frequencies = [];
  final List<_AdditionalInsuredDraft> _additional = [];

  bool _loadingEnums = true;
  bool _submitting = false;
  LeadwayLifeCotationResult? _result;

  bool get _usesFunerairesTariff => LeadwayLifeFunerairesTariff.appliesTo(widget.productCode);

  @override
  void initState() {
    super.initState();
    _loadEnums();
    _hydrateFromMeta();
  }

  Future<void> _hydrateFromMeta() async {
    final phone = await LeadwayHostBridge.getMeta(LeadwayMetaKeys.phone);
    if (!mounted) return;
    if (_phoneCtrl.text.trim().isEmpty) {
      final fromWidget = widget.telephone.trim();
      if (fromWidget.isNotEmpty) {
        setState(() => _phoneCtrl.text = fromWidget);
      } else if (phone != null && phone.isNotEmpty) {
        setState(() => _phoneCtrl.text = phone);
      }
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _amountCtrl.dispose();
    for (final a in _additional) {
      a.dispose();
    }
    super.dispose();
  }

  Future<void> _loadEnums() async {
    try {
      final results = await Future.wait([
        _api.fetchRelationships(),
        _api.fetchPaymentFrequencies(),
      ]);
      if (!mounted) return;
      setState(() {
        _relationships = results[0];
        var frequencies = results[1];
        if (_usesFunerairesTariff) {
          frequencies = LeadwayLifeFunerairesTariff.enrichFrequencies(frequencies);
        }
        _frequencies = frequencies;
        _loadingEnums = false;
        if (_frequencies.isNotEmpty) {
          final monthly = _frequencies.where((e) => e.value.toUpperCase() == 'MONTHLY');
          _frequencyCode = monthly.isNotEmpty ? monthly.first.value : _frequencies.first.value;
          _applyTariffAmountForFrequency(_frequencyCode);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingEnums = false);
      LeadwayToast.show(context, message: 'Impossible de charger les listes : $e', type: LeadwayToastType.error);
    }
  }

  void _applyTariffAmountForFrequency(String frequencyCode) {
    if (!_usesFunerairesTariff) return;
    final amount = LeadwayLifeFunerairesTariff.amountFor(frequencyCode);
    if (amount != null) {
      _amountCtrl.text = amount.toString();
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<DateTime?> _pickDate({
    required DateTime? current,
    required DateTime first,
    required DateTime last,
  }) async {
    final initial = current ?? DateTime(1990, 1, 1);
    return showDatePicker(
      context: context,
      initialDate: initial.isBefore(first)
          ? first
          : (initial.isAfter(last) ? last : initial),
      firstDate: first,
      lastDate: last,
      builder: (context, child) {
        final brand = LeadwayBrand.of(context);
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme(
              brightness: brand.isDark ? Brightness.dark : Brightness.light,
              primary: brand.primary,
              onPrimary: Colors.white,
              secondary: brand.primaryDark,
              onSecondary: Colors.white,
              surface: brand.card,
              onSurface: brand.text,
              error: brand.danger,
              onError: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
  }

  void _addInsured() {
    setState(() {
      _additional.add(_AdditionalInsuredDraft(
        relationship: LeadwayLifeRelationship.child.code,
      ));
      _result = null;
    });
  }

  void _removeInsured(int index) {
    setState(() {
      _additional[index].dispose();
      _additional.removeAt(index);
      _result = null;
    });
  }

  Future<void> _submit() async {
    if (_firstNameCtrl.text.trim().isEmpty || _lastNameCtrl.text.trim().isEmpty) {
      LeadwayToast.show(context, message: 'Renseignez le nom et le prénom du souscripteur.', type: LeadwayToastType.error);
      return;
    }
    if (_birthDate == null) {
      LeadwayToast.show(context, message: 'Renseignez la date de naissance.', type: LeadwayToastType.error);
      return;
    }
    if (_phoneCtrl.text.trim().isEmpty) {
      LeadwayToast.show(context, message: 'Renseignez le numéro de téléphone.', type: LeadwayToastType.error);
      return;
    }
    if (_emailCtrl.text.trim().isNotEmpty && !_emailCtrl.text.contains('@')) {
      LeadwayToast.show(context, message: 'Adresse e-mail invalide.', type: LeadwayToastType.error);
      return;
    }
    if (_effectiveDate == null) {
      LeadwayToast.show(context, message: 'Renseignez la date d\'effet.', type: LeadwayToastType.error);
      return;
    }
    final amount = int.tryParse(_amountCtrl.text.replaceAll(RegExp(r'\s'), '')) ?? 0;
    if (amount <= 0) {
      LeadwayToast.show(context, message: 'Le montant de cotisation doit être supérieur à 0.', type: LeadwayToastType.error);
      return;
    }

    for (var i = 0; i < _additional.length; i++) {
      final a = _additional[i];
      if (a.firstNameCtrl.text.trim().isEmpty || a.lastNameCtrl.text.trim().isEmpty) {
        LeadwayToast.show(context, message: 'Assuré additionnel ${i + 1} : nom et prénom requis.', type: LeadwayToastType.error);
        return;
      }
      if (a.birthDate == null) {
        LeadwayToast.show(context, message: 'Assuré additionnel ${i + 1} : date de naissance requise.', type: LeadwayToastType.error);
        return;
      }
    }

    final subscriptionRef = widget.subscriptionRef.trim();
    if (subscriptionRef.isEmpty) {
      LeadwayToast.show(
        context,
        message: 'Référence de souscription manquante. Reprenez depuis la souscription.',
        type: LeadwayToastType.error,
      );
      return;
    }

    await LeadwayHostBridge.setMeta(LeadwayMetaKeys.subscriptionRef, subscriptionRef);
    final phone = _phoneCtrl.text.trim();
    if (phone.isNotEmpty) {
      await LeadwayHostBridge.setMeta(LeadwayMetaKeys.phone, phone);
    }

    final subscriber = LeadwayLifeInsured(
      person: LeadwayLifePerson(
        fullName: LeadwayLifeFullName(
          firstName: _firstNameCtrl.text.trim(),
          lastName: _lastNameCtrl.text.trim(),
        ),
        birthDate: _fmtDate(_birthDate!),
        gender: _gender,
        phone: phone,
        email: _emailCtrl.text.trim(),
      ),
      relationshipToSubscriber: LeadwayLifeRelationship.self,
      subscriber: true,
    );

    final additional = _additional.map((a) {
      return LeadwayLifeInsured(
        person: LeadwayLifePerson(
          fullName: LeadwayLifeFullName(
            firstName: a.firstNameCtrl.text.trim(),
            lastName: a.lastNameCtrl.text.trim(),
          ),
          birthDate: _fmtDate(a.birthDate!),
          gender: a.gender,
          phone: a.phoneCtrl.text.trim(),
          email: a.emailCtrl.text.trim(),
        ),
        relationshipToSubscriber:
            LeadwayLifeRelationship.fromCode(a.relationship) ?? LeadwayLifeRelationship.child,
        subscriber: false,
      );
    }).toList();

    final request = LeadwayLifeCotationRequest(
      subscriptionRef: subscriptionRef,
      productCode: widget.productCode,
      subscriber: subscriber,
      additionalInsureds: additional,
      paymentFrequency: _frequencyCode,
      tierInputAmount: amount,
      effectiveDate: _fmtDate(_effectiveDate!),
    );

    setState(() {
      _submitting = true;
      _result = null;
    });

    try {
      final result = await _api.calculateCotation(request);
      if (!mounted) return;
      setState(() => _result = result);
      LeadwayToast.show(context, message: 'Cotation calculée avec succès.', type: LeadwayToastType.success);
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
      LeadwayToast.show(context, message: 'Erreur cotation : $e', type: LeadwayToastType.error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _formatAmount(num amount) {
    final s = amount.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
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
              child: _loadingEnums
                  ? const Center(child: CircularProgressIndicator(color: LeadwayBrand.primary))
                  : ListView(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        _card(
                          title: 'Produit',
                          children: [
                            Text(
                              widget.productLabel,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.productCode,
                              style: TextStyle(fontSize: 12, color: LeadwayBrand.of(context).muted, fontFamily: 'Urbanist'),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Réf. ${widget.subscriptionRef}',
                              style: TextStyle(fontSize: 12, color: LeadwayBrand.of(context).muted, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        _card(
                          title: '1. Souscripteur',
                          children: [
                            _textField('Prénom *', _firstNameCtrl, 'Ex. Kouassi'),
                            const SizedBox(height: 12),
                            _textField('Nom *', _lastNameCtrl, 'Ex. Bernard'),
                            const SizedBox(height: 12),
                            _dateTile(
                              label: 'Date de naissance *',
                              date: _birthDate,
                              onTap: () async {
                                final picked = await _pickDate(
                                  current: _birthDate,
                                  first: DateTime(1920),
                                  last: DateTime.now(),
                                );
                                if (picked != null) {
                                  setState(() {
                                  _birthDate = picked;
                                  _result = null;
                                });
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            _dropdownGender(),
                            const SizedBox(height: 12),
                            _textField('Téléphone *', _phoneCtrl, 'Ex. 0707070707', keyboard: TextInputType.phone),
                            const SizedBox(height: 12),
                            _textField('E-mail', _emailCtrl, 'Optionnel', keyboard: TextInputType.emailAddress),
                          ],
                        ),
                        _card(
                          title: '2. Cotisation',
                          children: [
                            _dropdownFrequency(),
                            const SizedBox(height: 12),
                            if (_usesFunerairesTariff)
                              _tariffAmountDisplay()
                            else
                              _textField(
                                'Montant (FCFA) *',
                                _amountCtrl,
                                'Ex. 5000',
                                keyboard: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              ),
                            const SizedBox(height: 12),
                            _dateTile(
                              label: 'Date d\'effet *',
                              date: _effectiveDate,
                              onTap: () async {
                                final now = DateTime.now();
                                final picked = await _pickDate(
                                  current: _effectiveDate,
                                  first: DateTime(now.year, now.month, now.day),
                                  last: now.add(const Duration(days: 365 * 2)),
                                );
                                if (picked != null) {
                                  setState(() {
                                  _effectiveDate = picked;
                                  _result = null;
                                });
                                }
                              },
                            ),
                          ],
                        ),
                        _card(
                          title: '3. Assurés additionnels (optionnel)',
                          children: [
                            if (_additional.isEmpty)
                              Text(
                                'Aucun assuré additionnel. Vous pouvez en ajouter (conjoint, enfant…).',
                                style: TextStyle(fontSize: 12, color: LeadwayBrand.of(context).muted),
                              ),
                            for (var i = 0; i < _additional.length; i++) ...[
                              if (i > 0) const Divider(height: 28),
                              _buildAdditionalCard(i),
                            ],
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _addInsured,
                              icon: const Icon(Icons.person_add_alt_1, size: 18),
                              label: const Text('Ajouter un assuré'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: LeadwayBrand.primary,
                                side: BorderSide(color: LeadwayBrand.primary.withValues(alpha: 0.4)),
                              ),
                            ),
                          ],
                        ),
                        if (_result != null) _buildResultCard(_result!),
                      ],
                    ),
            ),
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
                      : const Text('Obtenir la cotation', style: TextStyle(fontWeight: FontWeight.w800)),
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
                  'Cotation Assurance Vie',
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
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: brand.primary,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
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
          onChanged: (_) => setState(() => _result = null),
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

  Widget _dateTile({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    final brand = LeadwayBrand.of(context);
    final text = date == null
        ? 'Sélectionner une date'
        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: brand.muted)),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: brand.border),
            ),
            child: Row(
              children: [
                Expanded(child: Text(text, style: TextStyle(color: date == null ? brand.muted : brand.text))),
                Icon(Icons.calendar_today_outlined, size: 18, color: brand.muted),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _dropdownGender() {
    return DropdownButtonFormField<LeadwayLifeGender>(
      initialValue: _gender,
      decoration: _dropdownDecoration('Genre *'),
      items: LeadwayLifeGender.values
          .map((g) => DropdownMenuItem(value: g, child: Text(g.label)))
          .toList(),
      onChanged: (v) {
        if (v != null) {
          setState(() {
          _gender = v;
          _result = null;
        });
        }
      },
    );
  }

  Widget _tariffAmountDisplay() {
    final brand = LeadwayBrand.of(context);
    final amount = LeadwayLifeFunerairesTariff.amountFor(_frequencyCode) ??
        (int.tryParse(_amountCtrl.text.replaceAll(RegExp(r'\s'), '')) ?? 0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: brand.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: brand.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Montant (grille Funérailles)', style: TextStyle(fontSize: 12, color: brand.muted)),
          const SizedBox(height: 4),
          Text(
            '${_formatAmount(amount)} FCFA',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: LeadwayBrand.primary),
          ),
        ],
      ),
    );
  }

  Widget _dropdownFrequency() {
    final items = _frequencies.isNotEmpty
        ? _frequencies
        : LeadwayLifePaymentFrequency.values
            .map((e) => LeadwayLifeEnumItem(value: e.code, description: e.label))
            .toList();
    final values = items.map((e) => e.value).toSet();
    final selected = values.contains(_frequencyCode)
        ? _frequencyCode
        : (items.isNotEmpty ? items.first.value : null);

    return DropdownButtonFormField<String>(
      // ignore: deprecated_member_use
      value: selected,
      decoration: _dropdownDecoration('Fréquence de paiement *'),
      items: items
          .map((e) => DropdownMenuItem(
                value: e.value,
                child: Text(e.description.isEmpty ? e.value : e.description),
              ))
          .toList(),
      onChanged: (v) {
        if (v == null) return;
        setState(() {
          _frequencyCode = v;
          _applyTariffAmountForFrequency(v);
          _result = null;
        });
      },
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

  Widget _buildAdditionalCard(int index) {
    final a = _additional[index];
    final relItems = _relationships.isNotEmpty
        ? _relationships.where((e) => e.value != 'SELF').toList()
        : LeadwayLifeRelationship.values
            .where((e) => e != LeadwayLifeRelationship.self)
            .map((e) => LeadwayLifeEnumItem(value: e.code, description: e.label))
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Assuré ${index + 1}', style: const TextStyle(fontWeight: FontWeight.w700)),
            const Spacer(),
            IconButton(
              tooltip: 'Retirer',
              onPressed: () => _removeInsured(index),
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            ),
          ],
        ),
        DropdownButtonFormField<String>(
          initialValue: relItems.any((e) => e.value == a.relationship) ? a.relationship : relItems.first.value,
          decoration: _dropdownDecoration('Lien de parenté *'),
          items: relItems
              .map((e) => DropdownMenuItem(value: e.value, child: Text(e.description.isEmpty ? e.value : e.description)))
              .toList(),
          onChanged: (v) {
            if (v != null) {
              setState(() {
              a.relationship = v;
              _result = null;
            });
            }
          },
        ),
        const SizedBox(height: 12),
        _textField('Prénom *', a.firstNameCtrl, 'Prénom'),
        const SizedBox(height: 12),
        _textField('Nom *', a.lastNameCtrl, 'Nom'),
        const SizedBox(height: 12),
        _dateTile(
          label: 'Date de naissance *',
          date: a.birthDate,
          onTap: () async {
            final picked = await _pickDate(
              current: a.birthDate,
              first: DateTime(1920),
              last: DateTime.now(),
            );
            if (picked != null) {
              setState(() {
              a.birthDate = picked;
              _result = null;
            });
            }
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<LeadwayLifeGender>(
          initialValue: a.gender,
          decoration: _dropdownDecoration('Genre *'),
          items: LeadwayLifeGender.values
              .map((g) => DropdownMenuItem(value: g, child: Text(g.label)))
              .toList(),
          onChanged: (v) {
            if (v != null) {
              setState(() {
              a.gender = v;
              _result = null;
            });
            }
          },
        ),
        const SizedBox(height: 12),
        _textField('Téléphone', a.phoneCtrl, 'Optionnel', keyboard: TextInputType.phone),
        const SizedBox(height: 12),
        _textField('E-mail', a.emailCtrl, 'Optionnel', keyboard: TextInputType.emailAddress),
      ],
    );
  }

  Widget _buildResultCard(LeadwayLifeCotationResult result) {
    final p = result.data.premium;
    final freq = LeadwayLifePaymentFrequency.fromCode(p.frequency)?.label ?? p.frequency;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LeadwayBrand.gradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Résultat de la cotation',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            'Réf. ${result.data.subscriptionRef}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11),
          ),
          const SizedBox(height: 16),
          Text(
            '${_formatAmount(p.gross.amount)} ${p.gross.currency}',
            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
          ),
          Text(
            'Prime TTC — $freq',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
          ),
          const SizedBox(height: 12),
          _resultLine('Prime nette', '${_formatAmount(p.net.amount)} ${p.net.currency}'),
          _resultLine('Taxes', '${_formatAmount(p.tax.amount)} ${p.tax.currency}'),
          if (p.breakdown.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...p.breakdown.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(line, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12)),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final phone = _phoneCtrl.text.trim();
                if (phone.isNotEmpty) {
                  await LeadwayHostBridge.setMeta(LeadwayMetaKeys.phone, phone);
                }
                final subscriptionRef = result.data.subscriptionRef.isNotEmpty
                    ? result.data.subscriptionRef
                    : widget.subscriptionRef;
                if (subscriptionRef.isNotEmpty) {
                  await LeadwayHostBridge.setMeta(LeadwayMetaKeys.subscriptionRef, subscriptionRef);
                }
                if (!context.mounted) return;
                final premiumLabel =
                    '${_formatAmount(p.gross.amount)} ${p.gross.currency} ($freq)';
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => LeadwayLifePaymentScreen(
                      subscriptionRef: subscriptionRef,
                      productLabel: widget.productLabel,
                      telephone: phone.isNotEmpty ? phone : widget.telephone,
                      policyNumber: widget.policyNumber,
                      premiumLabel: premiumLabel,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: LeadwayBrand.primary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Procéder au paiement',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }
}

class _AdditionalInsuredDraft {
  _AdditionalInsuredDraft({required this.relationship});

  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  DateTime? birthDate;
  LeadwayLifeGender gender = LeadwayLifeGender.male;
  String relationship;

  void dispose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
  }
}
