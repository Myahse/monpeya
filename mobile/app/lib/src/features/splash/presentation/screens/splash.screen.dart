import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/src/core/assets/constants/asset.paths.dart';
import 'package:app/src/core/routing/routes.dart';
import 'package:app/src/core/storage/constants/prefs.keys.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  static const routeName = '/splash';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fade = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool(PrefsKeys.seenOnboarding) ?? false;
    if (!mounted) return;
    if (!seenOnboarding) {
      Navigator.of(context).pushReplacementNamed(Routes.onboarding);
      return;
    }

    Navigator.of(context).pushReplacementNamed(Routes.app);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: Image.asset(
            isDark ? AssetPaths.logoDark : AssetPaths.logo,
            width: 220,
            height: 220,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
