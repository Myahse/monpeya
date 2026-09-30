class PeyapayCarteMontant {
  const PeyapayCarteMontant({
    required this.montantCarte,
    required this.currencyCode,
  });

  final int montantCarte;
  final String currencyCode;

  factory PeyapayCarteMontant.fromJson(Map<String, dynamic> json) {
    return PeyapayCarteMontant(
      montantCarte: _int(json['montantCarte']),
      currencyCode: json['currencyCode']?.toString() ?? 'XOF',
    );
  }
}

class PeyapayCarteCurrent {
  const PeyapayCarteCurrent({
    this.codeClient,
    this.statusCarte,
    this.statusCarteLabel,
    this.active = false,
    this.hasActiveCard = false,
    this.canBuyNewCard = true,
    this.registrationLast4Digits,
    this.codeLivraison,
    this.libelleVille,
    this.libelleCommune,
    this.nomPdv,
    this.montantCarte,
    this.message,
    this.missingFields = const [],
    this.errorCode,
  });

  final String? codeClient;
  final int? statusCarte;
  final String? statusCarteLabel;
  final bool active;
  final bool hasActiveCard;
  final bool canBuyNewCard;
  final String? registrationLast4Digits;
  final String? codeLivraison;
  final String? libelleVille;
  final String? libelleCommune;
  final String? nomPdv;
  final int? montantCarte;
  final String? message;
  final List<String> missingFields;
  final String? errorCode;

  bool get isDelivering => statusCarte == 9;
  bool get isActiveOrDelivered => statusCarte == 2 || statusCarte == 10;
  bool get isRejected => statusCarte == 4;
  bool get isPending => statusCarte == 3 || statusCarte == 8;

  factory PeyapayCarteCurrent.fromJson(Map<String, dynamic> json) {
    final missing = json['missingFields'];
    return PeyapayCarteCurrent(
      codeClient: json['codeClient']?.toString(),
      statusCarte: _nullableInt(json['statusCarte']),
      statusCarteLabel: json['statusCarteLabel']?.toString(),
      active: json['active'] == true,
      hasActiveCard: json['hasActiveCard'] == true,
      canBuyNewCard: json['canBuyNewCard'] != false,
      registrationLast4Digits: json['registrationLast4Digits']?.toString(),
      codeLivraison: json['codeLivraison']?.toString(),
      libelleVille: json['libelleVille']?.toString(),
      libelleCommune: json['libelleCommune']?.toString(),
      nomPdv: json['nomPdv']?.toString(),
      montantCarte: _nullableInt(json['montantCarte']),
      message: json['message']?.toString(),
      missingFields: missing is List
          ? missing.map((e) => e.toString()).toList(growable: false)
          : const [],
      errorCode: json['errorCode']?.toString(),
    );
  }
}

class PeyapayCarteBalance {
  const PeyapayCarteBalance({
    this.codeClient,
    this.accountId,
    this.soldeCarte,
    this.currencyCode,
    this.message,
  });

  final String? codeClient;
  final String? accountId;
  final int? soldeCarte;
  final String? currencyCode;
  final String? message;

  factory PeyapayCarteBalance.fromJson(Map<String, dynamic> json) {
    final balance = json['soldeCarte'] ?? json['balance'];
    return PeyapayCarteBalance(
      codeClient: json['codeClient']?.toString(),
      accountId: json['accountId']?.toString(),
      soldeCarte: _nullableInt(balance),
      currencyCode: json['currencyCode']?.toString() ?? 'XOF',
      message: json['message']?.toString(),
    );
  }
}

class PeyapayCarteLocation {
  const PeyapayCarteLocation({
    required this.id,
    required this.label,
  });

  final int id;
  final String label;

  factory PeyapayCarteLocation.fromJson(Map<String, dynamic> json) {
    final id = _nullableInt(
      json['idWVille'] ??
          json['idWCommunes'] ??
          json['idwVilleLivrer'] ??
          json['id'] ??
          json['ID'],
    );
    return PeyapayCarteLocation(
      id: id ?? 0,
      label: (json['libelleVille'] ??
              json['libelleCommune'] ??
              json['libellecommune'] ??
              json['libelle'] ??
              json['nom'] ??
              json['NOM'] ??
              '—')
          .toString(),
    );
  }
}

int _int(Object? value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? fallback;
}

int? _nullableInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value');
}
