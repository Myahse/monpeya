import 'package:flutter/material.dart';

import 'package:leadway/src/core/constants/leadway_life.constants.dart';
import 'package:leadway/src/core/host/leadway_host.bridge.dart';
import 'package:leadway/src/data/models/leadway_api.exception.dart';
import 'package:leadway/src/data/models/leadway_life_list.model.dart';
import 'package:leadway/src/data/services/leadway_life_api.service.dart';
import 'package:leadway/src/presentation/constants/leadway.brand.dart';
import 'package:leadway/src/presentation/widgets/leadway_toast.widget.dart';

/// Liste paginée des paiements récurrents Vie (scroll infini).
/// `customerId` vient des métadonnées app (généré / réutilisé automatiquement).
class LeadwayLifeRecurringPaymentsScreen extends StatefulWidget {
  const LeadwayLifeRecurringPaymentsScreen({super.key});

  @override
  State<LeadwayLifeRecurringPaymentsScreen> createState() => _LeadwayLifeRecurringPaymentsScreenState();
}

class _LeadwayLifeRecurringPaymentsScreenState extends State<LeadwayLifeRecurringPaymentsScreen> {
  final _api = LeadwayLifeApiService();
  final _policyCtrl = TextEditingController();
  final _productCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  static const _pageSize = 10;

  String _customerId = '';
  LeadwayLifeRecurringPaymentStatus? _statusFilter;
  DateTime? _createdFrom;
  DateTime? _createdTo;
  bool _showAdvanced = false;

  final List<LeadwayLifeRecurringPaymentItem> _items = [];
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
    await _reload();
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _policyCtrl.dispose();
    _productCtrl.dispose();
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

  String? _fmtDate(DateTime? d) {
    if (d == null) return null;
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  Future<void> _pickDate({required bool from}) async {
    final initial = from ? (_createdFrom ?? DateTime.now()) : (_createdTo ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (from) {
        _createdFrom = picked;
      } else {
        _createdTo = picked;
      }
    });
  }

  Future<void> _reload() async {
    if (_customerId.isEmpty) {
      final customerId = await LeadwayHostBridge.getMeta(LeadwayMetaKeys.customerId) ?? '';
      if (!mounted) return;
      setState(() => _customerId = customerId);
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
      final result = await _api.listRecurringPayments(
        customerId: _customerId.isEmpty ? null : _customerId,
        policyNumber: _policyCtrl.text.trim().isEmpty ? null : _policyCtrl.text.trim(),
        productCode: _productCtrl.text.trim().isEmpty ? null : _productCtrl.text.trim(),
        status: _statusFilter?.code,
        createdFrom: _fmtDate(_createdFrom),
        createdTo: _fmtDate(_createdTo),
        page: page,
        size: _pageSize,
      );
      if (!mounted) return;
      final p = result.page;
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
                    '$_totalItems paiement${_totalItems > 1 ? 's' : ''} récurrent${_totalItems > 1 ? 's' : ''}',
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
                  'Paiements récurrents',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: brand.text),
                ),
                Text(
                  'Leadway Assurance Vie',
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
      child: Column(
        children: [
          DropdownButtonFormField<LeadwayLifeRecurringPaymentStatus?>(
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
              ...LeadwayLifeRecurringPaymentStatus.values.map(
                (s) => DropdownMenuItem(value: s, child: Text(s.label)),
              ),
            ],
            onChanged: (v) => setState(() => _statusFilter = v),
          ),
          TextButton(
            onPressed: () => setState(() => _showAdvanced = !_showAdvanced),
            child: Text(_showAdvanced ? 'Masquer les filtres' : 'Plus de filtres'),
          ),
          if (_showAdvanced) ...[
            TextField(
              controller: _policyCtrl,
              decoration: InputDecoration(
                labelText: 'N° de police',
                filled: true,
                fillColor: brand.card,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _productCtrl,
              decoration: InputDecoration(
                labelText: 'Code produit',
                filled: true,
                fillColor: brand.card,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(from: true),
                    child: Text(_createdFrom == null ? 'Du' : 'Du ${_fmtDate(_createdFrom)}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(from: false),
                    child: Text(_createdTo == null ? 'Au' : 'Au ${_fmtDate(_createdTo)}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _loading || _bootstrapping ? null : _reload,
              style: ElevatedButton.styleFrom(
                backgroundColor: LeadwayBrand.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Rechercher', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
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
      return _emptyHint('Aucun paiement récurrent trouvé.');
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
        return _paymentCard(_items[index]);
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

  Widget _paymentCard(LeadwayLifeRecurringPaymentItem item) {
    final brand = LeadwayBrand.of(context);
    final statusLabel = LeadwayLifeRecurringPaymentStatus.fromCode(item.status)?.label ?? item.status;
    final freq = LeadwayLifePaymentFrequency.fromCode(item.frequency)?.label ?? item.frequency;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: brand.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: brand.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.productCode,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: brand.text),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF1565C0)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Police ${item.policyNumber}', style: TextStyle(fontSize: 12, color: brand.muted)),
          Text('${item.paymentMethod} · $freq', style: TextStyle(fontSize: 12, color: brand.muted)),
          const SizedBox(height: 8),
          Text(
            '${item.amount.round()} ${item.currency}',
            style: const TextStyle(fontWeight: FontWeight.w900, color: LeadwayBrand.primary, fontSize: 15),
          ),
          if (item.nextPaymentDate != null && item.nextPaymentDate!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Prochain : ${item.nextPaymentDate}', style: TextStyle(fontSize: 11, color: brand.muted)),
          ],
          if (item.lastPaymentDate != null && item.lastPaymentDate!.isNotEmpty)
            Text('Dernier : ${item.lastPaymentDate}', style: TextStyle(fontSize: 11, color: brand.muted)),
        ],
      ),
    );
  }
}
