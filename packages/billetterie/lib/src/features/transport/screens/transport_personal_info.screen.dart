import 'package:flutter/material.dart';

import 'package:billetterie/src/core/constants/billetterie.brand.dart';
import 'package:billetterie/src/core/host/billetterie_host.bridge.dart';
import 'package:billetterie/src/features/transport/models/transport_profile.model.dart';
import 'package:billetterie/src/shared/widgets/ticket_purchase_result.dialog.dart';

enum _SexAtBirth { male, female }

/// Full-screen personal information form (opened from Profil).
class TransportPersonalInfoScreen extends StatefulWidget {
  const TransportPersonalInfoScreen({
    super.key,
    this.identity,
    required this.profile,
  });

  final BilletterieClientIdentity? identity;
  final TransportProfileState profile;

  @override
  State<TransportPersonalInfoScreen> createState() =>
      _TransportPersonalInfoScreenState();
}

class _TransportPersonalInfoScreenState
    extends State<TransportPersonalInfoScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _countryCode = TextEditingController(text: '+225');
  final _phone = TextEditingController();
  _SexAtBirth? _sex;
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _applyIdentity(widget.identity);
    _loadClientDetails();
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _countryCode.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _applyIdentity(BilletterieClientIdentity? identity) {
    if (identity == null) return;

    final first = identity.firstName?.trim();
    final last = identity.lastName?.trim();
    if ((first == null || first.isEmpty) && (last == null || last.isEmpty)) {
      final parts = _splitName(identity.displayName);
      _firstName.text = parts.$1;
      _lastName.text = parts.$2;
    } else {
      _firstName.text = first ?? '';
      _lastName.text = last ?? '';
    }

    _email.text = identity.email?.trim() ?? '';
    _countryCode.text =
        identity.countryCode?.trim().isNotEmpty == true
            ? identity.countryCode!.trim()
            : '+225';
    _phone.text = identity.phone?.trim() ?? '';
  }

  Future<void> _loadClientDetails() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final identity = await BilletterieHostBridge.resolveClientOrNull();
      if (!mounted) return;
      if (identity == null) {
        setState(() {
          _loadError = 'Connectez-vous pour charger votre profil client';
          _loading = false;
        });
        return;
      }
      setState(() {
        _applyIdentity(identity);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (widget.identity == null) {
        setState(() {
          _loadError = 'Impossible de charger le profil client';
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    }
  }

  (String, String) _splitName(String? raw) {
    final name = raw?.trim() ?? '';
    if (name.isEmpty) return ('', '');
    final bits = name.split(RegExp(r'\s+'));
    if (bits.length == 1) return (bits.first, '');
    return (bits.first, bits.sublist(1).join(' '));
  }

  void _soon(String label) {
    showBilletterieResultDialog(
      context,
      title: 'Bientôt disponible',
      message: '$label sera disponible prochainement.',
      kind: BilletterieResultKind.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    final brand = BilletterieBrand.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: brand.bg,
      appBar: AppBar(
        backgroundColor: brand.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: brand.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Informations personnelles',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: brand.text,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: brand.border),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _loadError!,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: brand.muted,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _loadClientDetails,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  children: [
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: brand.searchFill,
                            child: Icon(
                              Icons.person_rounded,
                              size: 48,
                              color: brand.muted,
                            ),
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () => _soon('Photo de profil'),
                            child: Text(
                              'Modifier la photo de profil',
                              style: textTheme.bodySmall?.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: brand.primaryDark,
                                decoration: TextDecoration.underline,
                                decorationColor: brand.primaryDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    _LabeledField(
                      brand: brand,
                      label: 'Prénom',
                      controller: _firstName,
                    ),
                    const SizedBox(height: 16),
                    _LabeledField(
                      brand: brand,
                      label: 'Nom',
                      controller: _lastName,
                    ),
                    const SizedBox(height: 16),
                    _FieldLabel(brand: brand, text: 'Sexe à la naissance'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _SexChip(
                            brand: brand,
                            label: 'Homme',
                            selected: _sex == _SexAtBirth.male,
                            onTap: () =>
                                setState(() => _sex = _SexAtBirth.male),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SexChip(
                            brand: brand,
                            label: 'Femme',
                            selected: _sex == _SexAtBirth.female,
                            onTap: () =>
                                setState(() => _sex = _SexAtBirth.female),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _LabeledField(
                      brand: brand,
                      label: 'E-mail',
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 100,
                          child: _LabeledField(
                            brand: brand,
                            label: 'Indicatif',
                            controller: _countryCode,
                            keyboardType: TextInputType.phone,
                            readOnly: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _LabeledField(
                            brand: brand,
                            label: 'Téléphone (profil)',
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            readOnly: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.profile.isConductorMode
                          ? 'Client PeyaPay · mode Conducteur'
                          : 'Client PeyaPay · mode Client',
                      style: textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: brand.muted,
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.brand, required this.text});

  final BilletterieBrand brand;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: brand.text,
          ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.brand,
    required this.label,
    required this.controller,
    this.keyboardType,
    this.readOnly = false,
  });

  final BilletterieBrand brand;
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldLabel(brand: brand, text: label),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: brand.text,
              ),
          decoration: InputDecoration(
            filled: true,
            fillColor: brand.card,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: brand.text.withValues(alpha: 0.85)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: brand.text.withValues(alpha: 0.85)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: brand.primaryDark, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}

class _SexChip extends StatelessWidget {
  const _SexChip({
    required this.brand,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final BilletterieBrand brand;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? brand.primarySoft : brand.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? brand.primaryDark
                  : brand.text.withValues(alpha: 0.85),
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: brand.text,
                ),
          ),
        ),
      ),
    );
  }
}
