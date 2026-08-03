import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:billetterie/src/core/constants/billetterie.brand.dart';
import 'package:billetterie/src/core/host/billetterie_host.bridge.dart';
import 'package:billetterie/src/features/event/models/event_ticket_layout.dart';
import 'package:billetterie/src/features/event/services/billetterie_event_api.service.dart';
import 'package:billetterie/src/features/event/widgets/event_datetime_range_sheet.widget.dart';
import 'package:billetterie/src/features/event/widgets/event_ticket_preview.widget.dart';
import 'package:billetterie/src/shared/models/ticketing_api.exception.dart';
import 'package:billetterie/src/shared/widgets/ticket_purchase_result.dialog.dart';

/// Stepped wizard: event details → lieu/dates → billets (layout) → publier.
class EventCreateScreen extends StatefulWidget {
  const EventCreateScreen({super.key});

  @override
  State<EventCreateScreen> createState() => _EventCreateScreenState();
}

class _EventCreateScreenState extends State<EventCreateScreen> {
  static const _steps = [
    (title: 'Événement', icon: Icons.celebration_outlined),
    (title: 'Lieu & dates', icon: Icons.place_outlined),
    (title: 'Billets', icon: Icons.confirmation_number_outlined),
    (title: 'Finaliser', icon: Icons.check_circle_outline),
  ];

  final _api = BilletterieEventApiService();
  final _pageCtrl = PageController();
  final _nameCtrl = TextEditingController();
  final _venueCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController(text: 'Abidjan');
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _maxTicketsCtrl = TextEditingController();

  final _step0Key = GlobalKey<FormState>();
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();

  int _step = 0;
  String _category = 'Concerts';
  EventTicketLayout _layout = EventTicketLayout.horizontal;
  DateTime _start = DateTime.now().add(const Duration(days: 7));
  DateTime _end = DateTime.now().add(const Duration(days: 7, hours: 3));
  bool _saving = false;

  static const _categories = [
    'Concerts',
    'Festivals',
    'Théâtre',
    'Ballet',
    'Art',
    'Autre',
  ];

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    _venueCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _maxTicketsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDates({
    EventDateTimeRangeField field = EventDateTimeRangeField.start,
  }) async {
    final result = await showEventDateTimeRangeSheet(
      context: context,
      initialStart: _start,
      initialEnd: _end,
      initialField: field,
      title: 'Lieu & dates',
      confirmLabel: 'Confirmer les dates',
      dayCount: 400,
    );
    if (!mounted || result == null) return;
    setState(() {
      _start = result.start;
      _end = result.end;
    });
  }

  String _fmt(DateTime d) => formatEventDateTime(d);

  String get _pricePreview {
    final n = int.tryParse(_priceCtrl.text.trim());
    if (n == null) return '';
    return '$n FCFA';
  }

