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
        ConstructionTab.work =>
          role == ConstructionRole.supplier ? 'Commandes' : 'Chantiers',
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
            icon: role == ConstructionRole.supplier
                ? Icons.inventory_2_outlined
                : Icons.foundation_outlined,
            selectedIcon: role == ConstructionRole.supplier
                ? Icons.inventory_2_rounded
                : Icons.foundation_rounded,
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
  chefSite;

  String get label => switch (this) {
        ConstructionRole.supplier => 'Fournisseur',
        ConstructionRole.chefSite => 'Chef de chantier',
      };
}
