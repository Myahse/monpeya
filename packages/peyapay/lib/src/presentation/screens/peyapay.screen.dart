import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:peyapay/src/core/host/peyapay_host.bridge.dart';
import 'package:peyapay/src/data/models/transaction.item.dart';
import 'package:peyapay/src/data/services/peyapay_api.service.dart';
import 'package:peyapay/src/core/utils/formatters.util.dart';
import 'package:peyapay/src/core/utils/screen_insets.util.dart';
import 'package:peyapay/src/presentation/controllers/peyapay_home_reveal.controller.dart';
import 'package:peyapay/src/presentation/widgets/action_button.widget.dart';
import 'package:peyapay/src/presentation/widgets/peyapay_home_skeleton.widget.dart';
import 'package:peyapay/src/presentation/widgets/peyapay_slide_panel.widget.dart';
import 'package:peyapay/src/presentation/widgets/peyapay_top_bar.widget.dart';
import 'package:peyapay/src/presentation/screens/peyapay_payment_services.screen.dart';
import 'package:peyapay/src/presentation/screens/peyapay_source_of_funds.screen.dart';
import 'package:peyapay/src/presentation/screens/peyapay_transaction_detail.screen.dart';
import 'package:peyapay/src/presentation/screens/peyapay_transactions.screen.dart';
import 'package:peyapay/src/presentation/screens/peyapay_prepaid_card.screen.dart';
import 'package:peyapay/src/presentation/screens/peyapay_qr_code.screen.dart';
import 'package:peyapay/src/presentation/screens/peyapay_transfer_contacts.screen.dart';
import 'package:peyapay/src/presentation/widgets/peyapay_nav_bar_icon.widget.dart';
import 'package:peyapay/src/presentation/widgets/peyapay_transaction_list_tile.widget.dart';

class PeyapayScreen extends StatefulWidget {
  const PeyapayScreen({
    super.key,
    this.revealController,
  });

  /// Optional host hook so the tab shell can reverse the actions card
  /// before switching away.
  final PeyapayHomeRevealController? revealController;

  @override
  State<PeyapayScreen> createState() => _PeyapayScreenState();
}

class _PeyapayScreenState extends State<PeyapayScreen> with TickerProviderStateMixin, PeyapaySlideOverlayMixin {
  bool _showBalance = false;
  bool _showLoginRequiredModal = false;
  String _userName = 'Utilisateur';

  // Loaded from backend wallet APIs when session is active.
  int? _balance;
  List<TransactionItem> _transactions = const [];

  /// Full-page skeleton while wallet content is not ready to show.
  bool _bootstrapping = true;

  /// Once true, background refreshes keep the current UI (no blank flash).
  bool _ready = false;

  /// Coalesces overlapping reloads (session listener + initState).
  Future<void>? _inflightLoad;

  /// Forces a second full load when PIN login lands while the first
  /// bootstrap was still running against an inactive session.
  bool _reloadAfterBootstrap = false;

  static const _homeTransactionsPreviewCount = 3;

  late final AnimationController _actionsDropController;
  late final Animation<double> _actionsDropFactor;

  /// Tall actions sheet that sits behind the balance card and drops down.
  static const _actionsCardHeight = 220.0;
  static const _balanceCardApproxHeight = 118.0;
  /// How much of the grey card peeks under the green card when closed.
  static const _actionsClosedPeek = 14.0;
  /// Extra drop past flush-under-balance when fully open.
  static const _actionsOpenDrop = 56.0;

  /// Show skeleton when we have nothing meaningful to display yet.
  bool get _shouldShowSkeleton => _bootstrapping && (_balance == null || !_ready);

  @override
  void initState() {
    super.initState();
    _actionsDropController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
      reverseDuration: const Duration(milliseconds: 320),
    );
    _actionsDropFactor = CurvedAnimation(
      parent: _actionsDropController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _bindRevealController(widget.revealController);
    PeyapayHostBridge.sessionChanges?.addListener(_onSessionChanged);
    _loadProfile();
  }

