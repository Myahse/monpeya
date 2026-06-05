import 'package:flutter/material.dart';

import '../models/fund_source_item.dart';
import '../widgets/peyapay_card_link_success_dialog.dart';
import '../widgets/peyapay_debit_card_preview.dart';
import 'peyapay_add_money_screen.dart';

/// Flutter port of RN `Deposit.tsx` — "Select your source of funds".
///
/// Opened from dashboard quick action **Banques et assurances** (`handleDepositPress`)
/// or from Payments & services → **Assurance** (embedded overlay).
class PeyapaySourceOfFundsScreen extends StatefulWidget {
  const PeyapaySourceOfFundsScreen({
    super.key,
    this.onClose,
    this.onDepositComplete,
    this.embeddedInPaymentServices = false,
  });

  final VoidCallback? onClose;
  final VoidCallback? onDepositComplete;
  final bool embeddedInPaymentServices;

  @override
  State<PeyapaySourceOfFundsScreen> createState() => _PeyapaySourceOfFundsScreenState();
}

class _PeyapaySourceOfFundsScreenState extends State<PeyapaySourceOfFundsScreen> {
  static const _green = Color(0xFF006D56);

  bool _searchActive = false;
  String _searchQuery = '';
  bool _showTransferSheet = false;
  bool _showBankSheet = false;
  bool _showCardSheet = false;
  bool _showSuccess = false;
  String _linkedCardType = 'VISA';
  String _linkedCardLastFour = '4387';
  String _linkedBankName = 'Société générale';

  late List<FundSourceItem> _banks;
  late List<FundSourceItem> _cards;

  @override
  void initState() {
    super.initState();
    _banks = List<FundSourceItem>.from(peyapayBanks);
    _cards = List<FundSourceItem>.from(peyapayDebitCards);
  }

  String get _title => widget.embeddedInPaymentServices ? 'Assurance' : 'Select your source of funds';

  String get _subtitle => widget.embeddedInPaymentServices
      ? 'Liez un compte ou une carte pour payer vos primes'
      : 'Pick a method to add money to your PeyaPay account';

  List<FundSourceItem> get _filteredBanks {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _banks;
    return _banks.where((b) => b.name.toLowerCase().contains(q)).toList();
  }

