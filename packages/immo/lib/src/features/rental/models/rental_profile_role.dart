/// How the user interacts with Mr Immo Location on the home tab.
enum RentalProfileRole {
  landlord,
  seeker;

  String get storageKey => name;

  String get label => switch (this) {
        RentalProfileRole.landlord => 'Propriétaire',
        RentalProfileRole.seeker => 'Locataire',
      };

  String get homeTitle => switch (this) {
        RentalProfileRole.landlord => 'Tableau de bord',
        RentalProfileRole.seeker => 'Trouver un logement',
      };

  String get homeSubtitle => switch (this) {
        RentalProfileRole.landlord => 'Gérez vos biens & locataires',
        RentalProfileRole.seeker => 'Parcourez les biens disponibles',
      };

  static RentalProfileRole? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final role in RentalProfileRole.values) {
      if (role.name == raw || role.storageKey == raw) return role;
    }
    return null;
  }
}
