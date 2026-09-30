class SimProduitCatalogue {
  const SimProduitCatalogue({
    required this.code,
    required this.libelle,
    required this.actifPourPartenaire,
    required this.kycRequis,
    required this.tauxCommissionApi,
    this.formules = const [],
  });

  final String code;
  final String libelle;
  final bool actifPourPartenaire;
  final bool kycRequis;
  final double tauxCommissionApi;
  final List<SimFormule> formules;

  bool get supportsSubscription => SimProduitCatalogue.subscriptionCodes.contains(code);

  static const subscriptionCodes = {
    'relaxmoto',
    'relaxauto',
    'relaxaccidents_fraismedicaux',
    'relaxaccidents_fraismedicaux_livreurs',
  };

  factory SimProduitCatalogue.fromJson(Map<String, dynamic> json) {
    return SimProduitCatalogue(
      code: json['code']?.toString() ?? '',
      libelle: json['libelle']?.toString() ?? '',
      actifPourPartenaire: json['actifPourPartenaire'] == true,
      kycRequis: json['kycRequis'] == true,
      tauxCommissionApi: (json['tauxCommissionApi'] as num?)?.toDouble() ?? 0,
      formules: (json['formules'] as List?)
              ?.whereType<Map>()
              .map((e) => SimFormule.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
    );
  }
}

class SimFormule {
  const SimFormule({
    required this.libelleVariante,
    required this.prime,
    required this.capitalGaranti,
    this.cycleFacturation,
  });

  final String? libelleVariante;
  final int prime;
  final int capitalGaranti;
  final String? cycleFacturation;

  factory SimFormule.fromJson(Map<String, dynamic> json) {
    return SimFormule(
      libelleVariante: json['libelleVariante']?.toString(),
      prime: (json['prime'] as num?)?.toInt() ?? 0,
      capitalGaranti: (json['capitalGaranti'] as num?)?.toInt() ?? 0,
      cycleFacturation: json['cycleFacturation']?.toString(),
    );
  }
}

/// Option affichée dans l'UI ; [value] est envoyé à l'API comme `formule`.
class SimFormuleOption {
  const SimFormuleOption({
    required this.value,
    required this.label,
    this.prime,
    this.capitalGaranti,
  });

  final String value;
  final String label;
  final int? prime;
  final int? capitalGaranti;
}

extension SimProduitCatalogueFormules on SimProduitCatalogue {
  bool get isMotoAuto => code == 'relaxmoto' || code == 'relaxauto';

  /// Valeur `formule` pour l'API : `mensuel`/`annuel` (moto/auto) ou `libelleVariante`.
  List<SimFormuleOption> formuleOptions() {
    if (formules.isEmpty) {
      if (isMotoAuto) {
        return const [
          SimFormuleOption(value: 'mensuel', label: 'Mensuel'),
          SimFormuleOption(value: 'annuel', label: 'Annuel'),
        ];
      }
      return const [];
    }

    final seen = <String>{};
    final options = <SimFormuleOption>[];

    for (final f in formules) {
      final value = isMotoAuto
          ? (f.cycleFacturation ?? f.libelleVariante ?? '').trim()
          : (f.libelleVariante ?? f.cycleFacturation ?? '').trim();
      if (value.isEmpty || seen.contains(value)) continue;
      seen.add(value);

      final label = (f.libelleVariante ?? f.cycleFacturation ?? value).trim();
      options.add(
        SimFormuleOption(
          value: value,
          label: label.isEmpty ? value : label,
          prime: f.prime,
          capitalGaranti: f.capitalGaranti,
        ),
      );
    }

    return options;
  }
}
