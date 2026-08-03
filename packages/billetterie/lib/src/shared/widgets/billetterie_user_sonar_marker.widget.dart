import 'package:flutter/material.dart';

/// Animated sonar marker for the user's position on billetterie maps.
class BilletterieUserSonarMarker extends StatefulWidget {
  const BilletterieUserSonarMarker({super.key, required this.color});

  final Color color;

  @override
  State<BilletterieUserSonarMarker> createState() =>
      _BilletterieUserSonarMarkerState();
}

class _BilletterieUserSonarMarkerState extends State<BilletterieUserSonarMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              for (final phase in const [0.0, 0.45]) _sonarRing(t, phase),
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.45),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sonarRing(double t, double phase) {
    final raw = (t + phase) % 1.0;
    final scale = 0.35 + raw * 0.9;
    final opacity = (1.0 - raw).clamp(0.0, 1.0) * 0.55;
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: opacity),
        ),
      ),
    );
  }
}
