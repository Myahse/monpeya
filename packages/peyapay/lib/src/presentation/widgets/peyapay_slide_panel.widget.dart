import 'package:flutter/material.dart';

/// Slide-in overlay controllers for PeyaPay dashboard (RN `slideAnim` pattern).
mixin PeyapaySlideOverlayMixin<T extends StatefulWidget> on State<T>, TickerProviderStateMixin<T> {
  late final AnimationController paymentsSlideController;
  late final AnimationController sourceOfFundsSlideController;

  bool showPaymentsServices = false;
  bool showSourceOfFunds = false;

  @override
  void initState() {
    super.initState();
    paymentsSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    sourceOfFundsSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    paymentsSlideController.dispose();
    sourceOfFundsSlideController.dispose();
    super.dispose();
  }

  Future<void> openPaymentsServices() async {
    setState(() => showPaymentsServices = true);
    await paymentsSlideController.forward(from: 0);
  }

  Future<void> closePaymentsServices() async {
    await paymentsSlideController.reverse();
    if (!mounted) return;
    setState(() => showPaymentsServices = false);
  }

  Future<void> openSourceOfFunds() async {
    setState(() => showSourceOfFunds = true);
    await sourceOfFundsSlideController.forward(from: 0);
  }

  Future<void> closeSourceOfFunds() async {
    await sourceOfFundsSlideController.reverse();
    if (!mounted) return;
    setState(() => showSourceOfFunds = false);
  }
}

/// Full-screen panel that slides in from the right (RN `sourceOfFundsContainer`).
class PeyapaySlidePanel extends StatelessWidget {
  const PeyapaySlidePanel({
    super.key,
    required this.animation,
    required this.child,
  });

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final bg = Theme.of(context).colorScheme.surface;
    return Positioned.fill(
      child: SlideTransition(
        position: Tween<Offset>(begin: Offset(1, 0), end: Offset.zero).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOut),
        ),
        child: Material(
          color: bg,
          elevation: 8,
          child: SizedBox(width: w, child: child),
        ),
      ),
    );
  }
}
