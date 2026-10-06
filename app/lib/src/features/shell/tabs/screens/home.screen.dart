import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:app/src/core/assets/constants/asset.paths.dart';
import 'package:app/src/core/auth/module.auth.dart';
import 'package:app/src/core/auth/pin_auth.logger.dart';
import 'package:app/src/core/modules/app.module.dart';
import 'package:app/src/core/modules/repositories/module.repository.dart';
import 'package:app/src/core/peyapay/peyapay_profile.util.dart';
import 'package:app/src/core/routing/routes.dart';
import 'package:app/src/core/session/mon_peya.session.dart';
import 'package:app/src/core/storage/auth.store.dart';
import 'package:app/src/core/theme/mon_peya.design.dart';
import 'package:app/src/features/notifications/presentation/screens/notifications.screen.dart';
import 'package:app/src/features/shell/screens/mon_peya_my_services.screen.dart';
import 'package:app/src/features/shell/scopes/main_tabs.scope.dart';
import 'package:app/src/features/shell/services/module_launcher.service.dart';
import 'package:app/src/core/modules/widgets/module.icon.dart';
import 'package:app/src/features/shell/widgets/main_bottom_navigation_bar.widget.dart';
import 'package:app/src/features/shell/widgets/main_tabs.shell.dart';
import 'package:app/src/integration/adapters/peyapay_host.adapter.dart';
import 'package:peyapay/peyapay.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  bool _showBalance = false;
  int? _balanceSolde;
  bool _loadingBalance = false;
  String _clientTitle = PeyapayProfileDisplay.guestLabel;
  String _clientInitials = 'UT';

  /// Staggered entrance for every home section.
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  /// Slow ambient loop for the hero glow shapes.
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  )..repeat();

  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _showBalance = MonPeyaSession.instance.isSessionActive;
    MonPeyaSession.instance.addListener(_onSessionChanged);
    _loadProfileAndBalance();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _enter.forward();
    });
  }

  @override
  void dispose() {
    MonPeyaSession.instance.removeListener(_onSessionChanged);
    _enter.dispose();
    _ambient.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onSessionChanged() {
    if (MonPeyaSession.instance.isSessionActive) {
      setState(() => _showBalance = true);
    }
    unawaited(_loadProfileAndBalance());
  }

  Future<void> _loadClientTitle() async {
    final title = await PeyapayProfileDisplay.resolveHomeTitle();
    if (!mounted) return;
    setState(() {
      _clientTitle = title;
      _clientInitials = PeyapayProfileDisplay.initials(title);
    });
  }

  Future<void> _loadProfileAndBalance() async {
    final signedIn = await ModuleAuth.hasActiveSessionOrToken();
    if (signedIn) {
      final api = PeyapayHostBridge.api;
      final phone = await AuthStore.getPhone();
      if (api != null && phone != null && phone.isNotEmpty) {
        try {
          await api.fetchClientState(phone: phone);
        } catch (_) {}
      }
    }
    await _loadClientTitle();
    await _loadBalance();
  }

  Future<void> _loadBalance() async {
    final signedIn = await ModuleAuth.hasActiveSessionOrToken();
    if (!signedIn) {
      if (!mounted) return;
      setState(() {
        _balanceSolde = null;
        _loadingBalance = false;
        _showBalance = false;
      });
      return;
    }

    final api = PeyapayHostBridge.api;
    final cached = api?.walletBalance?.solde;
    if (cached != null && mounted) {
      setState(() {
        _balanceSolde = cached;
        _showBalance = true;
      });
    }

    final phone = await AuthStore.getPhone();
    if (!mounted || phone == null || phone.isEmpty || api == null) return;

    setState(() => _loadingBalance = true);
    try {
      await peyapayEnsureBearerReady();
      final balance = await api.fetchWalletBalance(phone: phone, ensureToken: false);
      if (!mounted) return;
      setState(() {
        _balanceSolde = balance.solde;
        _loadingBalance = false;
        if (balance.solde != null) _showBalance = true;
      });
      await _loadClientTitle();
      PinAuthLogger.success(
        'Solde home${balance.solde != null ? ' — ${balance.solde} XOF' : ' (vide)'}',
      );
    } on PeyapayApiException catch (e) {
      PinAuthLogger.failure('Solde home', e);
      if (!mounted) return;
      setState(() => _loadingBalance = false);
    } catch (e) {
      PinAuthLogger.failure('Solde home', e);
      if (!mounted) return;
      setState(() => _loadingBalance = false);
    }
  }

  Future<void> _toggleBalanceVisibility() async {
    if (!MonPeyaSession.instance.isSessionActive) {
      final ok = await ModuleAuth.ensureRegistered(context);
      if (ok && mounted) {
        await _loadProfileAndBalance();
        setState(() => _showBalance = true);
      }
      return;
    }
    setState(() => _showBalance = !_showBalance);
  }

  void _openModule(AppModule module) {
    ModuleLauncher.open(context, module);
  }

  Future<void> _openMyQrCode() async {
    if (!MonPeyaSession.instance.isSessionActive) {
      final ok = await ModuleAuth.ensureRegistered(context);
      if (!ok || !mounted) return;
      await _loadProfileAndBalance();
    }

    if (!mounted) return;
    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const PeyapayQrCodeScreen(),
      ),
    );
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const NotificationsScreen(),
      ),
    );
  }

  String _formatFcfa(double v) {
    final whole = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      final idxFromEnd = whole.length - i;
      buf.write(whole[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buf.write(' ');
    }
    return buf.toString();
  }

  Future<void> _requireSessionThen(Future<void> Function() action) async {
    if (!MonPeyaSession.instance.isSessionActive) {
      final ok = await ModuleAuth.ensureRegistered(context);
      if (!ok || !mounted) return;
      await _loadProfileAndBalance();
      if (!mounted) return;
    }
    await action();
  }

  void _push(Widget screen) {
    Navigator.of(context, rootNavigator: true)
        .push<void>(MaterialPageRoute<void>(builder: (_) => screen));
  }

  void _openPeyaPayTab() {
    final select = MainTabsScope.maybeOf(context);
    if (select != null) unawaited(select(MainTab.peyapay));
  }

  void _openModuleByKey(String key) {
    final module = ModuleRepository.modules
        .where((m) => m.moduleKey == key)
        .firstOrNull;
    if (module != null) {
      _openModule(module);
    } else if (key == 'peyapay') {
      _openPeyaPayTab();
    }
  }

  Animation<double> _interval(double begin, double end) => CurvedAnimation(
        parent: _enter,
        curve: Interval(begin, end, curve: Curves.easeOutCubic),
      );

  @override
  Widget build(BuildContext context) {
    final modules = ModuleRepository.modules;
    final topPad = peyapayStatusBarTop(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ListenableBuilder(
        listenable: MonPeyaSession.instance,
        builder: (context, _) {
          final session = MonPeyaSession.instance.isSessionActive;
          return ColoredBox(
            color: MonPeyaColors.background(context),
            child: Stack(
              children: [
                // Gradient + glow shapes; drifts up slower than content.
                AnimatedBuilder(
                  animation: _scroll,
                  builder: (context, child) {
                    final offset = _scroll.hasClients ? _scroll.offset : 0.0;
                    return Positioned(
                      top: -offset * 0.45,
                      left: 0,
                      right: 0,
                      height: topPad + 420,
                      child: child!,
                    );
                  },
                  child: _HeroBackdrop(ambient: _ambient),
                ),
                CustomScrollView(
                  controller: _scroll,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20, topPad + 8, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _Reveal(
                              animation: _interval(0.0, 0.35),
                              dy: -12,
                              child: _TopBar(
                                greeting: _greeting(),
                                name: _clientTitle,
                                initials: _clientInitials,
                                onPressProfile: () => rootNavKey.currentState
                                    ?.pushNamed(Routes.settings),
                                onPressNotifications: _openNotifications,
                              ),
                            ),
                            const SizedBox(height: 18),
                            _Reveal(
                              animation: _interval(0.08, 0.45),
                              child: _BalanceCard(
                                sessionActive: session,
                                showBalance: _showBalance,
                                balanceSolde: _balanceSolde,
                                loadingBalance: _loadingBalance,
                                formatFcfa: _formatFcfa,
                                onToggleBalance: _toggleBalanceVisibility,
                                onShowQr: _openMyQrCode,
                              ),
                            ),
                            const SizedBox(height: 18),
                            _QuickActions(
                              enter: _enter,
                              actions: [
                                _QuickAction(
                                  'Envoyer',
                                  Icons.north_east_rounded,
                                  () => _requireSessionThen(() async =>
                                      _push(const PeyapayTransferContactsScreen())),
                                ),
                                _QuickAction(
                                  'Recharger',
                                  Icons.add_rounded,
                                  _openPeyaPayTab,
                                ),
                                _QuickAction(
                                  'Scanner',
                                  Icons.qr_code_scanner_rounded,
                                  () => _requireSessionThen(() async =>
                                      _push(const PeyapayQrScanScreen())),
                                ),
                                _QuickAction(
                                  'Mon QR',
                                  Icons.qr_code_2_rounded,
                                  _openMyQrCode,
                                ),
                              ],
                            ),
                            const SizedBox(height: 26),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _Sheet(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            20,
                            22,
                            20,
                            MainBottomNavigationBar.contentBottomPadding(context),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _Reveal(
                                animation: _interval(0.30, 0.62),
                                child: _MonPeyaMiniCard(
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          const MonPeyaMyServicesScreen(),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 22),
                              _Reveal(
                                animation: _interval(0.36, 0.66),
                                child: _SectionHeader(
                                  title: 'Mes services',
                                  trailing: '${modules.length} disponibles',
                                ),
                              ),
                              const SizedBox(height: 12),
                              _ServiceGrid(
                                modules: modules,
                                enter: _enter,
                                onOpen: _openModule,
                              ),
                              const SizedBox(height: 26),
                              _Reveal(
                                animation: _interval(0.62, 0.86),
                                child: const _SectionHeader(title: 'À la une'),
                              ),
                              const SizedBox(height: 12),
                              _Reveal(
                                animation: _interval(0.66, 0.92),
                                child: _HighlightsCarousel(
                                  onOpen: _openModuleByKey,
                                ),
                              ),
                              const SizedBox(height: 22),
                              _Reveal(
                                animation: _interval(0.74, 1.0),
                                child: const _SecurityTip(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bonjour';
    if (h < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MOTION HELPERS
// ═══════════════════════════════════════════════════════════════════════════

/// Fade + slide driven by an entrance interval.
class _Reveal extends StatelessWidget {
  const _Reveal({required this.animation, required this.child, this.dy = 18});

  final Animation<double> animation;
  final Widget child;
  final double dy;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) => Opacity(
        opacity: animation.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - animation.value) * dy),
          child: child,
        ),
      ),
    );
  }
}

/// Shrinks a little while pressed — used by every tappable tile.
class _Pressable extends StatefulWidget {
  const _Pressable({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? 0.94 : 1,
        duration: MonPeyaMotion.fast,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HERO
// ═══════════════════════════════════════════════════════════════════════════

class _HeroBackdrop extends StatelessWidget {
  const _HeroBackdrop({required this.ambient});

  final Animation<double> ambient;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: MonPeyaColors.heroGradient),
      child: AnimatedBuilder(
        animation: ambient,
        builder: (context, _) {
          final t = ambient.value * 2 * math.pi;
          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              _Glow(
                left: -60 + math.sin(t) * 30,
                top: -40 + math.cos(t) * 20,
                size: 240,
                color: const Color(0xFF34C759),
                alpha: 0.28,
              ),
              _Glow(
                right: -80 + math.cos(t * 0.8) * 26,
                top: 90 + math.sin(t * 0.8) * 24,
                size: 260,
                color: const Color(0xFF00C2A8),
                alpha: 0.22,
              ),
              _Glow(
                left: 120 + math.sin(t * 1.3) * 40,
                bottom: -90,
                size: 220,
                color: Colors.white,
                alpha: 0.08,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({
    this.left,
    this.right,
    this.top,
    this.bottom,
    required this.size,
    required this.color,
    required this.alpha,
  });

  final double? left;
  final double? right;
  final double? top;
  final double? bottom;
  final double size;
  final Color color;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: alpha),
                color.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.greeting,
    required this.name,
    required this.initials,
    required this.onPressProfile,
    required this.onPressNotifications,
  });

  final String greeting;
  final String name;
  final String initials;
  final VoidCallback onPressProfile;
  final VoidCallback onPressNotifications;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Pressable(
          onTap: onPressProfile,
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting 👋',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
        _Pressable(
          onTap: onPressNotifications,
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.14),
            ),
            child: const Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.notifications_none_rounded,
                    color: Colors.white, size: 24),
                Positioned(top: 11, right: 12, child: _PulseDot()),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Red dot with a soft expanding ring.
class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 9,
      height: 9,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Transform.scale(
              scale: 1 + _c.value * 1.6,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MonPeyaColors.danger
                      .withValues(alpha: (1 - _c.value) * 0.5),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MonPeyaColors.danger,
                border: Border.all(color: Colors.white, width: 1.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.sessionActive,
    required this.showBalance,
    required this.balanceSolde,
    required this.loadingBalance,
    required this.formatFcfa,
    required this.onToggleBalance,
    required this.onShowQr,
  });

  final bool sessionActive;
  final bool showBalance;
  final int? balanceSolde;
  final bool loadingBalance;
  final String Function(double) formatFcfa;
  final VoidCallback onToggleBalance;
  final Future<void> Function() onShowQr;

  bool get _visible =>
      sessionActive && showBalance && balanceSolde != null;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(MonPeyaRadius.lg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(MonPeyaRadius.lg),
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.22),
                Colors.white.withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'PEYA PAY',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Solde disponible',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: onToggleBalance,
                      behavior: HitTestBehavior.opaque,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: AnimatedSwitcher(
                              duration: MonPeyaMotion.normal,
                              transitionBuilder: (child, a) => FadeTransition(
                                opacity: a,
                                child: SizeTransition(
                                  sizeFactor: a,
                                  axis: Axis.horizontal,
                                  child: child,
                                ),
                              ),
                              child: _visible
                                  ? TweenAnimationBuilder<double>(
                                      key: const ValueKey('amount'),
                                      tween: Tween(
                                        begin: 0,
                                        end: balanceSolde!.toDouble(),
                                      ),
                                      duration:
                                          const Duration(milliseconds: 1100),
                                      curve: Curves.easeOutExpo,
                                      builder: (context, v, _) => _Amount(
                                        text: formatFcfa(v),
                                        suffix: 'XOF',
                                      ),
                                    )
                                  : _Amount(
                                      key: const ValueKey('hidden'),
                                      text: loadingBalance && sessionActive
                                          ? '···'
                                          : '• • • • •',
                                    ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            showBalance && sessionActive
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: Colors.white.withValues(alpha: 0.8),
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      sessionActive
                          ? 'Touchez pour afficher ou masquer'
                          : 'Connectez-vous pour voir votre solde',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: PeyapayWalletQrThumb(
                  size: 78,
                  fillFactor: 0.95,
                  // Dark modules on the white tile.
                  lightOnDark: false,
                  sessionActive: sessionActive,
                  onTap: onShowQr,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Amount extends StatelessWidget {
  const _Amount({super.key, required this.text, this.suffix});

  final String text;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),
        if (suffix != null) ...[
          const SizedBox(width: 6),
          Text(
            suffix!,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ],
    );
  }
}

class _QuickAction {
  const _QuickAction(this.label, this.icon, this.onTap);

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.enter, required this.actions});

  final AnimationController enter;
  final List<_QuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < actions.length; i++)
          _PopIn(
            animation: CurvedAnimation(
              parent: enter,
              curve: Interval(0.18 + i * 0.06, 0.52 + i * 0.06,
                  curve: Curves.easeOutBack),
            ),
            child: _Pressable(
              onTap: actions[i].onTap,
              child: SizedBox(
                width: 72,
                child: Column(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(actions[i].icon,
                          color: MonPeyaColors.green, size: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      actions[i].label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Scale + fade pop used for buttons and tiles.
class _PopIn extends StatelessWidget {
  const _PopIn({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) => Opacity(
        opacity: animation.value.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: 0.6 + 0.4 * animation.value,
          child: child,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SHEET CONTENT
// ═══════════════════════════════════════════════════════════════════════════

class _Sheet extends StatelessWidget {
  const _Sheet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MonPeyaColors.background(context),
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(MonPeyaRadius.xl)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _MonPeyaMiniCard extends StatelessWidget {
  const _MonPeyaMiniCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    return _Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        decoration: monPeyaCard(context),
        child: Row(
          children: [
            Image.asset(
              isDark ? AssetPaths.logoDark : AssetPaths.logo,
              height: 34,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mon espace personnel',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                  Text(
                    'Profil, sécurité & préférences',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: MonPeyaColors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_rounded,
                  size: 18, color: MonPeyaColors.green),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: cs.onSurface,
              letterSpacing: -0.4,
            ),
          ),
        ),
        if (trailing != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: MonPeyaColors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              trailing!,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: MonPeyaColors.green,
              ),
            ),
          ),
      ],
    );
  }
}

class _ServiceGrid extends StatelessWidget {
  const _ServiceGrid({
    required this.modules,
    required this.enter,
    required this.onOpen,
  });

  final List<AppModule> modules;
  final AnimationController enter;
  final ValueChanged<AppModule> onOpen;

  @override
  Widget build(BuildContext context) {
    if (modules.isEmpty) {
      return Text(
        'Aucun service disponible pour le moment.',
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: modules.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 14,
        crossAxisSpacing: 10,
        mainAxisExtent: 96,
      ),
      itemBuilder: (context, i) {
        final start = (0.40 + i * 0.035).clamp(0.0, 0.85);
        return _PopIn(
          animation: CurvedAnimation(
            parent: enter,
            curve: Interval(start, (start + 0.28).clamp(0.0, 1.0),
                curve: Curves.easeOutBack),
          ),
          child: _ServiceTile(
            module: modules[i],
            onTap: () => onOpen(modules[i]),
          ),
        );
      },
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.module, required this.onTap});

  final AppModule module;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = MonPeyaColors.moduleAccent(module.moduleKey);
    final hasAsset = moduleIconAsset(
          moduleKey: module.moduleKey,
          iconKey: module.icon,
        ) !=
        null;

    return _Pressable(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: hasAsset
                  ? MonPeyaColors.surface(context)
                  : accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accent.withValues(alpha: 0.18)),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: ModuleIcon.forModule(
              module,
              size: hasAsset ? 46 : 28,
              color: accent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            module.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

/// Mon Peya's own highlights — auto-advancing, scales the focused card.
class _HighlightsCarousel extends StatefulWidget {
  const _HighlightsCarousel({required this.onOpen});

  final ValueChanged<String> onOpen;

  @override
  State<_HighlightsCarousel> createState() => _HighlightsCarouselState();
}

class _HighlightsCarouselState extends State<_HighlightsCarousel> {
  final _controller = PageController(viewportFraction: 0.86);
  Timer? _timer;
  int _page = 0;

  static const _items = [
    (
      tag: 'PEYA PAY',
      title: 'Payez CIE et SODECI\nen quelques secondes',
      cta: 'Payer une facture',
      icon: Icons.bolt_rounded,
      colors: [Color(0xFF00876A), Color(0xFF063E1C)],
      moduleKey: 'peyapay',
    ),
    (
      tag: 'BILLETTERIE',
      title: 'Vos tickets de car\ntoujours sur vous',
      cta: 'Réserver un trajet',
      icon: Icons.directions_bus_rounded,
      colors: [Color(0xFF38BDF8), Color(0xFF0369A1)],
      moduleKey: 'billetterie-transport',
    ),
    (
      tag: 'MR IMMO',
      title: 'Trouvez un logement\nprès de chez vous',
      cta: 'Voir les biens',
      icon: Icons.home_work_rounded,
      colors: [Color(0xFF1F7A3F), Color(0xFF063E1C)],
      moduleKey: 'real-estate',
    ),
    (
      tag: 'ASSURANCE',
      title: 'Assurez votre moto\nen 3 étapes',
      cta: 'Obtenir un devis',
      icon: Icons.two_wheeler_rounded,
      colors: [Color(0xFF14B8A6), Color(0xFF0E7C66)],
      moduleKey: 'sim-assurance',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_controller.hasClients) return;
      final next = (_page + 1) % _items.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 168,
          child: OverflowBox(
            maxWidth: MediaQuery.sizeOf(context).width,
            child: PageView.builder(
              controller: _controller,
              itemCount: _items.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, i) {
                final item = _items[i];
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    var delta = 0.0;
                    if (_controller.hasClients &&
                        _controller.position.haveDimensions) {
                      delta = (_controller.page! - i).abs().clamp(0.0, 1.0);
                    } else {
                      delta = i == 0 ? 0 : 1;
                    }
                    return Transform.scale(
                      scale: 1 - delta * 0.08,
                      child: Opacity(opacity: 1 - delta * 0.35, child: child),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: _Pressable(
                      onTap: () => widget.onOpen(item.moduleKey),
                      child: _HighlightCard(
                        tag: item.tag,
                        title: item.title,
                        cta: item.cta,
                        icon: item.icon,
                        colors: item.colors,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _items.length,
            (i) => AnimatedContainer(
              duration: MonPeyaMotion.normal,
              curve: MonPeyaMotion.curve,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _page ? 22 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: MonPeyaColors.green
                    .withValues(alpha: i == _page ? 1 : 0.22),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({
    required this.tag,
    required this.title,
    required this.cta,
    required this.icon,
    required this.colors,
  });

  final String tag;
  final String title;
  final String cta;
  final IconData icon;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(MonPeyaRadius.lg),
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(MonPeyaRadius.lg),
        child: Stack(
          children: [
            Positioned(
              right: -24,
              bottom: -24,
              child: Icon(
                icon,
                size: 150,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            Positioned(
              right: 18,
              top: 18,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tag,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          cta,
                          style: TextStyle(
                            color: colors.last,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded,
                            size: 14, color: colors.last),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecurityTip extends StatelessWidget {
  const _SecurityTip();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: monPeyaCard(context),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFB020).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.shield_outlined, color: Color(0xFFE09600)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Astuce sécurité',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Mon Peya ne vous demandera jamais votre code PIN par téléphone ou SMS.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: cs.onSurface.withValues(alpha: 0.6),
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
