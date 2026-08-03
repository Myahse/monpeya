import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:billetterie/src/core/constants/billetterie.brand.dart';
import 'package:billetterie/src/core/host/billetterie_host.bridge.dart';
import 'package:billetterie/src/features/event/models/billetterie.event.dart';
import 'package:billetterie/src/features/event/screens/event_business_home.view.dart';
import 'package:billetterie/src/features/event/screens/event_client_home.view.dart';
import 'package:billetterie/src/features/event/screens/event_create.screen.dart';
import 'package:billetterie/src/features/event/screens/event_details.screen.dart';
import 'package:billetterie/src/features/event/screens/event_map_explore.screen.dart';
import 'package:billetterie/src/features/event/screens/event_profile.screen.dart';
import 'package:billetterie/src/features/event/screens/event_ticket_scan.screen.dart';
import 'package:billetterie/src/features/event/services/billetterie_event_api.service.dart';
import 'package:billetterie/src/features/event/widgets/event_bottom_nav.widget.dart';
import 'package:billetterie/src/features/event/widgets/event_placeholder.widget.dart';
import 'package:billetterie/src/features/event/widgets/event_ui_chrome.dart';
import 'package:billetterie/src/shared/models/ticketing_api.exception.dart';
import 'package:billetterie/src/shared/services/billetterie_realtime.client.dart';
import 'package:billetterie/src/shared/widgets/ticket_purchase_result.dialog.dart';

/// Entry point for **Billetterie Événements**.
class BilletterieEventModuleScreen extends StatefulWidget {
  const BilletterieEventModuleScreen({super.key});

  @override
  State<BilletterieEventModuleScreen> createState() =>
      _BilletterieEventModuleScreenState();
}

