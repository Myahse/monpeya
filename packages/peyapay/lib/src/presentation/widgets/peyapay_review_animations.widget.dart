import 'package:flutter/material.dart';

/// Shared entrance animations for review / verify payment screens.
class PeyapayReviewEntranceAnimations {
  PeyapayReviewEntranceAnimations(AnimationController controller)
      : cardsReveal = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: controller,
            curve: const Interval(0.0, 0.58, curve: Curves.easeOutCubic),
          ),
        ),
        arrowFade = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: controller,
            curve: const Interval(0.48, 0.82, curve: Curves.easeOut),
          ),
        ),
        circleScale = Tween<double>(begin: 0.9, end: 1).animate(
          CurvedAnimation(
            parent: controller,
            curve: const Interval(0.48, 0.82, curve: Curves.easeOutCubic),
          ),
        ),
        sheetSlide = Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: controller,
            curve: const Interval(0.38, 1.0, curve: Curves.easeOutCubic),
          ),
        ),
        sheetFade = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: controller,
            curve: const Interval(0.38, 0.86, curve: Curves.easeOut),
          ),
        );

  /// 0 → 1 drives symmetric card slide-in from both sides.
  final Animation<double> cardsReveal;
  final Animation<double> arrowFade;
  final Animation<double> circleScale;
  final Animation<Offset> sheetSlide;
  final Animation<double> sheetFade;

  static const entranceDuration = Duration(milliseconds: 520);
  static const exitDuration = Duration(milliseconds: 240);
}

/// Slide-up route — subtle fade only so card motion stays readable.
Route<bool> peyapayReviewTransferRoute(Widget screen) {
  return PageRouteBuilder<bool>(
    fullscreenDialog: true,
    opaque: true,
    barrierDismissible: false,
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: PeyapayReviewEntranceAnimations.exitDuration,
    pageBuilder: (context, animation, secondaryAnimation) => screen,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return FadeTransition(opacity: curved, child: child);
    },
  );
}
