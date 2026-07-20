class MonPeyaWalletBalance {
  const MonPeyaWalletBalance({
    this.phone,
    this.codePaysResidence,
    this.solde,
    this.numerocomptecomplet,
  });

  final String? phone;
  final String? codePaysResidence;
  final int? solde;
  final String? numerocomptecomplet;

  factory MonPeyaWalletBalance.fromJson(Map<String, dynamic> json) {
    return MonPeyaWalletBalance(
      phone: json['phone']?.toString(),
      codePaysResidence: json['codePaysResidence']?.toString(),
      solde: _parseAmount(json['solde']),
      numerocomptecomplet: json['numerocomptecomplet']?.toString(),
    );
  }

  static int? _parseAmount(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.round();
    final normalized = value.toString().trim().replaceAll(RegExp(r'[^0-9.,-]'), '');
    if (normalized.isEmpty) return null;
    final asInt = int.tryParse(normalized.replaceAll(RegExp(r'[.,].*$'), ''));
    if (asInt != null) return asInt;
    final asDouble = double.tryParse(normalized.replaceAll(',', '.'));
    return asDouble?.round();
  }
}

class MonPeyaWalletMovements {
  const MonPeyaWalletMovements({
    this.totalCount,
    this.items = const [],
  });

  final int? totalCount;
  final List<Map<String, dynamic>> items;

  factory MonPeyaWalletMovements.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = <Map<String, dynamic>>[];
    if (rawItems is List) {
      for (final row in rawItems) {
        if (row is Map) {
          items.add(Map<String, dynamic>.from(row));
        }
      }
    }
    final count = json['totalCount'];
    return MonPeyaWalletMovements(
      totalCount: count is int ? count : int.tryParse('$count'),
      items: items,
    );
  }
}

class MonPeyaWalletTransfer {
  const MonPeyaWalletTransfer({
    this.result,
    this.amountReceived,
    this.amountSent,
    this.recipientPhone,
  });

  final Map<String, dynamic>? result;
  final int? amountReceived;
  final int? amountSent;
  final String? recipientPhone;

  factory MonPeyaWalletTransfer.fromJson(Map<String, dynamic> json) {
    final raw = json['result'];
    return MonPeyaWalletTransfer(
      result: raw is Map ? Map<String, dynamic>.from(raw) : null,
      amountReceived: json['amountReceived'] is int
          ? json['amountReceived'] as int
          : int.tryParse('${json['amountReceived'] ?? ''}'),
      amountSent: json['amountSent'] is int
          ? json['amountSent'] as int
          : int.tryParse('${json['amountSent'] ?? ''}'),
      recipientPhone: json['recipientPhone']?.toString(),
    );
  }
}

class MonPeyaClientSearch {
  const MonPeyaClientSearch({
    this.phone,
    this.codeClient,
    this.nomClient,
    this.knownPeyaClient = false,
  });

  final String? phone;
  final String? codeClient;
  final String? nomClient;
  final bool knownPeyaClient;

  factory MonPeyaClientSearch.fromJson(Map<String, dynamic> json) {
    return MonPeyaClientSearch(
      phone: json['phone']?.toString(),
      codeClient: json['codeClient']?.toString(),
      nomClient: json['nomClient']?.toString(),
      knownPeyaClient: json['knownPeyaClient'] == true,
    );
  }
}

class MonPeyaProfile {
  const MonPeyaProfile({
    this.user,
    this.accounts = const [],
  });

  final Map<String, dynamic>? user;
  final List<Map<String, dynamic>> accounts;

  factory MonPeyaProfile.fromJson(Map<String, dynamic> json) {
    final userRaw = json['user'];
    final accountsRaw = json['accounts'];
    final accounts = <Map<String, dynamic>>[];
    if (accountsRaw is List) {
      for (final row in accountsRaw) {
        if (row is Map) {
          accounts.add(Map<String, dynamic>.from(row));
        }
      }
    }
    return MonPeyaProfile(
      user: userRaw is Map ? Map<String, dynamic>.from(userRaw) : null,
      accounts: accounts,
    );
  }

  String? get numerocomptecomplet {
    final fromUser = user?['numerocomptecomplet']?.toString();
    if (fromUser != null && fromUser.trim().isNotEmpty) return fromUser.trim();
    for (final account in accounts) {
      final n = account['numerocomptecomplet']?.toString();
      if (n != null && n.trim().isNotEmpty) return n.trim();
    }
    return user?['accountId']?.toString() ?? user?['phone']?.toString();
  }
}
