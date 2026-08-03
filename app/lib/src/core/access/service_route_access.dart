

enum MonPeyaServiceId {
  immoRental,
  immoConstruction,
  immoCollection,
  billetterieTransport,
  billetterieEvent,
  peyapay,
}


enum ServiceRouteAccessLevel {
  /// Guests may open / browse without login.
  guestOk,

  /// Requires an active Mon Peya session — prompt login if guest.
  authRequired,

  /// Screen is visible to guests but the primary action needs login

  authForAction,

 
  comingSoon,
}

class ServiceRouteDef {
  const ServiceRouteDef({
    required this.id,
    required this.label,
    required this.access,
    this.notes,
  });


  final String id;

  final String label;

  final ServiceRouteAccessLevel access;

  final String? notes;
}


abstract final class ServiceRouteAccess {
  ServiceRouteAccess._();

  static const Map<MonPeyaServiceId, List<ServiceRouteDef>> routes = {
    MonPeyaServiceId.immoRental: _immoRental,
    MonPeyaServiceId.immoConstruction: _immoConstruction,
    MonPeyaServiceId.immoCollection: _immoCollection,
    MonPeyaServiceId.billetterieTransport: _billetterieTransport,
    MonPeyaServiceId.billetterieEvent: _billetterieEvent,
    MonPeyaServiceId.peyapay: _peyapay,
  };

  static List<ServiceRouteDef> forService(MonPeyaServiceId service) =>
      routes[service] ?? const [];

  static List<ServiceRouteDef> guestRoutes(MonPeyaServiceId service) =>
      forService(service)
          .where(
            (r) =>
                r.access == ServiceRouteAccessLevel.guestOk ||
                r.access == ServiceRouteAccessLevel.authForAction,
          )
          .toList();

  static List<ServiceRouteDef> authRoutes(MonPeyaServiceId service) =>
      forService(service)
          .where(
            (r) =>
                r.access == ServiceRouteAccessLevel.authRequired ||
                r.access == ServiceRouteAccessLevel.authForAction,
          )
          .toList();

  static ServiceRouteDef? find(MonPeyaServiceId service, String routeId) {
    for (final r in forService(service)) {
      if (r.id == routeId) return r;
    }
    return null;
  }

  static bool isGuestOk(MonPeyaServiceId service, String routeId) {
    final r = find(service, routeId);
    return r != null &&
        (r.access == ServiceRouteAccessLevel.guestOk ||
            r.access == ServiceRouteAccessLevel.authForAction);
  }

  static bool requiresAuth(MonPeyaServiceId service, String routeId) {
    final r = find(service, routeId);
    return r != null &&
        (r.access == ServiceRouteAccessLevel.authRequired ||
            r.access == ServiceRouteAccessLevel.authForAction);
  }

  static bool isComingSoon(MonPeyaServiceId service, String routeId) {
    final r = find(service, routeId);
    return r?.access == ServiceRouteAccessLevel.comingSoon;
  }

  //  Mr Immo Location 

  static const _immoRental = <ServiceRouteDef>[
    ServiceRouteDef(
      id: 'immo.rental.tab.home',
      label: 'Home',
      access: ServiceRouteAccessLevel.guestOk,
      notes: 'Browse available listings; landlord “my properties” needs auth',
    ),
    ServiceRouteDef(
      id: 'immo.rental.tab.search',
      label: 'Recherche',
      access: ServiceRouteAccessLevel.guestOk,
    ),
    ServiceRouteDef(
      id: 'immo.rental.tab.favorites',
      label: 'Favoris',
      access: ServiceRouteAccessLevel.authForAction,
      notes: 'Tab visible; list requires login',
    ),
    ServiceRouteDef(
      id: 'immo.rental.tab.map',
      label: 'Carte',
      access: ServiceRouteAccessLevel.guestOk,
    ),
    ServiceRouteDef(
      id: 'immo.rental.tab.account',
      label: 'Profil',
      access: ServiceRouteAccessLevel.guestOk,
    ),
    ServiceRouteDef(
      id: 'immo.rental.tab.tenants',
      label: 'Locataires',
      access: ServiceRouteAccessLevel.authRequired,
      notes: 'Business tab only',
    ),
    ServiceRouteDef(
      id: 'immo.rental.property.detail',
      label: 'Détail bien',
      access: ServiceRouteAccessLevel.guestOk,
      notes: 'Favorite / contact may need auth',
    ),
    ServiceRouteDef(
      id: 'immo.rental.profile.personal',
      label: 'Informations personnelles',
      access: ServiceRouteAccessLevel.authRequired,
    ),
    ServiceRouteDef(
      id: 'immo.rental.profile.favorites',
      label: 'Biens favoris',
      access: ServiceRouteAccessLevel.authRequired,
    ),
    ServiceRouteDef(
      id: 'immo.rental.profile.documents',
      label: 'Mes documents',
      access: ServiceRouteAccessLevel.authRequired,
      notes: 'coming soon UI for now',
    ),
    ServiceRouteDef(
      id: 'immo.rental.profile.payments',
      label: 'Paiements',
      access: ServiceRouteAccessLevel.authRequired,
    ),
    ServiceRouteDef(
      id: 'immo.rental.profile.publish',
      label: 'Publier un bien',
      access: ServiceRouteAccessLevel.authRequired,
    ),
    ServiceRouteDef(
      id: 'immo.rental.profile.new_tenant',
      label: 'Nouveau locataire',
      access: ServiceRouteAccessLevel.authRequired,
    ),
    ServiceRouteDef(
      id: 'immo.rental.profile.contracts',
      label: 'Contrats',
      access: ServiceRouteAccessLevel.authRequired,
    ),
    ServiceRouteDef(
      id: 'immo.rental.profile.stats',
      label: 'Statistiques',
      access: ServiceRouteAccessLevel.comingSoon,
    ),
    ServiceRouteDef(
      id: 'immo.rental.profile.security',
      label: 'Connexion & sécurité',
      access: ServiceRouteAccessLevel.authRequired,
    ),
    ServiceRouteDef(
      id: 'immo.rental.profile.support',
      label: 'Support client',
      access: ServiceRouteAccessLevel.comingSoon,
    ),
    ServiceRouteDef(
      id: 'immo.rental.profile.legal',
      label: 'Informations légales',
      access: ServiceRouteAccessLevel.comingSoon,
    ),
    ServiceRouteDef(
      id: 'immo.rental.login',
      label: 'Connexion',
      access: ServiceRouteAccessLevel.authRequired,
      notes: 'Guest CTA → promptLogin (PIN / phone), not exitModule',
    ),
  ];

