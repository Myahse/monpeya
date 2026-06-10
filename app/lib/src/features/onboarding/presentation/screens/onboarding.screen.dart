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
 
    await prefs.setBool(PrefsKeys.isRegistered, false);
    await prefs.setString(PrefsKeys.phoneNumber, '');
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(Routes.app);
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_index];
    final bgImage = AssetPaths.onboardingImages[_index % AssetPaths.onboardingImages.length];
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full top background that matches current slide.
          Positioned.fill(
            child: ClipRect(
              child: FittedBox(
                fit: BoxFit.cover,
                alignment: Alignment.center,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  child: Image.asset(bgImage, fit: BoxFit.cover),
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

          // Card carousel (rectangular cards, positioned lower, no border frame).
          Align(
            alignment: Alignment.topCenter,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 230),
                child: SizedBox(
                  height: 360,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _slides.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) {
                      final img = AssetPaths.onboardingImages[i % AssetPaths.onboardingImages.length];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: Center(
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.65,
                            height: 360,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: DecoratedBox(
                                decoration: const BoxDecoration(color: Colors.transparent),
                                child: Image.asset(img, fit: BoxFit.cover),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
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

