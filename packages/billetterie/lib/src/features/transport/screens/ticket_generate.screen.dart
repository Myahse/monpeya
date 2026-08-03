import 'package:flutter/material.dart';

import 'package:billetterie/src/core/constants/billetterie.brand.dart';
import 'package:billetterie/src/core/host/billetterie_host.bridge.dart';
import 'package:billetterie/src/features/transport/constants/transport_cities.dart';
import 'package:billetterie/src/features/transport/services/billetterie_transport_api.service.dart';
import 'package:billetterie/src/features/transport/services/conductor_ticket.store.dart';
import 'package:billetterie/src/shared/widgets/ticket_purchase_result.dialog.dart';

/// Form for a conductor to create a transport ticket.
class TicketGenerateScreen extends StatefulWidget {
  const TicketGenerateScreen({super.key});

  @override
  State<TicketGenerateScreen> createState() => _TicketGenerateScreenState();
}

class _TicketGenerateScreenState extends State<TicketGenerateScreen> {
  static const _stepCount = 4;

  final _pageController = PageController();
  final _api = BilletterieTransportApiService();
  final _store = ConductorTicketStore();

  final _placeCtrl = TextEditingController();
  final _vehicleCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _driverNameCtrl = TextEditingController();
  final _driverPhoneCtrl = TextEditingController();

  final _routeKey = GlobalKey<FormState>();
  final _vehicleKey = GlobalKey<FormState>();
  final _priceKey = GlobalKey<FormState>();

  int _step = 0;
  String? _fromCity;
  String? _toCity;
  DateTime? _validFrom;
  DateTime? _validUntil;
  String _vehicleType = 'BUS';
  bool _saving = false;

  static const _vehicleTypes = [
    'BUS',
    'MINIBUS',
    'CAR',
    'TAXI',
    'MOTORBIKE',
    'OTHER',
  ];