  List<FundSourceItem> get _filteredCards {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _cards;
    return _cards.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  void _markBankAdded(int id) {
    setState(() {
      _banks = _banks.map((b) => b.id == id ? b.copyWith(isAdded: true) : b).toList();
    });
  }

  void _markCardAdded(int id) {
    setState(() {
      _cards = _cards.map((c) => c.id == id ? c.copyWith(isAdded: true) : c).toList();
    });
  }

  void _back() {
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _toggleSearch() {
    setState(() {
      if (_searchActive) {
        _searchActive = false;
        _searchQuery = '';
      } else {
        _searchActive = true;
      }
    });
  }

  Future<void> _openTransferMethod() async {
    setState(() => _showTransferSheet = true);
  }

  Future<void> _closeTransferMethod() async {
    if (!mounted) return;
    setState(() => _showTransferSheet = false);
  }

  Future<void> _selectDebitCard() async {
    await _closeTransferMethod();
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;
    setState(() => _showCardSheet = true);
  }

  Future<void> _selectBankAccount() async {
    await _closeTransferMethod();
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;
    setState(() => _showBankSheet = true);
  }

  void _onCardAdded(String cardType, String lastFour) {
    final cardId = cardType == 'MASTERCARD' ? 3 : 1;
    _markCardAdded(cardId);
    setState(() {
      _showCardSheet = false;
      _linkedCardType = cardType;
      _linkedCardLastFour = lastFour;
      _linkedBankName = cardType == 'VISA' ? 'Société générale' : 'Banque';
      _showSuccess = true;
    });
  }

  Future<void> _openAddMoneyFlow() async {
    if (!mounted) return;
    final ok = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute<bool>(
        fullscreenDialog: true,
        builder: (_) => PeyapayAddMoneyScreen(
          cardType: _linkedCardType,
          bankName: _linkedBankName,
          cardLastFour: _linkedCardLastFour,
          onDepositComplete: widget.onDepositComplete,
        ),
      ),
    );
    if (!mounted) return;
    if (ok == true) {
      widget.onDepositComplete?.call();
      _back();
    }
  }

  void _onBankSelected(FundSourceItem bank) {
    _markBankAdded(bank.id);
    setState(() => _showBankSheet = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${bank.name} sera connecté sous 4–5 jours ouvrés.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final titleSize = w < 375 ? 18.0 : w < 414 ? 20.0 : 22.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 12, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _back,
                        icon: const Icon(Icons.chevron_left, size: 24, color: Colors.black),
                      ),
                      Expanded(
                        child: Text(
                          _title,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: titleSize * 0.85, fontWeight: FontWeight.w900, color: Colors.black),
                        ),
                      ),
                      IconButton(
                        onPressed: _toggleSearch,
                        icon: Icon(_searchActive ? Icons.close : Icons.search, size: 20, color: const Color(0xFF666666)),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Text(
                    _subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF666666)),
                  ),
                ),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    children: [
                      _Section(
                        title: 'Bank accounts',
                        items: _banks.where((b) => b.isAdded).toList(),
                        onAdd: _openTransferMethod,
                      ),
                      const SizedBox(height: 20),
                      _Section(
                        title: 'Debit card',
                        items: _cards.where((c) => c.isAdded).toList(),
                        onAdd: _selectDebitCard,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: Material(
                color: _green,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: _openTransferMethod,
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Center(
                      child: Text(
                        '+ Ajouter',
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_searchActive)
              _SearchOverlay(
                query: _searchQuery,
                banks: _filteredBanks,
                cards: _filteredCards,
                onQueryChanged: (v) => setState(() => _searchQuery = v),
                onClose: _toggleSearch,
                onAddBank: (b) {
                  if (!b.isAdded) _markBankAdded(b.id);
                  _toggleSearch();
                },
                onAddCard: (c) {
                  if (!c.isAdded) {
                    _markCardAdded(c.id);
                    _selectDebitCard();
                  } else {
                    _toggleSearch();
                  }
                },
              ),
            if (_showTransferSheet)
              _TransferMethodSheet(
                onClose: _closeTransferMethod,
                onBank: _selectBankAccount,
                onDebitCard: _selectDebitCard,
              ),
            if (_showBankSheet)
              _BankPickerSheet(
                banks: _banks,
                onClose: () => setState(() => _showBankSheet = false),
                onSelect: _onBankSelected,
              ),
            if (_showCardSheet)
              _CreditCardSheet(
                onClose: () => setState(() => _showCardSheet = false),
                onAdded: _onCardAdded,
              ),
            if (_showSuccess)
              PeyapayCardLinkSuccessDialog(
                cardType: _linkedCardType,
                onAddMoney: _openAddMoneyFlow,
                onBackHome: () {
                  if (!mounted) return;
                  setState(() => _showSuccess = false);
                  _back();
                },
                onRetry: () {
                  if (!mounted) return;
                  setState(() {
                    _showSuccess = false;
                    _showCardSheet = true;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.items, required this.onAdd});

  final String title;
  final List<FundSourceItem> items;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.black)),
            InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  children: [
                    Text('Add', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.grey.shade600)),
                    Icon(Icons.add, size: 20, color: Colors.grey.shade600),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map((item) => _FundRow(item: item)),
      ],
    );
  }
}

class _FundRow extends StatelessWidget {
  const _FundRow({required this.item});

  final FundSourceItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          _Logo(item: item),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.item});

  final FundSourceItem item;

  @override
  Widget build(BuildContext context) {
    final path = item.logoAsset;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: path != null
          ? Image.asset(
              path,
              width: 44,
              height: 44,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _placeholder(item.name),
            )
          : _placeholder(item.name),
    );
  }

  Widget _placeholder(String name) {
    return Container(
      width: 44,
      height: 44,
      color: const Color(0xFFF3F4F6),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0] : '?',
        style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF111827)),
      ),
    );
  }
}

class _SearchOverlay extends StatelessWidget {
  const _SearchOverlay({
    required this.query,
    required this.banks,
    required this.cards,
    required this.onQueryChanged,
    required this.onClose,
    required this.onAddBank,
    required this.onAddCard,
  });

