import 'package:flutter/material.dart';
import '../../app/assets/asset_paths.dart';
import '../../app/routing/routes.dart';

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
    // Match RN timing: fade in (1000ms) and keep splash visible (~2500ms total).
    await Future<void>.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    // RN behavior: always go to Onboarding after Splash.
    Navigator.of(context).pushReplacementNamed(Routes.onboarding);
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

