import 'package:flutter/material.dart';

import 'package:leadway/src/core/constants/leadway_life.constants.dart';
import 'package:leadway/src/core/host/leadway_host.bridge.dart';
import 'package:leadway/src/data/models/leadway_api.exception.dart';
import 'package:leadway/src/data/models/leadway_life_list.model.dart';
import 'package:leadway/src/data/services/leadway_life_api.service.dart';
import 'package:leadway/src/presentation/constants/leadway.brand.dart';
import 'package:leadway/src/presentation/screens/leadway_life_subscription_detail.screen.dart';
import 'package:leadway/src/presentation/widgets/leadway_toast.widget.dart';

/// Liste paginée des souscriptions Vie (scroll infini).
/// `customerId` vient des métadonnées app (généré / réutilisé automatiquement).
class LeadwayLifeSubscriptionsScreen extends StatefulWidget {
  const LeadwayLifeSubscriptionsScreen({super.key});

  @override
  State<LeadwayLifeSubscriptionsScreen> createState() => _LeadwayLifeSubscriptionsScreenState();
}

class _LeadwayLifeSubscriptionsScreenState extends State<LeadwayLifeSubscriptionsScreen> {
  final _api = LeadwayLifeApiService();
  final _scrollCtrl = ScrollController();

  static const _pageSize = 10;

  String _customerId = '';
  LeadwayLifeSubscriptionStatus? _statusFilter;
  final List<LeadwayLifeSubscriptionItem> _items = [];
  int _page = 0;
  int _totalPages = 0;
  int _totalItems = 0;
  bool _loading = false;
  bool _loadingMore = false;
  bool _bootstrapping = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final customerId = await LeadwayHostBridge.getMeta(LeadwayMetaKeys.customerId) ?? '';
    if (!mounted) return;
    setState(() {
      _customerId = customerId;
      _bootstrapping = false;
    });
    if (_customerId.isNotEmpty) {
      await _reload();
    }
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients || _loadingMore || _loading) return;
    if (_page + 1 >= _totalPages) return;
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _reload() async {
    if (_customerId.isEmpty) {
      final customerId = await LeadwayHostBridge.getMeta(LeadwayMetaKeys.customerId) ?? '';
      if (!mounted) return;
      setState(() => _customerId = customerId);
    }
    if (_customerId.isEmpty) {
      LeadwayToast.show(
        context,
        message: 'Identifiant client indisponible.',
        type: LeadwayToastType.error,
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _items.clear();
      _page = 0;
      _totalPages = 0;
      _totalItems = 0;
    });
    await _fetchPage(0, replace: true);
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _page + 1 >= _totalPages) return;
    setState(() => _loadingMore = true);
    await _fetchPage(_page + 1, replace: false);
  }

  Future<void> _fetchPage(int page, {required bool replace}) async {
    try {
      final result = await _api.listSubscriptions(
        customerId: _customerId,
        status: _statusFilter?.code,
        page: page,
        size: _pageSize,
      );
      if (!mounted) return;
      final p = result.subscriptions;
      setState(() {
        if (replace) {
          _items
            ..clear()
            ..addAll(p.items);
        } else {
          _items.addAll(p.items);
        }
        _page = p.page;
        _totalPages = p.totalPages;
        _totalItems = p.totalItems;
        _loading = false;
        _loadingMore = false;
        _error = null;
      });
    } on LeadwayApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = e.displayMessage;
      });
      LeadwayToast.show(context, message: e.displayMessage, type: LeadwayToastType.error);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = '$e';
      });
      LeadwayToast.show(context, message: 'Erreur chargement : $e', type: LeadwayToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LeadwayTheme(
      child: Scaffold(
      backgroundColor: LeadwayBrand.of(context).bg,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _filtersCard(),
            ),
            if (_totalItems > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$_totalItems souscription${_totalItems > 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 12, color: LeadwayBrand.of(context).muted, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            Expanded(child: _body()),
          ],
        ),
      ),
    ),
    );
  }

  Widget _header() {
    final brand = LeadwayBrand.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
      child: Row(
        children: [
          IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.chevron_left)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mes souscriptions Vie',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: brand.text),
                ),
                Text(
                  'Leadway Assurance',
                  style: TextStyle(fontSize: 11, color: brand.muted, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _loading || _bootstrapping ? null : _reload,
            icon: const Icon(Icons.refresh, color: LeadwayBrand.primary),
          ),
        ],
      ),
    );
  }

  Widget _filtersCard() {
    final brand = LeadwayBrand.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: brand.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: brand.border),
      ),
      child: DropdownButtonFormField<LeadwayLifeSubscriptionStatus?>(
        // ignore: deprecated_member_use
        value: _statusFilter,
        decoration: InputDecoration(
          labelText: 'Statut',
          filled: true,
          fillColor: brand.card,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        items: [
          const DropdownMenuItem(value: null, child: Text('Tous')),
          ...LeadwayLifeSubscriptionStatus.values.map(
            (s) => DropdownMenuItem(value: s, child: Text(s.label)),
          ),
        ],
        onChanged: _loading || _bootstrapping
            ? null
            : (v) {
                setState(() => _statusFilter = v);
                _reload();
              },
      ),
    );
  }

  Widget _body() {
    if (_bootstrapping || (_loading && _items.isEmpty)) {
      return const Center(child: CircularProgressIndicator(color: LeadwayBrand.primary));
    }
    if (_error != null && _items.isEmpty) {
      return _emptyHint(_error!);
    }
    if (_items.isEmpty) {
      return _emptyHint('Aucune souscription trouvée.');
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _items.length + (_loadingMore || _page + 1 < _totalPages ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: CircularProgressIndicator(color: LeadwayBrand.primary, strokeWidth: 2.5),
            ),
          );
        }
        return _subscriptionCard(_items[index]);
      },
    );
  }

  Widget _emptyHint(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(text, textAlign: TextAlign.center, style: TextStyle(color: LeadwayBrand.of(context).muted, height: 1.4)),
      ),
    );
  }

  Widget _subscriptionCard(LeadwayLifeSubscriptionItem item) {
    final brand = LeadwayBrand.of(context);
    final premium = item.premium.gross;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: brand.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => LeadwayLifeSubscriptionDetailScreen(
                  subscriptionRef: item.subscriptionRef,
                  preview: item,
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: brand.border),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Container(
                    width: 5,
                    decoration: const BoxDecoration(
                      color: LeadwayBrand.primary,
                      borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.productCode,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: brand.text,
                                  ),
                                ),
                              ),
                              _statusChip(item.status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Réf. ${item.subscriptionRef}',
                            style: TextStyle(fontSize: 12, color: brand.muted),
                          ),
                          if (item.policyNumber.isNotEmpty)
                            Text(
                              'Police ${item.policyNumber}',
                              style: TextStyle(fontSize: 12, color: brand.muted),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            '${premium.amountRounded} ${premium.currency}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: LeadwayBrand.primary,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(Icons.chevron_right, color: LeadwayBrand.of(context).muted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    final known = LeadwayLifeSubscriptionStatus.fromCode(status);
    final label = known?.label ?? status;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF2E7D32)),
      ),
    );
  }
}
