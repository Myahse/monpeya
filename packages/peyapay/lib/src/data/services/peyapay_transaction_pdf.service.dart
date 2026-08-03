import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import 'package:peyapay/src/core/constants/peya_pay.assets.dart';
import 'package:peyapay/src/core/host/peyapay_host.bridge.dart';
import 'package:peyapay/src/core/utils/formatters.util.dart';
import 'package:peyapay/src/data/models/transaction.item.dart';

class PeyapayTransactionPdfService {
  static const _brandGreen = PdfColor.fromInt(0xFF006D56);
  static const _ink = PdfColor.fromInt(0xFF111827);
  static const _muted = PdfColor.fromInt(0xFF6B7280);
  static const _border = PdfColor.fromInt(0xFFE5E7EB);

  Future<Uint8List> buildSingleReceipt(TransactionItem item) async {
    final logos = await _loadLogos();
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _header(logos, title: 'Reçu de transaction'),
              pw.SizedBox(height: 28),
              pw.Center(
                child: pw.Text(
                  '${item.isCredit ? '+' : '-'}${formatFrMoneySigned(item.amount.abs())} XOF',
                  style: pw.TextStyle(
                    fontSize: 26,
                    fontWeight: pw.FontWeight.bold,
                    color: item.isCredit ? _brandGreen : _ink,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  item.recipient,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _ink),
                ),
              ),
              pw.SizedBox(height: 24),
              _detailsCard([
                _DetailEntry('Type', item.typeLabel),
                _DetailEntry('Date', formatFrDateTime(item.dateIso)),
                _DetailEntry('Statut', item.statusLabel),
                if (item.reference != null && item.reference!.isNotEmpty)
                  _DetailEntry('Référence', item.reference!),
                if (item.description != null && item.description!.isNotEmpty)
                  _DetailEntry('Description', item.description!),
                _DetailEntry('Identifiant', item.id),
              ]),
              pw.Spacer(),
              _footer(logos: logos),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  Future<Uint8List> buildStatement({
    required List<TransactionItem> items,
    required String periodLabel,
  }) async {
    final logos = await _loadLogos();
    final doc = pw.Document();
    final sorted = [...items]..sort((a, b) => b.dateIso.compareTo(a.dateIso));

    final credits = sorted.where((t) => t.isCredit).fold<int>(0, (sum, t) => sum + t.amount);
    final debits = sorted.where((t) => !t.isCredit).fold<int>(0, (sum, t) => sum + t.amount.abs());

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 32),
        header: (context) => _header(logos, title: 'Relevé de transactions'),
        footer: (context) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 12),
          child: _footer(compact: true, logos: logos),
        ),
        build: (context) {
          return [
            pw.Text(
              'Période : $periodLabel',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _ink),
            ),
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _border),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Entrées', style: pw.TextStyle(fontSize: 10, color: _muted)),
                        pw.Text(
                          '+${formatFrMoneySigned(credits)} XOF',
                          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _brandGreen),
                        ),
                      ],
                    ),
                  ),
                  pw.Container(width: 1, height: 32, color: _border),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Sorties', style: pw.TextStyle(fontSize: 10, color: _muted)),
                        pw.Text(
                          '-${formatFrMoneySigned(debits)} XOF',
                          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _ink),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 18),
            if (sorted.isEmpty)
              pw.Text(
                'Aucune transaction pour cette période.',
                style: pw.TextStyle(fontSize: 12, color: _muted),
              )
            else
              pw.Table(
                border: pw.TableBorder(
                  horizontalInside: pw.BorderSide(color: _border, width: 0.5),
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(3.5),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(2.2),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFF3F4F6)),
                    children: [
                      _tableHead('Date'),
                      _tableHead('Libellé'),
                      _tableHead('Type'),
                      _tableHead('Montant', align: pw.TextAlign.right),
                    ],
                  ),
                  for (final item in sorted)
                    pw.TableRow(
                      children: [
                        _tableCell(formatFrDateOnly(item.dateIso)),
                        _tableCell(item.recipient),
                        _tableCell(item.typeLabel),
                        _tableCell(
                          '${item.isCredit ? '+' : '-'}${formatFrMoneySigned(item.amount.abs())}',
                          align: pw.TextAlign.right,
                          color: item.isCredit ? _brandGreen : _ink,
                          bold: true,
                        ),
                      ],
                    ),
                ],
              ),
          ];
        },
      ),
    );

    return doc.save();
  }

  Future<void> sharePdf({
    required Uint8List bytes,
    required String fileName,
    String? subject,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf', name: fileName)],
      subject: subject,
      text: subject,
    );
  }

  String fileNameForItem(TransactionItem item) {
    final ref = item.reference?.trim();
    final safeRef = (ref != null && ref.isNotEmpty)
        ? ref.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_')
        : item.id.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return 'peyapay_recu_$safeRef.pdf';
  }

  String fileNameForStatement(String periodLabel) {
    final safe = periodLabel.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return 'peyapay_releve_$safe.pdf';
  }

  Future<_Logos> _loadLogos() async {
    pw.MemoryImage? monPeya;
    pw.MemoryImage? peyapay;

    try {
      final loader = PeyapayHostBridge.loadHostAsset;
      if (loader != null) {
        final bytes = await loader(PeyapayHostBridge.monPeyaLogoAssetPath);
        if (bytes != null && bytes.isNotEmpty) {
          monPeya = pw.MemoryImage(bytes);
        }
      }
    } catch (_) {}

    try {
      final path = 'packages/${PeyaPayAssets.package}/${PeyaPayAssets.bank(PeyaPayAssets.brandLogo)}';
      final data = await rootBundle.load(path);
      peyapay = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {}

    return _Logos(monPeya: monPeya, peyapay: peyapay);
  }

  pw.Widget _header(_Logos logos, {required String title}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _logoBox(logos.peyapay, label: 'Peya Pay', height: 40, maxWidth: 120),
        pw.SizedBox(height: 20),
        pw.Container(height: 3, color: _brandGreen),
        pw.SizedBox(height: 14),
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: _ink),
        ),
      ],
    );
  }

  pw.Widget _logoBox(
    pw.ImageProvider? image, {
    required String label,
    required double height,
    required double maxWidth,
  }) {
    if (image != null) {
      return pw.SizedBox(
        height: height,
        width: maxWidth,
        child: pw.Image(image, fit: pw.BoxFit.contain),
      );
    }
    return pw.Text(
      label,
      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: _brandGreen),
    );
  }

  pw.Widget _detailsCard(List<_DetailEntry> rows) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _border),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) pw.Divider(color: _border, height: 20),
            _detailRow(rows[i]),
          ],
        ],
      ),
    );
  }

  pw.Widget _detailRow(_DetailEntry entry) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 2,
          child: pw.Text(entry.label, style: pw.TextStyle(fontSize: 11, color: _muted)),
        ),
        pw.Expanded(
          flex: 3,
          child: pw.Text(
            entry.value,
            textAlign: pw.TextAlign.right,
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _ink),
          ),
        ),
      ],
    );
  }

  pw.Widget _footer({required _Logos logos, bool compact = false}) {
    return pw.Column(
      children: [
        pw.Divider(color: _border),
        pw.SizedBox(height: compact ? 8 : 12),
        pw.Center(
          child: _logoBox(
            logos.monPeya,
            label: 'Mon Peya',
            height: compact ? 44 : 52,
            maxWidth: compact ? 150 : 180,
          ),
        ),
      ],
    );
  }

  pw.Widget _tableHead(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _ink),
      ),
    );
  }

  pw.Widget _tableCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    PdfColor? color,
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? _ink,
        ),
      ),
    );
  }
}

class _Logos {
  const _Logos({this.monPeya, this.peyapay});

  final pw.MemoryImage? monPeya;
  final pw.MemoryImage? peyapay;
}

class _DetailEntry {
  const _DetailEntry(this.label, this.value);

  final String label;
  final String value;
}
