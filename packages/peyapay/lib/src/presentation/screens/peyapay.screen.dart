import 'package:flutter/material.dart';

import 'package:peyapay/src/core/host/peyapay_host.bridge.dart';
import 'package:peyapay/src/data/models/transaction.item.dart';
import 'package:peyapay/src/core/utils/formatters.util.dart';
import 'package:peyapay/src/core/utils/screen_insets.util.dart';
import 'package:peyapay/src/presentation/widgets/action_button.widget.dart';
import 'package:peyapay/src/presentation/widgets/blocked_states.widget.dart';
import 'package:peyapay/src/presentation/widgets/peyapay_slide_panel.widget.dart';
import 'package:peyapay/src/presentation/widgets/peyapay_top_bar.widget.dart';
import 'package:peyapay/src/presentation/screens/peyapay_payment_services.screen.dart';
import 'package:peyapay/src/presentation/screens/peyapay_source_of_funds.screen.dart';
import 'package:peyapay/src/presentation/screens/peyapay_transactions.screen.dart';
import 'package:peyapay/src/presentation/screens/peyapay_transfer_contacts.screen.dart';

class PeyapayScreen extends StatefulWidget {
  const PeyapayScreen({super.key});

  @override
  State<PeyapayScreen> createState() => _PeyapayScreenState();
}

class _PeyapayScreenState extends State<PeyapayScreen> with TickerProviderStateMixin, PeyapaySlideOverlayMixin {
  bool _authChecked = false;
  bool _isRegistered = false;
  bool _showBalance = false;
  bool _showLoginRequiredModal = false;
  String _userName = '...';

  // TODO: Wire to the same data source as the RN dashboardDataCache.
  final int _balance = 125000;
  final List<TransactionItem> _recent = const [
    TransactionItem(id: '1', recipient: 'Supermarché', dateIso: '2026-04-15T10:10:00.000Z', amount: -12500),
    TransactionItem(id: '2', recipient: 'Oumar D.', dateIso: '2026-04-14T16:22:00.000Z', amount: 25000),
    TransactionItem(id: '3', recipient: 'Orange Money', dateIso: '2026-04-13T09:05:00.000Z', amount: 10000),
  ];

  @override
  void initState() {
    super.initState();
    _checkRegistration();

 
    Future<void>(() async {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (!mounted) return;
      setState(() => _userName = 'Utilisateur');
    });
  }

  Future<void> _checkRegistration() async {
    try {
      final ok = await PeyapayHostBridge.requireAuth.isRegistered();
      if (!mounted) return;
      setState(() {
        _isRegistered = ok;
        _authChecked = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isRegistered = false;
        _authChecked = true;
      });
    }
  }

  void _toggleBalanceVisibility() => setState(() => _showBalance = !_showBalance);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = isDark ? cs.surface : const Color(0xFFFFFFFF);
    final ink = isDark ? cs.onSurface : const Color(0xFF111827);
    final muted = isDark ? cs.onSurfaceVariant : const Color(0xFF6B7280);
    final border = isDark ? cs.outlineVariant : const Color(0xFFE5E7EB);
    const balanceGreen = Color(0xFF006D56);
    final iconBgGrey = isDark ? cs.surfaceContainerHighest : const Color(0xFFF3F4F6);

    final w = MediaQuery.of(context).size.width;
    const actionsPaddingH = 40.0; // left+right = 20+20
    const gap = 8.0;
    final actionWidth = ((w - actionsPaddingH - (gap * 3)) / 4).clamp(0.0, 220.0);

    if (!_authChecked) {
      return Scaffold(
        backgroundColor: bg,
        body: PeyapayLoadingGate(textColor: ink),
      );
    }

