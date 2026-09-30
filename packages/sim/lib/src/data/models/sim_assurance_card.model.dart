import 'dart:convert';
import 'dart:typed_data';

class SimAssuranceCardRecord {
  const SimAssuranceCardRecord({
    required this.id,
    required this.souscriptionId,
    required this.numeroPolice,
    required this.productCode,
    required this.productLabel,
    required this.dateDebut,
    required this.dateFin,
    required this.holderName,
    this.primeAmount,
    this.paymentReference,
    this.cartePngBase64,
    required this.savedAt,
  });

  final String id;
  final String souscriptionId;
  final String numeroPolice;
  final String productCode;
  final String productLabel;
  final String dateDebut;
  final String dateFin;
  final String holderName;
  final int? primeAmount;
  final String? paymentReference;
  final String? cartePngBase64;
  final String savedAt;

  Uint8List? get cartePngBytes {
    final raw = cartePngBase64?.trim();
    if (raw == null || raw.isEmpty) return null;
    try {
      return base64Decode(raw);
    } catch (_) {
      return null;
    }
  }

  DateTime? get _endDate => DateTime.tryParse(dateFin);

  bool get isActive {
    final end = _endDate;
    if (end == null) return true;
    final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
    return DateTime.now().isBefore(endOfDay);
  }

  String get validityLabel {
    if (dateDebut.isEmpty && dateFin.isEmpty) return 'Validité —';
    if (dateDebut.isEmpty) return 'Jusqu\'au ${_formatDisplayDate(dateFin)}';
    if (dateFin.isEmpty) return 'À partir du ${_formatDisplayDate(dateDebut)}';
    return 'Du ${_formatDisplayDate(dateDebut)} au ${_formatDisplayDate(dateFin)}';
  }

  String get statusLabel => isActive ? 'En cours' : 'Expirée';

  String get shortEndDate => dateFin.isEmpty ? '—/—/—' : _formatDisplayDate(dateFin);

  Map<String, dynamic> toJson() => {
        'id': id,
        'souscriptionId': souscriptionId,
        'numeroPolice': numeroPolice,
        'productCode': productCode,
        'productLabel': productLabel,
        'dateDebut': dateDebut,
        'dateFin': dateFin,
        'holderName': holderName,
        if (primeAmount != null) 'primeAmount': primeAmount,
        if (paymentReference != null) 'paymentReference': paymentReference,
        if (cartePngBase64 != null) 'cartePngBase64': cartePngBase64,
        'savedAt': savedAt,
      };

  factory SimAssuranceCardRecord.fromJson(Map<String, dynamic> json) {
    return SimAssuranceCardRecord(
      id: json['id']?.toString() ?? '',
      souscriptionId: json['souscriptionId']?.toString() ?? '',
      numeroPolice: json['numeroPolice']?.toString() ?? '',
      productCode: json['productCode']?.toString() ?? '',
      productLabel: json['productLabel']?.toString() ?? '',
      dateDebut: json['dateDebut']?.toString() ?? '',
      dateFin: json['dateFin']?.toString() ?? '',
      holderName: json['holderName']?.toString() ?? '',
      primeAmount: (json['primeAmount'] as num?)?.toInt(),
      paymentReference: json['paymentReference']?.toString(),
      cartePngBase64: json['cartePngBase64']?.toString(),
      savedAt: json['savedAt']?.toString() ?? DateTime.now().toUtc().toIso8601String(),
    );
  }

  SimAssuranceCardRecord copyWith({
    String? cartePngBase64,
  }) {
    return SimAssuranceCardRecord(
      id: id,
      souscriptionId: souscriptionId,
      numeroPolice: numeroPolice,
      productCode: productCode,
      productLabel: productLabel,
      dateDebut: dateDebut,
      dateFin: dateFin,
      holderName: holderName,
      primeAmount: primeAmount,
      paymentReference: paymentReference,
      cartePngBase64: cartePngBase64 ?? this.cartePngBase64,
      savedAt: savedAt,
    );
  }

  static String _formatDisplayDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final d = parsed.day.toString().padLeft(2, '0');
    final m = parsed.month.toString().padLeft(2, '0');
    return '$d/$m/${parsed.year}';
  }
}
