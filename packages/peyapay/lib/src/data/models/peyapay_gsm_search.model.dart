import 'package:peyapay/src/data/models/peyapay_type_client.model.dart';

class PeyapayGsmClientProfile {
  const PeyapayGsmClientProfile({
    this.codeClient,
    this.gsmPrincipale,
    this.nomClient,
    this.changerTelephone = false,
    this.estFournisseur,
    this.wtypeClient,
    this.typcpts = const [],
  });

  final String? codeClient;
  final String? gsmPrincipale;
  final String? nomClient;
  final bool changerTelephone;
  final String? estFournisseur;
  final PeyapayTypeClient? wtypeClient;
  final List<String> typcpts;

  factory PeyapayGsmClientProfile.fromJson(Map<String, dynamic> json) {
    var nomClient = json['nomClient']?.toString();
    final accounts = json['datasCompte'];
    if ((nomClient == null || nomClient.isEmpty) &&
        accounts is List &&
        accounts.isNotEmpty) {
      final firstAccount = accounts.first;
      if (firstAccount is Map) {
        final wclients = firstAccount['wclients'];
        if (wclients is Map) {
          nomClient = wclients['nomClient']?.toString();
        }
      }
    }

    PeyapayTypeClient? wtypeClient;
    final rawType = json['wtypeClient'] ?? json['wTypeClient'];
    if (rawType is Map) {
      wtypeClient =
          PeyapayTypeClient.fromJson(Map<String, dynamic>.from(rawType));
    } else if (accounts is List) {
      for (final row in accounts) {
        if (row is! Map) continue;
        final nested = row['wtypeClient'] ?? row['wTypeClient'];
        if (nested is Map) {
          wtypeClient =
              PeyapayTypeClient.fromJson(Map<String, dynamic>.from(nested));
          break;
        }
      }
    }

    return PeyapayGsmClientProfile(
      codeClient: json['codeClient']?.toString(),
      gsmPrincipale: json['gsmPrincipale']?.toString(),
      nomClient: nomClient,
      changerTelephone: json['changerTelephone'] == true,
      estFournisseur: json['estFournisseur']?.toString(),
      wtypeClient: wtypeClient,
      typcpts: PeyapayTypeClient.readTypcptsFromAccounts(accounts),
    );
  }
}

class PeyapayGsmSearchResult {
  const PeyapayGsmSearchResult({
    required this.count,
    this.items = const [],
  });

  final int count;
  final List<PeyapayGsmClientProfile> items;

  bool get isRecognized => items.isNotEmpty;

  PeyapayGsmClientProfile? get firstProfile => items.isEmpty ? null : items.first;
}

class PeyapayPinVerificationResult {
  const PeyapayPinVerificationResult({
    this.gsmPrincipale,
    this.codePaysResidence,
    this.solde,
  });

  final String? gsmPrincipale;
  final String? codePaysResidence;
  final String? solde;

  factory PeyapayPinVerificationResult.fromJson(Map<String, dynamic> json) {
    return PeyapayPinVerificationResult(
      gsmPrincipale: json['gsmPrincipale']?.toString(),
      codePaysResidence: json['codePaysResidence']?.toString(),
      solde: json['solde']?.toString(),
    );
  }
}
