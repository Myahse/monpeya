class RentalTenant {
  const RentalTenant({
    required this.id,
    required this.lastName,
    required this.firstName,
    required this.email,
    required this.phone,
    required this.status,
    this.photoUrl,
    this.profession,
    this.monthlyIncome,
    this.propertyName,
    this.propertyAddress,
  });

  final String id;
  final String lastName;
  final String firstName;
  final String email;
  final String phone;
  final String status;
  final String? photoUrl;
  final String? profession;
  final double? monthlyIncome;
  final String? propertyName;
  final String? propertyAddress;

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final a = firstName.isNotEmpty ? firstName[0] : '';
    final b = lastName.isNotEmpty ? lastName[0] : '';
    return '$a$b'.toUpperCase();
  }

  factory RentalTenant.fromBackend(Map<String, dynamic> item) {
    return RentalTenant(
      id: (item['locatairesId'] ?? item['id'] ?? '').toString(),
      lastName: (item['nom'] as String?) ?? '',
      firstName: (item['prenoms'] ?? item['prenom'] as String?) ?? '',
      email: (item['email'] as String?) ?? '',
      phone: (item['telephone'] as String?) ?? '',
      status: (item['statut'] as String?) ?? 'actif',
      photoUrl: item['photo'] as String?,
      profession: item['profession'] as String?,
      monthlyIncome: double.tryParse('${item['revenuMensuel']}'),
      propertyName: item['propertyName'] as String?,
      propertyAddress: item['propertyAddress'] as String?,
    );
  }
}
