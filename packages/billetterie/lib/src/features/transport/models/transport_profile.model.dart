/// How the user uses Billetterie Transport.
enum TransportProfileRole {
  /// Passenger — buy and show tickets.
  client,

  /// Ticket maker — conductor / car owner / company.
  conductor,
}

/// Lifecycle of access for a given role / request.
enum TransportAccessStatus {
  /// Default: logged in as PeyaPay client, not yet subscribed to use the service.
  none,

  /// Request submitted (docs or subscribe), waiting for validation.
  pending,

  /// Allowed to use this role in the module.
  active,
}

/// Local profile state for Billetterie Transport (client vs conductor).
class TransportProfileState {
  const TransportProfileState({
    this.role = TransportProfileRole.client,
    this.clientAccess = TransportAccessStatus.none,
    this.conductorAccess = TransportAccessStatus.none,
    this.partnerAccess = TransportAccessStatus.none,
    this.idCardFrontPath,
    this.idCardBackPath,
    this.companyDocPath,
    this.isCompany = false,
    this.peyapayMerchant = false,
    this.requestNote,
  });

  final TransportProfileRole role;
  final TransportAccessStatus clientAccess;
  final TransportAccessStatus conductorAccess;

  /// Non-merchant path: request to become a PeyaPay partner first.
  final TransportAccessStatus partnerAccess;

  /// Local paths / markers for uploaded KYC docs (Documents screen).
  final String? idCardFrontPath;
  final String? idCardBackPath;
  final String? companyDocPath;
  final bool isCompany;

  /// Cached from host: already a PeyaPay merchant.
  final bool peyapayMerchant;
  final String? requestNote;

  bool get isClientMode => role == TransportProfileRole.client;
  bool get isConductorMode => role == TransportProfileRole.conductor;

  bool get canUseAsClient => clientAccess == TransportAccessStatus.active;
  bool get canUseAsConductor =>
      conductorAccess == TransportAccessStatus.active;

  bool get hasConductorRequestPending =>
      conductorAccess == TransportAccessStatus.pending;

  bool get hasClientSubscribePending =>
      clientAccess == TransportAccessStatus.pending;

  bool get hasPartnerRequestPending =>
      partnerAccess == TransportAccessStatus.pending;

  bool get isPartnerOrMerchant =>
      peyapayMerchant || partnerAccess == TransportAccessStatus.active;

  bool get hasAnyDocument =>
      (idCardFrontPath?.isNotEmpty ?? false) ||
      (idCardBackPath?.isNotEmpty ?? false) ||
      (companyDocPath?.isNotEmpty ?? false);

  TransportProfileState copyWith({
    TransportProfileRole? role,
    TransportAccessStatus? clientAccess,
    TransportAccessStatus? conductorAccess,
    TransportAccessStatus? partnerAccess,
    String? idCardFrontPath,
    String? idCardBackPath,
    String? companyDocPath,
    bool? isCompany,
    bool? peyapayMerchant,
    String? requestNote,
    bool clearIdFront = false,
    bool clearIdBack = false,
    bool clearCompanyDoc = false,
    bool clearRequestNote = false,
  }) {
    return TransportProfileState(
      role: role ?? this.role,
      clientAccess: clientAccess ?? this.clientAccess,
      conductorAccess: conductorAccess ?? this.conductorAccess,
      partnerAccess: partnerAccess ?? this.partnerAccess,
      idCardFrontPath:
          clearIdFront ? null : (idCardFrontPath ?? this.idCardFrontPath),
      idCardBackPath:
          clearIdBack ? null : (idCardBackPath ?? this.idCardBackPath),
      companyDocPath:
          clearCompanyDoc ? null : (companyDocPath ?? this.companyDocPath),
      isCompany: isCompany ?? this.isCompany,
      peyapayMerchant: peyapayMerchant ?? this.peyapayMerchant,
      requestNote: clearRequestNote ? null : (requestNote ?? this.requestNote),
    );
  }

  Map<String, dynamic> toJson() => {
        'role': role.name,
        'clientAccess': clientAccess.name,
        'conductorAccess': conductorAccess.name,
        'partnerAccess': partnerAccess.name,
        if (idCardFrontPath != null) 'idCardFrontPath': idCardFrontPath,
        if (idCardBackPath != null) 'idCardBackPath': idCardBackPath,
        if (companyDocPath != null) 'companyDocPath': companyDocPath,
        'isCompany': isCompany,
        'peyapayMerchant': peyapayMerchant,
        if (requestNote != null) 'requestNote': requestNote,
      };

  factory TransportProfileState.fromJson(Map<String, dynamic> json) {
    TransportProfileRole roleFrom(String? raw) {
      return TransportProfileRole.values.firstWhere(
        (e) => e.name == raw,
        orElse: () => TransportProfileRole.client,
      );
    }

    TransportAccessStatus accessFrom(String? raw) {
      return TransportAccessStatus.values.firstWhere(
        (e) => e.name == raw,
        orElse: () => TransportAccessStatus.none,
      );
    }

    return TransportProfileState(
      role: roleFrom(json['role']?.toString()),
      clientAccess: accessFrom(json['clientAccess']?.toString()),
      conductorAccess: accessFrom(json['conductorAccess']?.toString()),
      partnerAccess: accessFrom(json['partnerAccess']?.toString()),
      idCardFrontPath: json['idCardFrontPath']?.toString(),
      idCardBackPath: json['idCardBackPath']?.toString(),
      companyDocPath: json['companyDocPath']?.toString(),
      isCompany: json['isCompany'] == true,
      peyapayMerchant: json['peyapayMerchant'] == true,
      requestNote: json['requestNote']?.toString(),
    );
  }
}
