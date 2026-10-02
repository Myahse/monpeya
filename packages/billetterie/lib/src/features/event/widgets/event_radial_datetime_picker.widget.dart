import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import 'package:billetterie/src/core/constants/billetterie.brand.dart';
import 'package:billetterie/src/features/event/widgets/event_ui_chrome.dart';

/// Two-level radial filter: outer ring = date, inner ring = time.
///
/// Native-feel spin with inertia + spring snap; top item is selected.
class EventRadialDateTimePicker extends StatefulWidget {
  const EventRadialDateTimePicker({
    super.key,
    this.initialDateTime,
    this.dayCount = 75,
    this.timeStepMinutes = 60,
    this.heading,
    this.onChanged,
  });

  final DateTime? initialDateTime;
  final int dayCount;
  final int timeStepMinutes;
  final String? heading;
  final ValueChanged<DateTime>? onChanged;

  @override
  EventRadialDateTimePickerState createState() =>
      EventRadialDateTimePickerState();
}

class EventRadialDateTimePickerState extends State<EventRadialDateTimePicker>
    with TickerProviderStateMixin {
  static const _dateSide = 4;
  static const _timeSide = 4;
  static const _dateGap = 0.40;
  static const _timeGap = 0.36;
  static const _dateRadiusFactor = 0.47;
  static const _timeRadiusFactor = 0.29;
  /// Extra vertical space so the inner time ring is not clipped in the sheet.
  static const _dialHeightFactor = 1.20;
  static const _sensitivity = 1.85;
  static const _minDragRadius = 22.0;

  static const _spring = SpringDescription(
    mass: 0.8,
    stiffness: 120,
    damping: 18,
  );

  late final List<DateTime> _dates;
  late final List<TimeOfDay> _times;

  late final AnimationController _dateCtrl;
  late final AnimationController _timeCtrl;

  bool _draggingDate = false;
  bool _dragging = false;
  bool _suppressNotify = false;
  bool _busy = false;
  Offset? _lastPos;
  double _lastAngularVel = 0;
  int _lastDateTick = 0;
  int _lastTimeTick = 0;

  @override
  void initState() {
    super.initState();
    final seed = widget.initialDateTime ?? DateTime.now();
    final today = DateTime(seed.year, seed.month, seed.day);
    final anchor = today.subtract(const Duration(days: 7));

    _dates = List.generate(
      widget.dayCount,
      (i) => anchor.add(Duration(days: i)),
    );

    _times = [
      for (var m = 0; m < 24 * 60; m += widget.timeStepMinutes)
        TimeOfDay(hour: m ~/ 60, minute: m % 60),
    ];

    final now = DateTime.now();
    final dateTarget = _indexForDate(now).toDouble();
    final timeTarget =
        _nearestTimeIndex(TimeOfDay.fromDateTime(now)).toDouble();

    // Start offset so entrance can roll into today.
    final dateStart = (dateTarget - 10).clamp(0.0, (_dates.length - 1).toDouble());
    final timeStart = timeTarget - 8;

    _dateCtrl = AnimationController.unbounded(vsync: this, value: dateStart)
      ..addListener(_onDateTick);
    _timeCtrl = AnimationController.unbounded(vsync: this, value: timeStart)
      ..addListener(_onTimeTick);

    _lastDateTick = dateStart.round();
    _lastTimeTick = timeStart.round();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) playRollToToday(outbound: false);
    });
  }

  @override
  void didUpdateWidget(covariant EventRadialDateTimePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_busy || _dragging) return;
    final next = widget.initialDateTime;
    if (next == null) return;
    final cur = _selected;
    if (cur.year == next.year &&
        cur.month == next.month &&
        cur.day == next.day &&
        cur.hour == next.hour &&
        cur.minute == next.minute) {
      return;
    }
    _jumpTo(next, animate: true);
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _timeCtrl.dispose();
    super.dispose();
  }

  /// Rolls both rings to now. Used on open (`outbound: false`) and close.
  Future<void> playRollToToday({required bool outbound}) async {
    if (!mounted) return;
    _busy = true;
    _suppressNotify = true;
    _dateCtrl.stop();
    _timeCtrl.stop();

    final now = DateTime.now();
    final dateTarget = _indexForDate(now).toDouble();
    final timeTarget =
        _nearestTimeIndex(TimeOfDay.fromDateTime(now)).toDouble();
    final maxDate = (_dates.length - 1).toDouble();

    if (!outbound) {
      _dateCtrl.value =
          (dateTarget - 10).clamp(0.0, maxDate);
      _timeCtrl.value = timeTarget - 8;
    }

    // Outbound: add extra spins so it feels like the wheel winds down.
    final dateEnd = outbound
        ? (dateTarget - 2).clamp(0.0, maxDate)
        : dateTarget;
    final timeEnd = outbound ? timeTarget - 6 : timeTarget;

    await Future.wait<void>([
      _rollWheel(
        _dateCtrl,
        to: dateEnd,
        duration: Duration(milliseconds: outbound ? 700 : 1100),
      ),
      _rollWheel(
        _timeCtrl,
        to: timeEnd,
        duration: Duration(milliseconds: outbound ? 750 : 1200),
      ),
    ]);

    if (outbound) {
      // Finish on today after the wind-down spin.
      await Future.wait<void>([
        _rollWheel(
          _dateCtrl,
          to: dateTarget,
          duration: const Duration(milliseconds: 380),
        ),
        _rollWheel(
          _timeCtrl,
          to: timeTarget,
          duration: const Duration(milliseconds: 400),
        ),
      ]);
    }

    _normalizeTimeValue();
    _suppressNotify = false;
    _busy = false;
    if (mounted) setState(() {});
  }

  Future<void> _rollWheel(
    AnimationController wheel, {
    required double to,
    required Duration duration,
  }) async {
    final from = wheel.value;
    if ((from - to).abs() < 0.001) return;

    final driver = AnimationController(vsync: this, duration: duration);
    final curved = CurvedAnimation(parent: driver, curve: Curves.easeOutCubic);
    final tween = Tween<double>(begin: from, end: to).animate(curved);

    void tick() {
      if (!mounted) return;
      wheel.value = tween.value;
    }

    tween.addListener(tick);
    try {
      await driver.forward();
    } finally {
      tween.removeListener(tick);
      driver.dispose();
      if (mounted) wheel.value = to;
    }
  }

  int _indexForDate(DateTime dt) {
    final day = DateTime(dt.year, dt.month, dt.day);
    final idx = day.difference(_dates.first).inDays;
    return idx.clamp(0, _dates.length - 1);
  }

  void _jumpTo(DateTime dt, {bool animate = false}) {
    if (_busy) return;
    _dateCtrl.stop();
    _timeCtrl.stop();
    final dateTarget = _indexForDate(dt).toDouble();
    final timeTarget = _nearestTimeIndex(TimeOfDay.fromDateTime(dt)).toDouble();
    if (!animate) {
      _dateCtrl.value = dateTarget;
      _timeCtrl.value = timeTarget;
      _lastDateTick = dateTarget.round();
      _lastTimeTick = timeTarget.round();
      return;
    }
    _dateCtrl.animateWith(
      SpringSimulation(_spring, _dateCtrl.value, dateTarget, 0),
    );
    _timeCtrl.animateWith(
      SpringSimulation(_spring, _timeCtrl.value, timeTarget, 0),
    );
  }

  void _onDateTick() {
    if (!mounted) return;
    final tick = _dateIndex;
    if (tick != _lastDateTick) {
      _lastDateTick = tick;
      if (!_suppressNotify) {
        HapticFeedback.selectionClick();
        widget.onChanged?.call(_selected);
      }
    }
    setState(() {});
  }

  void _onTimeTick() {
    if (!mounted) return;
    final tick = _timeIndex;
    if (tick != _lastTimeTick) {
      _lastTimeTick = tick;
      if (!_suppressNotify) {
        HapticFeedback.selectionClick();
        widget.onChanged?.call(_selected);
      }
    }
    setState(() {});
  }

  int _nearestTimeIndex(TimeOfDay t) {
    final minutes = t.hour * 60 + t.minute;
    var best = 0;
    var bestDelta = 1 << 30;
    for (var i = 0; i < _times.length; i++) {
      final m = _times[i].hour * 60 + _times[i].minute;
      final d = (m - minutes).abs();
      if (d < bestDelta) {
        bestDelta = d;
        best = i;
      }
    }
    return best;
  }

  int get _dateIndex =>
      _dateCtrl.value.round().clamp(0, _dates.length - 1);

  int get _timeIndex {
    var i = _timeCtrl.value.round() % _times.length;
    if (i < 0) i += _times.length;
    return i;
  }

  DateTime get _selected {
    final d = _dates[_dateIndex];
    final t = _times[_timeIndex];
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  double _wrapAngle(double a) {
    if (a > math.pi) return a - 2 * math.pi;
    if (a < -math.pi) return a + 2 * math.pi;
    return a;
  }

  double _rubberDate(double v) {
    const min = 0.0;
    final max = (_dates.length - 1).toDouble();
    if (v < min) return min + (v - min) * 0.22;
    if (v > max) return max + (v - max) * 0.22;
    return v;
  }

  void _onPanStart(DragStartDetails details, Size size) {
    if (_busy) return;
    _dateCtrl.stop();
    _timeCtrl.stop();
    _dragging = true;

    final center = _ringCenter(size);
    final d = (details.localPosition - center).distance;
    final dateR = size.shortestSide * _dateRadiusFactor;
    final timeR = _timeRadius(size);
    // Match visual rings so outer drags date, inner drags time.
    if (d >= dateR - 18) {
      _draggingDate = true;
    } else if (d <= timeR + 26) {
      _draggingDate = false;
    } else {
      _draggingDate = d > (dateR + timeR) / 2;
    }
    _lastPos = details.localPosition;
    _lastAngularVel = 0;
  }

  double _angleDeltaFromCenter(Offset prev, Offset curr) {
    if (prev.distance < _minDragRadius && curr.distance < _minDragRadius) {
      return 0;
    }
    final aPrev = math.atan2(prev.dy, prev.dx);
    final aCurr = math.atan2(curr.dy, curr.dx);
    return -_wrapAngle(aCurr - aPrev);
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    final center = _ringCenter(size);
    final prevGlobal = _lastPos ?? details.localPosition;
    final prev = prevGlobal - center;
    final curr = details.localPosition - center;
    _lastPos = details.localPosition;

    final a = _angleDeltaFromCenter(prev, curr);
    if (a.abs() < 0.0005) return;

    _lastAngularVel = a * 60;

    if (_draggingDate) {
      _dateCtrl.value =
          _rubberDate(_dateCtrl.value + a / _dateGap * _sensitivity);
    } else {
      _timeCtrl.value += a / _timeGap * _sensitivity;
    }
  }

  void _onPanEnd(DragEndDetails details) {
    _lastPos = null;
    _dragging = false;
    final linear = details.velocity.pixelsPerSecond;
    final boost = linear.distance > 60 ? 1.25 : 0.85;
    final itemVel =
        (_lastAngularVel / (_draggingDate ? _dateGap : _timeGap)) *
            _sensitivity *
            boost;

    if (_draggingDate) {
      _settleDate(itemVel);
    } else {
      _settleTime(itemVel);
    }
  }

  void _onPanCancel() {
    _lastPos = null;
    _dragging = false;
    if (_draggingDate) {
      _settleDate(0);
    } else {
      _settleTime(0);
    }
  }

  void _settleDate(double velocity) {
    final max = (_dates.length - 1).toDouble();
    final projected = (_dateCtrl.value + velocity * 0.22).clamp(0.0, max);
    final target = projected.roundToDouble();
    if ((target - _dateCtrl.value).abs() < 0.001 && velocity.abs() < 0.05) {
      _dateCtrl.value = target;
      widget.onChanged?.call(_selected);
      return;
    }
    _dateCtrl.animateWith(
      SpringSimulation(_spring, _dateCtrl.value, target, velocity),
    );
  }

  void _normalizeTimeValue() {
    if (!mounted) return;
    final n = _times.length;
    var v = _timeCtrl.value % n;
    if (v < 0) v += n;
    if ((_timeCtrl.value - v).abs() > 0.001) {
      _timeCtrl.value = v;
    }
  }

  void _settleTime(double velocity) {
    _normalizeTimeValue();
    final n = _times.length;
    final current = _timeCtrl.value;
    final projected = current + velocity * 0.22;
    var target = projected.round() % n;
    if (target < 0) target += n;

    var best = target.toDouble();
    for (final candidate in [target - n, target, target + n]) {
      if ((candidate - current).abs() < (best - current).abs()) {
        best = candidate.toDouble();
      }
    }

    if ((best - current).abs() < 0.001 && velocity.abs() < 0.05) {
      _timeCtrl.value = best;
      _normalizeTimeValue();
      widget.onChanged?.call(_selected);
      return;
    }

    _timeCtrl
        .animateWith(SpringSimulation(_spring, current, best, velocity))
        .whenComplete(_normalizeTimeValue);
  }

  static const _weekdays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
  static const _months = [
    'Janvier',
    'Février',
    'Mars',
    'Avril',
    'Mai',
    'Juin',
    'Juillet',
    'Août',
    'Septembre',
    'Octobre',
    'Novembre',
    'Décembre',
  ];

  /// 24h French-style time, e.g. `9:00`, `14:00`.
  String _formatTime(TimeOfDay t) {
    final mm = t.minute.toString().padLeft(2, '0');
    return '${t.hour}:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final brand = BilletterieBrand.eventOf(context);
    final chrome = EventUiChrome.of(context);
    final selected = _selected;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.heading != null) ...[
          Text(
            widget.heading!,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 0.4,
              color: brand.primaryDark,
            ),
          ),
          const SizedBox(height: 4),
        ],
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: Text(
            '${_months[selected.month - 1]} ${selected.year}',
            key: ValueKey('${selected.month}-${selected.year}'),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: brand.text,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${_weekdays[(selected.weekday - 1) % 7]} ${selected.day}'
          ' · ${_formatTime(_times[_timeIndex])}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: brand.primaryDark,
          ),
        ),
        const SizedBox(height: 28),
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = w * _dialHeightFactor;
            final size = Size(w, h);
            final ring = _ringCenter(size);
            final dateR = size.shortestSide * _dateRadiusFactor;
            final timeR = _timeRadius(size);
            return SizedBox(
              width: w,
              height: h,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (d) => _onPanStart(d, size),
                onPanUpdate: (d) => _onPanUpdate(d, size),
                onPanEnd: _onPanEnd,
                onPanCancel: _onPanCancel,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CustomPaint(
                      size: size,
                      painter: _DualWheelPainter(
                        center: ring,
                        dateRadius: dateR,
                        timeRadius: timeR,
                        stage: chrome.wheelStage,
                        dateTrack: chrome.wheelDateTrack,
                        timeTrack: chrome.wheelTimeTrack,
                        rim: chrome.wheelRim,
                        hub: chrome.wheelHub,
                      ),
                    ),
                    CustomPaint(
                      size: size,
                      painter: _TimeHighlightPainter(
                        accent: chrome.wheelAccent,
                        center: ring,
                        radius: timeR,
                      ),
                    ),
                    IgnorePointer(child: Stack(children: _buildTimeLabels(size, chrome))),
                    IgnorePointer(child: Stack(children: _buildDateCards(size, chrome))),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Offset _ringCenter(Size size) {
    // Center the rings in the taller dial so the inner time wheel clears the bottom.
    return Offset(size.width / 2, size.height * 0.49);
  }

  double _timeRadius(Size size) => size.width * _timeRadiusFactor;

  List<Widget> _buildDateCards(Size size, EventUiChrome chrome) {
    final center = _ringCenter(size);
    final radius = size.shortestSide * _dateRadiusFactor;
    final value = _dateCtrl.value;
    final widgets = <Widget>[];

    final base = value.floor();
    for (var i = base - _dateSide; i <= base + _dateSide + 1; i++) {
      if (i < 0 || i >= _dates.length) continue;
      final frac = i - value;
      if (frac.abs() > _dateSide + 0.6) continue;

      final angle = -math.pi / 2 + frac * _dateGap;
      final focus = (1.0 - frac.abs().clamp(0.0, 1.0));
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      final date = _dates[i];

      widgets.add(
        Positioned(
          left: x - 30,
          top: y - 46,
          child: Transform.rotate(
            angle: angle + math.pi / 2,
            child: _DateCard(
              weekday: _weekdays[(date.weekday - 1) % 7],
              day: date.day,
              focus: focus,
              idleColor: chrome.wheelCardIdle,
              selectedBg: chrome.wheelSelectedBg,
              selectedFg: chrome.wheelSelectedFg,
              muted: chrome.wheelIdleFg,
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  List<Widget> _buildTimeLabels(Size size, EventUiChrome chrome) {
    final center = _ringCenter(size);
    final radius = _timeRadius(size);
    final value = _timeCtrl.value;
    final widgets = <Widget>[];

    final base = value.floor();
    for (var i = base - _timeSide; i <= base + _timeSide + 1; i++) {
      final frac = i - value;
      if (frac.abs() > _timeSide + 0.6) continue;

      var idx = i % _times.length;
      if (idx < 0) idx += _times.length;

      final angle = -math.pi / 2 + frac * _timeGap;
      final focus = (1.0 - frac.abs().clamp(0.0, 1.0));
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      widgets.add(
        Positioned(
          left: x - 34,
          top: y - 12,
          width: 68,
          child: Transform.rotate(
            angle: angle + math.pi / 2,
            child: Opacity(
              opacity: 0.35 + 0.65 * focus,
              child: Text(
                _formatTime(_times[idx]),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11 + 2 * focus,
                  fontWeight: focus > 0.7 ? FontWeight.w800 : FontWeight.w600,
                  color: focus > 0.75
                      ? chrome.wheelSelectedFg
                      : chrome.wheelIdleFg,
                ),
              ),
            ),
          ),
        ),
      );
    }
    return widgets;
  }
}

class _DateCard extends StatelessWidget {
  const _DateCard({
    required this.weekday,
    required this.day,
    required this.focus,
    required this.idleColor,
    required this.selectedBg,
    required this.selectedFg,
    required this.muted,
  });

  final String weekday;
  final int day;
  final double focus;
  final Color idleColor;
  final Color selectedBg;
  final Color selectedFg;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final selected = focus > 0.72;
    final scale = 0.92 + 0.10 * focus;
    final bg = Color.lerp(idleColor, selectedBg, focus.clamp(0.0, 1.0))!;
    final fg = Color.lerp(muted, selectedFg, focus)!;

    return Transform.scale(
      scale: scale,
      child: Container(
        width: 56,
        height: 84,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28 * focus),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 12,
              color: Color.lerp(muted, selectedFg, focus),
            ),
            const SizedBox(height: 4),
            Text(
              weekday,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$day',
              style: TextStyle(
                fontSize: 17 + 3 * focus,
                fontWeight: FontWeight.w800,
                height: 1,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DualWheelPainter extends CustomPainter {
  const _DualWheelPainter({
    required this.center,
    required this.dateRadius,
    required this.timeRadius,
    required this.stage,
    required this.dateTrack,
    required this.timeTrack,
    required this.rim,
    required this.hub,
  });

  final Offset center;
  final double dateRadius;
  final double timeRadius;
  final Color stage;
  final Color dateTrack;
  final Color timeTrack;
  final Color rim;
  final Color hub;

  @override
  void paint(Canvas canvas, Size size) {
    final outerR = dateRadius + 34;
    final between = (dateRadius + timeRadius) / 2;

    // Outer disc (date wheel body).
    canvas.drawCircle(center, outerR, Paint()..color = stage);

    // Date ring band.
    canvas.drawCircle(
      center,
      dateRadius,
      Paint()
        ..color = dateTrack
        ..style = PaintingStyle.stroke
        ..strokeWidth = 58
        ..isAntiAlias = true,
    );

    // Inner disc (time wheel body).
    canvas.drawCircle(center, between - 4, Paint()..color = hub);

    // Time ring band.
    canvas.drawCircle(
      center,
      timeRadius,
      Paint()
        ..color = timeTrack
        ..style = PaintingStyle.stroke
        ..strokeWidth = 42
        ..isAntiAlias = true,
    );

    // Hub.
    canvas.drawCircle(center, timeRadius - 28, Paint()..color = stage);

    // Subtle rims.
    final rimPaint = Paint()
      ..color = rim
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..isAntiAlias = true;
    canvas.drawCircle(center, outerR - 1, rimPaint);
    canvas.drawCircle(center, between, rimPaint);
    canvas.drawCircle(center, timeRadius - 28, rimPaint);
  }

  @override
  bool shouldRepaint(covariant _DualWheelPainter oldDelegate) {
    return oldDelegate.center != center ||
        oldDelegate.dateRadius != dateRadius ||
        oldDelegate.timeRadius != timeRadius ||
        oldDelegate.stage != stage ||
        oldDelegate.hub != hub;
  }
}

class _TimeHighlightPainter extends CustomPainter {
  const _TimeHighlightPainter({
    required this.accent,
    required this.center,
    required this.radius,
  });

  final Color accent;
  final Offset center;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final r = radius;
    const half = 0.22;
    const mid = -math.pi / 2;

    final path = Path()
      ..moveTo(
        center.dx + (r - 16) * math.cos(mid - half),
        center.dy + (r - 16) * math.sin(mid - half),
      )
      ..lineTo(
        center.dx + (r + 14) * math.cos(mid - half * 0.8),
        center.dy + (r + 14) * math.sin(mid - half * 0.8),
      )
      ..lineTo(
        center.dx + (r + 20) * math.cos(mid),
        center.dy + (r + 20) * math.sin(mid) - 5,
      )
      ..lineTo(
        center.dx + (r + 14) * math.cos(mid + half * 0.8),
        center.dy + (r + 14) * math.sin(mid + half * 0.8),
      )
      ..lineTo(
        center.dx + (r - 16) * math.cos(mid + half),
        center.dy + (r - 16) * math.sin(mid + half),
      )
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = accent
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(covariant _TimeHighlightPainter oldDelegate) =>
      oldDelegate.accent != accent ||
      oldDelegate.center != center ||
      oldDelegate.radius != radius;
}
