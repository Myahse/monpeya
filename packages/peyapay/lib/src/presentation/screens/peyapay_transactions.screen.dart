import 'package:flutter/material.dart';

import 'package:peyapay/src/core/host/peyapay_host.bridge.dart';
import 'package:peyapay/src/core/utils/formatters.util.dart';
import 'package:peyapay/src/core/utils/screen_insets.util.dart';
import 'package:peyapay/src/core/utils/peyapay_transaction_share.util.dart';
import 'package:peyapay/src/data/models/transaction.item.dart';
import 'package:peyapay/src/presentation/screens/peyapay_transaction_detail.screen.dart';
import 'package:peyapay/src/presentation/widgets/peyapay_nav_bar_icon.widget.dart';
import 'package:peyapay/src/presentation/widgets/peyapay_transaction_list_tile.widget.dart';

const _monthLabels = [
  'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
  'Juil', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc',
];

class PeyapayTransactionsScreen extends StatefulWidget {
  const PeyapayTransactionsScreen({super.key, this.initialItems = const []});

  final List<TransactionItem> initialItems;

  @override
  State<PeyapayTransactionsScreen> createState() => _PeyapayTransactionsScreenState();
}

class _PeyapayTransactionsScreenState extends State<PeyapayTransactionsScreen> {
  late int _selectedYear;
  int? _selectedMonth;
  List<TransactionItem> _items = const [];
  bool _loading = false;
  String? _error;

  List<int> get _yearOptions {
    final current = DateTime.now().year;
    return List.generate(6, (i) => current - i);
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
    _items = widget.initialItems;
    _loadTransactions();
  }

  ({DateTime start, DateTime end}) _filterRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_selectedMonth == null) {
      final start = DateTime(_selectedYear, 1, 1);
      final yearEnd = DateTime(_selectedYear, 12, 31);
      final end = _selectedYear == now.year && yearEnd.isAfter(today) ? today : yearEnd;
      return (start: start, end: end);
    }

    final month = _selectedMonth!;
    final start = DateTime(_selectedYear, month, 1);
    final monthEnd = DateTime(_selectedYear, month + 1, 0);
    final end = _selectedYear == now.year && month == now.month && monthEnd.isAfter(today)
        ? today
        : monthEnd;
    return (start: start, end: end);
  }

  String get _filterLabel {
    if (_selectedMonth == null) return 'Année $_selectedYear';
    return '${_monthLabels[_selectedMonth! - 1]} $_selectedYear';
  }

  Future<void> _loadTransactions() async {
    final api = PeyapayHostBridge.api;
    if (api == null) {
      setState(() => _error = 'API PeyaPay non initialisée');
      return;
    }

    final phone = await PeyapayHostBridge.requireAuth.getPhone();
    final accountNumber = api.resolveWalletAccountNumber(phone: phone);
    if (accountNumber == null) {
      setState(() => _error = 'Compte PeyaPay indisponible');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await api.hydrateBearerFrom(
        PeyapayHostBridge.requireAuth.authToken,
        preferAppToken: true,
      );

      final range = _filterRange();
      final page = await api.fetchAccountMovements(
        accountNumber: accountNumber,
        index: 0,
        size: 100,
        startDate: range.start,
        endDate: range.end,
        ensureToken: false,
      );

      if (!mounted) return;
      setState(() {
        _items = page.movements.map((m) => m.toTransactionItem()).toList(growable: false);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _selectYear(int year) {
    if (_selectedYear == year || _loading) return;
    setState(() => _selectedYear = year);
    _loadTransactions();
  }

  void _selectMonth(int? month) {
    if (_selectedMonth == month || _loading) return;
    setState(() => _selectedMonth = month);
    _loadTransactions();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? cs.surface : const Color(0xFFFFFFFF);
    final ink = isDark ? cs.onSurface : const Color(0xFF111827);
    final muted = isDark ? cs.onSurfaceVariant : const Color(0xFF6B7280);
    final border = isDark ? cs.outlineVariant : const Color(0xFFE5E7EB);
    final iconBgGrey = isDark ? cs.surfaceContainerHighest : const Color(0xFFF3F4F6);

    final sections = _groupByDate(_items);

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, peyapayStatusBarTop(context) + 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 44,
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: Icon(Icons.chevron_left_rounded, color: ink, size: 28),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const PeyaPayNavBarIcon(size: 24, width: 68),
                            const SizedBox(width: 8),
                            Text(
                              'Transactions',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: ink),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 44),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Année',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: muted),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      for (final year in _yearOptions) ...[
                        _FilterChip(
                          label: '$year',
                          selected: _selectedYear == year,
                          muted: muted,
                          border: border,
                          onTap: () => _selectYear(year),
                        ),
                        if (year != _yearOptions.last) const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Mois',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: muted),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'Tous',
                        selected: _selectedMonth == null,
                        muted: muted,
                        border: border,
                        onTap: () => _selectMonth(null),
                      ),
                      const SizedBox(width: 8),
                      for (var month = 1; month <= 12; month++) ...[
                        _FilterChip(
                          label: _monthLabels[month - 1],
                          selected: _selectedMonth == month,
                          muted: muted,
                          border: border,
                          onTap: () => _selectMonth(month),
                        ),
                        if (month != 12) const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _filterLabel,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ink),
                      ),
                    ),
                    if (!_loading && _error == null)
                      IconButton(
                        onPressed: _items.isEmpty
                            ? null
                            : () => sharePeyapayTransactionsStatementPdf(
                                  context,
                                  items: _items,
                                  periodLabel: _filterLabel,
                                ),
                        icon: Icon(Icons.ios_share_rounded, color: ink, size: 22),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        tooltip: 'Partager le relevé PDF',
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: muted),
              ),
            )
          else ...[
            if (_items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: _TransactionsSummary(items: _items, ink: ink, muted: muted, border: border, surface: bg),
              ),
            Expanded(
              child: _items.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Aucune transaction pour $_filterLabel',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: muted),
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: sections.length,
                      itemBuilder: (context, index) {
                        final section = sections[index];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(bottom: 10, top: index == 0 ? 0 : 8),
                              child: Text(
                                section.label,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: muted),
                              ),
                            ),
                            for (final item in section.items) ...[
                              PeyapayTransactionListTile(
                                item: item,
                                ink: ink,
                                muted: muted,
                                border: border,
                                iconBg: iconBgGrey,
                                surface: bg,
                                onTap: () => openPeyapayTransactionDetail(context, item),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ],
                        );
                      },
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.muted,
    required this.border,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color muted;
  final Color border;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF006D56) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? const Color(0xFF006D56) : border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : muted,
          ),
        ),
      ),
    );
  }
}

