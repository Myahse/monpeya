import 'package:flutter/material.dart';

import 'package:immo/src/shared/widgets/immo_layout.widget.dart';

enum ConstructionTab {
  home,
  work,
  messages,
  payments,
  account;

  String labelFor(ConstructionRole role) => switch (this) {
        ConstructionTab.home => 'Accueil',
        ConstructionTab.work => switch (role) {
            ConstructionRole.supplier => 'Commandes',
            ConstructionRole.chefSite => 'Chantiers',
            ConstructionRole.superviseur => 'Demandes',
            ConstructionRole.moyensGeneraux => 'Achats',
          },
        ConstructionTab.messages => 'Messages',
        ConstructionTab.payments => 'Paiements',
        ConstructionTab.account => 'Profil',
      };

  ImmoNavItem navItem(ConstructionRole role) => switch (this) {
        ConstructionTab.home => const ImmoNavItem(
            label: 'Accueil',
            icon: Icons.home_outlined,
            selectedIcon: Icons.home_rounded,
          ),
        ConstructionTab.work => ImmoNavItem(
            label: labelFor(role),
            icon: switch (role) {
              ConstructionRole.supplier => Icons.inventory_2_outlined,
              ConstructionRole.chefSite => Icons.foundation_outlined,
              ConstructionRole.superviseur => Icons.fact_check_outlined,
              ConstructionRole.moyensGeneraux => Icons.shopping_cart_outlined,
            },
            selectedIcon: switch (role) {
              ConstructionRole.supplier => Icons.inventory_2_rounded,
              ConstructionRole.chefSite => Icons.foundation_rounded,
              ConstructionRole.superviseur => Icons.fact_check_rounded,
              ConstructionRole.moyensGeneraux => Icons.shopping_cart_rounded,
            },
          ),
        ConstructionTab.messages => const ImmoNavItem(
            label: 'Messages',
            icon: Icons.chat_bubble_outline_rounded,
            selectedIcon: Icons.chat_bubble_rounded,
          ),
        ConstructionTab.payments => const ImmoNavItem(
            label: 'Paiements',
            icon: Icons.account_balance_wallet_outlined,
            selectedIcon: Icons.account_balance_wallet_rounded,
          ),
        ConstructionTab.account => const ImmoNavItem(
            label: 'Profil',
            icon: Icons.person_outline_rounded,
            selectedIcon: Icons.person_rounded,
          ),
      };
}

enum ConstructionRole {
  supplier,
  chefSite,

  /// Validates the chefs' demandes before the moyens généraux order them.
  superviseur,

  /// Orders validated material demandes from suppliers.
  moyensGeneraux;

  String get label => switch (this) {
        ConstructionRole.supplier => 'Fournisseur',
        ConstructionRole.chefSite => 'Chef de chantier',
        ConstructionRole.superviseur => 'Superviseur',
        ConstructionRole.moyensGeneraux => 'Moyens généraux',
      };

  IconData get icon => switch (this) {
        ConstructionRole.supplier => Icons.local_shipping_outlined,
        ConstructionRole.chefSite => Icons.engineering_outlined,
        ConstructionRole.superviseur => Icons.fact_check_outlined,
        ConstructionRole.moyensGeneraux => Icons.shopping_cart_outlined,
      };

  /// The view matching a backend niveau d'accès; null when none fits.
  static ConstructionRole? fromAccessLevel(String? level) => switch (level) {
        'CHEF_CHANTIER' || 'ADMIN_ENTREPRISE' || 'ENTREPRISE' || 'SYSTEM_ADMIN' => ConstructionRole.chefSite,
        'SUPERVISEUR' => ConstructionRole.superviseur,
        'MOYEN_GENERAUX' => ConstructionRole.moyensGeneraux,
        'FOURNISSEUR' => ConstructionRole.supplier,
        _ => null,
      };
}
