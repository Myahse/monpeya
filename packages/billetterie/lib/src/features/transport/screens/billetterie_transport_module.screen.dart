import 'dart:async';

import 'package:flutter/material.dart';

import 'package:billetterie/src/core/constants/billetterie.brand.dart';
import 'package:billetterie/src/core/host/billetterie_host.bridge.dart';
import 'package:billetterie/src/features/transport/models/billetterie_transport_ticket.dart';
import 'package:billetterie/src/features/transport/models/transport_profile.model.dart';
import 'package:billetterie/src/features/transport/screens/billetterie_home.view.dart';
import 'package:billetterie/src/features/transport/screens/business_home.view.dart';
import 'package:billetterie/src/features/transport/screens/ticket_details.screen.dart';
import 'package:billetterie/src/features/transport/screens/ticket_generate.screen.dart';
import 'package:billetterie/src/features/transport/screens/ticket_scan_consume.screen.dart';
import 'package:billetterie/src/features/transport/screens/transport_map_explore.screen.dart';
import 'package:billetterie/src/features/transport/services/billetterie_transport_api.service.dart';
import 'package:billetterie/src/features/transport/services/conductor_ticket.store.dart';
import 'package:billetterie/src/features/transport/services/ticket_pdf.service.dart';
import 'package:billetterie/src/features/transport/services/transport_profile.store.dart';
import 'package:billetterie/src/features/transport/widgets/owned_transport_ticket.widget.dart';
import 'package:billetterie/src/features/transport/screens/transport_profile.screen.dart';
import 'package:billetterie/src/shared/services/billetterie_realtime.client.dart';
import 'package:billetterie/src/shared/widgets/billetterie_bottom_nav.widget.dart';
import 'package:billetterie/src/shared/widgets/billetterie_skeleton.widget.dart';
import 'package:billetterie/src/shared/widgets/ticket_purchase_result.dialog.dart';

/// Entry point for **Billetterie Transport** 
class BilletterieTransportModuleScreen extends StatefulWidget {
  const BilletterieTransportModuleScreen({super.key});

  @override
  State<BilletterieTransportModuleScreen> createState() =>
      _BilletterieTransportModuleScreenState();
}