  final String query;
  final List<FundSourceItem> banks;
  final List<FundSourceItem> cards;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClose;
  final ValueChanged<FundSourceItem> onAddBank;
  final ValueChanged<FundSourceItem> onAddCard;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.5),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        autofocus: true,
                        onChanged: onQueryChanged,
                        decoration: InputDecoration(
                          hintText: 'Search banks and cards...',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ),
                    IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
                  ],
                ),
              ),
              if (query.isNotEmpty)
                Expanded(
                  child: Material(
                    color: Colors.white,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (banks.isNotEmpty) ...[
                          const Text('Bank accounts', style: TextStyle(fontWeight: FontWeight.w900)),
                          ...banks.map((b) => _SearchResultRow(item: b, onAdd: () => onAddBank(b))),
                        ],
                        if (cards.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Text('Debit cards', style: TextStyle(fontWeight: FontWeight.w900)),
                          ...cards.map((c) => _SearchResultRow(item: c, onAdd: () => onAddCard(c))),
                        ],
                        if (banks.isEmpty && cards.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: Text('No results found')),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchResultRow extends StatelessWidget {
  const _SearchResultRow({required this.item, required this.onAdd});

  final FundSourceItem item;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _Logo(item: item),
      title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: item.isAdded
          ? const Icon(Icons.check_circle, color: Color(0xFF006D56), size: 22)
          : IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Color(0xFF006D56)),
              onPressed: onAdd,
            ),
      onTap: item.isAdded ? null : onAdd,
    );
  }
}

class _TransferMethodSheet extends StatelessWidget {
  const _TransferMethodSheet({
    required this.onClose,
    required this.onBank,
    required this.onDebitCard,
  });

  final VoidCallback onClose;
  final VoidCallback onBank;
  final VoidCallback onDebitCard;

  @override
  Widget build(BuildContext context) {
    return _BottomSheetScaffold(
      onDismiss: onClose,
      heightFactor: 0.38,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SheetHandle(),
          const Text('Select transfer method', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text(
            'Select your preferred transfer method to add your money to your PeyaPay account',
            style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
          ),
          const SizedBox(height: 16),
          _MethodTile(
            icon: Icons.business_outlined,
            title: 'Connect bank account',
            subtitle: '4-5 business days',
            onTap: onBank,
          ),
          _MethodTile(
            icon: Icons.credit_card_outlined,
            title: 'Debit card',
            subtitle: '0.5% Fees',
            onTap: onDebitCard,
          ),
        ],
      ),
    );
  }
}

class _BankPickerSheet extends StatelessWidget {
  const _BankPickerSheet({
    required this.banks,
    required this.onClose,
    required this.onSelect,
  });

  final List<FundSourceItem> banks;
  final VoidCallback onClose;
  final ValueChanged<FundSourceItem> onSelect;

