import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../models/progress_entry.dart';
import '../theme/app_colors.dart';

/// Line chart of logged weights over time. Tap or hover to inspect a point.
class WeightChart extends StatefulWidget {
  /// Entries in any order; they are plotted oldest to newest.
  final List<ProgressEntry> entries;

  /// Optional reference line, drawn dashed (e.g. the starting weight).
  final double? baseline;
  final bool isDark;

  const WeightChart({
    super.key,
    required this.entries,
    required this.isDark,
    this.baseline,
  });

  @override
  State<WeightChart> createState() => _WeightChartState();
}

class _WeightChartState extends State<WeightChart> {
  int? _selected;

  List<ProgressEntry> get _sorted =>
      [...widget.entries]..sort((a, b) => a.date.compareTo(b.date));

  void _select(Offset pos, Size size) {
    final points = _WeightChartPainter.layout(_sorted, widget.baseline, size).points;
    if (points.isEmpty) return;
    var best = 0;
    for (var i = 1; i < points.length; i++) {
      if ((points[i].dx - pos.dx).abs() < (points[best].dx - pos.dx).abs()) best = i;
    }
    if (best != _selected) setState(() => _selected = best);
  }

  @override
  Widget build(BuildContext context) {
    final sorted = _sorted;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, 220);
        return MouseRegion(
          onHover: (e) => _select(e.localPosition, size),
          onExit: (_) => setState(() => _selected = null),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => _select(d.localPosition, size),
            onHorizontalDragUpdate: (d) => _select(d.localPosition, size),
            child: CustomPaint(
              size: size,
              painter: _WeightChartPainter(
                entries: sorted,
                baseline: widget.baseline,
                selected: _selected != null && _selected! < sorted.length ? _selected : null,
                isDark: widget.isDark,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ChartLayout {
  final Rect plot;
  final double minY;
  final double maxY;
  final List<Offset> points;
  _ChartLayout(this.plot, this.minY, this.maxY, this.points);

  double yFor(double v) => plot.bottom - (v - minY) / (maxY - minY) * plot.height;
}

class _WeightChartPainter extends CustomPainter {
  final List<ProgressEntry> entries;
  final double? baseline;
  final int? selected;
  final bool isDark;

  _WeightChartPainter({
    required this.entries,
    required this.baseline,
    required this.selected,
    required this.isDark,
  });

  static const _leftPad = 40.0;
  static const _bottomPad = 24.0;
  static const _topPad = 28.0;
  static const _rightPad = 12.0;

  static _ChartLayout layout(List<ProgressEntry> entries, double? baseline, Size size) {
    final plot = Rect.fromLTRB(_leftPad, _topPad, size.width - _rightPad, size.height - _bottomPad);
    final values = [
      ...entries.map((e) => e.weight),
      if (baseline != null && baseline > 0) baseline,
    ];
    if (values.isEmpty) return _ChartLayout(plot, 0, 1, const []);

    var lo = values.reduce(math.min);
    var hi = values.reduce(math.max);
    // Keep at least a 4 kg window so small changes aren't exaggerated.
    final span = math.max(hi - lo, 4.0);
    final mid = (hi + lo) / 2;
    lo = (mid - span * 0.6).floorToDouble();
    hi = (mid + span * 0.6).ceilToDouble();

    final layout = _ChartLayout(plot, lo, hi, []);
    if (entries.isEmpty) return layout;

    final first = entries.first.date.millisecondsSinceEpoch.toDouble();
    final last = entries.last.date.millisecondsSinceEpoch.toDouble();
    for (var i = 0; i < entries.length; i++) {
      final t = entries[i].date.millisecondsSinceEpoch.toDouble();
      final x = last == first
          ? (entries.length == 1 ? plot.center.dx : plot.left + plot.width * i / (entries.length - 1))
          : plot.left + (t - first) / (last - first) * plot.width;
      layout.points.add(Offset(x, layout.yFor(entries[i].weight)));
    }
    return layout;
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  static String _fmtKg(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  void _text(Canvas canvas, String s, Offset at, TextStyle style, {TextAlign align = TextAlign.left}) {
    final tp = TextPainter(text: TextSpan(text: s, style: style), textDirection: TextDirection.ltr)..layout();
    var dx = at.dx;
    if (align == TextAlign.right) dx -= tp.width;
    if (align == TextAlign.center) dx -= tp.width / 2;
    tp.paint(canvas, Offset(dx, at.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final l = layout(entries, baseline, size);
    final brand = AppColors.brand(isDark);
    final labelStyle = TextStyle(fontSize: 11, color: AppColors.textMuted(isDark));

    // Grid lines and y labels.
    final grid = Paint()
      ..color = AppColors.border(isDark)
      ..strokeWidth = 1;
    const ticks = 4;
    for (var i = 0; i <= ticks; i++) {
      final v = l.minY + (l.maxY - l.minY) * i / ticks;
      final y = l.yFor(v);
      canvas.drawLine(Offset(l.plot.left, y), Offset(l.plot.right, y), grid);
      _text(canvas, _fmtKg(v), Offset(l.plot.left - 8, y), labelStyle, align: TextAlign.right);
    }

    // Starting weight reference line.
    if (baseline != null && baseline! > 0) {
      final y = l.yFor(baseline!);
      final dash = Paint()
        ..color = AppColors.textMuted(isDark)
        ..strokeWidth = 1.2;
      for (var x = l.plot.left; x < l.plot.right; x += 8) {
        canvas.drawLine(Offset(x, y), Offset(math.min(x + 4, l.plot.right), y), dash);
      }
      _text(canvas, 'Start', Offset(l.plot.right, y - 9), labelStyle, align: TextAlign.right);
    }

    if (l.points.isEmpty) return;

    // X labels: first and last date.
    final xLabelY = l.plot.bottom + 14;
    _text(canvas, _fmtDate(entries.first.date), Offset(l.points.first.dx, xLabelY), labelStyle,
        align: l.points.length == 1 ? TextAlign.center : TextAlign.left);
    if (l.points.length > 1) {
      _text(canvas, _fmtDate(entries.last.date), Offset(l.points.last.dx, xLabelY), labelStyle,
          align: TextAlign.right);
    }

    // Area fill and line.
    if (l.points.length > 1) {
      final path = Path()..moveTo(l.points.first.dx, l.points.first.dy);
      for (final p in l.points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      final area = Path.from(path)
        ..lineTo(l.points.last.dx, l.plot.bottom)
        ..lineTo(l.points.first.dx, l.plot.bottom)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [brand.withValues(alpha: 0.18), brand.withValues(alpha: 0.0)],
          ).createShader(l.plot),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = brand
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // Points.
    final surface = AppColors.surface(isDark);
    for (var i = 0; i < l.points.length; i++) {
      final isSel = i == selected;
      canvas.drawCircle(l.points[i], isSel ? 6 : 4, Paint()..color = brand);
      canvas.drawCircle(l.points[i], isSel ? 3 : 2, Paint()..color = surface);
    }

    // Tooltip for the selected point.
    if (selected != null) {
      final p = l.points[selected!];
      final e = entries[selected!];
      canvas.drawLine(Offset(p.dx, l.plot.top), Offset(p.dx, l.plot.bottom),
          Paint()..color = AppColors.textMuted(isDark).withValues(alpha: 0.4));
      final tp = TextPainter(
        text: TextSpan(
          text: '${_fmtKg(e.weight)} kg  ·  ${_fmtDate(e.date)}/${e.date.year}',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.bg(isDark)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final w = tp.width + 16;
      final h = tp.height + 8;
      final left = (p.dx - w / 2).clamp(0.0, math.max(0.0, size.width - w)).toDouble();
      final rect = RRect.fromRectAndRadius(Rect.fromLTWH(left, 0, w, h), const Radius.circular(6));
      canvas.drawRRect(rect, Paint()..color = AppColors.textPrimary(isDark));
      tp.paint(canvas, Offset(left + 8, 4));
    }
  }

  @override
  bool shouldRepaint(covariant _WeightChartPainter old) =>
      old.entries != entries || old.baseline != baseline || old.selected != selected || old.isDark != isDark;
}
