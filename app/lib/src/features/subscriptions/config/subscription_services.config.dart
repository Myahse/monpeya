import 'package:flutter/foundation.dart';

/// Mon Peya backend module code + display metadata for the subscriptions hub.
@immutable
class SubscriptionServiceEntry {
  const SubscriptionServiceEntry({
    required this.moduleCode,
    required this.title,
    required this.subtitle,
    required this.iconKey,
    this.moduleKey,
  });

  /// Backend `/v1/plans` + `/v1/subscriptions/*` module code.
  final String moduleCode;
  final String title;
  final String subtitle;
  final String iconKey;
  final String? moduleKey;
}

/// Subscribable services shown individually in the Abonnements tab.
abstract final class SubscriptionServices {
  SubscriptionServices._();

  static const billetterieTransport = SubscriptionServiceEntry(
    moduleCode: 'billetterie',
    moduleKey: 'billetterie-transport',
    title: 'Billetterie Transport',
    subtitle: 'Bus, cars et espace conducteur',
    iconKey: 'billetterie-transport',
  );

  static const billetterieEvent = SubscriptionServiceEntry(
    moduleCode: 'billetterie',
    moduleKey: 'billetterie-event',
    title: 'Billetterie Événements',
    subtitle: 'Billets et billetterie événementielle',
    iconKey: 'billetterie-event',
  );

  static const immoRental = SubscriptionServiceEntry(
    moduleCode: 'immo',
    moduleKey: 'real-estate',
    title: 'Mr Immo Location',
    subtitle: 'Location et gestion locative',
    iconKey: 'immo-rental',
  );

  static const immoConstruction = SubscriptionServiceEntry(
    moduleCode: 'immo',
    moduleKey: 'construction',
    title: 'Mr Immo Construction',
    subtitle: 'Chantiers et fournisseurs',
    iconKey: 'immo-construction',
  );

  static const immoCollection = SubscriptionServiceEntry(
    moduleCode: 'immo',
    moduleKey: 'collection',
    title: 'Mr Immo Collection',
    subtitle: 'Copropriété et syndic',
    iconKey: 'immo-collection',
  );

  static const leadway = SubscriptionServiceEntry(
    moduleCode: 'leadway',
    moduleKey: 'leadway-assurance',
    title: 'Leadway Moto',
    subtitle: 'Assurance moto et vie',
    iconKey: 'leadway',
  );

  static const sim = SubscriptionServiceEntry(
    moduleCode: 'sim',
    moduleKey: 'sim-assurance',
    title: 'SIM Assurances',
    subtitle: 'RelaxMoto, RelaxAuto, Accidents',
    iconKey: 'sim',
  );

  static const catalog = [
    billetterieTransport,
    billetterieEvent,
    immoRental,
    immoConstruction,
    immoCollection,
    leadway,
    sim,
  ];

  static String moduleLabel(String moduleCode) {
    return switch (moduleCode.toLowerCase()) {
      'billetterie' => 'Billetterie',
      'immo' => 'Mr Immo',
      'leadway' => 'Leadway',
      'sim' => 'SIM Assurances',
      _ => moduleCode,
    };
  }
}