    if (!_isRegistered) {
      return Scaffold(
        backgroundColor: bg,
        body: PeyapayBlockedGate(
          titleColor: ink,
          bodyColor: isDark ? muted : const Color(0xFF4B5563),
          buttonBg: ink,
          onPressLogin: () => PeyapayHostBridge.openNamedRoute(PeyapayHostRoutes.phoneInput),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.only(
                top: peyapayStatusBarTop(context),
                bottom: 24,
              ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PeyapayTopBar(
                      title: 'Bienvenue $_userName',
                      onPressProfile: () => PeyapayHostBridge.openNamedRoute(PeyapayHostRoutes.settings),
                    ),

                    // Balance card
                    Container(
                      margin: const EdgeInsets.only(top: 6, left: 20, right: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: balanceGreen,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "N’TERI",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: Color.fromRGBO(255, 255, 255, 0.92),
                                  letterSpacing: 0.6,
                                ),
                              ),
                              GestureDetector(
                                onTap: _toggleBalanceVisibility,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color.fromRGBO(255, 255, 255, 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    _showBalance ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Solde actuel',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color.fromRGBO(255, 255, 255, 0.92),
                            ),
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: _toggleBalanceVisibility,
                            child: Text(
                              _showBalance ? '${formatFrMoneySigned(_balance)} XOF' : '*****',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Quick actions
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 20, right: 20, bottom: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ActionButton(
                            width: actionWidth,
                            bg: const Color.fromRGBO(26, 158, 9, 0.18),
                            icon: Icons.arrow_upward_rounded,
                            iconSize: 28,
                            iconColor: const Color(0xFF1A9E09),
                            label: 'Transfert',
                            textColor: ink,
                            onTap: () => Navigator.of(context, rootNavigator: true).push(
                              MaterialPageRoute<void>(builder: (_) => const PeyapayTransferContactsScreen()),
                            ),
                          ),
                          const SizedBox(width: gap),
                          ActionButton(
                            width: actionWidth,
                            bg: const Color.fromRGBO(53, 167, 224, 0.22),
                            icon: Icons.credit_card_outlined,
                            iconSize: 28,
                            iconColor: const Color(0xFF35A7E0),
                            label: 'Paiement',
                            textColor: ink,
                            onTap: openPaymentsServices,
                          ),
                          const SizedBox(width: gap),
                          ActionButton(
                            width: actionWidth,
                            bg: const Color.fromRGBO(255, 102, 0, 0.22),
                            icon: Icons.credit_card,
                            iconSize: 28,
                            iconColor: const Color(0xFFFF6600),
                            label: 'Carte prépayée',
                            textColor: ink,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(builder: (_) => const _Placeholder(title: 'PrepaidCard')),
                            ),
                          ),
                          const SizedBox(width: gap),
                          ActionButton(
                            width: actionWidth,
                            bg: ink,
                            icon: Icons.add,
                            iconSize: 24,
                            iconColor: Colors.white,
                            label: 'Banques et assurances',
                            textColor: ink,
                            onTap: openSourceOfFunds,
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: PeyapayHostBridge.newsCarousel(context, height: 185) ?? const SizedBox.shrink(),
                    ),

                    // Transactions
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Transactions récentes',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: ink),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => PeyapayTransactionsScreen(items: _recent),
                                  ),
                                ),
                                child: Text(
                                  'Voir tout',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: ink),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (_recent.isEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              decoration: BoxDecoration(
                                color: bg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: border),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Aucune transaction pour le moment',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: muted),
                              ),
                            )
                          else
                            Column(
                              children: [
                                for (final item in _recent)
                                  GestureDetector(
                                    onTap: () => _showTxAlert(context, item),
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: bg,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: border),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 36,
                                                  height: 36,
                                                  decoration: BoxDecoration(
                                                    color: iconBgGrey,
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: Icon(Icons.swap_horiz_rounded, size: 18, color: ink),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        item.recipient,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: ink),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        formatFrDateOnly(item.dateIso),
                                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: muted),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            '${formatFrMoneySigned(item.amount)} XOF',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: ink),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (showPaymentsServices)
              PeyapaySlidePanel(
                animation: paymentsSlideController,
                child: PeyapayPaymentServicesScreen(onClose: closePaymentsServices),
              ),
            if (showSourceOfFunds)
              PeyapaySlidePanel(
                animation: sourceOfFundsSlideController,
                child: PeyapaySourceOfFundsScreen(
                  onClose: closeSourceOfFunds,
                  onDepositComplete: () {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Dépôt effectué — solde mis à jour')),
                    );
                    // TODO: refresh balance from API (RN fetchProfileData / fetchTransactions).
                  },
                ),
              ),
            if (_showLoginRequiredModal)
              _AuthModal(
                onYes: () => setState(() => _showLoginRequiredModal = false),
                onNo: () => setState(() => _showLoginRequiredModal = false),
              ),
          ],
        ),
    );
  }
}

void _showTxAlert(BuildContext context, TransactionItem item) {
  showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Transaction'),
      content: Text('${item.recipient}\n${formatFrMoneySigned(item.amount)} XOF'),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
    ),
  );
}

class _AuthModal extends StatelessWidget {
  const _AuthModal({required this.onYes, required this.onNo});
  final VoidCallback onYes;
  final VoidCallback onNo;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF111827);
    const green = Color(0xFF006D56);
    const grey = Color(0xFFE5E7EB);
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.4),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Connexion requise',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ink),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Connectez-vous pour afficher votre solde.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: onYes,
                    child: Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(color: green, borderRadius: BorderRadius.circular(12)),
                      alignment: Alignment.center,
                      child: const Text(
                        'Oui',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: onNo,
                    child: Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(color: grey, borderRadius: BorderRadius.circular(12)),
                      alignment: Alignment.center,
                      child: const Text(
                        'Non',
                        style: TextStyle(color: ink, fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const SafeArea(child: Center(child: Text('TODO'))),
    );
  }
}

