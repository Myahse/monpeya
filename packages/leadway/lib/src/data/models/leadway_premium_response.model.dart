import 'package:leadway/src/data/models/leadway_quote_values.model.dart';

class LeadwayPremiumResult {
  const LeadwayPremiumResult({
    required this.primeTtc,
    required this.quoteValues,
    this.primeHt,
    this.raw,
  });

  final int primeTtc;
  final int? primeHt;
  final LeadwayQuoteValues quoteValues;
  final Map<String, dynamic>? raw;

  factory LeadwayPremiumResult.fromJson(Map<String, dynamic> json) {
    final quoteValues = _extractQuoteValues(json);
    if (quoteValues == null) {
      throw FormatException('Réponse API sans resultValue: $json');
    }

    return LeadwayPremiumResult(
      primeTtc: quoteValues.detailsPrime.primeTtc,
      primeHt: quoteValues.detailsPrime.primeNette,
      quoteValues: quoteValues,
      raw: json,
    );
  }

  static LeadwayQuoteValues? _extractQuoteValues(Map<String, dynamic> json) {
    final results = json['result'];
    if (results is List && results.isNotEmpty) {
      final first = results.first;
      if (first is Map) {
        final resultValue = first['resultValue'];
        if (resultValue is Map) {
          return LeadwayQuoteValues.fromJson(Map<String, dynamic>.from(resultValue));
        }
      }
    }

    final cotation = json['cotation'];
    if (cotation is Map) {
      final detailsPrime = cotation['detailsPrime'];
      final listeGaranties = cotation['listeGaranties'];
      if (detailsPrime is Map && listeGaranties is Map) {
        return LeadwayQuoteValues.fromJson({
          'detailsPrime': detailsPrime,
          'listeGaranties': listeGaranties,
        });
      }
    }

    return null;
  }
}
