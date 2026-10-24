class CreateTenantDraft {
  CreateTenantDraft();

  String lastName = '';
  String firstName = '';
  String email = '';
  String password = '';
  String phone = '';
  String nationalId = '';
  String birthDate = '';
  String address = '';
  String profession = '';
  String monthlyIncome = '';
  String status = 'actif';
  String? propertyId;
  String? photoPath;
  String monthlyRent = '';
  String paymentFrequency = 'monthly';
  String leaseStartDate = '';
  String leaseEndDate = '';
  String paymentDay = '1';

  /// Lease contract terms, sent once the tenant exists.
  String deposit = '';
  String paymentMode = 'mobile_money';

  static double? amount(String text) {
    final digits = text.replaceAll(RegExp(r'[^0-9.]'), '');
    return digits.isEmpty ? null : double.tryParse(digits);
  }

  /// The contract's periodicité for the payment frequency picked here.
  String get contractPeriodicity => switch (paymentFrequency) {
        'daily' => 'journalier',
        'yearly' => 'annuel',
        _ => 'mensuel',
      };

  Map<String, dynamic> toCreatePayload({
    required String utilisateursId,
    String? photoUrl,
  }) {
    return {
      'nom': lastName.trim(),
      'prenoms': firstName.trim(),
      'email': email.trim(),
      'password': password,
      'telephone': phone.trim(),
      'cni': nationalId.trim(),
      'adresse': address.trim().isEmpty ? null : address.trim(),
      'profession': profession.trim().isEmpty ? null : profession.trim(),
      'revenuMensuel': monthlyIncome.trim().isEmpty
          ? null
          : double.tryParse(monthlyIncome.replaceAll(RegExp(r'[^0-9.]'), '')),
      'dateNaissance':
          birthDate.trim().isEmpty ? null : '${birthDate.trim()}T00:00:00',
      'statut': status,
      'biensId': propertyId,
      'photo': photoUrl,
      'utilisateursId': utilisateursId,
      if (monthlyRent.trim().isNotEmpty)
        'montantLoyer': double.tryParse(monthlyRent.replaceAll(RegExp(r'[^0-9.]'), '')),
      if (paymentFrequency.isNotEmpty) 'frequencePaiement': paymentFrequency,
      if (leaseStartDate.trim().isNotEmpty)
        'dateDebutBail': '${leaseStartDate.trim()}T00:00:00',
      if (leaseEndDate.trim().isNotEmpty) 'dateFinBail': '${leaseEndDate.trim()}T00:00:00',
      if (paymentDay.trim().isNotEmpty) 'jourPaiement': int.tryParse(paymentDay),
    };
  }
}
