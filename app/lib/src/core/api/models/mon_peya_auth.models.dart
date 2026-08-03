class MonPeyaAuthUser {
  const MonPeyaAuthUser({
    this.userId,
    this.phone,
    this.codeClient,
    this.nomClient,
    this.displayName,
    this.isPeyaClient,
    this.isPeyapayMerchant,
    this.isDeplafonne,
    this.numerocomptecomplet,
    this.accountId,
    this.codePaysResidence,
  });

  final String? userId;
  final String? phone;
  final String? codeClient;
  final String? nomClient;
  final String? displayName;
  final bool? isPeyaClient;
  final bool? isPeyapayMerchant;
  /// Required for CLIENT straight subscribe debit (Peya `deplafonner`).
  final bool? isDeplafonne;
  final String? numerocomptecomplet;
  final String? accountId;
  final String? codePaysResidence;

  factory MonPeyaAuthUser.fromJson(Map<String, dynamic> json) {
    return MonPeyaAuthUser(
      userId: json['userId']?.toString(),
      phone: json['phone']?.toString(),
      codeClient: json['codeClient']?.toString(),
      nomClient: json['nomClient']?.toString(),
      displayName: json['displayName']?.toString(),
      isPeyaClient: _readBool(json['isPeyaClient']),
      isPeyapayMerchant: _readBool(json['isPeyapayMerchant']),
      // Backend may expose either Mon Peya or raw Peya field names.
      isDeplafonne: _readBool(json['isDeplafonne'] ?? json['deplafonner']),
      numerocomptecomplet: json['numerocomptecomplet']?.toString(),
      accountId: json['accountId']?.toString(),
      codePaysResidence: json['codePaysResidence']?.toString(),
    );
  }
}

bool? _readBool(Object? value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final s = value.toString().trim().toLowerCase();
  if (s == 'true' || s == '1' || s == 'o' || s == 'oui' || s == 'yes') {
    return true;
  }
  if (s == 'false' || s == '0' || s == 'n' || s == 'non' || s == 'no') {
    return false;
  }
  return null;
}

class MonPeyaAuthSession {
  const MonPeyaAuthSession({
    this.accessToken,
    this.refreshToken,
    this.expiresAt,
    this.refreshExpiresAt,
    this.user,
    this.knownPeyaClient,
    this.otpRequired,
  });

  final String? accessToken;
  final String? refreshToken;
  final String? expiresAt;
  final String? refreshExpiresAt;
  final MonPeyaAuthUser? user;
  final bool? knownPeyaClient;
  final bool? otpRequired;

  bool get isRecognized => knownPeyaClient == true;

  factory MonPeyaAuthSession.fromJson(Map<String, dynamic> json) {
    final userRaw = json['user'];
    return MonPeyaAuthSession(
      accessToken: json['accessToken']?.toString(),
      refreshToken: json['refreshToken']?.toString(),
      expiresAt: json['expiresAt']?.toString(),
      refreshExpiresAt: json['refreshExpiresAt']?.toString(),
      user: userRaw is Map
          ? MonPeyaAuthUser.fromJson(Map<String, dynamic>.from(userRaw))
          : null,
      knownPeyaClient: json['knownPeyaClient'] as bool?,
      otpRequired: json['otpRequired'] as bool?,
    );
  }
}

class MonPeyaAccessDecision {
  const MonPeyaAccessDecision({
    required this.allowed,
    this.requiredLevel,
    this.reason,
    this.moduleCode,
    this.actionCode,
    this.authenticated,
    this.hasActiveSubscription,
    this.planCode,
    this.requiredRole,
    this.userRole,
  });

  final bool allowed;
  final String? requiredLevel;
  final String? reason;
  final String? moduleCode;
  final String? actionCode;
  final bool? authenticated;
  final bool? hasActiveSubscription;
  final String? planCode;
  final String? requiredRole;
  final String? userRole;

  String? get level => requiredLevel;

  factory MonPeyaAccessDecision.fromJson(Map<String, dynamic> json) {
    return MonPeyaAccessDecision(
      allowed: json['allowed'] == true,
      requiredLevel:
          (json['requiredLevel'] ?? json['level'])?.toString(),
      reason: json['reason']?.toString(),
      moduleCode: json['moduleCode']?.toString(),
      actionCode: json['actionCode']?.toString(),
      authenticated: json['authenticated'] as bool?,
      hasActiveSubscription: json['hasActiveSubscription'] as bool?,
      planCode: json['planCode']?.toString(),
      requiredRole: json['requiredRole']?.toString(),
      userRole: json['userRole']?.toString(),
    );
  }
}
