import 'package:flutter/material.dart';

import 'package:peyapay/src/core/constants/peya_pay.assets.dart';

import 'package:peyapay/src/data/models/fund_source.item.dart';
import 'package:peyapay/src/core/utils/screen_insets.util.dart';
import 'package:peyapay/src/presentation/widgets/peyapay_card_link_success_dialog.widget.dart';
import 'package:peyapay/src/presentation/widgets/peyapay_debit_card_preview.widget.dart';
import 'package:peyapay/src/presentation/widgets/peyapay_draggable_bottom_sheet.widget.dart';
import 'package:peyapay/src/presentation/screens/peyapay_add_money.screen.dart';



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

  String get _title => widget.embeddedInPaymentServices ? 'Assurance' : 'Source de fonds';

  String get _subtitle => widget.embeddedInPaymentServices
      ? 'Liez un compte ou une carte pour payer vos primes'
      : 'Choisissez un moyen pour alimenter votre compte PeyaPay';

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
      _linkedCardType = cardType;
      _linkedCardLastFour = lastFour;
      _linkedBankName = cardType == 'VISA' ? 'Société générale' : 'Banque';
      _showSuccess = true;
    });
  }

  Future<void> _openAddMoneyFlow() async {
    if (!mounted) return;
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
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
    final cs = Theme.of(context).colorScheme;
    final ink = cs.onSurface;
    final muted = cs.onSurfaceVariant;
    final topPad = peyapayStatusBarTop(context);
    final w = MediaQuery.sizeOf(context).width;
    final titleSize = w < 375 ? 18.0 : w < 414 ? 20.0 : 22.0;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(8, topPad + 8, 12, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _back,
                      icon: Icon(Icons.chevron_left, size: 24, color: ink),
                    ),
                    Expanded(
                      child: Text(
                        _title,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: titleSize * 0.85, fontWeight: FontWeight.w900, color: ink),
                      ),
                    ),
                    IconButton(
                      onPressed: _toggleSearch,
                      icon: Icon(_searchActive ? Icons.close : Icons.search, size: 20, color: muted),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  _subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: muted),
                ),
              ),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  children: [
                    _Section(
                      title: 'Comptes bancaires',
                      items: _banks.where((b) => b.isAdded).toList(),
                      onAdd: _openTransferMethod,
                      ink: ink,
                      muted: muted,
                    ),
                    const SizedBox(height: 20),
                    _Section(
                      title: 'Carte bancaire',
                      items: _cards.where((c) => c.isAdded).toList(),
                      onAdd: _selectDebitCard,
                      ink: ink,
                      muted: muted,
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
                onDismiss: () => setState(() => _showSuccess = false),
                onAddMoney: _openAddMoneyFlow,
                onBackHome: _back,
                onRetry: () => setState(() => _showCardSheet = true),
              ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.items,
    required this.onAdd,
    required this.ink,
    required this.muted,
  });

  final String title;
  final List<FundSourceItem> items;
  final VoidCallback onAdd;
  final Color ink;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: ink)),
            InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  children: [
                    Text('Ajouter', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: muted)),
                    Icon(Icons.add, size: 20, color: muted),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map((item) => _FundRow(item: item, ink: ink)),
      ],
    );
  }
}

class _FundRow extends StatelessWidget {
  const _FundRow({required this.item, required this.ink});

