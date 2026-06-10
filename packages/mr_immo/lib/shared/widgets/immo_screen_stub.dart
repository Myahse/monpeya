import 'package:flutter/material.dart';

/// Placeholder while porting a screen from the React Native Mr Immo app.
class ImmoScreenStub extends StatelessWidget {
  const ImmoScreenStub({
    super.key,
    required this.appName,
    required this.screenPath,
    required this.primaryColor,
    this.features = const [],
    this.footer,
  });

  final String appName;
  final String screenPath;
  final Color primaryColor;
  final List<String> features;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text(
            appName,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            screenPath,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.phone_iphone, color: primaryColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Écran Flutter — portage depuis mobile/expo-apps',
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
          if (features.isNotEmpty) ...[
            const SizedBox(height: 18),
            for (final f in features)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.circle, size: 6, color: primaryColor),
                    const SizedBox(width: 8),
                    Expanded(child: Text(f, style: const TextStyle(fontSize: 13))),
                  ],
                ),
              ),
          ],
          if (footer != null) ...[
            const SizedBox(height: 20),
            footer!,
          ],
        ],
      ),
    );
  }
}

/// Scaffold wrapper for stack overlays (detail screens, wizards).
class ImmoOverlayScreen extends StatelessWidget {
  const ImmoOverlayScreen({
    super.key,
    required this.title,
    required this.primaryColor,
    required this.onBack,
    required this.body,
  });

  final String title;
  final Color primaryColor;
  final VoidCallback onBack;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack),
        title: Text(title),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: body,
    );
  }
}