  static const _stepTitles = [
    'Trajet',
    'Horaires',
    'Véhicule',
    'Prix & publication',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _placeCtrl.dispose();
    _vehicleCtrl.dispose();
    _priceCtrl.dispose();
    _driverNameCtrl.dispose();
    _driverPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({required bool isFrom}) async {
    final now = DateTime.now();
    final initial = isFrom
        ? (_validFrom ?? now)
        : (_validUntil ?? now.add(const Duration(hours: 2)));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    final dt =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isFrom) {
        _validFrom = dt;
      } else {
        _validUntil = dt;
      }
    });
  }

  Future<void> _notify({
    required String title,
    required String message,
    BilletterieResultKind kind = BilletterieResultKind.info,
  }) {
    return showBilletterieResultDialog(
      context,
      title: title,
      message: message,
      kind: kind,
    );
  }

  Future<bool> _validateCurrentStep() async {
    switch (_step) {
      case 0:
        if (!(_routeKey.currentState?.validate() ?? false)) return false;
        if (_fromCity == null || _toCity == null) {
          await _notify(
            title: 'Trajet incomplet',
            message: 'Choisissez les villes de départ et d’arrivée.',
          );
          return false;
        }
        if (_fromCity == _toCity) {
          await _notify(
            title: 'Trajet invalide',
            message: 'Le départ et l’arrivée doivent être différents.',
          );
          return false;
        }
        return true;
      case 1:
        if (_validFrom == null || _validUntil == null) {
          await _notify(
            title: 'Horaires manquants',
            message: 'Indiquez les horaires de départ et d’arrivée.',
          );
          return false;
        }
        if (!_validUntil!.isAfter(_validFrom!)) {
          await _notify(
            title: 'Horaires invalides',
            message: 'L’arrivée doit être après le départ.',
          );
          return false;
        }
        return true;
      case 2:
        return _vehicleKey.currentState?.validate() ?? false;
      case 3:
        return _priceKey.currentState?.validate() ?? false;
      default:
        return true;
    }
  }

  Future<void> _goNext() async {
    if (!await _validateCurrentStep()) return;
    if (_step >= _stepCount - 1) {
      await _submit();
      return;
    }
    await _pageController.animateToPage(
      _step + 1,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _goBack() async {
    if (_step == 0) {
      Navigator.of(context).maybePop();
      return;
    }
    await _pageController.animateToPage(
      _step - 1,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (!await _validateCurrentStep()) return;

    setState(() => _saving = true);
    try {
      final client = await BilletterieHostBridge.requireClient();
      final fromCity = _fromCity!;
      final toCity = _toCity!;
      final price = int.parse(_priceCtrl.text.trim());
      final place =
          _placeCtrl.text.trim().isEmpty ? null : _placeCtrl.text.trim();
      final driverPhone = _driverPhoneCtrl.text.trim();
      // Prefer explicit driver Peya id; else conductor publishes as own driver.
      final driverCode = driverPhone.isNotEmpty ? driverPhone : client.codeClient;

      final ticket = await _api.generateTicket(
        codeClient: client.codeClient,
        title: '$fromCity - $toCity',
        fromCity: fromCity,
        toCity: toCity,
        place: place,
        validFrom: _validFrom!,
        validUntil: _validUntil!,
        price: price,
        vehicleType: _vehicleType,
        vehicleNumber: _vehicleCtrl.text.trim(),
        driverCodeClient: driverCode,
        driverName: _driverNameCtrl.text.trim().isEmpty
            ? null
            : _driverNameCtrl.text.trim(),
        driverPhone: driverPhone.isEmpty ? null : driverPhone,
        ticketType: _vehicleType,
        quantity: 1,
      );

      // Cache locally for offline business dashboard / demo merge.
      await _store.saveGenerated(
        issuerCodeClient: client.codeClient,
        ticket: ticket,
      );

      if (!mounted) return;
      final code = ticket.ticketCode?.trim();
      await showBilletterieResultDialog(
        context,
        title: 'Billet publié',
        message: code != null && code.isNotEmpty
            ? 'Votre billet a été créé avec succès.\nCode : $code'
            : 'Votre billet a été créé avec succès.',
        kind: BilletterieResultKind.success,
        confirmLabel: 'Terminer',
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      await showBilletterieResultDialog(
        context,
        title: 'Publication impossible',
        message: '$e',
        kind: BilletterieResultKind.error,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _fmtWhen(DateTime? dt) {
    if (dt == null) return 'Choisir';
    return '${ConductorTicketStore.hhmm(dt)} · ${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final brand = BilletterieBrand.of(context);
    final isLast = _step == _stepCount - 1;
    final fieldStyle = _FieldStyle.of(context);

    return Scaffold(
      backgroundColor: brand.bg,
      appBar: AppBar(
        title: Text(_stepTitles[_step]),
        backgroundColor: brand.bg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _saving ? null : _goBack,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _step = i),
              children: [
                _StepScaffold(
                  title: 'Où va le trajet ?',
                  subtitle: 'Choisissez le départ, l’arrivée et le point d’embarquement.',
                  child: Form(
                    key: _routeKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _CityDropdown(
                          key: ValueKey('from-$_fromCity-$_toCity'),
                          label: 'Ville de départ',
                          value: _fromCity,
                          exclude: _toCity,
                          onChanged: (v) => setState(() => _fromCity = v),
                        ),
                        const SizedBox(height: 14),
                        _CityDropdown(
                          key: ValueKey('to-$_toCity-$_fromCity'),
                          label: 'Ville d’arrivée',
                          value: _toCity,
                          exclude: _fromCity,
                          onChanged: (v) => setState(() => _toCity = v),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _placeCtrl,
                          style: fieldStyle.textStyle,
                          decoration: fieldStyle.decoration(
                            label: 'Point d’embarquement',
                            hint: 'Gare, parking, arrêt…',
                            prefixIcon: Icons.place_outlined,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _StepScaffold(
                  title: 'Quand part-il ?',
                  subtitle: 'Indiquez les horaires de départ et d’arrivée.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _DateCard(
                        label: 'Départ',
                        value: _fmtWhen(_validFrom),
                        onTap: () => _pickDateTime(isFrom: true),
                      ),
                      const SizedBox(height: 14),
                      _DateCard(
                        label: 'Arrivée',
                        value: _fmtWhen(_validUntil),
                        onTap: () => _pickDateTime(isFrom: false),
                      ),
                      if (_validFrom != null && _validUntil != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: brand.primarySoft.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.timelapse_rounded, color: brand.primaryDark, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                'Durée : ${ConductorTicketStore.durationLabel(_validFrom, _validUntil)}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: brand.text,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _StepScaffold(
                  title: 'Quel véhicule ?',
                  subtitle: 'Renseignez le type, la plaque et le chauffeur.',
                  child: Form(
                    key: _vehicleKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _vehicleType,
                          isExpanded: true,
                          style: fieldStyle.textStyle,
                          decoration: fieldStyle.decoration(
                            label: 'Type de véhicule',
                            prefixIcon: Icons.directions_bus_filled_outlined,
                          ),
                          items: _vehicleTypes
                              .map(
                                (v) => DropdownMenuItem(value: v, child: Text(v)),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _vehicleType = v);
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _vehicleCtrl,
                          style: fieldStyle.textStyle,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Champ requis'
                              : null,
                          decoration: fieldStyle.decoration(
                            label: 'Immatriculation',
                            hint: 'Ex. AB-1234-CI',
                            prefixIcon: Icons.confirmation_number_outlined,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _driverNameCtrl,
                          style: fieldStyle.textStyle,
                          decoration: fieldStyle.decoration(
                            label: 'Nom du chauffeur',
                            prefixIcon: Icons.person_outline_rounded,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _driverPhoneCtrl,
                          keyboardType: TextInputType.phone,
                          style: fieldStyle.textStyle,
                          decoration: fieldStyle.decoration(
                            label: 'Téléphone chauffeur',
                            hint: '07 XX XX XX XX',
                            prefixIcon: Icons.phone_outlined,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _StepScaffold(
                  title: 'Prix et confirmation',
                  subtitle: 'Fixez le montant puis vérifiez le récapitulatif.',
                  child: Form(
                    key: _priceKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _priceCtrl,
                          keyboardType: TextInputType.number,
                          style: fieldStyle.textStyle,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Champ requis';
                            }
                            if (int.tryParse(v.trim()) == null) {
                              return 'Montant invalide';
                            }
                            return null;
                          },
                          decoration: fieldStyle.decoration(
                            label: 'Prix (Fcfa)',
                            hint: 'Ex. 2500',
                            prefixIcon: Icons.payments_outlined,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _ReviewCard(
                          fromCity: _fromCity,
                          toCity: _toCity,
                          place: _placeCtrl.text.trim(),
                          fromWhen: _fmtWhen(_validFrom),
                          toWhen: _fmtWhen(_validUntil),
                          vehicleType: _vehicleType,
                          plate: _vehicleCtrl.text.trim(),
                          price: _priceCtrl.text.trim(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : _goBack,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: brand.primaryDark,
                          side: BorderSide(color: brand.primaryDark, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Retour'),
                      ),
                    ),
                  if (_step > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _saving ? null : _goNext,
                      style: FilledButton.styleFrom(
                        backgroundColor: brand.primaryDark,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _saving
                            ? 'Création…'
                            : (isLast ? 'Publier le billet' : 'Continuer'),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldStyle {
  _FieldStyle({
    required this.brand,
    required this.textStyle,
  });

  final BilletterieBrand brand;
  final TextStyle textStyle;

  static _FieldStyle of(BuildContext context) {
    final brand = BilletterieBrand.of(context);
    return _FieldStyle(
      brand: brand,
      textStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(
            color: brand.text,
            fontWeight: FontWeight.w600,
          ),
    );
  }

  InputDecoration decoration({
    required String label,
    String? hint,
    IconData? prefixIcon,
  }) {
    final radius = BorderRadius.circular(16);
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: brand.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      prefixIcon: prefixIcon == null
          ? null
          : Icon(prefixIcon, color: brand.primaryDark, size: 22),
      labelStyle: TextStyle(
        color: brand.muted,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: TextStyle(
        color: brand.muted.withValues(alpha: 0.85),
        fontWeight: FontWeight.w500,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: brand.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: brand.primaryDark, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: brand.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: brand.danger, width: 1.6),
      ),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: brand.border),
      ),
    );
  }
}

class _StepScaffold extends StatelessWidget {
  const _StepScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final brand = BilletterieBrand.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                  decoration: BoxDecoration(
                    color: brand.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: brand.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: brand.text,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: brand.muted,
                              height: 1.35,
                            ),
                      ),
                      const SizedBox(height: 22),
                      child,
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CityDropdown extends StatelessWidget {
  const _CityDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.exclude,
  });

  final String label;
  final String? value;
  final String? exclude;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final fieldStyle = _FieldStyle.of(context);
    final cities = TransportCities.all
        .where((c) => exclude == null || c != exclude)
        .toList(growable: false);
    final selected = value != null && cities.contains(value) ? value : null;

    return DropdownButtonFormField<String>(
      initialValue: selected,
      isExpanded: true,
      style: fieldStyle.textStyle,
      decoration: fieldStyle.decoration(
        label: label,
        prefixIcon: Icons.location_city_rounded,
      ),
      items: cities
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
      onChanged: onChanged,
    );
  }
}

class _DateCard extends StatelessWidget {
  const _DateCard({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brand = BilletterieBrand.of(context);
    return Material(
      color: brand.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: brand.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: brand.primarySoft.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.schedule_rounded, color: brand.primaryDark, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: brand.muted,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: brand.text,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: brand.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.fromCity,
    required this.toCity,
    required this.place,
    required this.fromWhen,
    required this.toWhen,
    required this.vehicleType,
    required this.plate,
    required this.price,
  });

  final String? fromCity;
  final String? toCity;
  final String place;
  final String fromWhen;
  final String toWhen;
  final String vehicleType;
  final String plate;
  final String price;

  @override
  Widget build(BuildContext context) {
    final brand = BilletterieBrand.of(context);
    final rows = <(String, String)>[
      ('Trajet', '${fromCity ?? '—'} → ${toCity ?? '—'}'),
      if (place.isNotEmpty) ('Embarquement', place),
      ('Départ', fromWhen),
      ('Arrivée', toWhen),
      ('Véhicule', '$vehicleType · $plate'),
      if (price.isNotEmpty) ('Prix', '$price Fcfa'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: brand.primarySoft.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: brand.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Récapitulatif',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: brand.text,
                ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    rows[i].$1,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: brand.muted,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Flexible(
                  child: Text(
                    rows[i].$2,
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: brand.text,
                        ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
