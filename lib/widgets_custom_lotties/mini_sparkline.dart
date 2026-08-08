import 'package:flutter/material.dart';

/// A tiny line chart with no axis, grid, or interval math — just the values
/// mapped straight onto the canvas.
///
/// Built to replace fl_chart's LineChart for small inline sparklines after
/// tracing a class of real fl_chart crashes (imaNNeo/fl_chart#1739, #774:
/// "Unsupported operation: Infinity or NaN") back to its internal axis/grid
/// interval calculations. Skipping that machinery entirely — rather than
/// trying to configure around it — means there is no interval computation
/// left to misbehave at any width or data shape.
class MiniSparkline extends StatefulWidget {
  const MiniSparkline({
    super.key,
    required this.values,
    required this.color,
    this.strokeWidth = 2.2,
    this.filled = true,
    this.livePulse = false,
  });

  final List<double> values;
  final Color color;
  final double strokeWidth;
  final bool filled;

  /// Draws a softly pulsing dot on the most recent point — the "this is
  /// live" cue real trading apps use. Opt-in and off by default, so the
  /// many static uses of this widget stay allocation-free and the existing
  /// painter regression tests keep exercising the same code path.
  final bool livePulse;

  @override
  State<MiniSparkline> createState() => _MiniSparklineState();
}

class _MiniSparklineState extends State<MiniSparkline>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulse;

  @override
  void initState() {
    super.initState();
    if (widget.livePulse) {
      _startPulse();
    }
  }

  @override
  void didUpdateWidget(covariant MiniSparkline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.livePulse && _pulse == null) {
      _startPulse();
    } else if (!widget.livePulse && _pulse != null) {
      _pulse!.dispose();
      _pulse = null;
    }
  }

  void _startPulse() {
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final pulse = _pulse;

    if (pulse == null || reduceMotion) {
      return CustomPaint(
        size: Size.infinite,
        painter: _MiniSparklinePainter(
          values: widget.values,
          color: widget.color,
          strokeWidth: widget.strokeWidth,
          filled: widget.filled,
          // Still draw a static marker so the endpoint reads as "latest".
          pulse: widget.livePulse ? 0.0 : null,
        ),
      );
    }

    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) => CustomPaint(
        size: Size.infinite,
        painter: _MiniSparklinePainter(
          values: widget.values,
          color: widget.color,
          strokeWidth: widget.strokeWidth,
          filled: widget.filled,
          pulse: pulse.value,
        ),
      ),
    );
  }
}

class _MiniSparklinePainter extends CustomPainter {
  _MiniSparklinePainter({
    required this.values,
    required this.color,
    required this.strokeWidth,
    required this.filled,
    this.pulse,
  });

  final List<double> values;
  final Color color;
  final double strokeWidth;
  final bool filled;

  /// 0..1 pulse phase, or null for no live marker at all.
  final double? pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final series = values.where((v) => v.isFinite).toList(growable: false);
    if (series.length < 2 || size.width <= 0 || size.height <= 0) {
      return;
    }

    var minV = series.first;
    var maxV = series.first;
    for (final v in series) {
      if (v < minV) minV = v;
      if (v > maxV) maxV = v;
    }
    final range = (maxV - minV) <= 0 ? 1.0 : (maxV - minV);

    final stepX = size.width / (series.length - 1);
    final points = <Offset>[
      for (var i = 0; i < series.length; i++)
        Offset(i * stepX, size.height - ((series[i] - minV) / range) * size.height),
    ];

    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      line.lineTo(p.dx, p.dy);
    }

    if (filled) {
      final fill = Path()
        ..moveTo(points.first.dx, size.height)
        ..lineTo(points.first.dx, points.first.dy);
      for (final p in points.skip(1)) {
        fill.lineTo(p.dx, p.dy);
      }
      fill
        ..lineTo(points.last.dx, size.height)
        ..close();
      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.30),
            color.withValues(alpha: 0.02),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawPath(fill, fillPaint);
    }

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(line, linePaint);

    // Live marker on the most recent point: a halo that swells and fades on
    // a loop, plus a solid dot. Same idea as the blinking last-price dot in
    // real trading apps — it makes a static line read as still-updating.
    final phase = pulse;
    if (phase != null) {
      final last = points.last;
      final swell = Curves.easeOut.transform(phase.clamp(0.0, 1.0));
      canvas.drawCircle(
        last,
        strokeWidth * (1.4 + swell * 2.6),
        Paint()..color = color.withValues(alpha: (1 - swell) * 0.45),
      );
      canvas.drawCircle(
        last,
        strokeWidth * 1.25,
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MiniSparklinePainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.filled != filled ||
        oldDelegate.pulse != pulse;
  }
}
