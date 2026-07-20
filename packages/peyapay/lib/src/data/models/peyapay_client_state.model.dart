/// Enum representing the client state in PeyaPay
enum PeyapayClientEtat {
  newCustomer('NEW_CUSTOMER'),
  codePin('CODE_PIN'),
  customer('CUSTOMER');

  const PeyapayClientEtat(this.apiValue);

  final String apiValue;

  static PeyapayClientEtat? fromApi(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final etat in PeyapayClientEtat.values) {
      if (etat.apiValue == value) return etat;
    }
    return null;
  }
}

class PeyapayClientState {
  const PeyapayClientState({
    this.accountId,
    this.cgu,
    this.changerTelephone = false,
    required this.codePaysResidence,
    this.deplafonner = false,
    this.etatClient,
    this.gsmPrincipale,
    this.identifiantPush,
    this.idwTypeClient,
    this.imei,
    this.modele,
    this.nomClient,
    this.plateform,
    this.codeClient,
    this.email,
  });

  final String? accountId;
  final String? cgu;
  final bool changerTelephone;
  final String codePaysResidence;
  final bool deplafonner;
  final PeyapayClientEtat? etatClient;
  final String? gsmPrincipale;
  final String? identifiantPush;
  final int? idwTypeClient;
  final String? imei;
  final String? modele;
  final String? nomClient;
  final String? plateform;
  final String? codeClient;
  final String? email;

  bool get isNewCustomer => etatClient == PeyapayClientEtat.newCustomer;
  bool get needsPinSetup => etatClient == PeyapayClientEtat.codePin;
  bool get isRegisteredCustomer => etatClient == PeyapayClientEtat.customer;

  factory PeyapayClientState.fromJson(Map<String, dynamic> json) {
    return PeyapayClientState(
      accountId: json['accountId']?.toString(),
      cgu: json['cgu']?.toString(),
      changerTelephone: json['changerTelephone'] == true,
      codePaysResidence: json['codePaysResidence']?.toString() ?? 'CI',
      deplafonner: json['deplafonner'] == true,
      etatClient: PeyapayClientEtat.fromApi(json['etatClient']?.toString()),
      gsmPrincipale: json['gsmPrincipale']?.toString(),
      identifiantPush: json['identifiantPush']?.toString(),
      idwTypeClient: json['idwTypeClient'] is int
          ? json['idwTypeClient'] as int
          : int.tryParse('${json['idwTypeClient']}'),
      imei: json['imei']?.toString(),
      modele: json['modele']?.toString(),
      nomClient: json['nomClient']?.toString(),
      plateform: json['plateform']?.toString(),
      codeClient: json['codeClient']?.toString(),
      email: json['email']?.toString(),
    );
  }

  String get statusLabel => switch (etatClient) {
        PeyapayClientEtat.customer => 'Client actif',
        PeyapayClientEtat.newCustomer => 'Nouveau client',
        PeyapayClientEtat.codePin => 'PIN à définir',
        null => '—',
      };
}
