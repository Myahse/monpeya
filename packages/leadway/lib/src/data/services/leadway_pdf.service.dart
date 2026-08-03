import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

enum LeadwayPdfDocumentType {
  contract('contrat'),
  quote('devis');

  const LeadwayPdfDocumentType(this.prefix);
  final String prefix;

  String fileName(String policyNo) => '${prefix}_$policyNo.pdf';
}

enum LeadwayPdfAction { preview, share, save }

class LeadwayPdfService {
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
