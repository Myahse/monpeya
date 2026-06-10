import 'package:flutter/material.dart';

/// Design tokens passed from Flutter into embedded web modules.
class ModuleShellTheme {
  const ModuleShellTheme({
    required this.primary,
    required this.background,
    required this.foreground,
    required this.isDark,
    required this.safeTop,
    required this.safeBottom,
  });

  final String primary;
  final String background;
  final String foreground;
  final bool isDark;
  final double safeTop;
  final double safeBottom;

  factory ModuleShellTheme.fromContext(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final padding = MediaQuery.paddingOf(context);
    return ModuleShellTheme(
      primary: _hex(cs.primary),
      background: _hex(cs.surface),
      foreground: _hex(cs.onSurface),
      isDark: Theme.of(context).brightness == Brightness.dark,
      safeTop: padding.top,
      safeBottom: padding.bottom + 24,
    );
  }

  Map<String, String> get queryParams => {
        'themePrimary': primary,
        'themeBg': background,
        'themeFg': foreground,
        'themeDark': isDark ? '1' : '0',
        'safeTop': safeTop.toStringAsFixed(1),
        'safeBottom': safeBottom.toStringAsFixed(1),
      };

  String get cssVariables => '''
    --shell-primary: $primary;
    --shell-bg: $background;
    --shell-fg: $foreground;
    --shell-safe-top: ${safeTop}px;
    --shell-safe-bottom: ${safeBottom}px;
  ''';

  static String _hex(Color c) {
    final r = (c.r * 255).round();
    final g = (c.g * 255).round();
    final b = (c.b * 255).round();
    return '#${(r << 16 | g << 8 | b).toRadixString(16).padLeft(6, '0')}';
  }
}
