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
class MiniSparkline extends StatelessWidget {
  const MiniSparkline({
    super.key,
    required this.values,
    required this.color,
    this.strokeWidth = 2.2,
    this.filled = true,
  });

  final List<double> values;
  final Color color;
  final double strokeWidth;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _MiniSparklinePainter(
        values: values,
        color: color,
        strokeWidth: strokeWidth,
        filled: filled,
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
  });

  final List<double> values;
  final Color color;
  final double strokeWidth;
  final bool filled;

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
  }

  @override
  bool shouldRepaint(covariant _MiniSparklinePainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.filled != filled;
  }
}
