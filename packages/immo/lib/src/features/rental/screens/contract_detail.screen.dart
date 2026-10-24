import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:immo/src/core/constants/immo.brand.dart';
import 'package:immo/src/features/rental/auth/scopes/rental_session.scope.dart';
import 'package:immo/src/features/rental/models/rental.contract.dart';
import 'package:immo/src/features/rental/navigation/rental_bottom.navigation.dart';
import 'package:immo/src/features/rental/services/rental_contract.service.dart';
import 'package:immo/src/features/rental/theme/themes/rental.theme.dart';
import 'package:immo/src/features/rental/utils/rental_format.util.dart';
import 'package:immo/src/features/rental/widgets/rental_layout_widgets.widget.dart';

/// A lease: its terms, who signed, the PDF; the owner signs it here and answers
/// the tenant's early termination request. Same home layout (green header + white sheet).
class ContractDetailScreen extends StatefulWidget {
  const ContractDetailScreen({
    super.key,
    required this.contractId,
    required this.onBack,
  });

  final String contractId;
  final VoidCallback onBack;

  @override
  State<ContractDetailScreen> createState() => _ContractDetailScreenState();
}

class _ContractDetailScreenState extends State<ContractDetailScreen> {
  RentalContract? _doc;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  RentalContractService get _contracts => RentalSessionScope.of(context).api.contracts;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final contract = await _contracts.fetchContract(widget.contractId);
      if (!mounted) return;
      setState(() {
        _doc = contract;
        _error = contract == null ? 'Document introuvable.' : null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger ce document.';
        _loading = false;
      });
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _openPdf(RentalContract doc) async {
    try {
      // The browser cannot send the sign-in: it opens a short-lived link instead
      final link = await _contracts.pdfLink(doc);
      final ok = await launchUrl(link, mode: LaunchMode.externalApplication);
      if (!ok && mounted) _toast('Impossible d’ouvrir le PDF');
    } catch (_) {
      if (mounted) _toast('Impossible d’ouvrir le PDF');
    }
  }

  Future<void> _sign(RentalContract doc) async {
    final signed = await showRentalSheet<bool>(
      context,
      builder: (_) => _SignSheet(contract: doc, contracts: _contracts),
    );
    if (signed != true || !mounted) return;
    _toast('Contrat signé');
    await _load();
  }

