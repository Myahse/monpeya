import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/src/core/assets/constants/asset.paths.dart';
import 'package:app/src/core/routing/routes.dart';
import 'package:app/src/core/storage/constants/prefs.keys.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  static const routeName = '/onboarding';

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  static const _bottomEntranceDelay = Duration(milliseconds: 180);
  static const _bottomEntranceDuration = Duration(milliseconds: 520);

  static const _slides = <({String title, String description})>[
    (
      title: 'Bienvenue sur',
      description: 'Découvrez votre nouvelle application tout en un',
    ),
    (
      title: 'Services multiples',
      description: 'Accédez à tous vos services préférés en un seul endroit',
    ),
    (
      title: 'Abonnements faciles',
      description: 'Gérez vos abonnements et modules en toute simplicité',
    ),
    (
      title: 'Prêt à commencer',
      description: 'Rejoignez la communauté NTERI dès maintenant',
    ),
  ];

  late final PageController _pageController;
  late final AnimationController _bottomController;
  late final Animation<double> _bottomOpacity;
  late final Animation<double> _bottomTranslateY;

  int _index = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _bottomController = AnimationController(
      vsync: this,
      duration: _bottomEntranceDuration,
    );
    _bottomOpacity = CurvedAnimation(parent: _bottomController, curve: Curves.easeOut);
    _bottomTranslateY = Tween<double>(begin: 24, end: 0).animate(
      CurvedAnimation(parent: _bottomController, curve: Curves.easeOutCubic),
    );

    Future<void>.delayed(_bottomEntranceDelay, () {
      if (mounted) _bottomController.forward();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bottomController.dispose();
    super.dispose();
  }

  void _goTo(int next) {
    final clamped = (next % _slides.length + _slides.length) % _slides.length;
    _pageController.animateToPage(
      clamped,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _handleStart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefsKeys.seenOnboarding, true);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(Routes.app);
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_index];
    final art = _SlideArt.slides[_index % _SlideArt.slides.length];
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mq = MediaQuery.of(context);
    final topInset = mq.viewPadding.top;
    final bottomInset = mq.viewPadding.bottom;
    final screenH = mq.size.height;
    final screenW = mq.size.width;

    const bottomContentHeight = 210.0;
    final bottomReserved = bottomContentHeight + bottomInset + 20;
    final cardTop = topInset + (screenH * 0.24).clamp(80.0, 150.0);
    final cardHeight = (screenH - cardTop - bottomReserved).clamp(200.0, 360.0);
    final cardWidth = (screenW * 0.65).clamp(220.0, 320.0);

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full top background that matches current slide.
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: art.colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // Slight dark overlay in dark mode to keep contrast.
          if (isDark)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35)),
              ),
            ),

          // Fade at bottom (like the RN LinearGradient), but theme-aware for dark mode.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    isDark ? const Color(0x00000000) : const Color(0x00FFFFFF),
                    cs.surface,
                    cs.surface,
                  ],
                  stops: const [0.25, 0.65, 1.0],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Card carousel — height adapts so bottom text never overlaps.
          Positioned(
            top: cardTop,
            left: 0,
            right: 0,
            height: cardHeight,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _slides.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Center(
                    child: SizedBox(
                      width: cardWidth,
                      height: cardHeight,
                      child: _SlideArt(
                        data: _SlideArt.slides[i % _SlideArt.slides.length],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: AnimatedBuilder(
                animation: _bottomController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _bottomOpacity.value,
                    child: Transform.translate(
                      offset: Offset(0, _bottomTranslateY.value),
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 0),
                      Transform.translate(
                        offset: const Offset(0, -16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          child: SizedBox(
                            width: double.infinity,
                            height: 100,
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                // Logo sits between title and description.
                                Image.asset(
                                  Theme.of(context).brightness == Brightness.dark
                                      ? AssetPaths.logoDark
                                      : AssetPaths.logo,
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.contain,
                                ),
                                Positioned(
                                  top: 20,
                                  left: 0,
                                  right: 0,
                                  child: Text(
                                    slide.title,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 18,
                                          height: 0.98,
                                          color: cs.onSurface,
                                        ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 10,
                                  left: 0,
                                  right: 0,
                                  child: Text(
                                    slide.description,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontSize: 12.5,
                                          color: isDark ? cs.onSurfaceVariant : Colors.black54,
                                          height: 0.98,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),

                      // Pagination dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < _slides.length; i++)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 8,
                              width: i == _index ? 18 : 8,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? (i == _index ? Colors.white : Colors.white38)
                                    : (i == _index ? Colors.black87 : Colors.black26),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Bottom arrows + start button
                      Row(
                        children: [
                          _ArrowButton(
                            direction: _ArrowDirection.left,
                            onPressed: () => _goTo(_index - 1),
                          ),
                          const Spacer(),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: isDark ? Colors.white : Colors.black87,
                              side: BorderSide(
                                color: isDark ? Colors.white : Colors.black26,
                                width: 1,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _handleStart,
                            child: const Text(
                              'Commencer',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const Spacer(),
                          _ArrowButton(
                            direction: _ArrowDirection.right,
                            onPressed: () => _goTo(_index + 1),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _ArrowDirection { left, right }

class _ArrowButton extends StatefulWidget {
  const _ArrowButton({required this.direction, required this.onPressed});
  final _ArrowDirection direction;
  final VoidCallback onPressed;

  @override
  State<_ArrowButton> createState() => _ArrowButtonState();
}

class _ArrowButtonState extends State<_ArrowButton> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1, end: 0.92).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final icon = widget.direction == _ArrowDirection.left
        ? Icons.chevron_left
        : Icons.chevron_right;
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapCancel: () => _c.reverse(),
      onTapUp: (_) {
        _c.reverse();
        widget.onPressed();
      },
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isDark ? Colors.transparent : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? Colors.white : Colors.black12),
          ),
          child: Icon(icon, color: isDark ? Colors.white : Colors.black87),
        ),
      ),
    );
  }
}

/// Branded slide illustration: gradient card, hero icon and floating
/// service icons that bob gently.
class _SlideArt extends StatefulWidget {
  const _SlideArt({required this.data});

  final ({List<Color> colors, IconData hero, List<IconData> orbit}) data;

  static const slides = <({List<Color> colors, IconData hero, List<IconData> orbit})>[
    (
      colors: [Color(0xFF00876A), Color(0xFF063E1C)],
      hero: Icons.account_balance_wallet_rounded,
      orbit: [Icons.qr_code_2_rounded, Icons.send_rounded, Icons.bolt_rounded, Icons.receipt_long_rounded],
    ),
    (
      colors: [Color(0xFF0EA5E9), Color(0xFF075985)],
      hero: Icons.apps_rounded,
      orbit: [Icons.home_work_rounded, Icons.directions_bus_rounded, Icons.shield_rounded, Icons.storefront_rounded],
    ),
    (
      colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
      hero: Icons.event_repeat_rounded,
      orbit: [Icons.notifications_active_rounded, Icons.check_circle_rounded, Icons.calendar_month_rounded, Icons.star_rounded],
    ),
    (
      colors: [Color(0xFFF59E0B), Color(0xFFB45309)],
      hero: Icons.rocket_launch_rounded,
      orbit: [Icons.groups_rounded, Icons.favorite_rounded, Icons.verified_rounded, Icons.celebration_rounded],
    ),
  ];

  @override
  State<_SlideArt> createState() => _SlideArtState();
}

class _SlideArtState extends State<_SlideArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respect the system "reduce motion" setting.
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 0.5;
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            Color.lerp(d.colors.first, Colors.white, 0.12)!,
            d.colors.last,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: d.colors.last.withValues(alpha: 0.45),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          final h = box.maxHeight;
          const spots = [
            Offset(0.18, 0.2),
            Offset(0.8, 0.24),
            Offset(0.2, 0.78),
            Offset(0.78, 0.74),
          ];
          return AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final t = Curves.easeInOut.transform(_c.value);
              return Stack(
                children: [
                  for (var i = 0; i < d.orbit.length && i < spots.length; i++)
                    Positioned(
                      left: spots[i].dx * w - 24,
                      top: spots[i].dy * h - 24 + (i.isEven ? -8 : 8) * (t - 0.5) * 2,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: Icon(d.orbit[i], color: Colors.white, size: 24),
                      ),
                    ),
                  Center(
                    child: Transform.scale(
                      scale: 0.96 + t * 0.06,
                      child: Container(
                        width: w * 0.42,
                        height: w * 0.42,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(d.hero, size: w * 0.2, color: d.colors.last),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
