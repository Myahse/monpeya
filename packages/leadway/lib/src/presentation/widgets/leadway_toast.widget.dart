import 'package:flutter/material.dart';

enum LeadwayToastType { success, error, info }

class LeadwayToast extends StatefulWidget {
  const LeadwayToast({
    super.key,
    required this.message,
    required this.type,
    required this.onDismiss,
    this.duration = const Duration(seconds: 3),
  });

  final String message;
  final LeadwayToastType type;
  final VoidCallback onDismiss;
  final Duration duration;

  static void show(
    BuildContext context, {
    required String message,
    required LeadwayToastType type,
    Duration? duration,
  }) {
    final resolvedDuration = duration ??
        (type == LeadwayToastType.error
            ? const Duration(seconds: 5)
            : const Duration(seconds: 3));
    final overlayState = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: Align(
          alignment: Alignment.topCenter,
          child: LeadwayToast(
            message: message,
            type: type,
            duration: resolvedDuration,
            onDismiss: () {
              entry.remove();
            },
          ),
        ),
      ),
    );

    overlayState.insert(entry);
  }

  @override
  State<LeadwayToast> createState() => _LeadwayToastState();
}

class _LeadwayToastState extends State<LeadwayToast> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();

    Future.delayed(widget.duration - const Duration(milliseconds: 250), () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon = switch (widget.type) {
      LeadwayToastType.success => const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20),
      LeadwayToastType.error => const Icon(Icons.cancel, color: Color(0xFFEF4444), size: 20),
      LeadwayToastType.info => const Icon(Icons.info, color: Color(0xFF3B82F6), size: 20),
    };

    final borderThemeColor = switch (widget.type) {
      LeadwayToastType.success => const Color(0xFF10B981).withValues(alpha: 0.15),
      LeadwayToastType.error => const Color(0xFFEF4444).withValues(alpha: 0.15),
      LeadwayToastType.info => const Color(0xFF3B82F6).withValues(alpha: 0.15),
    };

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderThemeColor, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: icon,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    widget.message,
                    softWrap: true,
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    _controller.reverse().then((_) => widget.onDismiss());
                  },
                  child: Icon(Icons.close, color: Colors.grey.shade400, size: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