  Future<void> _answerTermination(RentalContract doc, {required bool approve}) async {
    final done = await showRentalSheet<bool>(
      context,
      builder: (_) => _TerminationSheet(contract: doc, approve: approve, contracts: _contracts),
    );
    if (done != true || !mounted) return;
    _toast(approve ? 'Résiliation acceptée' : 'Résiliation refusée');
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    final topPad = MediaQuery.paddingOf(context).top;
    final headerBand = topPad + 132.0;
    final doc = _doc;
    final userId = RentalSessionScope.of(context).userId;
    final highlight = doc != null && (doc.isActive || doc.isToSign);
    // The owner of this lease signs it as bailleur, once
    final canSign = doc != null &&
        doc.isToSign &&
        doc.ownerSignedAt == null &&
        (doc.ownerId == null || doc.ownerId == userId);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: b.header),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _DetailHeader(
              onBack: widget.onBack,
              subtitle: doc?.documentType ?? 'Contrat de location',
            ),
          ),
          Positioned(
            top: headerBand,
            left: 0,
            right: 0,
            bottom: 0,
            child: RentalWhiteSheet(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null || doc == null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _error ?? 'Document introuvable.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: b.muted),
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: _load,
                                  child: const Text('Réessayer'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView(
                          padding: EdgeInsets.fromLTRB(
                            RentalTheme.spacingLg,
                            RentalTheme.spacingLg,
                            RentalTheme.spacingLg,
                            RentalBottomNavigation.contentBottomPadding(
                                  context,
                                ) +
                                16,
                          ),
                          children: [
                            RentalSectionHeader(title: 'Détails'),
                            const SizedBox(height: RentalTheme.spacingMd),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    doc.title,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: b.text,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: highlight
                                        ? b.primary.withValues(alpha: 0.12)
                                        : b.searchFill,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    doc.statusLabel,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: highlight
                                          ? b.primaryDark
                                          : b.muted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            if (doc.isTerminationPending) ...[
                              _DetailGroup(
                                title: 'Demande de résiliation',
                                rows: [
                                  _DetailRow(
                                    label: 'Fin souhaitée',
                                    value: formatRentalDate(doc.terminationEndOn),
                                  ),
                                  _DetailRow(
                                    label: 'Motif',
                                    value: doc.terminationReason?.trim().isNotEmpty == true
                                        ? doc.terminationReason!.trim()
                                        : '—',
                                  ),
                                  _DetailRow(
                                    label: 'Demandée le',
                                    value: formatRentalDate(doc.terminationRequestedAt),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              RentalActionButton(
                                label: 'Accepter la résiliation',
                                icon: Icons.check_rounded,
                                filled: true,
                                onTap: () => _answerTermination(doc, approve: true),
                              ),
                              const SizedBox(height: 12),
                              RentalActionButton(
                                label: 'Refuser',
                                icon: Icons.close_rounded,
                                filled: false,
                                onTap: () => _answerTermination(doc, approve: false),
                              ),
                              const SizedBox(height: 20),
                            ],
                            _DetailGroup(
                              title: 'Bien',
                              rows: [
                                _DetailRow(
                                  label: 'Nom',
                                  value: doc.propertyName?.trim().isNotEmpty ==
                                          true
                                      ? doc.propertyName!
                                      : '—',
                                ),
                                _DetailRow(
                                  label: 'Adresse',
                                  value: doc.propertyAddress
                                              ?.trim()
                                              .isNotEmpty ==
                                          true
                                      ? doc.propertyAddress!
                                      : '—',
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _DetailGroup(
                              title: 'Locataire',
                              rows: [
                                _DetailRow(
                                  label: 'Nom',
                                  value: doc.tenantName?.trim().isNotEmpty == true
                                      ? doc.tenantName!
                                      : '—',
                                ),
                                _DetailRow(
                                  label: 'Contact',
                                  value: doc.tenantPhone?.trim().isNotEmpty ==
                                          true
                                      ? doc.tenantPhone!
                                      : '—',
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _DetailGroup(
                              title: 'Bail',
                              rows: [
                                _DetailRow(
                                  label: 'Période',
                                  value: 'Du ${formatRentalDate(doc.startDate)} au ${formatRentalDate(doc.endDate)}',
                                ),
                                _DetailRow(
                                  label: 'Loyer',
                                  value: formatRentalAmount(doc.rentAmount),
                                ),
                                _DetailRow(
                                  label: 'Caution',
                                  value: formatRentalAmount(doc.deposit),
                                ),
                                _DetailRow(
                                  label: 'Paiement',
                                  value: [doc.paymentModeLabel, doc.periodicityLabel]
                                      .whereType<String>()
                                      .join(' · ')
                                      .ifEmpty('—'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _DetailGroup(
                              title: 'Signatures',
                              rows: [
                                _DetailRow(
                                  label: 'Locataire',
                                  value: doc.tenantSignedAt == null
                                      ? 'En attente'
                                      : 'Signé le ${formatRentalDate(doc.tenantSignedAt)}',
                                ),
                                _DetailRow(
                                  label: 'Propriétaire',
                                  value: doc.ownerSignedAt == null
                                      ? 'En attente'
                                      : 'Signé le ${formatRentalDate(doc.ownerSignedAt)}',
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _DetailGroup(
                              title: 'Document',
                              rows: [
                                _DetailRow(
                                  label: 'Type',
                                  value: 'Contrat de location',
                                ),
                                _DetailRow(
                                  label: 'Numéro',
                                  value: doc.number ?? '—',
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            if (canSign) ...[
                              RentalActionButton(
                                label: 'Signer le contrat',
                                icon: Icons.draw_outlined,
                                filled: true,
                                onTap: () => _sign(doc),
                              ),
                              const SizedBox(height: 12),
                            ] else if (doc.isToSign && doc.tenantSignedAt == null) ...[
                              Text(
                                'En attente de la signature du locataire.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: b.muted, height: 1.35),
                              ),
                              const SizedBox(height: 12),
                            ],
                            RentalActionButton(
                              label: 'Ouvrir le PDF',
                              icon: Icons.picture_as_pdf_outlined,
                              filled: !canSign && !doc.isTerminationPending,
                              onTap: () => _openPdf(doc),
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

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.onBack,
    required this.subtitle,
  });

  final VoidCallback onBack;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final b = ImmoBrand.rentalOf(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        8,
        top + RentalTheme.spacingMd,
        RentalTheme.spacingLg,
        RentalTheme.spacingXl + 8,
      ),
      color: b.header,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              Expanded(
                child: Text(
                  'Mr Immo location',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(left: RentalTheme.spacingLg - 8),
            child: Text(
              'Document',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: RentalTheme.spacingLg - 8),
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailGroup extends StatelessWidget {
  const _DetailGroup({
    required this.title,
    required this.rows,
  });

  final String title;
  final List<_DetailRow> rows;

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: b.searchFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: b.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: b.muted,
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: b.muted,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: b.text,
            ),
          ),
        ),
      ],
    );
  }
}

/// The note fields of the lease sheets: the page's group look (search fill, 16 radius, border).
InputDecoration _noteDecoration(ImmoRentalPalette b, String hint) => InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: b.muted),
      filled: true,
      fillColor: b.searchFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: b.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: b.border),
      ),
    );

/// The owner signs with a finger and rates the tenant (1 to 5). Pops `true` once signed.
class _SignSheet extends StatefulWidget {
  const _SignSheet({required this.contract, required this.contracts});

  final RentalContract contract;
  final RentalContractService contracts;

  @override
  State<_SignSheet> createState() => _SignSheetState();
}

class _SignSheetState extends State<_SignSheet> {
  final _strokes = <List<Offset>>[];
  final _comment = TextEditingController();
  Size _padSize = Size.zero;
  int _rating = 0;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  bool get _ready => _strokes.any((s) => s.length > 1) && _rating > 0;

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final png = await _signaturePng(_strokes, _padSize);
      final comment = _comment.text.trim();
      await widget.contracts.signAsOwner(
        contractId: widget.contract.id,
        signature: 'data:image/png;base64,${base64Encode(png)}',
        tenantRating: _rating,
        comment: comment.isEmpty ? null : comment,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    final label = TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: b.muted);
    return RentalSheetFrame(
      title: 'Signer le contrat',
      children: [
        Text(
          [
            'En signant, vous acceptez le bail',
            if (widget.contract.number != null) widget.contract.number!,
            'avec ${widget.contract.tenantName ?? 'le locataire'}.',
          ].join(' '),
          style: TextStyle(fontSize: 13, color: b.muted, height: 1.35),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: Text('Votre signature', style: label)),
            TextButton(
              onPressed: _busy || _strokes.isEmpty ? null : () => setState(_strokes.clear),
              child: const Text('Effacer'),
            ),
          ],
        ),
        // Drawn in the theme's colours; the saved PNG is always dark ink (see _signaturePng)
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: b.searchFill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: b.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
            builder: (context, box) {
              _padSize = box.biggest;
              return GestureDetector(
                onPanStart: _busy ? null : (d) => setState(() => _strokes.add([d.localPosition])),
                onPanUpdate: _busy ? null : (d) => setState(() => _strokes.last.add(d.localPosition)),
                child: CustomPaint(
                  painter: _SignaturePainter(_strokes, ink: b.text),
                  child: _strokes.isEmpty
                      ? Center(
                          child: Text(
                            'Signez ici avec le doigt',
                            style: TextStyle(color: b.muted),
                          ),
                        )
                      : const SizedBox.expand(),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Text('Évaluez le locataire', style: label),
        const SizedBox(height: 4),
        Row(
          children: [
            for (var n = 1; n <= 5; n++)
              IconButton(
                onPressed: _busy ? null : () => setState(() => _rating = n),
                tooltip: '$n étoile${n > 1 ? 's' : ''}',
                icon: Icon(
                  n <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: b.text,
                  size: 32,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _comment,
          enabled: !_busy,
          minLines: 1,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          style: TextStyle(color: b.text),
          decoration: _noteDecoration(b, 'Commentaire sur le locataire (facultatif)'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: TextStyle(color: b.danger, fontSize: 13)),
        ],
        const SizedBox(height: 20),
        RentalActionButton(
          label: 'Signer',
          icon: Icons.draw_outlined,
          filled: true,
          busy: _busy,
          onTap: _ready ? _submit : null,
        ),
        if (!_ready) ...[
          const SizedBox(height: 8),
          Text(
            'Signez et notez le locataire pour continuer.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: b.muted),
          ),
        ],
      ],
    );
  }
}

class _SignaturePainter extends CustomPainter {
  _SignaturePainter(this.strokes, {required this.ink});

  final List<List<Offset>> strokes;
  final Color ink;

  static void paintStrokes(Canvas canvas, List<List<Offset>> strokes, Color ink) {
    final paint = Paint()
      ..color = ink
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final s in strokes) {
      if (s.length < 2) continue;
      final path = Path()..moveTo(s.first.dx, s.first.dy);
      for (final p in s.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  void paint(Canvas canvas, Size size) => paintStrokes(canvas, strokes, ink);

  @override
  bool shouldRepaint(_SignaturePainter old) => true;
}

/// The strokes as a PNG on transparent ground, twice the pad's size. The ink is the light
/// palette's text whatever the theme, so the signature shows on the contract's white page.
Future<List<int>> _signaturePng(List<List<Offset>> strokes, Size size) async {
  const scale = 2.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..scale(scale);
  _SignaturePainter.paintStrokes(canvas, strokes, ImmoRentalPalette.light.text);
  final image = await recorder
      .endRecording()
      .toImage((size.width * scale).ceil().clamp(1, 4000), (size.height * scale).ceil().clamp(1, 4000));
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

/// The owner accepts or refuses the tenant's early termination, with a note. Pops `true` once answered.
class _TerminationSheet extends StatefulWidget {
  const _TerminationSheet({required this.contract, required this.approve, required this.contracts});

  final RentalContract contract;
  final bool approve;
  final RentalContractService contracts;

  @override
  State<_TerminationSheet> createState() => _TerminationSheetState();
}

class _TerminationSheetState extends State<_TerminationSheet> {
  final _notes = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final notes = _notes.text.trim();
      await widget.contracts.decideTermination(
        contractId: widget.contract.id,
        approve: widget.approve,
        notes: notes.isEmpty ? null : notes,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    final c = widget.contract;
    return RentalSheetFrame(
      title: widget.approve ? 'Accepter la résiliation ?' : 'Refuser la résiliation ?',
      children: [
        Text(
          widget.approve
              ? 'Le bail prendra fin le ${formatRentalDate(c.terminationEndOn)} au lieu du ${formatRentalDate(c.endDate)}.'
              : 'Le bail continue jusqu’au ${formatRentalDate(c.endDate)}.',
          style: TextStyle(fontSize: 13, color: b.muted, height: 1.35),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _notes,
          enabled: !_busy,
          minLines: 2,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          style: TextStyle(color: b.text),
          decoration: _noteDecoration(b, 'Note pour le locataire (facultatif)'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: TextStyle(color: b.danger, fontSize: 13)),
        ],
        const SizedBox(height: 20),
        // Refusing keeps the outlined look of the button that opened this sheet
        RentalActionButton(
          label: widget.approve ? 'Accepter' : 'Refuser',
          icon: widget.approve ? Icons.check_rounded : Icons.close_rounded,
          filled: widget.approve,
          busy: _busy,
          onTap: _submit,
        ),
      ],
    );
  }
}
