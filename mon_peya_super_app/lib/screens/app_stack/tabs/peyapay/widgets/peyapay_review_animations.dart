import 'package:flutter/material.dart';

/// Shared entrance animations for review / verify payment screens.
class PeyapayReviewEntranceAnimations {
  PeyapayReviewEntranceAnimations(AnimationController controller)
      : leftSlide = Tween<Offset>(
          begin: const Offset(-0.22, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: controller,
            curve: const Interval(0.0, 0.52, curve: Curves.easeOutCubic),
          ),
        ),
        rightSlide = Tween<Offset>(
          begin: const Offset(0.22, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: controller,
            curve: const Interval(0.06, 0.58, curve: Curves.easeOutCubic),
          ),
        ),
        arrowFade = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: controller,
            curve: const Interval(0.32, 0.72, curve: Curves.easeOut),
          ),
        ),
        circleScale = Tween<double>(begin: 0.88, end: 1).animate(
          CurvedAnimation(
            parent: controller,
            curve: const Interval(0.32, 0.72, curve: Curves.easeOutCubic),
          ),
        ),
        sheetSlide = Tween<Offset>(
          begin: const Offset(0, 0.14),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: controller,
            curve: const Interval(0.42, 1.0, curve: Curves.easeOutCubic),
          ),
        ),
        sheetFade = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: controller,
            curve: const Interval(0.42, 0.88, curve: Curves.easeOut),
          ),
        );

  final Animation<Offset> leftSlide;
  final Animation<Offset> rightSlide;
  final Animation<double> arrowFade;
  final Animation<double> circleScale;
  final Animation<Offset> sheetSlide;
  final Animation<double> sheetFade;

  static const entranceDuration = Duration(milliseconds: 560);
  static const exitDuration = Duration(milliseconds: 260);
}

/// Slide-up route — avoids the harsh default fullscreen-dialog zoom.
Route<bool> peyapayReviewTransferRoute(Widget screen) {
  return PageRouteBuilder<bool>(
    fullscreenDialog: true,
    opaque: true,
    barrierDismissible: false,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: PeyapayReviewEntranceAnimations.exitDuration,
    pageBuilder: (context, animation, secondaryAnimation) => screen,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.035),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
