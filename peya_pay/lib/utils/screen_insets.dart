import 'package:flutter/material.dart';

/// Top inset for edge-to-edge layouts — keeps headers below the status bar.
double peyapayStatusBarTop(BuildContext context) => MediaQuery.viewPaddingOf(context).top;

/// Spacer matching the status bar / notch height.
class PeyapayStatusBarSpacer extends StatelessWidget {
  const PeyapayStatusBarSpacer({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(height: peyapayStatusBarTop(context));
}
