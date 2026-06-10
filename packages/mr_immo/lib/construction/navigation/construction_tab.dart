import 'package:flutter/material.dart';

enum ConstructionTab {
  home,
  messages,
  payments,
  account;

  String get label => switch (this) {
        ConstructionTab.home => 'Accueil',
        ConstructionTab.messages => 'Messages',
        ConstructionTab.payments => 'Paiements',
        ConstructionTab.account => 'Compte',
      };

  IconData get icon => switch (this) {
        ConstructionTab.home => Icons.construction_outlined,
        ConstructionTab.messages => Icons.chat_bubble_outline,
        ConstructionTab.payments => Icons.payments_outlined,
        ConstructionTab.account => Icons.person_outline,
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