  final FundSourceItem item;
  final Color ink;

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
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: ink),
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
      package: PeyaPayAssets.package,
              width: 44,
              height: 44,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => _placeholder(context, item.name),
            )
          : _placeholder(context, item.name),
    );
  }

  Widget _placeholder(BuildContext context, String name) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 44,
      height: 44,
      color: cs.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0] : '?',
        style: TextStyle(fontWeight: FontWeight.w900, color: cs.onSurface),
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
    final cs = Theme.of(context).colorScheme;
    final ink = cs.onSurface;

    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.5),
        child: Column(
          children: [
            SizedBox(height: peyapayStatusBarTop(context) + 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        autofocus: true,
                        onChanged: onQueryChanged,
                        style: TextStyle(color: ink),
                        decoration: InputDecoration(
                          hintText: 'Rechercher banques et cartes...',
                          filled: true,
                          fillColor: cs.surface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ),
                    IconButton(onPressed: onClose, icon: Icon(Icons.close, color: ink)),
                  ],
                ),
              ),
              if (query.isNotEmpty)
                Expanded(
                  child: Material(
                    color: cs.surface,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (banks.isNotEmpty) ...[
                          Text('Comptes bancaires', style: TextStyle(fontWeight: FontWeight.w900, color: ink)),
                          ...banks.map((b) => _SearchResultRow(item: b, onAdd: () => onAddBank(b))),
                        ],
                        if (cards.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text('Cartes bancaires', style: TextStyle(fontWeight: FontWeight.w900, color: ink)),
                          ...cards.map((c) => _SearchResultRow(item: c, onAdd: () => onAddCard(c))),
                        ],
                        if (banks.isEmpty && cards.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(child: Text('Aucun résultat', style: TextStyle(color: cs.onSurfaceVariant))),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
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
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: _Logo(item: item),
      title: Text(item.name, style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurface)),
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
    final cs = Theme.of(context).colorScheme;
    final ink = cs.onSurface;
    final muted = cs.onSurfaceVariant;

    return PeyapayDraggableBottomSheet(
      onDismiss: onClose,
      heightFactor: 0.36,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Mode de transfert', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: ink)),
          const SizedBox(height: 4),
          Text(
            'Choisissez votre mode de transfert pour alimenter votre compte PeyaPay',
            style: TextStyle(fontSize: 12, color: muted),
          ),
          const SizedBox(height: 12),
          _MethodTile(
            icon: Icons.business_outlined,
            title: 'Compte bancaire',
            subtitle: '4-5 jours ouvrés',
            onTap: onBank,
            ink: ink,
            muted: muted,
          ),
          _MethodTile(
            icon: Icons.credit_card_outlined,
            title: 'Carte bancaire',
            subtitle: 'Frais 0,5 %',
            onTap: onDebitCard,
            ink: ink,
            muted: muted,
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
    final cs = Theme.of(context).colorScheme;
    final ink = cs.onSurface;
    final muted = cs.onSurfaceVariant;

    return PeyapayDraggableBottomSheet(
      onDismiss: onClose,
      heightFactor: 0.72,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Choisir une banque', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: ink)),
          const SizedBox(height: 6),
          Text('Sélectionnez une banque à connecter', style: TextStyle(fontSize: 12, color: muted)),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: banks.length,
            separatorBuilder: (_, _) => Divider(height: 1, color: cs.outlineVariant),
            itemBuilder: (_, i) {
              final bank = banks[i];
              return ListTile(
                leading: _Logo(item: bank),
                title: Text(bank.name, style: TextStyle(fontWeight: FontWeight.w800, color: ink)),
                trailing: bank.isAdded
                    ? const Icon(Icons.check_circle, color: Color(0xFF006D56), size: 22)
                    : const Icon(Icons.add_circle_outline, color: Color(0xFF006D56)),
                onTap: () => onSelect(bank),
              );
            },
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
  final _sheetKey = GlobalKey<PeyapayDraggableBottomSheetState>();
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

  Future<void> _submit() async {
    final onAdded = widget.onAdded;
    final digits = _digits(_numberCtrl.text);
    final lastFour = digits.length >= 4 ? digits.substring(digits.length - 4) : '****';
    final cardType = _cardType(_numberCtrl.text);
    await _sheetKey.currentState?.dismiss();
    onAdded(cardType, lastFour);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = cs.onSurface;
    final muted = cs.onSurfaceVariant;
    final borderColor = isDark ? cs.outlineVariant : const Color(0xFFE0E0E0);
    final border = OutlineInputBorder(borderSide: BorderSide(color: borderColor));
    final fieldStyle = TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: ink);
    final hintColor = muted.withValues(alpha: 0.75);

    return PeyapayDraggableBottomSheet(
      key: _sheetKey,
      onDismiss: widget.onClose,
      heightFactor: 0.68,
      scrollable: false,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 2),
            child: Text(
              'Ajouter une carte',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: ink),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
            child: Text(
              'Saisissez les informations de votre carte',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: muted),
            ),
          ),
          PeyapayDebitCardPreview(
            cardNumber: _numberCtrl.text,
            cardHolder: _holderCtrl.text,
            expiryDate: _expiryCtrl.text,
            cvv: _cvvCtrl.text,
            showDetails: _showCardDetails,
          ),
          Divider(height: 14, thickness: 1, color: cs.outlineVariant),
          _Field(
            label: 'Numéro de carte',
            ink: ink,
            child: TextField(
              controller: _numberCtrl,
              keyboardType: TextInputType.number,
              style: fieldStyle,
              decoration: InputDecoration(
                hintText: 'XXXX XXXX XXXX XXXX',
                hintStyle: TextStyle(color: hintColor),
                border: border,
                enabledBorder: border,
                focusedBorder: border,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
          const SizedBox(height: 8),
          _Field(
            label: 'Titulaire de la carte',
            ink: ink,
            child: TextField(
              controller: _holderCtrl,
              style: fieldStyle,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'Nom sur la carte',
                hintStyle: TextStyle(color: hintColor),
                border: border,
                enabledBorder: border,
                focusedBorder: border,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Field(
                  label: 'Date d\'expiration',
                  ink: ink,
                  child: TextField(
                    controller: _expiryCtrl,
                    keyboardType: TextInputType.number,
                    style: fieldStyle,
                    decoration: InputDecoration(
                      hintText: 'MM/AA',
                      hintStyle: TextStyle(color: hintColor),
                      border: border,
                      enabledBorder: border,
                      focusedBorder: border,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                  ink: ink,
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
                          hintStyle: TextStyle(color: hintColor),
                          border: border,
                          enabledBorder: border,
                          focusedBorder: border,
                          counterText: '',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showCardDetails ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 18,
                              color: muted,
                            ),
                            onPressed: () => setState(() => _showCardDetails = !_showCardDetails),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 2),
                        child: Text(
                          '3 chiffres au dos de la carte',
                          style: TextStyle(fontSize: 11, color: muted),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _submit,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF006D56),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Ajouter la carte',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child, required this.ink});

  final String label;
  final Widget child;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: ink)),
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
    required this.ink,
    required this.muted,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color ink;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: cs.surfaceContainerHighest, shape: BoxShape.circle),
              child: Icon(icon, size: 22, color: ink),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: ink)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: muted)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: muted),
          ],
        ),
      ),
    );
  }
}
