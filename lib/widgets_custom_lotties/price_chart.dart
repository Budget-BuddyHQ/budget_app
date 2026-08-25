import 'package:flutter/material.dart';

import '../services_backend_and_other_services/market_data_service.dart';
import 'package:google_fonts/google_fonts.dart';

enum ChartMode { line, candle }

/// A price chart that draws either a filled line or candlestick bars, with a
/// price axis (labels + gridlines on the right) and a current-price marker.
///
/// Like [MiniSparkline] this maps values straight onto the canvas with no
/// axis/grid/interval machinery of a chart package, which is deliberate — that
/// machinery is exactly what made fl_chart throw "Infinity or NaN" at small
/// widths. The price labels here are computed directly from min/max, so there
/// is no interval solver that can blow up.
class PriceChart extends StatelessWidget {
  const PriceChart({
    super.key,
    required this.candles,
    required this.mode,
    required this.accent,
    this.showAxis = true,
    this.hoverIndex,
  });

  final List<Candle> candles;
  final ChartMode mode;
  final Color accent;

  /// Draws the right-hand price labels, gridlines, and current-price line.
  final bool showAxis;

  /// Index of the candle the pointer is over, if any. Drawn as a crosshair.
  /// Lives here rather than in an overlay so it shares the painter's exact
  /// min/max scaling — an overlay would have to duplicate that maths and would
  /// drift out of alignment the moment either side changed.
  final int? hoverIndex;

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
        showAxis: showAxis,
        hoverIndex: hoverIndex,
      ),
    );
  }
}

/// Wraps [PriceChart] with pinch-to-zoom and drag-to-pan by slicing the visible
/// candle window, so the price axis stays honest — it always labels the candles
/// actually on screen.
class InteractivePriceChart extends StatefulWidget {
  const InteractivePriceChart({
    super.key,
    required this.candles,
    required this.mode,
    required this.accent,
  });

  final List<Candle> candles;
  final ChartMode mode;
  final Color accent;

  @override
  State<InteractivePriceChart> createState() => _InteractivePriceChartState();
}

class _InteractivePriceChartState extends State<InteractivePriceChart> {
  double _zoom = 1;
  double _centerFrac = 1; // start focused on the most recent candles
  double _zoomAtStart = 1;

  @override
  void didUpdateWidget(covariant InteractivePriceChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new range/timeframe was loaded — reset the view.
    if (oldWidget.candles.length != widget.candles.length) {
      _zoom = 1;
      _centerFrac = 1;
    }
  }

  static const double _minZoom = 1;
  static const double _maxZoom = 8;

