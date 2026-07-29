import 'package:flutter/material.dart';

import 'package:billetterie/src/core/constants/billetterie.brand.dart';
import 'package:billetterie/src/core/host/billetterie_host.bridge.dart';
import 'package:billetterie/src/features/transport/constants/transport_cities.dart';
import 'package:billetterie/src/features/transport/services/billetterie_transport_api.service.dart';
import 'package:billetterie/src/features/transport/services/conductor_ticket.store.dart';

/// Step-by-step (swipeable) form for a conductor to create a transport ticket.
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

  bool _validateCurrentStep() {
    switch (_step) {
      case 0:
        if (!(_routeKey.currentState?.validate() ?? false)) return false;
        if (_fromCity == null || _toCity == null) {
          _toast('Choisissez les villes de départ et d’arrivée');
          return false;
        }
        if (_fromCity == _toCity) {
          _toast('Départ et arrivée doivent être différents');
          return false;
        }
        return true;
      case 1:
        if (_validFrom == null || _validUntil == null) {
          _toast('Indiquez départ et arrivée');
          return false;
        }
        if (!_validUntil!.isAfter(_validFrom!)) {
          _toast('L’arrivée doit être après le départ');
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

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _goNext() async {
    if (!_validateCurrentStep()) return;
    if (_step >= _stepCount - 1) {
      await _submit();
      return;
    }
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _goBack() async {
    if (_step == 0) {
      Navigator.of(context).maybePop();
      return;
    }
    await _pageController.previousPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (!_validateCurrentStep()) return;

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
        place: place,
        validFrom: _validFrom!,
        validUntil: _validUntil!,
        price: price,
        vehicleType: _vehicleType,
        vehicleNumber: _vehicleCtrl.text.trim(),
        driverCodeClient: driverCode,
        ticketType: _vehicleType,
        quantity: 1,
      );

      // Cache locally for offline business dashboard / demo merge.
      await _store.saveGenerated(
        issuerCodeClient: client.codeClient,
        ticket: ticket,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Billet ${ticket.ticketCode ?? ''} enregistré en base'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      _toast('$e');
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: _StepProgress(
              step: _step,
              total: _stepCount,
              labels: _stepTitles,
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (i) => setState(() => _step = i),
              children: [
                _StepScaffold(
                  child: Form(
                    key: _routeKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Où va le trajet ?',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: brand.text,
                              ),
                        ),
                        const SizedBox(height: 16),
                        _CityDropdown(
                          key: ValueKey('from-$_fromCity-$_toCity'),
                          label: 'Ville de départ',
                          value: _fromCity,
                          exclude: _toCity,
                          onChanged: (v) => setState(() => _fromCity = v),
                        ),
                        const SizedBox(height: 12),
                        _CityDropdown(
                          key: ValueKey('to-$_toCity-$_fromCity'),
                          label: 'Ville d’arrivée',
                          value: _toCity,
                          exclude: _fromCity,
                          onChanged: (v) => setState(() => _toCity = v),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _placeCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Point d’embarquement',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _StepScaffold(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Quand part-il ?',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: brand.text,
                            ),
                      ),
                      const SizedBox(height: 16),
                      _DateCard(
                        label: 'Départ',
                        value: _fmtWhen(_validFrom),
                        onTap: () => _pickDateTime(isFrom: true),
                      ),
                      const SizedBox(height: 12),
                      _DateCard(
                        label: 'Arrivée',
                        value: _fmtWhen(_validUntil),
                        onTap: () => _pickDateTime(isFrom: false),
                      ),
                      if (_validFrom != null && _validUntil != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Durée : ${ConductorTicketStore.durationLabel(_validFrom, _validUntil)}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: brand.muted,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                _StepScaffold(
                  child: Form(
                    key: _vehicleKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Quel véhicule ?',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: brand.text,
                              ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _vehicleType,
                          decoration: const InputDecoration(
                            labelText: 'Type de véhicule',
                            border: OutlineInputBorder(),
                          ),
                          items: _vehicleTypes
                              .map(
                                (v) =>
                                    DropdownMenuItem(value: v, child: Text(v)),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _vehicleType = v);
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _vehicleCtrl,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Champ requis'
                              : null,
                          decoration: const InputDecoration(
                            labelText: 'Immatriculation',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _driverNameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nom du chauffeur',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _driverPhoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Téléphone chauffeur',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _StepScaffold(
                  child: Form(
                    key: _priceKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Prix et confirmation',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: brand.text,
                              ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _priceCtrl,
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Champ requis';
                            }
                            if (int.tryParse(v.trim()) == null) {
                              return 'Montant invalide';
                            }
                            return null;
                          },
                          decoration: const InputDecoration(
                            labelText: 'Prix (Fcfa)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
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

class _StepScaffold extends StatelessWidget {
  const _StepScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      physics: const BouncingScrollPhysics(),
      child: child,
    );
  }
}

class _StepProgress extends StatelessWidget {
  const _StepProgress({
    required this.step,
    required this.total,
    required this.labels,
  });

  final int step;
  final int total;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final brand = BilletterieBrand.of(context);
    return Column(
      children: [
        Row(
          children: List.generate(total, (i) {
            final active = i <= step;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
                height: 4,
                decoration: BoxDecoration(
                  color: active ? brand.primaryDark : brand.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          'Étape ${step + 1}/$total · ${labels[step]}',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: brand.muted,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
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
    final cities = TransportCities.all
        .where((c) => exclude == null || c != exclude)
        .toList(growable: false);
    final selected = value != null && cities.contains(value) ? value : null;

    return DropdownButtonFormField<String>(
      initialValue: selected,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
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
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: brand.border),
          ),
          child: Row(
            children: [
              Icon(Icons.schedule_rounded, color: brand.primaryDark),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: brand.muted,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: brand.text,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: brand.muted),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: brand.primarySoft.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: brand.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    rows[i].$1,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: brand.muted,
                        ),
                  ),
                ),
                Flexible(
                  child: Text(
                    rows[i].$2,
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
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