  //  Mr Immo Construction 

  static const _immoConstruction = <ServiceRouteDef>[
    ServiceRouteDef(
      id: 'immo.construction.tab.home',
      label: 'Accueil',
      access: ServiceRouteAccessLevel.guestOk,
    ),
    ServiceRouteDef(
      id: 'immo.construction.tab.messages',
      label: 'Messages',
      access: ServiceRouteAccessLevel.authRequired,
    ),
    ServiceRouteDef(
      id: 'immo.construction.tab.payments',
      label: 'Paiements',
      access: ServiceRouteAccessLevel.authRequired,
    ),
    ServiceRouteDef(
      id: 'immo.construction.tab.account',
      label: 'Compte',
      access: ServiceRouteAccessLevel.guestOk,
    ),
  ];

  //  Mr Immo Collection 

  static const _immoCollection = <ServiceRouteDef>[
    ServiceRouteDef(
      id: 'immo.collection.onboarding',
      label: 'Onboarding',
      access: ServiceRouteAccessLevel.guestOk,
    ),
    ServiceRouteDef(
      id: 'immo.collection.dashboard',
      label: 'Tableau de bord',
      access: ServiceRouteAccessLevel.authRequired,
    ),
    ServiceRouteDef(
      id: 'immo.collection.properties',
      label: 'Biens',
      access: ServiceRouteAccessLevel.authRequired,
    ),
    ServiceRouteDef(
      id: 'immo.collection.map',
      label: 'Carte biens',
      access: ServiceRouteAccessLevel.authRequired,
    ),
    ServiceRouteDef(
      id: 'immo.collection.rent',
      label: 'Encaissement',
      access: ServiceRouteAccessLevel.authRequired,
    ),
  ];

  //  Billetterie Transport 

  static const _billetterieTransport = <ServiceRouteDef>[
    ServiceRouteDef(
      id: 'billetterie.transport.tab.home',
      label: 'Home',
      access: ServiceRouteAccessLevel.guestOk,
      notes: 'Guest sees catalog browse',
    ),
    ServiceRouteDef(
      id: 'billetterie.transport.tab.map',
      label: 'Carte',
      access: ServiceRouteAccessLevel.guestOk,
    ),
    ServiceRouteDef(
      id: 'billetterie.transport.tab.tickets',
      label: 'Mes tickets',
      access: ServiceRouteAccessLevel.authForAction,
      notes: 'Guest falls back to catalog; owned tickets need login',
    ),
    ServiceRouteDef(
      id: 'billetterie.transport.tab.profile',
      label: 'Profil',
      access: ServiceRouteAccessLevel.guestOk,
    ),
    ServiceRouteDef(
      id: 'billetterie.transport.purchase',
      label: 'Achat ticket',
      access: ServiceRouteAccessLevel.authRequired,
      notes: 'ensureLoggedIn + subscription',
    ),
    ServiceRouteDef(
      id: 'billetterie.transport.profile.personal',
      label: 'Informations personnelles',
      access: ServiceRouteAccessLevel.authRequired,
    ),
    ServiceRouteDef(
      id: 'billetterie.transport.profile.documents',
      label: 'Documents',
      access: ServiceRouteAccessLevel.authRequired,
    ),
    ServiceRouteDef(
      id: 'billetterie.transport.profile.conductor',
      label: 'Devenir conducteur',
      access: ServiceRouteAccessLevel.authRequired,
    ),
    ServiceRouteDef(
      id: 'billetterie.transport.profile.security',
      label: 'Connexion & sécurité',
      access: ServiceRouteAccessLevel.authRequired,
    ),
    ServiceRouteDef(
      id: 'billetterie.transport.profile.messages',
      label: 'Messages',
      access: ServiceRouteAccessLevel.comingSoon,
    ),
    ServiceRouteDef(
      id: 'billetterie.transport.profile.support',
      label: 'Support client',
      access: ServiceRouteAccessLevel.comingSoon,
    ),
    ServiceRouteDef(
      id: 'billetterie.transport.profile.legal',
      label: 'Informations légales',
      access: ServiceRouteAccessLevel.comingSoon,
    ),
    ServiceRouteDef(
      id: 'billetterie.transport.login',
      label: 'Connexion',
      access: ServiceRouteAccessLevel.authRequired,
      notes: 'promptLogin → ModuleAuth.ensureRegistered',
    ),
  ];