  @override
  void didUpdateWidget(covariant PeyapayScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.revealController != widget.revealController) {
      _unbindRevealController(oldWidget.revealController);
      _bindRevealController(widget.revealController);
    }
  }

  @override
  void dispose() {
    _unbindRevealController(widget.revealController);
    PeyapayHostBridge.sessionChanges?.removeListener(_onSessionChanged);
    _actionsDropController.dispose();
    super.dispose();
  }

  void _bindRevealController(PeyapayHomeRevealController? controller) {
    controller?.attach(exit: _playActionsExit, enter: _playActionsEnter);
  }

  void _unbindRevealController(PeyapayHomeRevealController? controller) {
    controller?.detach(exit: _playActionsExit, enter: _playActionsEnter);
  }

  void _playActionsEnter() {
    if (!mounted) return;
    _actionsDropController.forward();
  }

  Future<void> _playActionsExit() async {
    if (!mounted) return;
    await _actionsDropController.reverse();
  }

  void _onSessionChanged() {
    // If the first bootstrap is still in flight (often guest/inactive),
    // queue a reload so PIN login data is fetched right after.
    if (_bootstrapping && _inflightLoad != null) {
      _reloadAfterBootstrap = true;
      return;
    }
    _loadProfile();
  }

  Future<void> _loadProfile() {
    final existing = _inflightLoad;
    if (existing != null) return existing;

    late final Future<void> future;
    future = _doLoadProfile().whenComplete(() {
      if (identical(_inflightLoad, future)) _inflightLoad = null;
      if (_reloadAfterBootstrap) {
        _reloadAfterBootstrap = false;
        _loadProfile();
      }
    });
    _inflightLoad = future;
    return future;
  }

  Future<void> _doLoadProfile() async {
    try {
      final api = PeyapayHostBridge.api;
      final sessionActive = await PeyapayHostBridge.requireAuth.isSessionActive();
      final phone = await PeyapayHostBridge.requireAuth.getPhone();

      if (!mounted) return;

      // Skeleton on first paint, and after PIN login until balance arrives.
      // Keep existing UI for silent refreshes when data is already shown.
      final showSkeleton = !_ready || (sessionActive && _balance == null);
      if (showSkeleton) {
        setState(() => _bootstrapping = true);
      }

      if (sessionActive && api != null && phone != null && phone.isNotEmpty) {
        try {
          final state = await api.fetchClientState(phone: phone);
          if (mounted) {
            final nom = state.nomClient?.trim();
            if (nom != null && nom.isNotEmpty) {
              setState(() => _userName = nom);
            }
          }
        } catch (_) {
          // Fall through to cached / phone display.
        }
      }

      final clientState = api?.clientState;
      final nomClient = clientState?.nomClient?.trim();
      if (!mounted) return;
      setState(() {
        _userName = (nomClient != null && nomClient.isNotEmpty)
            ? nomClient
            : _displayName(phone);
      });

      if (!sessionActive) {
        if (!mounted) return;
        setState(() {
          _balance = null;
          _showBalance = false;
          _transactions = const [];
        });
        return;
      }

      if (api == null || phone == null || phone.isEmpty) return;

      await api.hydrateBearerFrom(
        PeyapayHostBridge.requireAuth.authToken,
        preferAppToken: true,
      );

      // Sequential on purpose: shared API client mutates bearer/state.
      int? solde;
      try {
        final balance =
            await api.fetchWalletBalance(phone: phone, ensureToken: false);
        solde = balance.solde;
      } catch (_) {
        solde = api.walletBalance?.solde;
      }

      final transactions = await _fetchTransactions(api: api, phone: phone);

      if (!mounted) return;
      setState(() {
        _balance = solde ?? api.walletBalance?.solde;
        if (_balance != null) _showBalance = true;
        _transactions = transactions;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _userName = 'Utilisateur');
    } finally {
      // Always leave the loader — even on errors / early returns.
      if (mounted) {
        setState(() {
          _bootstrapping = false;
          _ready = true;
        });
      } else {
        _bootstrapping = false;
        _ready = true;
      }
    }
  }

  /// Loads recent movements; returns an empty list on failure (never throws).
  Future<List<TransactionItem>> _fetchTransactions({
    required PeyapayApiService api,
    required String phone,
  }) async {
    var accountNumber = api.resolveWalletAccountNumber(phone: phone);
    if (accountNumber == null || accountNumber.isEmpty) {
      try {
        await api.fetchClientState(phone: phone);
        accountNumber = api.resolveWalletAccountNumber(phone: phone);
      } catch (_) {}
    }
    if (accountNumber == null || accountNumber.isEmpty) return const [];

    try {
      final page = await api.fetchAccountMovements(
        accountNumber: accountNumber,
        index: 0,
        size: 20,
        ensureToken: false,
      );
      return page.movements.map((m) => m.toTransactionItem()).toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  String _displayName(String? phone) {
    if (phone == null || phone.isEmpty) return 'Utilisateur';
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= 4) {
      return 'Utilisateur • ${digits.substring(digits.length - 4)}';
    }
    return 'Utilisateur';
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
    const actionsMarginH = 40.0; // left+right card margin
    const actionsPadH = 24.0; // left+right card padding
    const gap = 8.0;
    final actionWidth =
        ((w - actionsMarginH - actionsPadH - (gap * 3)) / 4).clamp(0.0, 220.0);
    final previewTransactions = _transactions.take(_homeTransactionsPreviewCount).toList(growable: false);

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.only(top: peyapayStatusBarTop(context)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PeyapayTopBar(
                      title: 'Bienvenue $_userName',
                      titleWidget: _shouldShowSkeleton ? const PeyapayNameSkeleton() : null,
                      onPressProfile: () => PeyapayHostBridge.openNamedRoute(PeyapayHostRoutes.settings),
                    ),
                    AnimatedBuilder(
                      animation: _actionsDropFactor,
                      builder: (context, _) {
                        final t = _actionsDropFactor.value;
                        // Tucked high behind the green card when closed; drops down when open.
                        final closedY = -(
                          _actionsCardHeight -
                          _balanceCardApproxHeight -
                          _actionsClosedPeek
                        );
                        final openY = _actionsOpenDrop;
                        final sheetY = closedY + (openY - closedY) * t;
                        final stackHeight = math.max(
                          _balanceCardApproxHeight,
                          sheetY + _actionsCardHeight,
                        );

                        return SizedBox(
                          height: stackHeight + 16,
                          child: Stack(
                            clipBehavior: Clip.hardEdge,
                            children: [
                              // Actions card — behind, taller, buttons pinned to bottom.
                              Positioned(
                                left: 20,
                                right: 20,
                                top: sheetY,
                                height: _actionsCardHeight,
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? cs.surfaceContainerHighest
                                        : const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      const Spacer(),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          ActionButton(
                                            width: actionWidth,
                                            bg: const Color.fromRGBO(26, 158, 9, 0.18),
                                            icon: Icons.arrow_upward_rounded,
                                            iconSize: 28,
                                            iconColor: const Color(0xFF1A9E09),
                                            label: 'Transfert',
                                            textColor: ink,
                                            onTap: () => Navigator.of(
                                              context,
                                              rootNavigator: true,
                                            ).push(
                                              MaterialPageRoute<void>(
                                                builder: (_) =>
                                                    const PeyapayTransferContactsScreen(),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: gap),
                                          ActionButton(
                                            width: actionWidth,
                                            bg: const Color.fromRGBO(
                                              53,
                                              167,
                                              224,
                                              0.22,
                                            ),
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
                                            bg: const Color.fromRGBO(
                                              255,
                                              102,
                                              0,
                                              0.22,
                                            ),
                                            icon: Icons.credit_card,
                                            iconSize: 28,
                                            iconColor: const Color(0xFFFF6600),
                                            label: 'Carte prépayée',
                                            textColor: ink,
                                            onTap: openPrepaidCard,
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
                                    ],
                                  ),
                                ),
                              ),
                              // Balance card — in front.
                              Positioned(
                                left: 20,
                                right: 20,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: balanceGreen,
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const PeyaPayNavBarIcon(
                                            size: 28,
                                            width: 76,
                                          ),
                                          Row(
                                            children: [
                                              GestureDetector(
                                                onTap: () => Navigator.of(
                                                  context,
                                                  rootNavigator: true,
                                                ).push(
                                                  MaterialPageRoute<void>(
                                                    builder: (_) =>
                                                        const PeyapayQrCodeScreen(),
                                                  ),
                                                ),
                                                child: Container(
                                                  width: 36,
                                                  height: 36,
                                                  decoration: BoxDecoration(
                                                    color: const Color.fromRGBO(
                                                      255,
                                                      255,
                                                      255,
                                                      0.12,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(12),
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: const Icon(
                                                    Icons.qr_code_2_rounded,
                                                    size: 18,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              GestureDetector(
                                                onTap: _shouldShowSkeleton
                                                    ? null
                                                    : _toggleBalanceVisibility,
                                                child: Container(
                                                  width: 36,
                                                  height: 36,
                                                  decoration: BoxDecoration(
                                                    color: const Color.fromRGBO(
                                                      255,
                                                      255,
                                                      255,
                                                      0.12,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(12),
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: Icon(
                                                    _showBalance
                                                        ? Icons
                                                            .visibility_off_outlined
                                                        : Icons
                                                            .visibility_outlined,
                                                    size: 18,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      if (_shouldShowSkeleton)
                                        const PeyapayBalanceSkeleton()
                                      else ...[
                                        const Text(
                                          'Solde actuel',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: Color.fromRGBO(
                                              255,
                                              255,
                                              255,
                                              0.92,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        GestureDetector(
                                          onTap: _toggleBalanceVisibility,
                                          child: Text(
                                            _showBalance && _balance != null
                                                ? '${formatFrMoneySigned(_balance!)} XOF'
                                                : '*****',
                                            style: const TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Builder(
                        builder: (context) {
                          final carousel = PeyapayHostBridge.newsCarousel(
                            context,
                            height: 180,
                          );
                          if (carousel == null) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: carousel,
                          );
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Transactions récentes',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: ink),
                          ),
                          if (!_shouldShowSkeleton && _transactions.isNotEmpty)
                            GestureDetector(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => PeyapayTransactionsScreen(initialItems: _transactions),
                                ),
                              ),
                              child: Text(
                                'Voir tout',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: ink),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_shouldShowSkeleton)
                        const PeyapayTransactionsSkeleton()
                      else if (_transactions.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
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
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final item in previewTransactions)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: PeyapayTransactionListTile(
                                  item: item,
                                  ink: ink,
                                  muted: muted,
                                  border: border,
                                  iconBg: iconBgGrey,
                                  surface: bg,
                                  onTap: () => openPeyapayTransactionDetail(context, item),
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
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
            if (showPrepaidCard)
              PeyapaySlidePanel(
                animation: prepaidCardSlideController,
                child: PeyapayPrepaidCardScreen(onClose: closePrepaidCard),
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