  @override
  Widget build(BuildContext context) {
    return _BottomSheetScaffold(
      onDismiss: onClose,
      heightFactor: 0.72,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SheetHandle(),
          const Text('Select a bank', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text('Choose a bank to connect your account', style: TextStyle(fontSize: 12, color: Color(0xFF666666))),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: banks.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final bank = banks[i];
                return ListTile(
                  leading: _Logo(item: bank),
                  title: Text(bank.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                  trailing: bank.isAdded
                      ? const Icon(Icons.check_circle, color: Color(0xFF006D56), size: 22)
                      : const Icon(Icons.add_circle_outline, color: Color(0xFF006D56)),
                  onTap: () => onSelect(bank),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CreditCardSheet extends StatefulWidget {
  const _CreditCardSheet({required this.onClose, required this.onAdded});

  final VoidCallback onClose;
  final void Function(String cardType, String lastFour) onAdded;

  @override
  State<_CreditCardSheet> createState() => _CreditCardSheetState();
}

class _CreditCardSheetState extends State<_CreditCardSheet> {
  final _numberCtrl = TextEditingController();
  final _holderCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  bool _showCardDetails = true;

  @override
  void initState() {
    super.initState();
    for (final c in [_numberCtrl, _holderCtrl, _expiryCtrl, _cvvCtrl]) {
      c.addListener(_onFieldChanged);
    }
  }

  void _onFieldChanged() => setState(() {});

  @override
  void dispose() {
    for (final c in [_numberCtrl, _holderCtrl, _expiryCtrl, _cvvCtrl]) {
      c.removeListener(_onFieldChanged);
    }
    _numberCtrl.dispose();
    _holderCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    super.dispose();
  }

  static String _digits(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

  static String _formatCardNumber(String input) {
    final d = _digits(input);
    final buf = StringBuffer();
    for (var i = 0; i < d.length && i < 16; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(d[i]);
    }
    return buf.toString();
  }

  static String _formatExpiry(String input) {
    final d = _digits(input);
    if (d.length >= 2) {
      return '${d.substring(0, 2)}${d.length > 2 ? '/${d.substring(2, d.length > 4 ? 4 : d.length)}' : ''}';
    }
    return d;
  }

  static String _cardType(String number) {
    final d = _digits(number);
    if (d.startsWith('4')) return 'VISA';
    if (d.startsWith('5')) return 'MASTERCARD';
    return 'CARD';
  }

  void _submit() {
    final digits = _digits(_numberCtrl.text);
    final lastFour = digits.length >= 4 ? digits.substring(digits.length - 4) : '****';
    widget.onAdded(_cardType(_numberCtrl.text), lastFour);
  }

  @override
  Widget build(BuildContext context) {
    const border = OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFE0E0E0)));
    const fieldStyle = TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF111827));

    return _BottomSheetScaffold(
      onDismiss: widget.onClose,
      heightFactor: 0.92,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SheetHandle(),
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 0, 8, 4),
            child: Text(
              'Add debit card',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              'Enter your card details to link it to your account',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
            ),
          ),
          Expanded(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
              children: [
                PeyapayDebitCardPreview(
                  cardNumber: _numberCtrl.text,
                  cardHolder: _holderCtrl.text,
                  expiryDate: _expiryCtrl.text,
                  cvv: _cvvCtrl.text,
                  showDetails: _showCardDetails,
                ),
                const Divider(height: 28, thickness: 1, color: Color(0xFFEEEEEE)),
                _Field(
                  label: 'Card Number',
                  child: TextField(
                    controller: _numberCtrl,
                    keyboardType: TextInputType.number,
                    style: fieldStyle,
                    decoration: const InputDecoration(
                      hintText: 'XXXX XXXX XXXX XXXX',
                      hintStyle: TextStyle(color: Color(0xFFAAAAAA)),
                      border: border,
                      enabledBorder: border,
                      focusedBorder: border,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: (v) {
                      final next = _formatCardNumber(v);
                      if (next != _numberCtrl.text) {
                        _numberCtrl.value = TextEditingValue(
                          text: next,
                          selection: TextSelection.collapsed(offset: next.length),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                _Field(
                  label: 'Card Holder Name',
                  child: TextField(
                    controller: _holderCtrl,
                    style: fieldStyle,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      hintText: 'Enter name on card',
                      hintStyle: TextStyle(color: Color(0xFFAAAAAA)),
                      border: border,
                      enabledBorder: border,
                      focusedBorder: border,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _Field(
                        label: 'Expiry Date',
                        child: TextField(
                          controller: _expiryCtrl,
                          keyboardType: TextInputType.number,
                          style: fieldStyle,
                          decoration: const InputDecoration(
                            hintText: 'MM/YY',
                            hintStyle: TextStyle(color: Color(0xFFAAAAAA)),
                            border: border,
                            enabledBorder: border,
                            focusedBorder: border,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          onChanged: (v) {
                            final next = _formatExpiry(v);
                            if (next != _expiryCtrl.text) {
                              _expiryCtrl.value = TextEditingValue(
                                text: next,
                                selection: TextSelection.collapsed(offset: next.length),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Field(
                        label: 'CVV',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: _cvvCtrl,
                              keyboardType: TextInputType.number,
                              obscureText: !_showCardDetails,
                              maxLength: 3,
                              style: fieldStyle,
                              decoration: InputDecoration(
                                hintText: 'XXX',
                                hintStyle: const TextStyle(color: Color(0xFFAAAAAA)),
                                border: border,
                                enabledBorder: border,
                                focusedBorder: border,
                                counterText: '',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _showCardDetails ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    size: 18,
                                    color: const Color(0xFF555555),
                                  ),
                                  onPressed: () => setState(() => _showCardDetails = !_showCardDetails),
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(top: 4, left: 2),
                              child: Text(
                                'Last 3 digits on back of card',
                                style: TextStyle(fontSize: 11, color: Color(0xFF888888)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF006D56),
                    foregroundColor: Colors.white,
                     padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Add Card',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: Color(0xFFF5F5F5), shape: BoxShape.circle),
              child: Icon(icon, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF666666)),
          ],
        ),
      ),
    );
  }
}

class _BottomSheetScaffold extends StatelessWidget {
  const _BottomSheetScaffold({
    required this.onDismiss,
    required this.heightFactor,
    required this.child,
  });

  final VoidCallback onDismiss;
  final double heightFactor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height * heightFactor;
    return Positioned.fill(
      child: GestureDetector(
        onTap: onDismiss,
        behavior: HitTestBehavior.opaque,
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.5),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () {},
              child: Container(
                height: h,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: const Color(0xFFE0E0E0), borderRadius: BorderRadius.circular(2)),
      ),
    );
  }
}
