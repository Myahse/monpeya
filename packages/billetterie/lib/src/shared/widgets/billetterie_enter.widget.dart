import 'package:flutter/material.dart';

/// Shared fade + slide entrance for Billetterie screens.
class BilletterieEnter extends StatelessWidget {
  const BilletterieEnter({
    super.key,
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
