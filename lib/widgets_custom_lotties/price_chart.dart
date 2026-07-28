import 'package:flutter/material.dart';

import '../services_backend_and_other_services/market_data_service.dart';

enum ChartMode { line, candle }

/// A price chart that draws either a filled line or candlestick bars.
///
/// Like [MiniSparkline] this maps values straight onto the canvas with no
/// axis/grid/interval machinery, which is deliberate — that machinery is
/// exactly what made fl_chart throw "Infinity or NaN" at small widths.
class PriceChart extends StatelessWidget {
  const PriceChart({
    super.key,
    required this.candles,
    required this.mode,
    required this.accent,
  });

  final List<Candle> candles;
  final ChartMode mode;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (candles.length < 2) {
      return Center(
        child: Text(
          'No chart data',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
        ),
      );
    }
    return CustomPaint(
      size: Size.infinite,
      painter: _PriceChartPainter(
        candles: candles,
        mode: mode,
        accent: accent,
      ),
    );
  }
}

class _PriceChartPainter extends CustomPainter {
  _PriceChartPainter({
    required this.candles,
    required this.mode,
    required this.accent,
  });

  final List<Candle> candles;
  final ChartMode mode;
  final Color accent;

  static const Color _up = Color(0xFF85EFAC);
  static const Color _down = Color(0xFFFF8A80);

  @override
  void paint(Canvas canvas, Size size) {
    final bars = candles.where((c) => c.isValid).toList(growable: false);
    if (bars.length < 2 || size.width <= 0 || size.height <= 0) {
      return;
    }

    var minV = bars.first.low;
    var maxV = bars.first.high;
    for (final c in bars) {
      if (c.low < minV) minV = c.low;
      if (c.high > maxV) maxV = c.high;
    }
    final range = (maxV - minV) <= 0 ? 1.0 : (maxV - minV);

    double y(double value) => size.height - ((value - minV) / range) * size.height;

    if (mode == ChartMode.line) {
      _paintLine(canvas, size, bars, y);
    } else {
      _paintCandles(canvas, size, bars, y);
    }
  }

  void _paintLine(
    Canvas canvas,
    Size size,
    List<Candle> bars,
    double Function(double) y,
  ) {
    final stepX = size.width / (bars.length - 1);
    final points = <Offset>[
      for (var i = 0; i < bars.length; i++) Offset(i * stepX, y(bars[i].close)),
    ];

    final fill = Path()..moveTo(points.first.dx, size.height);
    for (final p in points) {
      fill.lineTo(p.dx, p.dy);
    }
    fill
      ..lineTo(points.last.dx, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accent.withValues(alpha: 0.30),
            accent.withValues(alpha: 0.02),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      line.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  void _paintCandles(
    Canvas canvas,
    Size size,
    List<Candle> bars,
    double Function(double) y,
  ) {
    final slot = size.width / bars.length;
    // Keep a visible gap between bars, but never let the body vanish on a
    // narrow phone with 90 bars on screen.
    final bodyWidth = (slot * 0.62).clamp(1.0, 14.0);

    for (var i = 0; i < bars.length; i++) {
      final c = bars[i];
      final color = c.isUp ? _up : _down;
      final centerX = slot * i + slot / 2;

      canvas.drawLine(
        Offset(centerX, y(c.high)),
        Offset(centerX, y(c.low)),
        Paint()
          ..color = color
          ..strokeWidth = 1.1,
      );

      final openY = y(c.open);
      final closeY = y(c.close);
      final top = openY < closeY ? openY : closeY;
      final bottom = openY < closeY ? closeY : openY;
      canvas.drawRect(
        Rect.fromLTRB(
          centerX - bodyWidth / 2,
          top,
          centerX + bodyWidth / 2,
          // A doji (open == close) would be a zero-height invisible rect.
          bottom - top < 1 ? top + 1 : bottom,
        ),
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PriceChartPainter oldDelegate) {
    return oldDelegate.candles != candles ||
        oldDelegate.mode != mode ||
        oldDelegate.accent != accent;
  }
}
