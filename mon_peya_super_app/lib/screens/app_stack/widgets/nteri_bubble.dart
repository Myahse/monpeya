import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_stack_scope.dart';
import 'nteri_menu_sheet.dart';

/// Draggable N'TERI bubble — tap to expand menu from the bubble.
class NteriBubble extends StatefulWidget {
  const NteriBubble({
    super.key,
    required this.expanded,
    required this.activeRouteName,
    this.currentModuleKey,
  });

  static const double size = 56;
  static const double margin = 16;
  static const double panelGap = 10;

  final bool expanded;
  final String activeRouteName;
  final String? currentModuleKey;

  @override
  State<NteriBubble> createState() => _NteriBubbleState();
}

class _NteriBubbleState extends State<NteriBubble> with SingleTickerProviderStateMixin {
  static const _prefsX = 'nteriBubbleX';
  static const _prefsY = 'nteriBubbleY';
  static const _bubbleColor = Color(0xFF1A1A1A);

  late final AnimationController _expandCtrl;
  late final Animation<double> _expandAnim;

  Offset? _position;
  var _isDragging = false;
  var _dragMoved = false;

  @override
  void initState() {
    super.initState();
    _expandCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnim = CurvedAnimation(parent: _expandCtrl, curve: Curves.easeOutCubic);
    if (widget.expanded) _expandCtrl.value = 1;
    _loadPosition();
  }

  @override
  void didUpdateWidget(NteriBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync from current props only (hot-reload safe).
    if (widget.expanded) {
      if (_expandCtrl.status != AnimationStatus.forward &&
          _expandCtrl.status != AnimationStatus.completed) {
        _expandCtrl.forward();
      }
    } else {
      if (_expandCtrl.status != AnimationStatus.reverse &&
          _expandCtrl.status != AnimationStatus.dismissed) {
        _expandCtrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _expandCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final x = prefs.getDouble(_prefsX);
    final y = prefs.getDouble(_prefsY);
    if (!mounted) return;
    if (x != null && y != null) {
      setState(() => _position = Offset(x, y));
    }
  }

  Future<void> _savePosition(Offset position) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefsX, position.dx);
    await prefs.setDouble(_prefsY, position.dy);
  }

  Rect _bounds(BuildContext context) {
    final media = MediaQuery.of(context);
    return Rect.fromLTWH(
      NteriBubble.margin,
      media.padding.top + NteriBubble.margin,
      media.size.width - (NteriBubble.margin * 2) - NteriBubble.size,
      media.size.height -
          media.padding.top -
          media.padding.bottom -
          (NteriBubble.margin * 2) -
          NteriBubble.size,
    );
  }

  Offset _defaultPosition(BuildContext context) {
    final bounds = _bounds(context);
    return Offset(bounds.right, bounds.bottom);
  }

  Offset _clamp(Offset position, BuildContext context) {
    final bounds = _bounds(context);
    return Offset(
      position.dx.clamp(bounds.left, bounds.right),
      position.dy.clamp(bounds.top, bounds.bottom),
    );
  }

  Offset _resolvedPosition(BuildContext context) {
    return _clamp(_position ?? _defaultPosition(context), context);
  }

  double _panelWidth(BuildContext context, Offset position) {
    final screenW = MediaQuery.sizeOf(context).width;
    final spaceRight = screenW - position.dx - NteriBubble.margin;
    final spaceLeft = position.dx + NteriBubble.size - NteriBubble.margin;
    return (spaceRight > spaceLeft ? spaceRight : spaceLeft).clamp(220.0, 300.0);
  }

  bool _expandUpward(BuildContext context, Offset position) {
    return position.dy > MediaQuery.sizeOf(context).height * 0.38;
  }

  void _toggleMenu() {
    AppStackScope.of(context).toggleMenu();
  }

  void _onPanStart(DragStartDetails details) {
    if (widget.expanded) return;
    setState(() {
      _isDragging = true;
      _dragMoved = false;
    });
  }

  void _onPanUpdate(DragUpdateDetails details, BuildContext context) {
    if (widget.expanded) return;
    if (details.delta.distance > 8) _dragMoved = true;
    setState(() => _position = _clamp(_resolvedPosition(context) + details.delta, context));
  }

  void _onPanEnd(DragEndDetails details, BuildContext context) {
    if (widget.expanded) return;
    final openMenu = !_dragMoved;
    setState(() => _isDragging = false);
    _savePosition(_resolvedPosition(context));
    _dragMoved = false;
    if (openMenu) _toggleMenu();
  }

