import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import 'package:billetterie/src/core/host/billetterie_host.bridge.dart';
import 'package:billetterie/src/shared/utils/ticket_format.util.dart';
import 'package:billetterie/src/features/transport/models/billetterie_transport_ticket.dart';

/// Builds a printable A4 PDF for a transport ticket and shares it.
class TicketPdfService {
  static const _brand = PdfColor.fromInt(0xFF006D56);
  static const _ink = PdfColor.fromInt(0xFF0F172A);
  static const _muted = PdfColor.fromInt(0xFF64748B);
  static const _border = PdfColor.fromInt(0xFFE2E8F0);
  static const _headerBg = PdfColor.fromInt(0xFFF0FDFA);
  static const _rowAlt = PdfColor.fromInt(0xFFF8FAFC);

  static const _packageLogo = 'packages/billetterie/assets/logo/mon_peya.png';
  static const _hostLogoFallback = 'assets/logo/photo-Photoroom.png';

  Future<Uint8List> buildTicket(BilletterieTransportTicket ticket) async {
    final logo = await _loadMonPeyaLogo();
    final doc = pw.Document();
    final rows = _detailRows(ticket);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _header(logo, ticket),
              pw.SizedBox(height: 18),
              _routeBanner(ticket),
              pw.SizedBox(height: 18),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(flex: 3, child: _detailsTable(rows)),
                  pw.SizedBox(width: 18),
                  pw.Expanded(flex: 2, child: _qrBlock(ticket)),
                ],
              ),
              pw.Spacer(),
              _footer(logo),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  Future<pw.MemoryImage?> _loadMonPeyaLogo() async {
    final candidates = <String>[
      BilletterieHostBridge.monPeyaLogoAssetPath,
      _packageLogo,
      _hostLogoFallback,
    ];

    final hostLoader = BilletterieHostBridge.loadHostAsset;
    if (hostLoader != null) {
      for (final path in candidates) {
        try {
          final bytes = await hostLoader(path);
          if (bytes != null && bytes.isNotEmpty) {
            return pw.MemoryImage(_trimTransparentPng(bytes));
          }
        } catch (_) {}
      }
    }

    for (final path in candidates) {
      try {
        final data = await rootBundle.load(path);
        return pw.MemoryImage(
          _trimTransparentPng(data.buffer.asUint8List()),
        );
      } catch (_) {}
    }
    return null;
  }

  /// Crops empty transparent padding so the logo sits flush against nearby text.
  Uint8List _trimTransparentPng(Uint8List bytes) {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return bytes;
      final trimmed = img.trim(decoded, mode: img.TrimMode.transparent);
      final encoded = img.encodePng(trimmed);
      return Uint8List.fromList(encoded);
    } catch (_) {
      return bytes;
    }
  }

  pw.Widget _header(pw.MemoryImage? logo, BilletterieTransportTicket ticket) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (logo != null)
                  pw.Image(logo, height: 48, fit: pw.BoxFit.contain)
                else
                  pw.Text(
                    'Mon Peya',
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: _brand,
                    ),
                  ),
                pw.Text(
                  'Billetterie - billet de transport',
                  style: const pw.TextStyle(fontSize: 10, color: _muted),
                ),
              ],
            ),
            pw.Spacer(),
            if (ticket.ticketCode != null)
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'N billet',
                    style: const pw.TextStyle(fontSize: 8, color: _muted),
                  ),
                  pw.Text(
                    ticket.ticketCode!,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: _ink,
                    ),
                  ),
                ],
              ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Container(height: 3, color: _brand),
        if (ticket.title != null) ...[
          pw.SizedBox(height: 10),
          pw.Text(
            ticket.title!,
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
        ],
      ],
    );
  }

  pw.Widget _routeBanner(BilletterieTransportTicket ticket) {
    pw.Widget endpoint(String code, String city, String time) {
      return pw.Expanded(
        child: pw.Column(
          children: [
            pw.Text(
              code,
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: _ink,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              city,
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 10, color: _muted),
            ),
            pw.Text(
              time,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: _brand,
              ),
            ),
          ],
        ),
      );
    }

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: pw.BoxDecoration(
        color: _headerBg,
        border: pw.Border.all(color: _border),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Row(
        children: [
          endpoint(ticket.fromCode, ticket.fromCity, ticket.fromTime),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8),
            child: pw.Column(
              children: [
                pw.Text(
                  ticket.durationLabel,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: _ink,
                  ),
                ),
                pw.Text(
                  '>',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: _brand,
                  ),
                ),
              ],
            ),
          ),
          endpoint(ticket.toCode, ticket.toCity, ticket.toTime),
        ],
      ),
    );
  }

  List<(String, String)> _detailRows(BilletterieTransportTicket ticket) {
    return [
      if (ticket.place != null) ('Point de départ', ticket.place!),
      if (ticket.validFrom != null)
        ('Départ', formatTicketDateTime(ticket.validFrom!)),
      if (ticket.validUntil != null)
        ('Arrivée', formatTicketDateTime(ticket.validUntil!)),
      if (ticket.vehicleType != null)
        ('Type de véhicule', ticketVehicleTypeLabel(ticket.vehicleType!)),
      ('Immatriculation', ticket.vehicleNumber),
      if (ticket.driverName != null) ('Chauffeur', ticket.driverName!),
      if (ticket.driverPhone != null) ('Téléphone', ticket.driverPhone!),
      if (ticket.ticketType != null) ('Catégorie', ticket.ticketType!),
      if (ticket.status != null) ('Statut', ticketStatusLabel(ticket.status!)),
      ('Prix', '${ticket.price} ${ticket.currency}'),
      if (ticket.builtByName != null) ('Émis par', ticket.builtByName!),
      if (ticket.generatedAt != null)
        ('Émis le', formatTicketDateTime(ticket.generatedAt!)),
      if (ticket.buyerName != null) ('Acheteur', ticket.buyerName!),
      if (ticket.purchasedAt != null)
        ('Acheté le', formatTicketDateTime(ticket.purchasedAt!)),
      if (ticket.orderRef != null) ('Réf. commande', ticket.orderRef!),
      if (ticket.paymentReference != null)
        ('Réf. paiement', ticket.paymentReference!),
    ];
  }

  pw.Widget _detailsTable(List<(String, String)> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: _border, width: 0.8),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.2),
        1: pw.FlexColumnWidth(1.8),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _headerBg),
          children: [
            _th('Champ'),
            _th('Valeur'),
          ],
        ),
        for (var i = 0; i < rows.length; i++)
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: i.isOdd ? _rowAlt : PdfColors.white,
            ),
            children: [
              _td(rows[i].$1, muted: true),
              _td(rows[i].$2, bold: true),
            ],
          ),
      ],
    );
  }

  pw.Widget _th(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: _brand,
        ),
      ),
    );
  }

  pw.Widget _td(String text, {bool muted = false, bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9.5,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: muted ? _muted : _ink,
        ),
      ),
    );
  }

  pw.Widget _qrBlock(BilletterieTransportTicket ticket) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _border),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'QR de contrôle',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.BarcodeWidget(
            barcode: pw.Barcode.qrCode(),
            data: ticket.resolvedQrPayload,
            width: 130,
            height: 130,
            color: _ink,
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Présentez ce code au contrôleur',
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 8, color: _muted),
          ),
        ],
      ),
    );
  }

  pw.Widget _footer(pw.MemoryImage? logo) {
    return pw.Column(
      children: [
        pw.Divider(color: _border, thickness: 0.8),
        pw.SizedBox(height: 10),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            if (logo != null) ...[
              pw.Image(logo, height: 36, fit: pw.BoxFit.contain),
              pw.SizedBox(width: 8),
            ],
            pw.Expanded(
              child: pw.Text(
                "Document genere par Mon Peya - Billetterie electronique. "
                "Conservez ce PDF jusqu'a la fin du trajet.",
                style: const pw.TextStyle(fontSize: 8, color: _muted),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String fileNameFor(BilletterieTransportTicket ticket) {
    final code = ticket.ticketCode ??
        '${ticket.fromCode}-${ticket.toCode}-${ticket.vehicleNumber}';
    final safe = code.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return 'billet_$safe.pdf';
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

  /// Builds and shares in one call.
  Future<void> exportAndShare(BilletterieTransportTicket ticket) async {
    final bytes = await buildTicket(ticket);
    await sharePdf(
      bytes: bytes,
      fileName: fileNameFor(ticket),
      subject: 'Billet ${ticket.fromCode} -> ${ticket.toCode}',
    );
  }
}