class _BilletterieTransportModuleScreenState
    extends State<BilletterieTransportModuleScreen>
    with SingleTickerProviderStateMixin {
  final _api = BilletterieTransportApiService();
  final _profileStore = TransportProfileStore();
  final _conductorStore = ConductorTicketStore();
  final _ticketsSearchController = TextEditingController();
  final _realtime = BilletterieRealtimeClient();
  StreamSubscription<BilletterieRealtimeEvent>? _realtimeSub;
  Timer? _realtimeDebounce;

  BilletterieTab _tab = BilletterieTab.home;
  final Set<BilletterieTab> _visitedTabs = {BilletterieTab.home};
  String _ticketsQuery = '';
  TransportProfileState _profile = const TransportProfileState();

  List<BilletterieTransportTicket> _catalog = const [];
  List<BilletterieTransportTicket> _owned = const [];
  List<BilletterieTransportTicket> _generated = const [];
  List<BilletterieTransportTicket> _sales = const [];
  ConductorEarningsSummary _earnings = const ConductorEarningsSummary(
    generatedCount: 0,
    forSaleCount: 0,
    soldCount: 0,
    consumedCount: 0,
    totalEarned: 0,
    currency: 'Fcfa',
  );

  bool _loadingCatalog = true;
  bool _loadingOwned = false;
  bool _loadingBusiness = false;
  bool _catalogLoaded = false;
  bool _ownedLoaded = false;
  bool _businessLoaded = false;
  bool _isGuest = true;
  bool _merchantOnly = false;
  String? _catalogError;
  String? _ownedError;
  String? _businessError;

  late final AnimationController _navEnter;
  late final Animation<double> _navFade;
  late final Animation<Offset> _navSlide;

  bool get _isBusiness =>
      _merchantOnly ||
      (_profile.isConductorMode && _profile.canUseAsConductor);

  @override
  void initState() {
    super.initState();
    _navEnter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    final curve = CurvedAnimation(
      parent: _navEnter,
      curve: const Interval(0.62, 1.0, curve: Curves.easeOutCubic),
    );
    _navFade = curve;
    _navSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(curve);
    TransportProfileStore.revision.addListener(_onProfileRevision);
    BilletterieHostBridge.sessionChanges?.addListener(_onHostSessionChanged);
    _bootstrap();
    _startRealtime();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _navEnter.forward();
    });
  }

  @override
  void dispose() {
    TransportProfileStore.revision.removeListener(_onProfileRevision);
    BilletterieHostBridge.sessionChanges?.removeListener(_onHostSessionChanged);
    _realtimeDebounce?.cancel();
    _realtimeSub?.cancel();
    _realtime.dispose();
    _ticketsSearchController.dispose();
    _navEnter.dispose();
    super.dispose();
  }

  void _startRealtime() {
    _realtimeSub?.cancel();
    _realtimeSub = _realtime.events.listen(_onRealtimeEvent);
    _realtime.start();
  }

  void _onRealtimeEvent(BilletterieRealtimeEvent event) {
    if (!event.touchesTransport) return;
    _realtimeDebounce?.cancel();
    _realtimeDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      if (_isBusiness) {
        _loadBusiness(silent: true);
      } else {
        _loadCatalog(silent: true);
        if (_ownedLoaded || _tab == BilletterieTab.tickets) {
          _loadOwned(silent: true);
        }
      }
    });
  }

  void _onProfileRevision() {
    _bootstrap();
  }

  void _onHostSessionChanged() {
    _refreshGuestFlag();
    if (_isBusiness) {
      _loadBusiness(silent: _businessLoaded);
    } else {
      _loadCatalog(silent: _catalogLoaded);
      if (_tab == BilletterieTab.tickets || _ownedLoaded) {
        _loadOwned(silent: _ownedLoaded);
      }
    }
  }

  Future<void> _refreshGuestFlag() async {
    final guest = await BilletterieHostBridge.isGuest();
    if (!mounted) return;
    setState(() => _isGuest = guest);
  }

  Future<void> _bootstrap() async {
    await _refreshGuestFlag();
    final merchantOnly = await BilletterieHostBridge.isMerchantOnly();
    final profile = await _profileStore.load();
    if (!mounted) return;
    final wasBusiness = _isBusiness;
    setState(() {
      _merchantOnly = merchantOnly;
      _profile = profile;
    });
    final nowBusiness = merchantOnly ||
        (profile.isConductorMode && profile.canUseAsConductor);
    if (wasBusiness != nowBusiness) {
      setState(() => _tab = BilletterieTab.home);
    }
    if (nowBusiness) {
      await _loadBusiness(silent: _businessLoaded);
    } else {
      await _loadCatalog(silent: _catalogLoaded);
    }
  }

  Future<void> _loadCatalog({bool silent = false}) async {
    final blocking = !silent && !_catalogLoaded && _catalog.isEmpty;
    if (blocking) {
      setState(() {
        _loadingCatalog = true;
        _catalogError = null;
      });
    } else if (_catalogError != null) {
      setState(() => _catalogError = null);
    }
    try {
      List<BilletterieTransportTicket> apiTickets = const [];
      try {
        apiTickets = await _api.listForSale();
      } catch (_) {
        // Offline / API down — still show locally published tickets.
      }
      final localForSale = await _conductorStore.listForSalePublic();
      final merged = _mergeTickets(localFirst: localForSale, then: apiTickets);
      if (!mounted) return;
      setState(() {
        _catalog = merged;
        _catalogLoaded = true;
        _loadingCatalog = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (_catalog.isEmpty) _catalogError = '$e';
        _catalogLoaded = true;
        _loadingCatalog = false;
      });
    }
  }

  Future<void> _loadOwned({bool silent = false}) async {
    final blocking = !silent && !_ownedLoaded && _owned.isEmpty;
    if (blocking) {
      setState(() {
        _loadingOwned = true;
        _ownedError = null;
      });
    } else if (_ownedError != null) {
      setState(() => _ownedError = null);
    }
    try {
      final client = await BilletterieHostBridge.resolveClientOrNull();
      if (client == null) {
        if (!mounted) return;
        setState(() {
          _owned = const [];
          _ownedLoaded = true;
          _loadingOwned = false;
        });
        return;
      }
      List<BilletterieTransportTicket> apiOwned = const [];
      try {
        apiOwned = await _api.getMyTickets(client.codeClient);
      } catch (_) {}
      final localOwned =
          await _conductorStore.listPurchasedBy(client.codeClient);
      final merged = _mergeTickets(localFirst: localOwned, then: apiOwned);
      if (!mounted) return;
      setState(() {
        _owned = merged;
        _ownedLoaded = true;
        _loadingOwned = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (_owned.isEmpty) _ownedError = '$e';
        _ownedLoaded = true;
        _loadingOwned = false;
      });
    }
  }

  List<BilletterieTransportTicket> _mergeTickets({
    required List<BilletterieTransportTicket> localFirst,
    required List<BilletterieTransportTicket> then,
  }) {
    final seen = <String>{};
    final out = <BilletterieTransportTicket>[];
    for (final t in [...localFirst, ...then]) {
      final key = t.ticketCode ?? t.resolvedQrPayload;
      if (seen.contains(key)) continue;
      seen.add(key);
      out.add(t);
    }
    return out;
  }

  Future<void> _loadBusiness({bool silent = false}) async {
    final blocking = !silent && !_businessLoaded && _generated.isEmpty && _sales.isEmpty;
    if (blocking) {
      setState(() {
        _loadingBusiness = true;
        _businessError = null;
      });
    } else if (_businessError != null) {
      setState(() => _businessError = null);
    }
    try {
      final client = await BilletterieHostBridge.resolveClientOrNull();
      if (client == null) {
        if (!mounted) return;
        setState(() {
          _generated = const [];
          _sales = const [];
          _earnings = const ConductorEarningsSummary(
            generatedCount: 0,
            forSaleCount: 0,
            soldCount: 0,
            consumedCount: 0,
            totalEarned: 0,
            currency: 'Fcfa',
          );
          _businessLoaded = true;
          _loadingBusiness = false;
        });
        return;
      }
      List<BilletterieTransportTicket> generated = const [];
      List<BilletterieTransportTicket> sales = const [];

      try {
        generated = await _api.getMyGeneratedTickets(client.codeClient);
      } catch (_) {
        generated = await _conductorStore.listGenerated(client.codeClient);
      }
      try {
        sales = await _api.getMySales(client.codeClient);
      } catch (_) {
        sales = await _conductorStore.listSales(client.codeClient);
      }

      // Keep local copies in sync when API returns data.
      for (final t in [...generated, ...sales]) {
        await _conductorStore.saveGenerated(
          issuerCodeClient: client.codeClient,
          ticket: t,
        );
      }

      // Prefer merged local view so offline generates stay visible.
      generated = await _conductorStore.listGenerated(client.codeClient);
      sales = await _conductorStore.listSales(client.codeClient);
      final summary = await _conductorStore.summary(client.codeClient);

      if (!mounted) return;
      setState(() {
        _generated = generated;
        _sales = sales;
        _earnings = summary;
        _businessLoaded = true;
        _loadingBusiness = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (_generated.isEmpty && _sales.isEmpty) _businessError = '$e';
        _businessLoaded = true;
        _loadingBusiness = false;
      });
    }
  }

  List<BilletterieTransportTicket> get _filteredOwned {
    final q = _ticketsQuery.trim().toLowerCase();
    if (q.isEmpty) return _owned;
    return _owned.where((t) {
      return t.fromCode.toLowerCase().contains(q) ||
          t.toCode.toLowerCase().contains(q) ||
          t.fromCity.toLowerCase().contains(q) ||
          t.toCity.toLowerCase().contains(q) ||
          t.vehicleNumber.toLowerCase().contains(q) ||
          (t.ticketCode?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  void _onTabChanged(BilletterieTab tab) {
    if (_isBusiness && tab == BilletterieTab.tickets) {
      _openScanner();
      return;
    }
    setState(() {
      _tab = tab;
      _visitedTabs.add(tab);
    });
    // First visit only — later updates come from WebSocket / pull-to-refresh.
    if (tab == BilletterieTab.tickets) {
      if (!_catalogLoaded) _loadCatalog();
      if (!_ownedLoaded) _loadOwned();
    } else if (tab == BilletterieTab.home || tab == BilletterieTab.map) {
      if (_isBusiness && !_businessLoaded) {
        _loadBusiness();
      } else if (!_isBusiness && !_catalogLoaded) {
        _loadCatalog();
      }
    }
  }

  static const _tabOrder = <BilletterieTab>[
    BilletterieTab.home,
    BilletterieTab.map,
    BilletterieTab.tickets,
    BilletterieTab.profile,
  ];

  Future<void> _openScanner() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const TicketScanConsumeScreen(),
      ),
    );
    if (_isBusiness && mounted) await _loadBusiness(silent: true);
  }

  Future<void> _openGenerate() async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const TicketGenerateScreen(),
      ),
    );
    if (ok == true && mounted) await _loadBusiness(silent: true);
  }

  Future<void> _openBusinessTicket(BilletterieTransportTicket ticket) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => TicketDetailsScreen(
          ticket: ticket,
          owned: false,
        ),
      ),
    );
  }

  List<BilletterieTransportTicket> get _mapTickets {
    if (_isBusiness) {
      return _mergeTickets(localFirst: _generated, then: _sales);
    }
    return _catalog;
  }

  @override
  Widget build(BuildContext context) {
    final brand = BilletterieBrand.of(context);
    final isMap = _tab == BilletterieTab.map;
    final mapChromeLight = Theme.of(context).brightness == Brightness.light;
    final tabIndex = _tabOrder.indexOf(_tab).clamp(0, _tabOrder.length - 1);

    return Scaffold(
      backgroundColor: isMap
          ? (mapChromeLight ? brand.bg : Colors.black)
          : brand.bg,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          // Full-bleed under the frosted nav so maps can blur through.
          Positioned.fill(
            child: ClipRect(
              child: IndexedStack(
                index: tabIndex,
                sizing: StackFit.expand,
                children: [
                  for (final tab in _tabOrder)
                    _visitedTabs.contains(tab)
                        ? KeyedSubtree(
                            key: ValueKey('transport-$tab'),
                            child: tab == BilletterieTab.map
                                ? _buildTabPage(tab)
                                : SafeArea(
                                    bottom: false,
                                    child: _buildTabPage(tab),
                                  ),
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
            child: FadeTransition(
              opacity: _navFade,
              child: SlideTransition(
                position: _navSlide,
                child: BilletterieBottomNav(
                  current: _tab,
                  onChanged: _onTabChanged,
                  businessMode: _isBusiness,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabPage(BilletterieTab tab) {
    switch (tab) {
      case BilletterieTab.home:
        if (_isBusiness) {
          if (_loadingBusiness && !_businessLoaded) {
            return const BilletterieHomeSkeleton();
          }
          if (_businessError != null && !_businessLoaded) {
            return _ErrorPane(
              message: _businessError!,
              onRetry: _loadBusiness,
            );
          }
          return BusinessHomeView(
            summary: _earnings,
            generated: _generated,
            sales: _sales,
            onRefresh: () => _loadBusiness(silent: true),
            onGenerate: _openGenerate,
            onOpenTicket: _openBusinessTicket,
          );
        }
        if (_loadingCatalog && !_catalogLoaded) {
          return const BilletterieHomeSkeleton();
        }
        if (_catalogError != null && !_catalogLoaded) {
          return _ErrorPane(
            message: _catalogError!,
            onRetry: _loadCatalog,
          );
        }
        return BilletterieHomeView(tickets: _catalog);
      case BilletterieTab.map:
        final mapBrand = BilletterieBrand.of(context);
        final isLight = Theme.of(context).brightness == Brightness.light;
        final loadingBg = isLight ? mapBrand.bg : Colors.black;
        final loadingFg = isLight ? mapBrand.primaryDark : Colors.white70;
        if (_isBusiness) {
          if (_loadingBusiness && !_businessLoaded) {
            return ColoredBox(
              color: loadingBg,
              child: Center(
                child: CircularProgressIndicator(color: loadingFg),
              ),
            );
          }
        } else if (_loadingCatalog && !_catalogLoaded) {
          return ColoredBox(
            color: loadingBg,
            child: Center(
              child: CircularProgressIndicator(color: loadingFg),
            ),
          );
        }
        return TransportMapExploreScreen(
          tickets: _mapTickets,
          onRefresh: _isBusiness
              ? () => _loadBusiness(silent: true)
              : () => _loadCatalog(silent: true),
        );
      case BilletterieTab.tickets:
        if (_loadingOwned && !_ownedLoaded && !_isGuest) {
          return const BilletterieTicketsSkeleton();
        }
        if (_loadingCatalog && !_catalogLoaded && _isGuest) {
          return const BilletterieHomeSkeleton();
        }
        if (_ownedError != null && !_ownedLoaded && !_isGuest) {
          return _ErrorPane(
            message: _ownedError!,
            onRetry: _loadOwned,
          );
        }
        if (_isGuest && _owned.isEmpty) {
          if (_loadingCatalog && !_catalogLoaded) {
            return const BilletterieHomeSkeleton();
          }
          return BilletterieHomeView(
            tickets: _catalog,
            guestMode: true,
          );
        }
        return _MyTicketsView(
          searchController: _ticketsSearchController,
          onQueryChanged: (value) => setState(() => _ticketsQuery = value),
          tickets: _filteredOwned,
          onRefresh: () => _loadOwned(silent: true),
        );
      case BilletterieTab.profile:
        return const TransportProfileScreen();
    }
  }
}

class _ErrorPane extends StatelessWidget {
  const _ErrorPane({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final brand = BilletterieBrand.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 40, color: brand.muted),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: brand.muted,
                  ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyTicketsView extends StatefulWidget {
  const _MyTicketsView({
    required this.searchController,
    required this.onQueryChanged,
    required this.tickets,
    this.onRefresh,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onQueryChanged;
  final List<BilletterieTransportTicket> tickets;
  final Future<void> Function()? onRefresh;

  @override
  State<_MyTicketsView> createState() => _MyTicketsViewState();
}

class _MyTicketsViewState extends State<_MyTicketsView> {
  int? _expandedIndex;
  int? _flippedIndex;
  bool _exporting = false;
  int _qrRevealEpoch = 0;

  void _onTicketTap(int index) {
    setState(() {
      if (_flippedIndex == index) {
        _flippedIndex = null;
        _expandedIndex = index;
        return;
      }
      if (_expandedIndex == index) {
        _flippedIndex = index;
        return;
      }
      _expandedIndex = index;
      _flippedIndex = null;
    });
  }

  Future<void> _openDetails(
    BilletterieTransportTicket ticket,
    BilletterieTicketBadge? badge,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TicketDetailsScreen(
          ticket: ticket,
          badge: badge,
          owned: true,
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _qrRevealEpoch++);
    await widget.onRefresh?.call();
  }

  Future<void> _exportPdf(BilletterieTransportTicket ticket) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      await TicketPdfService().exportAndShare(ticket);
    } catch (e) {
      if (mounted) {
        await showBilletterieResultDialog(
          context,
          title: 'Export impossible',
          message: 'Impossible d’exporter le PDF.\n$e',
          kind: BilletterieResultKind.error,
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tickets = widget.tickets;
    final badges = computeTicketBadges(tickets);
    final brand = BilletterieBrand.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: _ScreenTitle('Mes tickets'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.searchController,
                  onChanged: widget.onQueryChanged,
                  decoration: InputDecoration(
                    hintText: 'Rechercher…',
                    hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: brand.muted,
                        ),
                    filled: true,
                    fillColor: brand.searchFill,
                    suffixIcon: Icon(
                      Icons.search_rounded,
                      color: brand.muted,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.filter_list_rounded, size: 28),
                color: brand.text,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: _SectionTitle('Ticket'),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: tickets.isEmpty
              ? Center(
                  child: Text(
                    'Aucun ticket',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: brand.muted,
                        ),
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    4,
                    16,
                    BilletterieBottomNav.contentBottomPadding(context),
                  ),
                  itemCount: tickets.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final ticket = tickets[index];
                    final active =
                        _expandedIndex == index || _flippedIndex == index;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OwnedTransportTicket(
                          ticket: ticket,
                          badge: badges[index],
                          expanded: _expandedIndex == index,
                          showingBack: _flippedIndex == index,
                          revealRevision: _qrRevealEpoch,
                          onTap: () => _onTicketTap(index),
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeInOutCubic,
                          alignment: Alignment.topCenter,
                          child: active
                              ? _TicketActionsRow(
                                  exporting: _exporting,
                                  onDetails: () =>
                                      _openDetails(ticket, badges[index]),
                                  onExportPdf: () => _exportPdf(ticket),
                                )
                              : const SizedBox(width: double.infinity),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _TicketActionsRow extends StatelessWidget {
  const _TicketActionsRow({
    required this.exporting,
    required this.onDetails,
    required this.onExportPdf,
  });

  final bool exporting;
  final VoidCallback onDetails;
  final VoidCallback onExportPdf;

  @override
  Widget build(BuildContext context) {
    final brand = BilletterieBrand.of(context);
    final labelStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: brand.text,
        );

    final style = OutlinedButton.styleFrom(
      foregroundColor: brand.text,
      side: BorderSide(color: brand.border),
      padding: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onDetails,
              icon: Icon(Icons.info_outline_rounded, size: 18, color: brand.text),
              label: Text('Détails', style: labelStyle),
              style: style,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: exporting ? null : onExportPdf,
              icon: exporting
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: brand.text,
                      ),
                    )
                  : Icon(
                      Icons.picture_as_pdf_rounded,
                      size: 18,
                      color: brand.text,
                    ),
              label: Text('PDF', style: labelStyle),
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScreenTitle extends StatelessWidget {
  const _ScreenTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: BilletterieBrand.of(context).text,
          ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: BilletterieBrand.of(context).text,
            letterSpacing: -0.4,
          ),
    );
  }
}

/// Backward-compatible alias — prefer [BilletterieTransportModuleScreen].
typedef BilletterieModuleScreen = BilletterieTransportModuleScreen;
