import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class SimCarteService {
  String _safeRef(String? numeroPolice, String? souscriptionId) {
    final ref = (numeroPolice?.trim().isNotEmpty == true ? numeroPolice : souscriptionId)?.trim();
    if (ref != null && ref.isNotEmpty) {
      return ref.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    }
    return 'carte';
  }

  String fileName(String? numeroPolice, String? souscriptionId) {
    return 'sim_carte_${_safeRef(numeroPolice, souscriptionId)}.png';
  }

  String pdfFileName(String? numeroPolice, String? souscriptionId) {
    return 'sim_carte_${_safeRef(numeroPolice, souscriptionId)}.pdf';
  }

  Future<Uint8List> buildPdfFromPng(
    Uint8List pngBytes, {
    required String numeroPolice,
    required String productLabel,
    String? dateDebut,
    String? dateFin,
  }) async {
    final image = pw.MemoryImage(pngBytes);
    final doc = pw.Document(
      title: 'Carte SIM — $numeroPolice',
      author: 'SIM Assurances',
    );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Text(
                'Carte de prise en charge',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 6),
              pw.Text('Police : $numeroPolice', style: const pw.TextStyle(fontSize: 11)),
              pw.Text('Produit : $productLabel', style: const pw.TextStyle(fontSize: 11)),
              if (dateDebut != null && dateDebut.isNotEmpty)
                pw.Text('Validité : $dateDebut → ${dateFin ?? '—'}', style: const pw.TextStyle(fontSize: 11)),
              pw.SizedBox(height: 16),
              pw.Expanded(
                child: pw.Center(
                  child: pw.Image(image, fit: pw.BoxFit.contain),
                ),
              ),
            ],
          );
        },
      ),
    );

    return Uint8List.fromList(await doc.save());
  }

  Future<File> writeToTemp(Uint8List bytes, String fileName) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<File> saveToDevice(Uint8List bytes, String fileName) async {
    Directory? dir = await getDownloadsDirectory();
    dir ??= await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}
