import 'package:flutter/material.dart';

/// Slide-to-confirm control with smooth snap-back animation.
class PeyapaySlideToConfirm extends StatefulWidget {
  const PeyapaySlideToConfirm({
    super.key,
    required this.enabled,
    required this.label,
    required this.onCompleted,
    required this.background,
    required this.foreground,
    required this.textColor,
  });

  final bool enabled;
  final String label;
  final Future<void> Function() onCompleted;
  final Color background;
  final Color foreground;
  final Color textColor;

  @override
  State<PeyapaySlideToConfirm> createState() => _PeyapaySlideToConfirmState();
}

class _PeyapaySlideToConfirmState extends State<PeyapaySlideToConfirm>
    with SingleTickerProviderStateMixin {
  static const _h = 54.0;
  static const _thumb = 46.0;

  double _dragX = 0;
  bool _done = false;
  bool _loading = false;

  late final AnimationController _snap;

  @override
  void initState() {
    super.initState();
    _snap = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _snap.addListener(() {
      if (!mounted || _snapAnim == null) return;
      setState(() => _dragX = _snapAnim!.value);
    });
  }

  Animation<double>? _snapAnim;

  @override
  void dispose() {
    _snap.dispose();
    super.dispose();
  }

  Future<void> _animateTo(double target) {
    _snapAnim = Tween<double>(begin: _dragX, end: target).animate(
      CurvedAnimation(parent: _snap, curve: Curves.easeOutCubic),
    );
    return _snap.forward(from: 0);
  }

  Future<void> _finish() async {
    if (_loading || _done) return;
    setState(() => _loading = true);
    await widget.onCompleted();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _done = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final maxLocal = c.maxWidth - _thumb;
        final x = _dragX.clamp(0.0, maxLocal);
        final progress = maxLocal <= 0 ? 0.0 : (x / maxLocal).clamp(0.0, 1.0);

        return AbsorbPointer(
          absorbing: !widget.enabled || _loading || _done,
          child: Container(
            height: _h,
            decoration: BoxDecoration(
              color: widget.background,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 150),
                        opacity: _loading ? 0.0 : (1.0 - progress * 0.65),
                        child: Text(
                          widget.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: widget.textColor.withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress.clamp(0.001, 1.0),
                      child: SizedBox(
                        width: c.maxWidth,
                        child: ColoredBox(color: widget.foreground.withValues(alpha: 0.18)),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: x,
                  top: (_h - _thumb) / 2,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (d) {
                      _snap.stop();
                      setState(() => _dragX = (_dragX + d.delta.dx).clamp(0, maxLocal));
                    },
                    onHorizontalDragEnd: (_) async {
                      if (_dragX >= maxLocal * 0.9) {
                        await _animateTo(maxLocal);
                        await _finish();
                      } else {
                        await _animateTo(0);
                      }
                    },
                    child: Container(
                      width: _thumb,
                      height: _thumb,
                      decoration: BoxDecoration(
                        color: widget.foreground,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: _loading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