class _TransactionsSummary extends StatelessWidget {
  const _TransactionsSummary({
    required this.items,
    required this.ink,
    required this.muted,
    required this.border,
    required this.surface,
  });

  final List<TransactionItem> items;
  final Color ink;
  final Color muted;
  final Color border;
  final Color surface;

  @override
  Widget build(BuildContext context) {
    final credits = items.where((t) => t.isCredit).fold<int>(0, (sum, t) => sum + t.amount);
    final debits = items.where((t) => !t.isCredit).fold<int>(0, (sum, t) => sum + t.amount.abs());

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _summaryCell('Entrées', '+${formatFrMoneySigned(credits)}', const Color(0xFF006D56), muted),
          ),
          Container(width: 1, height: 36, color: border),
          Expanded(
            child: _summaryCell('Sorties', '-${formatFrMoneySigned(debits)}', ink, muted),
          ),
        ],
      ),
    );
  }

  Widget _summaryCell(String label, String value, Color valueColor, Color mutedColor) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: mutedColor)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: valueColor)),
      ],
    );
  }
}

class _TransactionSection {
  const _TransactionSection({required this.label, required this.items});

  final String label;
  final List<TransactionItem> items;
}

List<_TransactionSection> _groupByDate(List<TransactionItem> items) {
  final sorted = [...items]..sort((a, b) => b.dateIso.compareTo(a.dateIso));
  final map = <String, List<TransactionItem>>{};

  for (final item in sorted) {
    final label = formatFrDateSectionLabel(item.dateIso);
    map.putIfAbsent(label, () => []).add(item);
  }

  return [
    for (final entry in map.entries) _TransactionSection(label: entry.key, items: entry.value),
  ];
}