  bool _validateCurrentStep() {
    switch (_step) {
      case 0:
        return _step0Key.currentState?.validate() ?? false;
      case 1:
        if (!(_step1Key.currentState?.validate() ?? false)) return false;
        if (!_end.isAfter(_start)) {
          showBilletterieResultDialog(
            context,
            title: 'Plage invalide',
            message: 'La fin doit être après le début.',
            kind: BilletterieResultKind.error,
            brand: BilletterieBrand.eventOf(context),
          );
          return false;
        }
        return true;
      case 2:
        if (!(_step2Key.currentState?.validate() ?? false)) return false;
        final price = int.tryParse(_priceCtrl.text.trim()) ?? -1;
        final maxTickets = int.tryParse(_maxTicketsCtrl.text.trim()) ?? 0;
        if (price < 0 || maxTickets < 1) {
          showBilletterieResultDialog(
            context,
            title: 'Champs invalides',
            message: 'Vérifiez le prix et le nombre de billets.',
            kind: BilletterieResultKind.error,
            brand: BilletterieBrand.eventOf(context),
          );
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  Future<void> _goNext() async {
    if (!_validateCurrentStep()) return;
    if (_step >= _steps.length - 1) return;
    setState(() => _step += 1);
    await _pageCtrl.animateToPage(
      _step,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _goBack() async {
    if (_step == 0) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() => _step -= 1);
    await _pageCtrl.animateToPage(
      _step,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish({required bool publish}) async {
    if (!_validateCurrentStep()) return;
    await _submit(publish: publish);
  }

  Future<void> _submit({required bool publish}) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final client = await BilletterieHostBridge.requireClient();
      final price = int.tryParse(_priceCtrl.text.trim()) ?? 0;
      final maxTickets = int.tryParse(_maxTicketsCtrl.text.trim()) ?? 0;

      var created = await _api.createEvent(
        codeClient: client.codeClient,
        name: _nameCtrl.text.trim(),
        category: _category,
        startAt: _start,
        endAt: _end,
        ticketPrice: price,
        maxTickets: maxTickets,
        venueName: _venueCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        ticketLayout: _layout,
      );

      var published = false;
      if (publish && created.id.isNotEmpty) {
        try {
          created = await _api.publishEvent(
            eventCode: created.id,
            codeClient: client.codeClient,
          );
          published = true;
        } on TicketingApiException {
          // Event exists as draft; surface soft failure below.
        }
      }

      if (!mounted) return;
      final idSuffix =
          created.id.isNotEmpty ? ' (N° ${created.id})' : '';
      if (publish && !published) {
        await showBilletterieResultDialog(
          context,
          title: 'Enregistré en brouillon',
          message:
              '${created.name} a été créé$idSuffix, mais la publication a échoué.\n'
              'Vous pourrez le publier depuis l’espace organisateur.',
          kind: BilletterieResultKind.error,
          brand: BilletterieBrand.eventOf(context),
        );
      } else {
        await showBilletterieResultDialog(
          context,
          title: published ? 'Événement publié' : 'Brouillon enregistré',
          message: published
              ? '${created.name} est en ligne$idSuffix.\n'
                  'Format billet : ${_layout.labelFr}.'
              : '${created.name} est enregistré$idSuffix sans être publié.\n'
                  'Les billets ne sont pas encore à la vente.',
          kind: BilletterieResultKind.success,
          brand: BilletterieBrand.eventOf(context),
        );
      }
      if (mounted) Navigator.of(context).maybePop(true);
    } on TicketingApiException catch (e) {
      if (!mounted) return;
      await showBilletterieResultDialog(
        context,
        title: 'Création impossible',
        message: e.message,
        kind: BilletterieResultKind.error,
        brand: BilletterieBrand.eventOf(context),
      );
    } catch (e) {
      if (!mounted) return;
      await showBilletterieResultDialog(
        context,
        title: 'Création impossible',
        message: '$e',
        kind: BilletterieResultKind.error,
        brand: BilletterieBrand.eventOf(context),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brand = BilletterieBrand.eventOf(context);
    final isLast = _step == _steps.length - 1;

    return Scaffold(
      backgroundColor: brand.bg,
      appBar: AppBar(
        backgroundColor: brand.bg,
        foregroundColor: brand.text,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _saving ? null : _goBack,
        ),
        title: Text(
          'Nouvel événement',
          style: TextStyle(color: brand.text, fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: _StepHeader(
              brand: brand,
              steps: _steps,
              current: _step,
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageCtrl,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _StepScaffold(
                  formKey: _step0Key,
                  child: _buildStepEvent(brand),
                ),
                _StepScaffold(
                  formKey: _step1Key,
                  child: _buildStepPlace(brand),
                ),
                _StepScaffold(
                  formKey: _step2Key,
                  child: _buildStepTickets(brand),
                ),
                _StepScaffold(
                  child: _buildStepReview(brand),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: isLast
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton(
                          onPressed:
                              _saving ? null : () => _finish(publish: true),
                          style: FilledButton.styleFrom(
                            backgroundColor: brand.primaryDark,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Créer et publier',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed:
                              _saving ? null : () => _finish(publish: false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: brand.text,
                            side: BorderSide(color: brand.border),
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Enregistrer en brouillon',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextButton(
                          onPressed: _saving ? null : _goBack,
                          child: Text(
                            'Retour',
                            style: TextStyle(
                              color: brand.muted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        if (_step > 0)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _saving ? null : _goBack,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: brand.text,
                                side: BorderSide(color: brand.border),
                                minimumSize: const Size.fromHeight(52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text('Retour'),
                            ),
                          ),
                        if (_step > 0) const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: _saving ? null : _goNext,
                            style: FilledButton.styleFrom(
                              backgroundColor: brand.primaryDark,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Continuer',
                              style: TextStyle(fontWeight: FontWeight.w800),
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

  Widget _buildStepEvent(BilletterieBrand brand) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(brand: brand, title: 'Parlez-nous de l’événement'),
        const SizedBox(height: 14),
        _field(
          brand: brand,
          controller: _nameCtrl,
          label: 'Nom de l’événement',
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Obligatoire' : null,
        ),
        const SizedBox(height: 14),
        Text(
          'Catégorie',
          style: TextStyle(
            color: brand.muted,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in _categories)
              ChoiceChip(
                label: Text(c),
                selected: _category == c,
                onSelected: (_) => setState(() => _category = c),
                selectedColor: brand.primaryDark.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: _category == c ? brand.primaryDark : brand.text,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        _field(
          brand: brand,
          controller: _descCtrl,
          label: 'Description (optionnel)',
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildStepPlace(BilletterieBrand brand) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(brand: brand, title: 'Où et quand ?'),
        const SizedBox(height: 14),
        _field(
          brand: brand,
          controller: _venueCtrl,
          label: 'Lieu / salle',
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Obligatoire' : null,
        ),
        const SizedBox(height: 12),
        _field(
          brand: brand,
          controller: _cityCtrl,
          label: 'Ville',
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Obligatoire' : null,
        ),
        const SizedBox(height: 12),
        _field(
          brand: brand,
          controller: _addressCtrl,
          label: 'Adresse (optionnel)',
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _DateButton(
                brand: brand,
                label: 'Début',
                value: _fmt(_start),
                onTap: () => _pickDates(field: EventDateTimeRangeField.start),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _DateButton(
                brand: brand,
                label: 'Fin',
                value: _fmt(_end),
                onTap: () => _pickDates(field: EventDateTimeRangeField.end),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepTickets(BilletterieBrand brand) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(brand: brand, title: 'Construisez le billet'),
        const SizedBox(height: 8),
        Text(
          'Choisissez le format que vos clients verront.',
          style: TextStyle(color: brand.muted, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _LayoutChoiceCard(
                brand: brand,
                layout: EventTicketLayout.horizontal,
                selected: _layout == EventTicketLayout.horizontal,
                onTap: () =>
                    setState(() => _layout = EventTicketLayout.horizontal),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _LayoutChoiceCard(
                brand: brand,
                layout: EventTicketLayout.square,
                selected: _layout == EventTicketLayout.square,
                onTap: () => setState(() => _layout = EventTicketLayout.square),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Center(
          child: EventTicketPreview(
            layout: _layout,
            title: _nameCtrl.text.trim(),
            venue: _venueCtrl.text.trim().isEmpty
                ? _cityCtrl.text.trim()
                : _venueCtrl.text.trim(),
            dateLabel: _fmt(_start),
            priceLabel: _pricePreview,
            selected: true,
            width: _layout == EventTicketLayout.horizontal ? 300 : 220,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _field(
                brand: brand,
                controller: _priceCtrl,
                label: 'Prix (FCFA)',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obligatoire' : null,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _field(
                brand: brand,
                controller: _maxTicketsCtrl,
                label: 'Nb billets',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obligatoire' : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepReview(BilletterieBrand brand) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionTitle(brand: brand, title: 'Vérifiez avant de créer'),
        const SizedBox(height: 8),
        Text(
          'Publiez maintenant pour mettre les billets en vente, '
          'ou enregistrez un brouillon pour finaliser plus tard.',
          style: TextStyle(
            color: brand.muted,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: EventTicketPreview(
            layout: _layout,
            title: _nameCtrl.text.trim(),
            venue: _venueCtrl.text.trim(),
            dateLabel: _fmt(_start),
            priceLabel: _pricePreview,
            selected: true,
            width: _layout == EventTicketLayout.horizontal ? 300 : 220,
          ),
        ),
        const SizedBox(height: 18),
        _ReviewCard(
          brand: brand,
          rows: [
            ('Nom', _nameCtrl.text.trim()),
            ('Catégorie', _category),
            ('Lieu', _venueCtrl.text.trim()),
            ('Ville', _cityCtrl.text.trim()),
            ('Début', _fmt(_start)),
            ('Fin', _fmt(_end)),
            ('Prix', _pricePreview),
            ('Billets', _maxTicketsCtrl.text.trim()),
            ('Format', _layout.labelFr),
          ],
        ),
      ],
    );
  }

  Widget _field({
    required BilletterieBrand brand,
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      onChanged: onChanged,
      style: TextStyle(color: brand.text, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: brand.muted),
        filled: true,
        fillColor: brand.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: brand.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: brand.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: brand.primaryDark, width: 1.4),
        ),
      ),
    );
  }
}

class _StepScaffold extends StatelessWidget {
  const _StepScaffold({this.formKey, required this.child});

  final GlobalKey<FormState>? formKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final body = ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [child],
    );
    if (formKey == null) return body;
    return Form(key: formKey, child: body);
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.brand,
    required this.steps,
    required this.current,
  });

  final BilletterieBrand brand;
  final List<({String title, IconData icon})> steps;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              if (i > 0)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    color: i <= current
                        ? brand.primaryDark
                        : brand.border,
                  ),
                ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i <= current
                      ? brand.primaryDark
                      : brand.card,
                  border: Border.all(
                    color: i <= current ? brand.primaryDark : brand.border,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  steps[i].icon,
                  size: 16,
                  color: i <= current ? Colors.white : brand.muted,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Étape ${current + 1}/${steps.length} · ${steps[current].title}',
          style: TextStyle(
            color: brand.muted,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.brand, required this.title});

  final BilletterieBrand brand;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: brand.text,
        fontWeight: FontWeight.w800,
        fontSize: 20,
      ),
    );
  }
}

class _LayoutChoiceCard extends StatelessWidget {
  const _LayoutChoiceCard({
    required this.brand,
    required this.layout,
    required this.selected,
    required this.onTap,
  });

  final BilletterieBrand brand;
  final EventTicketLayout layout;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? brand.primaryDark.withValues(alpha: 0.12)
          : brand.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? brand.primaryDark : brand.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                layout == EventTicketLayout.horizontal
                    ? Icons.crop_landscape_rounded
                    : Icons.crop_square_rounded,
                color: selected ? brand.primaryDark : brand.muted,
              ),
              const SizedBox(height: 8),
              Text(
                layout.labelFr,
                style: TextStyle(
                  color: brand.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                layout.subtitleFr,
                style: TextStyle(
                  color: brand.muted,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.brand, required this.rows});

  final BilletterieBrand brand;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: brand.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: brand.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 18, color: brand.border),
            Row(
              children: [
                SizedBox(
                  width: 96,
                  child: Text(
                    rows[i].$1,
                    style: TextStyle(
                      color: brand.muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    rows[i].$2.isEmpty ? '—' : rows[i].$2,
                    style: TextStyle(
                      color: brand.text,
                      fontWeight: FontWeight.w700,
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

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.brand,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final BilletterieBrand brand;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: brand.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: brand.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: brand.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: brand.text,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
