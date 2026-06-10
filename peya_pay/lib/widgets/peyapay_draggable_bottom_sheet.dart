import 'package:flutter/material.dart';

/// Full-width draggable bottom sheet overlay (RN-style action sheet).
class PeyapayDraggableBottomSheet extends StatefulWidget {
  const PeyapayDraggableBottomSheet({
    super.key,
    required this.onDismiss,
    required this.heightFactor,
    required this.child,
  });

  final VoidCallback onDismiss;
  final double heightFactor;
  final Widget child;

  @override
  PeyapayDraggableBottomSheetState createState() => PeyapayDraggableBottomSheetState();
}

class PeyapayDraggableBottomSheetState extends State<PeyapayDraggableBottomSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;
  double _dragOffset = 0;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..forward();
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  /// Animate closed, then invoke [onDismiss].
  Future<void> dismiss() => _requestDismiss();

  Future<void> _requestDismiss() async {
    if (_isDismissing) return;
    _isDismissing = true;
    await _enter.reverse();
    if (mounted) widget.onDismiss();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset = (_dragOffset + details.delta.dy).clamp(0.0, 500.0);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final sheetH = _sheetHeight(context);
    final velocity = details.velocity.pixelsPerSecond.dy;
    if (_dragOffset > sheetH * 0.18 || velocity > 650) {
      _requestDismiss();
      return;
    }
    setState(() => _dragOffset = 0);
  }

  double _sheetHeight(BuildContext context) {
    final screenH = MediaQuery.sizeOf(context).height;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return (screenH - keyboard) * widget.heightFactor;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sheetH = _sheetHeight(context);
    final dragProgress = sheetH <= 0 ? 0.0 : (_dragOffset / sheetH).clamp(0.0, 1.0);

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _enter,
        builder: (context, _) {
          final enter = Curves.easeOutCubic.transform(_enter.value);
          final backdropOpacity = 0.5 * enter * (1 - dragProgress * 0.85);
          final slideY = (1 - enter) * sheetH + _dragOffset;

          return Stack(
            children: [
              GestureDetector(
                onTap: _requestDismiss,
                behavior: HitTestBehavior.opaque,
                child: ColoredBox(color: Colors.black.withValues(alpha: backdropOpacity)),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Transform.translate(
                  offset: Offset(0, slideY),
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      height: sheetH,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 16,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          GestureDetector(
                            onVerticalDragUpdate: _onDragUpdate,
                            onVerticalDragEnd: _onDragEnd,
                            behavior: HitTestBehavior.translucent,
                            child: PeyapayBottomSheetHandle(color: cs.outlineVariant),
                          ),
                          Expanded(child: widget.child),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class PeyapayBottomSheetHandle extends StatelessWidget {
  const PeyapayBottomSheetHandle({this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final handleColor = color ?? Theme.of(context).colorScheme.outlineVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: handleColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