class _BilletterieEventModuleScreenState
    extends State<BilletterieEventModuleScreen> {
  final _api = BilletterieEventApiService();
  final _realtime = BilletterieRealtimeClient();
  StreamSubscription<BilletterieRealtimeEvent>? _realtimeSub;
  Timer? _realtimeDebounce;

  BilletterieEventTab _tab = BilletterieEventTab.home;
  final Set<BilletterieEventTab> _visitedTabs = {BilletterieEventTab.home};
  EventProfileRole _role = EventProfileRole.client;
  bool _merchantOnly = false;

  CreatorDashboardSummary? _creatorSummary;
  bool _creatorLoading = false;
  String? _creatorError;
  bool _creatorLoaded = false;

  @override
  void initState() {
    super.initState();
    _realtimeSub = _realtime.events.listen(_onRealtimeEvent);
    _realtime.start();
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyAccountRole());
  }

  Future<void> _applyAccountRole() async {
    final merchantOnly = await BilletterieHostBridge.isMerchantOnly();
    if (!mounted) return;
    setState(() {
      _merchantOnly = merchantOnly;
      if (merchantOnly) _role = EventProfileRole.business;
    });
    if (merchantOnly) {
      await _loadCreatorDashboard();
    }
  }

  @override
  void dispose() {
    _realtimeDebounce?.cancel();
    _realtimeSub?.cancel();
    _realtime.dispose();
    super.dispose();
  }

  void _onRealtimeEvent(BilletterieRealtimeEvent event) {
    if (!event.touchesEvent) return;
    if (_role != EventProfileRole.business) return;
    _realtimeDebounce?.cancel();
    _realtimeDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _loadCreatorDashboard(silent: true);
    });
  }

  Future<void> _setRole(EventProfileRole role) async {
    if (role == EventProfileRole.client &&
        (_merchantOnly || await BilletterieHostBridge.isMerchantOnly())) {
      if (!mounted) return;
      await showBilletterieResultDialog(
        context,
        title: 'Compte marchand',
        message:
            'Ce numéro PeyaPay est un compte marchand sans portefeuille client. '
            'L’espace client (achat de billets) n’est pas disponible.',
        kind: BilletterieResultKind.info,
        brand: BilletterieBrand.eventOf(context),
      );
      return;
    }

    final signedIn = await BilletterieHostBridge.resolveClientOrNull();
    if (signedIn == null) {
      if (!mounted) return;
      final ok = await BilletterieHostBridge.promptLogin(context);
      if (!ok || !mounted) return;
    }
    if (!mounted) return;
    setState(() {
      _role = role;
      if (role == EventProfileRole.business) {
        _tab = BilletterieEventTab.home;
      }
    });
    if (role == EventProfileRole.business) {
      await _loadCreatorDashboard();
    }
  }

  Future<void> _loadCreatorDashboard({bool silent = false}) async {
    final blocking = !silent && _creatorSummary == null;
    if (blocking) {
      setState(() {
        _creatorLoading = true;
        _creatorError = null;
      });
    } else if (_creatorError != null) {
      setState(() => _creatorError = null);
    }
    try {
      final client = await BilletterieHostBridge.requireClient();
      final summary = await _api.getCreatorSummary(client.codeClient);
      if (!mounted) return;
      setState(() {
        _creatorSummary = summary;
        _creatorLoaded = true;
        _creatorLoading = false;
      });
    } on TicketingApiException catch (e) {
      if (!mounted) return;
      setState(() {
        if (_creatorSummary == null) _creatorError = e.message;
        _creatorLoading = false;
        _creatorLoaded = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (_creatorSummary == null) {
          _creatorError = 'Impossible de charger le tableau de bord.\n$e';
        }
        _creatorLoading = false;
        _creatorLoaded = true;
      });
    }
  }

  Future<void> _openCreateEvent() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const EventCreateScreen()),
    );
    if (created == true && mounted) {
      await _loadCreatorDashboard(silent: true);
    }
  }

  Future<void> _publishDraft(BilletterieEvent event) async {
    if (event.id.isEmpty) return;
    final brand = BilletterieBrand.eventOf(context);
    try {
      final client = await BilletterieHostBridge.requireClient();
      await _api.publishEvent(
        eventCode: event.id,
        codeClient: client.codeClient,
      );
      if (!mounted) return;
      await showBilletterieResultDialog(
        context,
        title: 'Événement publié',
        message: '${event.name} est maintenant en ligne.\n'
            'Les billets sont disponibles à la vente.',
        kind: BilletterieResultKind.success,
        brand: brand,
      );
      await _loadCreatorDashboard(silent: true);
    } on TicketingApiException catch (e) {
      if (!mounted) return;
      await showBilletterieResultDialog(
        context,
        title: 'Publication impossible',
        message: e.message,
        kind: BilletterieResultKind.error,
        brand: brand,
      );
    } catch (e) {
      if (!mounted) return;
      await showBilletterieResultDialog(
        context,
        title: 'Publication impossible',
        message: '$e',
        kind: BilletterieResultKind.error,
        brand: brand,
      );
    }
  }

  void _openBusinessEvent(BilletterieEvent event) {
    openEventDetails(
      context,
      EventDetailsData(
        id: event.id,
        title: event.name,
        imageUrl: event.flyerImage ??
            'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?auto=format&fit=crop&w=900&q=80',
        dateTimeLabel: [
          if (event.date.isNotEmpty) event.date,
          if (event.time.isNotEmpty) event.time,
        ].join(' · '),
        description: event.description,
        place: [
          if (event.venue.isNotEmpty) event.venue,
          if (event.city.isNotEmpty) event.city,
        ].join(', '),
        availableTickets: event.ticketCategories.fold<int>(
          0,
          (sum, c) => sum + c.remaining,
        ),
        ticketNumber: event.id,
        city: event.city,
        latitude: event.latitude,
        longitude: event.longitude,
        category: event.eventType,
        galleryUrls: event.galleryImageUrls,
        tip: event.tip,
        status: event.status ?? 'Ouvert',
      ),
    );
  }

  Future<void> _openScanner() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const EventTicketScanScreen(),
      ),
    );
    if (_role == EventProfileRole.business && mounted) {
      await _loadCreatorDashboard(silent: true);
    }
  }

  void _onTabChanged(BilletterieEventTab tab) {
    if (_role == EventProfileRole.business &&
        tab == BilletterieEventTab.tickets) {
      _openScanner();
      return;
    }
    setState(() {
      _tab = tab;
      _visitedTabs.add(tab);
    });
    if (tab == BilletterieEventTab.home &&
        _role == EventProfileRole.business &&
        !_creatorLoaded) {
      _loadCreatorDashboard();
    }
  }

  static const _tabOrder = <BilletterieEventTab>[
    BilletterieEventTab.home,
    BilletterieEventTab.map,
    BilletterieEventTab.tickets,
    BilletterieEventTab.profile,
  ];

  @override
  Widget build(BuildContext context) {
    final chrome = EventUiChrome.of(context);
    final tabIndex = _tabOrder.indexOf(_tab).clamp(0, _tabOrder.length - 1);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: chrome.statusStyle,
      child: Scaffold(
        backgroundColor: chrome.scaffold,
        body: Stack(
          children: [
            Positioned.fill(
              child: ClipRect(
                child: IndexedStack(
                  index: tabIndex,
                  sizing: StackFit.expand,
                  children: [
                    for (final tab in _tabOrder)
                      _visitedTabs.contains(tab)
                          ? KeyedSubtree(
                              key: ValueKey('event-$tab-$_role'),
                              child: _buildTabPage(tab),
                            )
                          : const SizedBox.shrink(),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BilletterieEventBottomNav(
                current: _tab,
                onChanged: _onTabChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabPage(BilletterieEventTab tab) {
    switch (tab) {
      case BilletterieEventTab.home:
        if (_role == EventProfileRole.client) {
          return const EventClientHomeView();
        }
        return EventBusinessHomeView(
          summary: _creatorSummary,
          loading: _creatorLoading,
          error: _creatorError,
          onRefresh: () => _loadCreatorDashboard(silent: true),
          onCreateEvent: _openCreateEvent,
          onOpenEvent: _openBusinessEvent,
          onPublishEvent: _publishDraft,
          onScanTickets: _openScanner,
        );
      case BilletterieEventTab.map:
        if (_role == EventProfileRole.business) {
          return const SafeArea(
            bottom: false,
            child: EventPlaceholderPane(
              title: 'Carte organisateur',
              subtitle: 'Visualisez vos lieux d’événements ici bientôt.',
              icon: Icons.map_outlined,
            ),
          );
        }
        return const EventMapExploreScreen();
      case BilletterieEventTab.tickets:
        return const SafeArea(
          bottom: false,
          child: EventPlaceholderPane(
            title: 'Mes tickets',
            subtitle: 'Vos billets d’événements apparaîtront ici.',
            icon: Icons.confirmation_number_outlined,
          ),
        );
      case BilletterieEventTab.profile:
        return SafeArea(
          bottom: false,
          child: EventProfileScreen(
            role: _role,
            merchantOnly: _merchantOnly,
            onRoleChanged: _setRole,
            onScanTickets: _openScanner,
          ),
        );
    }
  }
}
