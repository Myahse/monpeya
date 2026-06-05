import 'package:flutter/material.dart';

class AuthFlowScaffold extends StatelessWidget {
  const AuthFlowScaffold({
    super.key,
    required this.logoPath,
    required this.onBack,
    required this.body,
    required this.bottom,
    this.title,
    this.subtitle,
    this.headerBottom,
    this.logoSize = 140,
  });

  final String logoPath;
  final VoidCallback onBack;

  final Widget? title;
  final Widget? subtitle;
  final Widget? headerBottom;

  final Widget body;
  final Widget bottom;

  final double logoSize;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
    const keyboardGap = 14.0;

    return Scaffold(
      backgroundColor: cs.surface,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              child: InkWell(
                onTap: onBack,
                borderRadius: BorderRadius.circular(999),
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: Icon(Icons.chevron_left, size: 28),
                ),
              ),
            ),
            // Scrollable content (so small heights / keyboard never overflow).
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  24,
                  18,
                  24,
                  // Reserve room for bottom CTA + keyboard.
                  96 + viewInsetsBottom + keyboardGap,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 36),
                    Center(
                      child: Image.asset(
                        logoPath,
                        width: logoSize,
                        height: logoSize,
                        fit: BoxFit.contain,
                      ),
                    ),
                    if (title != null) ...[
                      const SizedBox(height: 8),
                      DefaultTextStyle(
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: cs.onSurface,
                        ),
                        textAlign: TextAlign.center,
                        child: title!,
                      ),
                    ],
                    if (subtitle != null) ...[
                      const SizedBox(height: 8),
                      DefaultTextStyle(
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurfaceVariant,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                        child: subtitle!,
                      ),
                    ],
                    if (headerBottom != null) ...[
                      const SizedBox(height: 16),
                      headerBottom!,
                    ] else ...[
                      const SizedBox(height: 16),
                    ],
                    body,
                  ],
                ),
              ),
            ),
            // Floating bottom CTA above keyboard.
            Positioned(
              left: 24,
              right: 24,
              bottom: 0,
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(bottom: viewInsetsBottom + keyboardGap),
                child: SafeArea(top: false, child: bottom),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