  void _onBubbleTap() {
    _toggleMenu();
  }

  Widget _buildBubbleButton({required bool showClose}) {
    return AnimatedScale(
      scale: _isDragging ? 1.08 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Material(
        elevation: widget.expanded || _isDragging ? 12 : 8,
        shadowColor: Colors.black.withValues(alpha: 0.32),
        color: _bubbleColor,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: Semantics(
          button: true,
          label: widget.expanded ? "Fermer le menu N'TERI" : "Ouvrir le menu N'TERI",
          child: SizedBox(
            width: NteriBubble.size,
            height: NteriBubble.size,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                child: showClose
                    ? const Icon(Icons.close, key: ValueKey('close'), color: Colors.white, size: 26)
                    : const _SamsungGridIcon(
                        key: ValueKey('grid'),
                        size: 22,
                        color: Colors.white,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedPanel(
    BuildContext context,
    double panelWidth,
    bool expandUp,
    bool alignRight,
  ) {
    final maxPanelH = MediaQuery.sizeOf(context).height * 0.48;

    final panel = SizeTransition(
      sizeFactor: _expandAnim,
      axisAlignment: expandUp ? 1 : -1,
      child: FadeTransition(
        opacity: _expandAnim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: expandUp ? const Offset(0, 0.1) : const Offset(0, -0.1),
            end: Offset.zero,
          ).animate(_expandAnim),
          child: SizedBox(
            width: panelWidth,
            child: NteriMenuPanel(
              activeRouteName: widget.activeRouteName,
              currentModuleKey: widget.currentModuleKey,
              maxHeight: maxPanelH,
              compactHeader: true,
            ),
          ),
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: expandUp
          ? [panel, const SizedBox(height: NteriBubble.panelGap), _buildBubbleButton(showClose: true)]
          : [_buildBubbleButton(showClose: true), const SizedBox(height: NteriBubble.panelGap), panel],
    );
  }

  double _panelLeft(BuildContext context, Offset position, double panelWidth) {
    final screenW = MediaQuery.sizeOf(context).width;
    final alignRight = position.dx > screenW * 0.5;
    final raw = alignRight ? position.dx + NteriBubble.size - panelWidth : position.dx;
    return raw.clamp(NteriBubble.margin, screenW - panelWidth - NteriBubble.margin);
  }

  @override
  Widget build(BuildContext context) {
    final position = _resolvedPosition(context);
    final media = MediaQuery.of(context);
    final screenH = media.size.height;
    final expandUp = _expandUpward(context, position);
    final panelWidth = _panelWidth(context, position);
    final alignRight = position.dx > media.size.width * 0.5;

    final launcher = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.expanded ? _onBubbleTap : null,
      onPanStart: widget.expanded ? null : _onPanStart,
      onPanUpdate: widget.expanded ? null : (d) => _onPanUpdate(d, context),
      onPanEnd: widget.expanded ? null : (d) => _onPanEnd(d, context),
      child: widget.expanded
          ? _buildExpandedPanel(context, panelWidth, expandUp, alignRight)
          : _buildBubbleButton(showClose: false),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (widget.expanded)
          Positioned.fill(
            child: FadeTransition(
              opacity: _expandAnim,
              child: GestureDetector(
                onTap: _toggleMenu,
                behavior: HitTestBehavior.opaque,
                child: Container(color: Colors.black.withValues(alpha: 0.38)),
              ),
            ),
          ),
        if (!widget.expanded)
          Positioned(left: position.dx, top: position.dy, child: launcher)
        else if (expandUp)
          Positioned(
            left: _panelLeft(context, position, panelWidth),
            bottom: screenH - position.dy - NteriBubble.size,
            child: launcher,
          )
        else
          Positioned(
            left: _panelLeft(context, position, panelWidth),
            top: position.dy,
            child: launcher,
          ),
      ],
    );
  }
}

/// Samsung-style 2×2 rounded-square launcher icon.
class _SamsungGridIcon extends StatelessWidget {
  const _SamsungGridIcon({
    super.key,
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const gap = 3.0;
    const radius = 2.5;
    final cell = (size - gap) / 2;

    Widget cellBox() => Container(
          width: cell,
          height: cell,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(radius),
          ),
        );

    return SizedBox(
      width: size,
      height: size,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [cellBox(), const SizedBox(width: gap), cellBox()],
          ),
          const SizedBox(height: gap),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [cellBox(), const SizedBox(width: gap), cellBox()],
          ),
        ],
      ),
    );
  }
}
