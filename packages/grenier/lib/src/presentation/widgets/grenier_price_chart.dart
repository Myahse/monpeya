import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:grenier/src/presentation/widgets/grenier_ui.dart';
import 'package:grenier/src/shared/models/grenier_produit.model.dart';

enum GrenierChartPeriod {
  week('7 j', Duration(days: 7)),
  month('1 mois', Duration(days: 30)),
  quarter('3 mois', Duration(days: 90));

  const GrenierChartPeriod(this.label, this.span);
  final String label;
  final Duration span;
}

/// Smooth price line with period switch, min / average / max and an
/// animated draw-in.
class GrenierPriceChart extends StatefulWidget {
  const GrenierPriceChart({super.key, required this.points});

  /// Price readings, oldest first.
  final List<GrenierPricePoint> points;

  @override
  State<GrenierPriceChart> createState() => _GrenierPriceChartState();
}

class _GrenierPriceChartState extends State<GrenierPriceChart>
    with SingleTickerProviderStateMixin {
  GrenierChartPeriod _period = GrenierChartPeriod.week;
  late final AnimationController _draw = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  @override
  void dispose() {
    _draw.dispose();
    super.dispose();
  }

  void _select(GrenierChartPeriod p) {
    if (p == _period) return;
    setState(() => _period = p);
    _draw.forward(from: 0);
  }

  List<GrenierPricePoint> get _visible {
    final all = widget.points;
    if (all.length < 2) return all;
    final cutoff = all.last.at.subtract(_period.span);
    final inRange = all.where((p) => !p.at.isBefore(cutoff)).toList();
    return inRange.length >= 2 ? inRange : all;
  }

  @override
  Widget build(BuildContext context) {
    final points = _visible;
    final enough = points.length >= 2;
    final values = points.map((p) => p.price).toList();
    final minV = enough ? values.reduce(math.min) : 0.0;
    final maxV = enough ? values.reduce(math.max) : 0.0;
    final avg = enough ? values.reduce((a, b) => a + b) / values.length : 0.0;
    String f(double v) => '${GrenierProduit.formatAmount(v)} F';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: grenierCard(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Évolution du prix',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              _PeriodSwitch(selected: _period, onSelected: _select),
            ],
          ),
          const SizedBox(height: 14),
          if (!enough)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Text(
                'La courbe s’affichera dès que Mon Grenier fournira l’historique des prix de ce produit.',
                textAlign: TextAlign.center,
                style: TextStyle(color: GrenierColors.muted, height: 1.4),
              ),
            )
          else ...[
            SizedBox(
              height: 160,
              child: AnimatedBuilder(
                animation: _draw,
                builder: (context, _) => CustomPaint(
                  painter: _ChartPainter(
                    values: values,
                    progress: Curves.easeInOutCubic.transform(_draw.value),
                    labels: [f(maxV), f((maxV + minV) / 2), f(minV)],
                    lastLabel: f(values.last),
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(right: 44),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final p in _ticks(points))
                    Text(
                      p,
                      style: const TextStyle(fontSize: 11, color: GrenierColors.muted),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: GrenierColors.border),
            const SizedBox(height: 12),
            Row(
              children: [
                _Stat(label: 'Plus bas', value: f(minV), color: GrenierColors.downFg),
                _Stat(label: 'Moyenne', value: f(avg), align: CrossAxisAlignment.center),
                _Stat(
                  label: 'Plus haut',
                  value: f(maxV),
                  color: GrenierColors.upFg,
                  align: CrossAxisAlignment.end,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static const _months = [
    'janv', 'févr', 'mars', 'avr', 'mai', 'juin',
    'juil', 'août', 'sept', 'oct', 'nov', 'déc',
  ];

  List<String> _ticks(List<GrenierPricePoint> points) {
    String label(DateTime d) => '${d.day} ${_months[d.month - 1]}';
    final first = points.first.at;
    final last = points.last.at;
    final mid = first.add(last.difference(first) ~/ 2);
    return [label(first), label(mid), label(last)];
  }
}

class _PeriodSwitch extends StatelessWidget {
  const _PeriodSwitch({required this.selected, required this.onSelected});

  final GrenierChartPeriod selected;
  final ValueChanged<GrenierChartPeriod> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final p in GrenierChartPeriod.values)
            GestureDetector(
              onTap: () => onSelected(p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: p == selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: p == selected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  p.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: p == selected ? GrenierColors.primary : GrenierColors.muted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    this.color = GrenierColors.text,
    this.align = CrossAxisAlignment.start,
  });

  final String label;
  final String value;
  final Color color;
  final CrossAxisAlignment align;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: align,
        children: [
          Text(label, style: const TextStyle(fontSize: 11.5, color: GrenierColors.muted)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.values,
    required this.progress,
    required this.labels,
    required this.lastLabel,
  });

  final List<double> values;
  final double progress;
  final List<String> labels;
  final String lastLabel;

  static const _labelWidth = 44.0;
  static const _top = 22.0;
  static const _bottom = 12.0;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width - _labelWidth;
    final h = size.height;
    final chartTop = _top;
    final chartBottom = h - _bottom;
    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final span = math.max(maxV - minV, 1);

    // Guide lines + price labels.
    final grid = Paint()
      ..color = GrenierColors.border
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final y = chartTop + (chartBottom - chartTop) * i / 2;
      canvas.drawLine(Offset(0, y), Offset(w, y), grid);
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(fontSize: 10.5, color: GrenierColors.muted, fontFamily: 'Urbanist'),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: _labelWidth);
      tp.paint(canvas, Offset(size.width - tp.width, y - tp.height / 2));
    }

    final pts = <Offset>[
      for (var i = 0; i < values.length; i++)
        Offset(
          w * i / (values.length - 1),
          chartBottom - (values[i] - minV) / span * (chartBottom - chartTop),
        ),
    ];
    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final a = pts[i - 1];
      final b = pts[i];
      final cx = (a.dx + b.dx) / 2;
      line.cubicTo(cx, a.dy, cx, b.dy, b.dx, b.dy);
    }

    // Reveal left to right.
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, w * progress + 2, h));
    final area = Path.from(line)
      ..lineTo(pts.last.dx, h)
      ..lineTo(pts.first.dx, h)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, chartTop),
          Offset(0, h),
          [
            GrenierColors.primary.withValues(alpha: 0.22),
            GrenierColors.primary.withValues(alpha: 0),
          ],
        ),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = GrenierColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();

    if (progress >= 0.98) {
      final last = pts.last;
      canvas.drawCircle(last, 11, Paint()..color = GrenierColors.primary.withValues(alpha: 0.15));
      canvas.drawCircle(last, 5.5, Paint()..color = Colors.white);
      canvas.drawCircle(
        last,
        5.5,
        Paint()
          ..color = GrenierColors.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: lastLabel,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            fontFamily: 'Urbanist',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final box = Rect.fromLTWH(
        (last.dx - tp.width - 16).clamp(0, w),
        math.max(0, last.dy - tp.height - 18),
        tp.width + 16,
        tp.height + 6,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(box, const Radius.circular(8)),
        Paint()..color = GrenierColors.dark,
      );
      tp.paint(canvas, Offset(box.left + 8, box.top + 3));
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.progress != progress || old.values != values;
}
