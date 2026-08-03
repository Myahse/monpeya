/// How the user interacts with Mr Immo Location.
/// Client = seeker / locataire · Business = landlord / propriétaire.
enum RentalProfileRole {
  seeker,
  landlord;

  String get storageKey => name;

  /// UI label aligned with Billetterie Client / Business switch.
  String get modeLabel => switch (this) {
        RentalProfileRole.seeker => 'Client',
        RentalProfileRole.landlord => 'Business',
      };

  String get label => switch (this) {
        RentalProfileRole.landlord => 'Propriétaire',
        RentalProfileRole.seeker => 'Locataire',
      };

  bool get isBusiness => this == RentalProfileRole.landlord;
  bool get isClient => this == RentalProfileRole.seeker;

  static RentalProfileRole? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final normalized = raw.toLowerCase().trim();
    if (normalized == 'client' || normalized == 'seeker') {
      return RentalProfileRole.seeker;
    }
    if (normalized == 'business' ||
        normalized == 'landlord' ||
        normalized == 'proprietaire' ||
        normalized == 'propriétaire') {
      return RentalProfileRole.landlord;
    }
    for (final role in RentalProfileRole.values) {
      if (role.name == raw || role.storageKey == raw) return role;
    }
    return null;
  }
}
