import 'dart:async';

import 'package:flutter/material.dart';

import 'package:app/src/core/assets/constants/asset.paths.dart';
import 'package:app/src/core/auth/module.auth.dart';
import 'package:app/src/core/auth/pin_auth.logger.dart';
import 'package:app/src/core/modules/app.module.dart';
import 'package:app/src/core/modules/repositories/module.repository.dart';
import 'package:app/src/core/peyapay/peyapay_profile.util.dart';
import 'package:app/src/core/routing/routes.dart';
import 'package:app/src/core/session/mon_peya.session.dart';
import 'package:app/src/core/storage/auth.store.dart';
import 'package:app/src/features/notifications/presentation/screens/notifications.screen.dart';
import 'package:app/src/features/shell/screens/mon_peya_my_services.screen.dart';
import 'package:app/src/features/shell/services/module_launcher.service.dart';
import 'package:app/src/core/modules/widgets/module.icon.dart';
import 'package:app/src/features/shell/widgets/main_bottom_navigation_bar.widget.dart';
import 'package:app/src/integration/adapters/peyapay_host.adapter.dart';
import 'package:peyapay/peyapay.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  bool _showBalance = false;
  int? _balanceSolde;
  bool _loadingBalance = false;
  String _clientTitle = PeyapayProfileDisplay.guestLabel;
  String _clientInitials = 'UT';

  late final AnimationController _enter;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _miniFade;
  late final Animation<Offset> _miniSlide;
  late final Animation<double> _newsHeaderFade;
  late final Animation<Offset> _newsHeaderSlide;
  late final Animation<double> _newsFade;
  late final Animation<Offset> _newsSlide;
  late final Animation<double> _servicesHeaderFade;
  late final Animation<Offset> _servicesHeaderSlide;
  late final Animation<double> _servicesFade;
  late final Animation<Offset> _servicesSlide;

  static Animation<double> _fade(AnimationController c, double begin, double end) {
    return CurvedAnimation(
      parent: c,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );
  }

  static Animation<Offset> _slide(AnimationController c, double begin, double end) {
    return Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: c,
        curve: Interval(begin, end, curve: Curves.easeOutCubic),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _headerFade = _fade(_enter, 0.00, 0.34);
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _enter,
        curve: const Interval(0.00, 0.34, curve: Curves.easeOutCubic),
      ),
    );
    _miniFade = _fade(_enter, 0.16, 0.48);
    _miniSlide = _slide(_enter, 0.16, 0.48);
    _newsHeaderFade = _fade(_enter, 0.28, 0.58);
    _newsHeaderSlide = _slide(_enter, 0.28, 0.58);
    _newsFade = _fade(_enter, 0.36, 0.68);
    _newsSlide = _slide(_enter, 0.36, 0.68);
    _servicesHeaderFade = _fade(_enter, 0.46, 0.78);
    _servicesHeaderSlide = _slide(_enter, 0.46, 0.78);
    _servicesFade = _fade(_enter, 0.54, 0.90);
    _servicesSlide = _slide(_enter, 0.54, 0.90);

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

  void _showHomeActionSnack(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label : bientôt.')),
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const hPad = 16.0;
    final backgroundColor = cs.brightness == Brightness.dark
        ? const Color(0xFF0F0F0F)
        : const Color(0xFFF4F6F9);
    final modules = ModuleRepository.modules;

    return ListenableBuilder(
      listenable: MonPeyaSession.instance,
      builder: (context, _) {
        return ColoredBox(
          color: backgroundColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HomeEnter(
                fade: _headerFade,
                slide: _headerSlide,
                child: _HomeHeader(
                  sessionActive: MonPeyaSession.instance.isSessionActive,
                  clientTitle: _clientTitle,
                  clientInitials: _clientInitials,
                  showBalance: _showBalance,
                  balanceSolde: _balanceSolde,
                  loadingBalance: _loadingBalance,
                  formatFcfa: _formatFcfa,
                  onToggleBalance: _toggleBalanceVisibility,
                  onPressProfile: () =>
                      rootNavKey.currentState?.pushNamed(Routes.settings),
                  onPressNotifications: _openNotifications,
                  onShowQr: _openMyQrCode,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    hPad,
                    16,
                    hPad,
                    MainBottomNavigationBar.contentBottomPadding(context),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HomeEnter(
                        fade: _miniFade,
                        slide: _miniSlide,
                        child: _MonPeyaMiniCard(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  const MonPeyaMyServicesScreen(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _HomeEnter(
                        fade: _newsHeaderFade,
                        slide: _newsHeaderSlide,
                        child: _SectionHeader(
                          title: 'Actualités',
                          actionLabel: 'Voir tout',
                          onAction: () =>
                              _showHomeActionSnack(context, 'Actualités'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _HomeEnter(
                          fade: _newsFade,
                          slide: _newsSlide,
                          child: const _HorizontalNewsCarousel(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _HomeEnter(
                        fade: _servicesHeaderFade,
                        slide: _servicesHeaderSlide,
                        child: _SectionHeader(
                          title: 'Mes services',
                          actionLabel:
                              '${modules.length} disponible${modules.length > 1 ? 's' : ''}',
                        ),
                      ),
                      const SizedBox(height: 8),
                      _HomeEnter(
                        fade: _servicesFade,
                        slide: _servicesSlide,
                        child: _ServiceGrid(
                          modules: modules,
                          onOpen: _openModule,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Fade + slide entrance used by home sections.
class _HomeEnter extends StatelessWidget {
  const _HomeEnter({
    required this.fade,
    required this.slide,
    required this.child,
  });

  final Animation<double> fade;
  final Animation<Offset> slide;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: child,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HOME HEADER  (top bar + inset balance card with live QR)
// ═══════════════════════════════════════════════════════════════════════════

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.sessionActive,
    required this.clientTitle,
    required this.clientInitials,
    required this.showBalance,
    required this.balanceSolde,
    required this.loadingBalance,
    required this.formatFcfa,
    required this.onToggleBalance,
    required this.onPressProfile,
    required this.onPressNotifications,
    required this.onShowQr,
  });

  final bool sessionActive;
  final String clientTitle;
  final String clientInitials;
  final bool showBalance;
  final int? balanceSolde;
  final bool loadingBalance;
  final String Function(double) formatFcfa;
  final VoidCallback onToggleBalance;
  final VoidCallback onPressProfile;
  final VoidCallback onPressNotifications;
  final Future<void> Function() onShowQr;

  static const _balanceGreen = Color(0xFF006D56);

  String _balanceAmountText() {
    if (!sessionActive || !showBalance) return '*****';
    if (loadingBalance && balanceSolde == null) return '...';
    if (balanceSolde == null) return '*****';
    return formatFcfa(balanceSolde!.toDouble());
  }

  bool get _showFcfaSuffix =>
      sessionActive && showBalance && balanceSolde != null && !loadingBalance;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(top: peyapayStatusBarTop(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 78,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onPressProfile,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? Colors.white.withOpacity(0.12)
                            : const Color(0xFF006D56).withOpacity(0.12),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withOpacity(0.2)
                              : const Color(0xFF006D56).withOpacity(0.25),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          clientInitials,
                          style: TextStyle(
                            color: isDark ? Colors.white : _balanceGreen,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Bienvenue $clientTitle',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onPressNotifications,
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            color: cs.onSurface,
                            size: 24,
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF5252),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Container(
            margin: const EdgeInsets.fromLTRB(20, 6, 20, 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: _balanceGreen,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Solde actuel',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color.fromRGBO(255, 255, 255, 0.92),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: onToggleBalance,
                            child: Icon(
                              showBalance
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.white.withOpacity(0.85),
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: onToggleBalance,
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Flexible(
                              child: Text(
                                _balanceAmountText(),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            if (_showFcfaSuffix) ...[
                              const SizedBox(width: 6),
                              const Padding(
                                padding: EdgeInsets.only(bottom: 4),
                                child: Text(
                                  'XOF',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                PeyapayWalletQrThumb(
                  size: 96,
                  fillFactor: 0.95,
                  sessionActive: sessionActive,
                  onTap: onShowQr,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MON PEYA MINI CARD
// ═══════════════════════════════════════════════════════════════════════════

class _MonPeyaMiniCard extends StatelessWidget {
  const _MonPeyaMiniCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : const Color(0xFFEEEEEE),
            ),
          ),
          child: Row(
            children: [
              Image.asset(
                isDark ? AssetPaths.logoDark : AssetPaths.logo,
                height: 38,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mon espace personnel',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      'Paramètres, profil & préférences',
                      style: TextStyle(
                        fontSize: 10,
                        color: cs.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: cs.onSurface.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SECTION HEADER
// ═══════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: cs.onSurface,
              letterSpacing: -0.3,
            ),
          ),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF006D56).withOpacity(0.8),
              ),
            ),
          ),
      ],
    );
  }
}



class _HorizontalNewsCarousel extends StatefulWidget {
  const _HorizontalNewsCarousel();

  @override
  State<_HorizontalNewsCarousel> createState() =>
      _HorizontalNewsCarouselState();
}

class _HorizontalNewsCarouselState extends State<_HorizontalNewsCarousel> {
  final _controller = ScrollController();
  int _activeIndex = 0;

  static const _items = [
    (
      title: 'TukShopp Campus Connect',
      subtitle: 'Événement • Jeux • Cadeaux',
      imageAsset: 'assets/images/ad-1.jpg',
      badge: 'Événement',
      color: Color(0xFF1A237E),
    ),
    (
      title: 'Essence Academy',
      subtitle: 'Formations • Figma • Canva',
      imageAsset: 'assets/images/ad-2.jpg',
      badge: 'Formation',
      color: Color(0xFF1B5E20),
    ),
    (
      title: 'GEN Z FEST 2026',
      subtitle: 'Hangout • Music • Games',
      imageAsset: 'assets/images/ad-1.jpg',
      badge: 'Festival',
      color: Color(0xFF4A148C),
    ),
    (
      title: 'Exploration 2026',
      subtitle: 'Conférence • Youth Festival',
      imageAsset: 'assets/images/ad-2.jpg',
      badge: 'Conférence',
      color: Color(0xFF004D40),
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const cardWidth = 240.0;
    const cardGap = 12.0;

    return Column(
      children: [
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n is ScrollUpdateNotification) {
                final idx =
                    (_controller.offset / (cardWidth + cardGap)).round();
                if (idx != _activeIndex) setState(() => _activeIndex = idx);
              }
              return false;
            },
            child: ListView.separated(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              clipBehavior: Clip.none,
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(width: cardGap),
              itemBuilder: (context, index) {
                final item = _items[index];
                return SizedBox(
                  width: cardWidth,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          item.imageAsset,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: item.color,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                item.color.withOpacity(0.15),
                                item.color.withOpacity(0.85),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  item.badge.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                item.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                item.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _items.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _activeIndex ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == _activeIndex
                    ? const Color(0xFF006D56)
                    : const Color(0xFF006D56).withOpacity(0.25),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SERVICE GRID  (fixed 2 rows, no horizontal slide)
// ═══════════════════════════════════════════════════════════════════════════

class _ServiceGrid extends StatelessWidget {
  const _ServiceGrid({
    required this.modules,
    required this.onOpen,
  });

  final List<AppModule> modules;
  final ValueChanged<AppModule> onOpen;

  static const _columns = 4;
  static const _tileHeight = 112.0;

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
      physics: const NeverScrollableScrollPhysics(),
      itemCount: modules.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _columns,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        mainAxisExtent: _tileHeight,
      ),
      itemBuilder: (context, index) {
        return _ServiceTile(
          module: modules[index],
          iconBoxHeight: _tileHeight,
          onTap: () => onOpen(modules[index]),
        );
      },
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.module,
    required this.onTap,
    this.iconBoxHeight = 112,
  });

  final AppModule module;
  final VoidCallback onTap;
  final double iconBoxHeight;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasAsset = moduleIconAsset(
          moduleKey: module.moduleKey,
          iconKey: module.icon,
        ) !=
        null;
    final iconSize = hasAsset ? 40.0 : 34.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: iconBoxHeight,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.08)
              : const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
        child: Column(
          children: [
            ModuleIcon.forModule(
              module,
              size: iconSize,
              color: cs.onSurface,
            ),
            const Spacer(),
            Text(
              module.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