  // Billetterie Event 

  static const _billetterieEvent = <ServiceRouteDef>[
    ServiceRouteDef(
      id: 'billetterie.event.tab.home',
      label: 'Home',
      access: ServiceRouteAccessLevel.guestOk,
    ),
    ServiceRouteDef(
      id: 'billetterie.event.tab.map',
      label: 'Carte',
      access: ServiceRouteAccessLevel.guestOk,
    ),
    ServiceRouteDef(
      id: 'billetterie.event.tab.tickets',
      label: 'Mes billets',
      access: ServiceRouteAccessLevel.authForAction,
    ),
    ServiceRouteDef(
      id: 'billetterie.event.tab.profile',
      label: 'Profil',
      access: ServiceRouteAccessLevel.guestOk,
    ),
    ServiceRouteDef(
      id: 'billetterie.event.profile.personal',
      label: 'Informations personnelles',
      access: ServiceRouteAccessLevel.authRequired,
    ),
    ServiceRouteDef(
      id: 'billetterie.event.profile.favorites',
      label: 'Événements favoris',
      access: ServiceRouteAccessLevel.authRequired,
    ),
    ServiceRouteDef(
      id: 'billetterie.event.profile.tickets',
      label: 'Mes billets',
      access: ServiceRouteAccessLevel.authRequired,
    ),
    ServiceRouteDef(
      id: 'billetterie.event.profile.subscription',
      label: 'Abonnement événements',
      access: ServiceRouteAccessLevel.authRequired,
    ),
    ServiceRouteDef(
      id: 'billetterie.event.profile.scan',
      label: 'Scanner des billets',
      access: ServiceRouteAccessLevel.authRequired,
    ),
    ServiceRouteDef(
      id: 'billetterie.event.profile.stats',
      label: 'Statistiques',
      access: ServiceRouteAccessLevel.comingSoon,
    ),
    ServiceRouteDef(
      id: 'billetterie.event.profile.security',
      label: 'Connexion & sécurité',
      access: ServiceRouteAccessLevel.authRequired,
    ),
    ServiceRouteDef(
      id: 'billetterie.event.profile.support',
      label: 'Support client',
      access: ServiceRouteAccessLevel.comingSoon,
    ),
    ServiceRouteDef(
      id: 'billetterie.event.profile.legal',
      label: 'Informations légales',
      access: ServiceRouteAccessLevel.comingSoon,
    ),
    ServiceRouteDef(
      id: 'billetterie.event.login',
      label: 'Connexion',
      access: ServiceRouteAccessLevel.authRequired,
    ),
  ];

  // Peya Pay 

  static const _peyapay = <ServiceRouteDef>[
    ServiceRouteDef(
      id: 'peyapay.shell',
      label: 'Peya Pay',
      access: ServiceRouteAccessLevel.guestOk,
      notes: 'Chrome visible; balance hidden until session',
    ),
    ServiceRouteDef(
      id: 'peyapay.settings',
      label: 'Paramètres',
      access: ServiceRouteAccessLevel.guestOk,
      notes: 'PeyapayHostRoutes.settings — inner rows may need auth',
    ),
    ServiceRouteDef(
      id: 'peyapay.balance',
      label: 'Solde',
      access: ServiceRouteAccessLevel.authRequired,
    ),
    ServiceRouteDef(
      id: 'peyapay.transactions',
      label: 'Transactions',
      access: ServiceRouteAccessLevel.authRequired,
    ),
    ServiceRouteDef(
      id: 'peyapay.transfer',
      label: 'Transfert',
      access: ServiceRouteAccessLevel.authRequired,
    ),
    ServiceRouteDef(
      id: 'peyapay.qr',
      label: 'QR / paiement',
      access: ServiceRouteAccessLevel.authRequired,
    ),
    ServiceRouteDef(
      id: 'peyapay.topup',
      label: 'Recharger',
      access: ServiceRouteAccessLevel.authRequired,
    ),
    ServiceRouteDef(
      id: 'peyapay.login',
      label: 'Connexion',
      access: ServiceRouteAccessLevel.authRequired,
      notes: 'ModuleAuth.ensureRegistered / ensureRegisteredForTransaction',
    ),
  ];
}
