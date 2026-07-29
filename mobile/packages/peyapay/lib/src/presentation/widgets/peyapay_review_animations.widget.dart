import 'package:flutter/material.dart';

/// Shared entrance animations for review / verify payment screens.
///
/// Sequence: party cards slide in → center arrow → bottom sheet rises.
class PeyapayReviewEntranceAnimations {
  PeyapayReviewEntranceAnimations(AnimationController controller)
      : cardsReveal = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: controller,
            curve: const Interval(0.0, 0.48, curve: Curves.easeOutCubic),
          ),
        ),
        arrowFade = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: controller,
            curve: const Interval(0.38, 0.52, curve: Curves.easeOut),
          ),
        ),
        circleScale = Tween<double>(begin: 0.75, end: 1).animate(
          CurvedAnimation(
            parent: controller,
            curve: const Interval(0.38, 0.52, curve: Curves.easeOutBack),
          ),
        ),
        sheetSlide = Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: controller,
            curve: const Interval(0.52, 1.0, curve: Curves.easeOutCubic),
          ),
        ),
        sheetFade = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: controller,
            curve: const Interval(0.52, 0.92, curve: Curves.easeOut),
          ),
        );

  /// 0 → 1 drives symmetric card slide-in from both sides.
  final Animation<double> cardsReveal;
  final Animation<double> arrowFade;
  final Animation<double> circleScale;
  final Animation<Offset> sheetSlide;
  final Animation<double> sheetFade;

  static const entranceDuration = Duration(milliseconds: 1000);
  static const exitDuration = Duration(milliseconds: 240);
  static const confirmExitDuration = Duration(milliseconds: 340);
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