  void _setZoom(double next) {
    setState(() => _zoom = next.clamp(_minZoom, _maxZoom));
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.candles.length;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            // Opaque so the chart actually receives the pointer rather than
            // letting it fall through to the page behind.
            behavior: HitTestBehavior.opaque,
            onScaleStart: (_) => _zoomAtStart = _zoom,
            onScaleUpdate: (details) {
              setState(() {
                _zoom = (_zoomAtStart * details.scale).clamp(
                  _minZoom,
                  _maxZoom,
                );
                final width = context.size?.width ?? 1;
                // Drag right → pan back in time.
                _centerFrac =
                    (_centerFrac -
                            details.focalPointDelta.dx / (width * _zoom))
                        .clamp(0.0, 1.0);
              });
            },
            child: PriceChart(
              candles: _visibleCandles(total),
              mode: widget.mode,
              accent: widget.accent,
            ),
          ),
        ),
        // Explicit controls, not just pinch.
        //
        // This chart lives inside the order ticket's vertical ListView, and
        // a scale recogniser competes with that ListView's drag recogniser
        // in the gesture arena — the ListView usually wins, which is why
        // "pinch to zoom, drag to pan" did nothing on a phone however
        // correct the maths was. Buttons cannot be stolen by a parent
        // scrollable, so zoom works regardless of who wins the arena. They
        // are also simply more discoverable than an undocumented gesture.
        // Left, not right: the right 52px is the price-label gutter, so
        // buttons over there would sit on top of the numbers.
        Positioned(
          left: 4,
          top: 4,
          child: Column(
            children: [
              _ZoomButton(
                icon: Icons.add_rounded,
                accent: widget.accent,
                onTap: _zoom >= _maxZoom ? null : () => _setZoom(_zoom * 1.6),
              ),
              const SizedBox(height: 6),
              _ZoomButton(
                icon: Icons.remove_rounded,
                accent: widget.accent,
                onTap: _zoom <= _minZoom ? null : () => _setZoom(_zoom / 1.6),
              ),
              if (_zoom > _minZoom) ...[
                const SizedBox(height: 6),
                _ZoomButton(
                  icon: Icons.fit_screen_rounded,
                  accent: widget.accent,
                  onTap: () => setState(() {
                    _zoom = _minZoom;
                    _centerFrac = 1;
                  }),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  List<Candle> _visibleCandles(int total) {
    if (total < 2 || _zoom <= 1.0) {
      return widget.candles;
    }
    final visibleCount = (total / _zoom).round().clamp(2, total);
    final center = (_centerFrac * total).round();
    final start = (center - visibleCount ~/ 2).clamp(0, total - visibleCount);
    return widget.candles.sublist(start, start + visibleCount);
  }
}

class _PriceChartPainter extends CustomPainter {
  _PriceChartPainter({
    required this.candles,
    required this.mode,
    required this.accent,
    required this.showAxis,
    this.hoverIndex,
  });

  final List<Candle> candles;
  final ChartMode mode;
  final Color accent;
  final bool showAxis;
  final int? hoverIndex;

  static const Color _up = Color(0xFF85EFAC);
  static const Color _down = Color(0xFFFF8A80);
  static const double _gutter = 52; // room for price labels on the right

  @override
  void paint(Canvas canvas, Size size) {
    final bars = candles.where((c) => c.isValid).toList(growable: false);
    if (bars.length < 2 || size.width <= 0 || size.height <= 0) {
      return;
    }

    final gutter = showAxis ? _gutter : 0.0;
    final chartWidth = size.width - gutter;
    if (chartWidth <= 0) {
      return;
    }

    var minV = bars.first.low;
    var maxV = bars.first.high;
    for (final c in bars) {
      if (c.low < minV) minV = c.low;
      if (c.high > maxV) maxV = c.high;
    }
    final range = (maxV - minV) <= 0 ? 1.0 : (maxV - minV);

    double y(double value) =>
        size.height - ((value - minV) / range) * size.height;

    if (showAxis) {
      _paintGrid(canvas, size, chartWidth, minV, maxV, y);
    }

    if (mode == ChartMode.line) {
      _paintLine(canvas, size, chartWidth, bars, y);
    } else {
      _paintCandles(canvas, size, chartWidth, bars, y);
    }

    if (showAxis) {
      _paintCurrentPrice(canvas, size, chartWidth, bars.last.close, y);
    }

    _paintCrosshair(canvas, size, chartWidth, bars, y);
  }

  /// Vertical scrub line plus a dot on the series at the hovered point.
  void _paintCrosshair(
    Canvas canvas,
    Size size,
    double chartWidth,
    List<Candle> bars,
    double Function(double) y,
  ) {
    final index = hoverIndex;
    if (index == null || index < 0 || index >= bars.length) {
      return;
    }
    final stepX = chartWidth / (bars.length - 1);
    final x = (index * stepX).clamp(0.0, chartWidth);
    final cy = y(bars[index].close).clamp(0.0, size.height);

    canvas.drawLine(
      Offset(x, 0),
      Offset(x, size.height),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.45)
        ..strokeWidth = 1,
    );
    canvas.drawCircle(
      Offset(x, cy),
      5,
      Paint()..color = accent.withValues(alpha: 0.30),
    );
    canvas.drawCircle(Offset(x, cy), 2.6, Paint()..color = Colors.white);
  }

  void _paintGrid(
    Canvas canvas,
    Size size,
    double chartWidth,
    double minV,
    double maxV,
    double Function(double) y,
  ) {
    const levels = 4;
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (var i = 0; i <= levels; i++) {
      final value = minV + (maxV - minV) * (i / levels);
      final gy = y(value).clamp(0.0, size.height);
      canvas.drawLine(Offset(0, gy), Offset(chartWidth, gy), gridPaint);
      _label(
        canvas,
        _fmt(value),
        Offset(chartWidth + 6, gy),
        Colors.white.withValues(alpha: 0.5),
      );
    }
  }

  void _paintCurrentPrice(
    Canvas canvas,
    Size size,
    double chartWidth,
    double price,
    double Function(double) y,
  ) {
    final cy = y(price).clamp(0.0, size.height);
    // Dashed line across the chart at the latest price.
    final dash = Paint()
      ..color = accent.withValues(alpha: 0.7)
      ..strokeWidth = 1;
    const dashW = 5.0;
    for (var x = 0.0; x < chartWidth; x += dashW * 2) {
      canvas.drawLine(Offset(x, cy), Offset(x + dashW, cy), dash);
    }
    // A filled tag with the current price in the right gutter.
    final text = _fmt(price);
    final tp = _textPainter(text, const Color(0xFF08251A), bold: true);
    final tagRect = Rect.fromLTWH(
      chartWidth + 2,
      (cy - 9).clamp(0.0, size.height - 18),
      size.width - chartWidth - 4,
      18,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(tagRect, const Radius.circular(4)),
      Paint()..color = accent,
    );
    tp.paint(
      canvas,
      Offset(tagRect.left + 4, tagRect.top + (tagRect.height - tp.height) / 2),
    );
  }

  void _paintLine(
    Canvas canvas,
    Size size,
    double chartWidth,
    List<Candle> bars,
    double Function(double) y,
  ) {
    final stepX = chartWidth / (bars.length - 1);
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
        ).createShader(Rect.fromLTWH(0, 0, chartWidth, size.height)),
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

    // A static marker on the latest point — without this the line just
    // stops, with nothing telling you that end is "now" versus the axis
    // simply being cut off. Same idea as MiniSparkline's live-pulse dot.
    final last = points.last;
    canvas.drawCircle(last, 7, Paint()..color = accent.withValues(alpha: 0.22));
    canvas.drawCircle(last, 3.4, Paint()..color = accent);
    canvas.drawCircle(
      last,
      3.4,
      Paint()
        ..color = const Color(0xFF08251A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  void _paintCandles(
    Canvas canvas,
    Size size,
    double chartWidth,
    List<Candle> bars,
    double Function(double) y,
  ) {
    final slot = chartWidth / bars.length;
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

  String _fmt(double value) {
    // Coin prices are whole numbers in the thousands; keep them compact.
    if (value.abs() >= 1000) {
      return value.round().toString();
    }
    return value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1);
  }

  TextPainter _textPainter(String text, Color color, {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.pixelifySans(
          color: color,
          fontSize: 10,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    return tp;
  }

  void _label(Canvas canvas, String text, Offset at, Color color) {
    final tp = _textPainter(text, color);
    tp.paint(canvas, Offset(at.dx, at.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _PriceChartPainter oldDelegate) {
    return oldDelegate.candles != candles ||
        oldDelegate.mode != mode ||
        oldDelegate.accent != accent ||
        oldDelegate.showAxis != showAxis ||
        oldDelegate.hoverIndex != hoverIndex;
  }
}

/// A small square control on the chart. Deliberately a real tappable button
/// rather than a gesture hint — see [_InteractivePriceChartState.build].
class _ZoomButton extends StatelessWidget {
  const _ZoomButton({
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: const Color(0xFF0B1F17).withValues(alpha: enabled ? 0.78 : 0.45),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: accent.withValues(alpha: enabled ? 0.5 : 0.18),
            ),
          ),
          child: Icon(
            icon,
            size: 16,
            color: enabled ? accent : accent.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}
