import 'package:flutter/material.dart';

import 'package:immo/src/features/rental/models/rental_profile_role.dart';

/// Bottom navigation tabs — set depends on Client/Guest vs Business.
enum RentalTab {
  home,
  search,
  favorites,
  tenants,
  map,
  account;

  /// Guest / Client: Home · Recherche · Favoris · Carte · Profil
  static const clientTabs = <RentalTab>[
    home,
    search,
    favorites,
    map,
    account,
  ];

  /// Business: Home · Locataires · Carte · Profil
  static const businessTabs = <RentalTab>[
    home,
    tenants,
    map,
    account,
  ];

  static List<RentalTab> tabsFor(RentalProfileRole role) =>
      role.isBusiness ? businessTabs : clientTabs;

  String get label => switch (this) {
        RentalTab.home => 'Accueil',
        RentalTab.search => 'Recherche',
        RentalTab.favorites => 'Favoris',
        RentalTab.tenants => 'Locataires',
        RentalTab.map => 'Carte',
        RentalTab.account => 'Profil',
      };

  IconData get icon => switch (this) {
        RentalTab.home => Icons.home_outlined,
        RentalTab.search => Icons.search,
        RentalTab.favorites => Icons.favorite_border,
        RentalTab.tenants => Icons.people_outline_rounded,
        RentalTab.map => Icons.map_outlined,
        RentalTab.account => Icons.person_outline_rounded,
      };

  IconData get selectedIcon => switch (this) {
        RentalTab.home => Icons.home_rounded,
        RentalTab.search => Icons.search_rounded,
        RentalTab.favorites => Icons.favorite_rounded,
        RentalTab.tenants => Icons.people_rounded,
        RentalTab.map => Icons.map_rounded,
        RentalTab.account => Icons.person_rounded,
      };
}
