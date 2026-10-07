import 'dart:async';

import 'package:flutter/material.dart';

import 'package:grenier/src/core/host/grenier_host.bridge.dart';
import 'package:grenier/src/presentation/screens/grenier_account.view.dart';
import 'package:grenier/src/presentation/screens/grenier_detail.screen.dart';
import 'package:grenier/src/presentation/screens/grenier_follows.view.dart';
import 'package:grenier/src/presentation/screens/grenier_markets.view.dart';
import 'package:grenier/src/presentation/widgets/grenier_ui.dart';
import 'package:grenier/src/shared/models/grenier_produit.model.dart';
import 'package:grenier/src/shared/services/grenier_api.service.dart';
import 'package:grenier/src/shared/services/grenier_follow.store.dart';
import 'package:grenier/src/shared/services/grenier_realtime.client.dart';

/// Mon Grenier entry: Marchés / Suivis / Mon compte. Access is granted by the
/// Mon Peya subscription; there is no payment inside Mon Grenier.
class GrenierModuleScreen extends StatefulWidget {
  const GrenierModuleScreen({super.key});

  @override
  State<GrenierModuleScreen> createState() => _GrenierModuleScreenState();
}

class _GrenierModuleScreenState extends State<GrenierModuleScreen> {
  static const _tabs = [
    GrenierNavItem(
      'Marchés',
      Icons.storefront_outlined,
      Icons.storefront_rounded,
    ),
    GrenierNavItem('Suivis', Icons.star_outline_rounded, Icons.star_rounded),
    GrenierNavItem(
      'Mon compte',
      Icons.person_outline_rounded,
      Icons.person_rounded,
    ),
  ];

  final _api = GrenierApiService();
  final _realtime = GrenierRealtimeClient();
  final _followStore = GrenierFollowStore();
  StreamSubscription<List<GrenierProduit>>? _sub;

  List<GrenierProduit> _items = const [];
  bool _loading = true;
  String? _error;
  int? _flashId;
  int _tab = 0;

  GrenierHostProfile? _profile;
  Set<int> _follows = {};
  bool _ready = false;

  /// Prices seen during this session, used when the API sends no history.
  final Map<int, List<GrenierPricePoint>> _seen = {};

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final results = await Future.wait<Object?>([
      GrenierHostBridge.profile(),
      _followStore.load(),
    ]);
    if (!mounted) return;
    setState(() {
      _profile = results[0] as GrenierHostProfile?;
      _follows = results[1]! as Set<int>;
      _ready = true;
    });
    unawaited(_loadProducts());
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _api.listProduits();
      if (!mounted) return;
      _record(items);
      setState(() {
        _items = items;
        _loading = false;
      });
      await _sub?.cancel();
      _realtime.connect(initial: items);
      _sub = _realtime.stream.listen(_onLive);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _record(List<GrenierProduit> items) {
    final now = DateTime.now();
    for (final p in items) {
      final list = _seen.putIfAbsent(p.id, () => []);
      if (list.isEmpty || list.last.price != p.price) {
        list.add(GrenierPricePoint(at: p.updatedAt ?? now, price: p.price));
      }
    }
  }

  void _onLive(List<GrenierProduit> next) {
    if (!mounted) return;
    final prev = {for (final i in _items) i.id: i.price};
    int? changed;
    for (final i in next) {
      if (prev[i.id] != null && prev[i.id] != i.price) changed = i.id;
    }
    _record(next);
    setState(() {
      _items = next;
      _flashId = changed;
    });
    if (changed != null) {
      Future<void>.delayed(const Duration(milliseconds: 1200), () {
        if (mounted && _flashId == changed) setState(() => _flashId = null);
      });
    }
  }

  List<GrenierPricePoint> _historyOf(GrenierProduit p) =>
      p.history.length >= 2 ? p.history : (_seen[p.id] ?? const []);

  void _setFollow(GrenierProduit p, bool on) {
    setState(() {
      _follows = {..._follows};
      on ? _follows.add(p.id) : _follows.remove(p.id);
    });
    unawaited(_followStore.save(_follows));
  }

  void _open(GrenierProduit p) {
    final others =
        _items
            .where(
              (o) =>
                  o.id != p.id && o.name.toLowerCase() == p.name.toLowerCase(),
            )
            .toList()
          ..sort((a, b) => a.price.compareTo(b.price));
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 450),
        reverseTransitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, _, _) => GrenierDetailScreen(
          product: p,
          history: _historyOf(p),
          otherMarkets: others,
          followed: _follows.contains(p.id),
          onToggleFollow: (on) => _setFollow(p, on),
        ),
        transitionsBuilder: (_, a, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _realtime.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        backgroundColor: GrenierColors.primary,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: GrenierColors.bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: IndexedStack(
              index: _tab,
              children: [
                GrenierMarketsView(
                  products: _items,
                  profile: _profile,
                  flashId: _flashId,
                  loading: _loading,
                  error: _error,
                  onRetry: _loadProducts,
                  onOpen: _open,
                  onAccount: () => setState(() => _tab = 2),
                ),
                GrenierFollowsView(
                  products: _items
                      .where((p) => _follows.contains(p.id))
                      .toList(),
                  onOpen: _open,
                  onUnfollow: (p) => _setFollow(p, false),
                  onBrowse: () => setState(() => _tab = 0),
                ),
                GrenierAccountView(
                  profile: _profile,
                  onExit: () => GrenierHostBridge.exitModule(context),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: GrenierPillNav(
              items: _tabs,
              index: _tab,
              onSelected: (i) => setState(() => _tab = i),
            ),
          ),
        ],
      ),
    );
  }
}
