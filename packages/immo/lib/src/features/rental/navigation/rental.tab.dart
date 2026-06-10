import 'package:flutter/material.dart';

/// Bottom navigation tabs — mirrors rental-app `NavigationTab`.
enum RentalTab {
  home,
  messages,
  payments,
  account;

  String get label => switch (this) {
        RentalTab.home => 'Annonces',
        RentalTab.messages => 'Messages',
        RentalTab.payments => 'Paiements',
        RentalTab.account => 'Compte',
      };

  IconData get icon => switch (this) {
        RentalTab.home => Icons.home_work_outlined,
        RentalTab.messages => Icons.chat_bubble_outline,
        RentalTab.payments => Icons.payments_outlined,
        RentalTab.account => Icons.person_outline,
      };
}
