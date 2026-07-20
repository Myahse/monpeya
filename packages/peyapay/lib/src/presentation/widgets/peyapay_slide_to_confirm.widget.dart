import 'dart:async';

import 'package:flutter/material.dart';

/// Round slide-to-confirm control with animated direction hints.
class PeyapaySlideToConfirm extends StatefulWidget {
  const PeyapaySlideToConfirm({
    super.key,
    required this.enabled,
    required this.label,
    required this.onCompleted,
    this.background,
    this.foreground,
    this.textColor,
  });

  static const height = 56.0;

  final bool enabled;
  final String label;
  final Future<void> Function() onCompleted;
  final Color? background;
  final Color? foreground;
  final Color? textColor;

  @override
  State<PeyapaySlideToConfirm> createState() => _PeyapaySlideToConfirmState();
}

class _PeyapaySlideToConfirmState extends State<PeyapaySlideToConfirm>
    with SingleTickerProviderStateMixin {
  static const _thumb = 44.0;
  static const _inset = 6.0;
  static const _completeThreshold = 0.88;

  double _dragX = 0;
  double _trackTravel = 0;
  bool _done = false;
  bool _committed = false;

  late final AnimationController _snap;
  Animation<double>? _snapAnim;

  @override
  void initState() {
    super.initState();
    _snap = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
    _snap.addListener(() {
      if (!mounted || _snapAnim == null) return;
      setState(() => _dragX = _snapAnim!.value);
    });
  }

  @override
  void dispose() {
    _snap.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PeyapaySlideToConfirm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && oldWidget.enabled && !_committed && !_done) {
      unawaited(_resetToStart(animate: _dragX > 0));
    }
  }

  Future<void> _animateTo(double target) {
    _snapAnim = Tween<double>(begin: _dragX, end: target).animate(
      CurvedAnimation(parent: _snap, curve: Curves.easeOutCubic),
    );
    return _snap.forward(from: 0);
  }

  Future<void> _resetToStart({bool animate = false}) async {
    _snap.stop();
    if (animate && _dragX > 0) {
      await _animateTo(0);
    }
    if (!mounted) return;
    setState(() {
      _dragX = 0;
      _committed = false;
      _done = false;
    });
  }

  void _onDragUpdate(double delta, double travel) {
    if (!_committed && !_done) {
      _snap.stop();
      setState(() => _dragX = (_dragX + delta).clamp(0, travel));
    }
  }

  Future<void> _onDragEnd(double travel) async {
    if (_committed || _done) return;

    if (_dragX >= travel * _completeThreshold) {
      _committed = true;
      await _animateTo(travel);
      if (!mounted) return;
      setState(() {
        _dragX = travel;
        _trackTravel = travel;
        _done = true;
      });
      unawaited(
        widget.onCompleted().catchError((Object _) async {
          if (!mounted) return;
          await _resetToStart(animate: true);
        }),
      );
    } else {
      await _animateTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackColor = widget.background ?? (isDark ? Colors.black : const Color(0xFF111827));
    final hintColor = widget.textColor ?? Colors.white;
    final thumbFill = widget.foreground ?? (isDark ? Colors.black : const Color(0xFF374151));
    final thumbBorderColor = isDark ? Colors.white.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.35);
    final trackBorderColor = isDark ? Colors.white.withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.12);
    final radius = BorderRadius.circular(PeyapaySlideToConfirm.height / 2);
    final interactive = widget.enabled && !_committed && !_done;

    return SizedBox(
      height: PeyapaySlideToConfirm.height,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final travel = (constraints.maxWidth - _thumb - (_inset * 2)).clamp(0.0, double.infinity);
          final effectiveTravel = _done ? _trackTravel : travel;
          final x = _dragX.clamp(0.0, effectiveTravel > 0 ? effectiveTravel : travel);
          final denom = effectiveTravel > 0 ? effectiveTravel : travel;
          final progress = denom <= 0 ? 0.0 : (x / denom).clamp(0.0, 1.0);

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: interactive
                ? (details) => _onDragUpdate(details.delta.dx, travel)
                : null,
            onHorizontalDragEnd: interactive ? (_) => unawaited(_onDragEnd(travel)) : null,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: trackColor,
                borderRadius: radius,
                border: Border.all(color: trackBorderColor, width: 1),
              ),
              child: ClipRRect(
                borderRadius: radius,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: _thumb + (_inset * 2), right: 12),
                      child: Center(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 120),
                          opacity: interactive ? (1.0 - progress * 0.75) : 0,
                          child: Text(
                            widget.label,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: hintColor.withValues(alpha: 0.72),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (interactive && progress < 0.25)
                      Positioned.fill(
                        left: _thumb + (_inset * 2),
                        right: 12,
                        child: IgnorePointer(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              4,
                              (i) => Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 1),
                                child: Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18,
                                  color: hintColor.withValues(alpha: 0.45),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      left: _inset + x,
                      top: 0,
                      bottom: 0,
                      width: _thumb,
                      child: Center(
                        child: IgnorePointer(
                          child: Container(
                            width: _thumb,
                            height: _thumb,
                            decoration: BoxDecoration(
                              color: thumbFill,
                              shape: BoxShape.circle,
                              border: Border.all(color: thumbBorderColor, width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              _done ? Icons.check_rounded : Icons.chevron_right_rounded,
                              color: hintColor.withValues(alpha: 0.95),
                              size: _done ? 22 : 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
