import 'dart:math' as math;

import 'package:flutter/gestures.dart';
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

  /// Width reserved on the right for the price labels, so the plotted area
  /// stops short of the widget's full width.
  ///
  /// Public because anything mapping a pointer position onto a candle index
  /// has to subtract it — [InteractivePriceChart] does, and the Market Board
  /// used to hardcode its own copy of '52', which is exactly the kind of
  /// duplicated constant that drifts.
  static const double axisGutter = 52;

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

/// [PriceChart] you can actually move: pinch to zoom, drag to pan, drag to
/// scrub a crosshair, with buttons for anything a gesture cannot do.
///
/// **Why this was rebuilt.** "I still cannot zoom on the buy screen" came
/// back three times, and there were two separate causes.
///
/// The order ticket *was* using the interactive wrapper, and its +/- buttons
/// did work — but the buttons are a 28px control in a corner, and what
/// people actually try is to pinch or drag. Those did nothing, because the
/// old wrapper drove them from a `ScaleGestureRecognizer`, which accepts
/// pointers in **any** direction and therefore fights the enclosing vertical
/// `ListView` for every gesture. The list wins. So the feature was there,
/// the maths was right, and it was unreachable by the input anyone would
/// use.
///
/// The other three charts — the Market Board's detail sparkline, the P&L
/// curve and the net-worth trend — used the plain [PriceChart] directly and
/// were not interactive at all.
///
/// The gesture design is the part that is genuinely hard here, because this
/// chart lives inside a **vertical** `ListView`:
///
/// - **One finger, horizontal.** A `HorizontalDragGestureRecognizer` never
///   competes with a vertical `ListView`, so it always wins — which is why
///   the single-finger interaction is on horizontal drag rather than on a
///   scale recognizer. A scale recognizer accepts pointers in *any*
///   direction, so it fights the parent list for every vertical pixel and
///   usually loses. That is the arena fight the previous version kept
///   losing.
/// - **What that drag does depends on zoom.** At 1x the whole series is on
///   screen and there is nowhere to pan to, so dragging scrubs the
///   crosshair. Zoomed in, dragging pans — which is what someone who just
///   zoomed in expects.
/// - **Two fingers.** Pinch zooms, anchored on the focal point rather than
///   on the center, so the candle under your fingers stays put. Two-pointer
///   gestures do not conflict with a one-pointer list drag.
/// - **Buttons.** Zoom in, out, fit, and pan left/right. Not decoration: a
///   mouse has no pinch, a trackpad's pinch is inconsistent across
///   platforms, and buttons cannot be stolen by a parent scrollable no
///   matter who wins the arena.
///
/// The window is stored as **integer candle indices**, not as a zoom factor
/// plus a fractional center. A fractional center drifts as it is repeatedly
/// re-derived, so a pan-zoom-pan sequence would not land back where it
/// started. With indices the visible slice is exactly what it says it is,
/// and the price axis stays honest because [PriceChart] only ever sees the
/// candles actually on screen.
class InteractivePriceChart extends StatefulWidget {
  const InteractivePriceChart({
    super.key,
    required this.candles,
    required this.mode,
    required this.accent,
    this.onHoverIndexChanged,
  });

  final List<Candle> candles;
  final ChartMode mode;
  final Color accent;

  /// Reports the crosshair position in **whole-series** coordinates, so a
  /// caller showing "the price at this point" reads the same candle the user
  /// is touching however far the view is zoomed in.
  final ValueChanged<int?>? onHoverIndexChanged;

  @override
  State<InteractivePriceChart> createState() => _InteractivePriceChartState();
}

class _InteractivePriceChartState extends State<InteractivePriceChart> {
  /// Index of the first visible candle in the full series.
  int _start = 0;

  /// How many candles are visible. Equal to the series length at 1x.
  int _count = 0;

  /// Crosshair, in whole-series coordinates. Null when not scrubbing.
  int? _hover;

  // Captured when a gesture begins, so each update is applied against the
  // state the gesture started from. Accumulating frame-by-frame deltas
  // instead would round every frame to whole candles and lose all
  // sub-candle movement, making a slow drag do nothing at all.
  int _startAtBegin = 0;
  int _countAtBegin = 0;
  double _dragOriginDx = 0;
  double _focalFracAtBegin = 0.5;

  /// Never show fewer than this many candles — below it the chart is a
  /// couple of bars and a price axis, which is not a chart.
  static const int _minVisible = 6;

  int get _total => widget.candles.length;
  int get _floor => _minVisible < _total ? _minVisible : _total;
  bool get _isZoomed => _count < _total;

  @override
  void initState() {
    super.initState();
    _count = _total;
  }

  @override
  void didUpdateWidget(covariant InteractivePriceChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // different series (new symbol, new timeframe). an old window is
    // meaningless against it and could point off the end
    if (oldWidget.candles.length != widget.candles.length) {
      setState(_resetView);
    }
  }

  void _resetView() {
    _start = 0;
    _count = _total;
    _hover = null;
    widget.onHoverIndexChanged?.call(null);
  }

  void _clampWindow() {
    if (_total == 0) {
      _start = 0;
      _count = 0;
      return;
    }
    _count = _count.clamp(_floor, _total);
    _start = _start.clamp(0, _total - _count);
  }

  /// Zooms so that [anchorFrac] of the visible width stays put.
  void _zoomBy(double factor, {double anchorFrac = 0.5}) {
    if (_total < 2) return;
    final anchorIndex = _start + anchorFrac * _count;
    setState(() {
      _count = (_count / factor).round().clamp(_floor, _total);
      _start = (anchorIndex - anchorFrac * _count).round();
      _clampWindow();
    });
  }

  void _nudge(int direction) {
    setState(() {
      _start += direction * (_count * 0.4).round().clamp(1, _total);
      _clampWindow();
    });
  }

  void _panTo(double currentDx, double width) {
    if (!_isZoomed || width <= 0) return;
    // content follows the finger. drag right = earlier candles
    final candlesPerPixel = _count / width;
    setState(() {
      _start = (_startAtBegin - (currentDx - _dragOriginDx) * candlesPerPixel)
          .round();
      _clampWindow();
    });
  }

  void _scrubTo(double dx, double width) {
    if (width <= 0 || _total == 0) return;
    final frac = (dx / width).clamp(0.0, 1.0);
    final index = (_start + frac * (_count - 1)).round().clamp(0, _total - 1);
    if (index == _hover) return;
    setState(() => _hover = index);
    widget.onHoverIndexChanged?.call(index);
  }

  void _clearHover() {
    if (_hover == null) return;
    setState(() => _hover = null);
    widget.onHoverIndexChanged?.call(null);
  }

  @override
  Widget build(BuildContext context) {
    if (_total < 2) {
      return PriceChart(
        candles: widget.candles,
        mode: widget.mode,
        accent: widget.accent,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // plotted area stops short of the right edge, painter keeps a
        // gutter there for the price labels. if you map pointer x to a
        // candle index against the *full* width the crosshair drifts ahead
        // of your finger, gets worse the further right you go
        final width = (constraints.maxWidth - PriceChart.axisGutter).clamp(
          1.0,
          constraints.maxWidth <= 0 ? 1.0 : constraints.maxWidth,
        );
        _clampWindow();
        final visible = widget.candles.sublist(_start, _start + _count);
        // The painter indexes into the *visible* slice, so the crosshair is
        // translated into that frame — and dropped entirely once the
        // hovered candle has been panned off screen.
        final offset = _hover == null ? -1 : _hover! - _start;
        final localHover = offset >= 0 && offset < visible.length
            ? offset
            : null;

        return Stack(
          children: [
            Positioned.fill(
              child: RawGestureDetector(
                behavior: HitTestBehavior.opaque,
                gestures: <Type, GestureRecognizerFactory>{
                  // Horizontal only — see the class doc. This is what keeps
                  // the parent ListView out of the fight.
                  HorizontalDragGestureRecognizer:
                      GestureRecognizerFactoryWithHandlers<
                        HorizontalDragGestureRecognizer
                      >(HorizontalDragGestureRecognizer.new, (recognizer) {
                        recognizer
                          ..onStart = (details) {
                            _startAtBegin = _start;
                            _dragOriginDx = details.localPosition.dx;
                            if (!_isZoomed) {
                              _scrubTo(details.localPosition.dx, width);
                            }
                          }
                          ..onUpdate = (details) {
                            if (_isZoomed) {
                              _panTo(details.localPosition.dx, width);
                            } else {
                              _scrubTo(details.localPosition.dx, width);
                            }
                          }
                          ..onEnd = (_) {
                            if (!_isZoomed) _clearHover();
                          }
                          ..onCancel = _clearHover;
                      }),
                  // Two fingers or more: pinch. Ignoring single-pointer
                  // scales is what stops this recognizer claiming ordinary
                  // vertical list drags.
                  ScaleGestureRecognizer:
                      GestureRecognizerFactoryWithHandlers<
                        ScaleGestureRecognizer
                      >(ScaleGestureRecognizer.new, (recognizer) {
                        recognizer
                          ..onStart = (details) {
                            if (details.pointerCount < 2) return;
                            _startAtBegin = _start;
                            _countAtBegin = _count;
                            _focalFracAtBegin =
                                (details.localFocalPoint.dx / width).clamp(
                                  0.0,
                                  1.0,
                                );
                          }
                          ..onUpdate = (details) {
                            if (details.pointerCount < 2) return;
                            final anchorIndex =
                                _startAtBegin +
                                _focalFracAtBegin * _countAtBegin;
                            setState(() {
                              _count = (_countAtBegin / details.scale)
                                  .round()
                                  .clamp(_floor, _total);
                              _start =
                                  (anchorIndex - _focalFracAtBegin * _count)
                                      .round();
                              _clampWindow();
                            });
                          };
                      }),
                },
                child: MouseRegion(
                  // A mouse has no pinch and no drag-to-scrub, so hovering
                  // does the scrubbing on desktop and web.
                  onHover: (event) => _scrubTo(event.localPosition.dx, width),
                  onExit: (_) => _clearHover(),
                  child: PriceChart(
                    candles: visible,
                    mode: widget.mode,
                    accent: widget.accent,
                    hoverIndex: localHover,
                  ),
                ),
              ),
            ),
            // Left, not right: the right-hand gutter holds the price labels,
            // so controls over there would sit on top of the numbers.
            Positioned(
              left: 4,
              top: 4,
              child: Column(
                children: [
                  _ZoomButton(
                    icon: Icons.add_rounded,
                    accent: widget.accent,
                    onTap: _count <= _floor ? null : () => _zoomBy(1.6),
                  ),
                  const SizedBox(height: 6),
                  _ZoomButton(
                    icon: Icons.remove_rounded,
                    accent: widget.accent,
                    onTap: !_isZoomed ? null : () => _zoomBy(1 / 1.6),
                  ),
                  if (_isZoomed) ...[
                    const SizedBox(height: 6),
                    _ZoomButton(
                      icon: Icons.fit_screen_rounded,
                      accent: widget.accent,
                      onTap: () => setState(_resetView),
                    ),
                  ],
                ],
              ),
            ),
            // Pan arrows, only while there is somewhere to pan to.
            //
            // Not redundant with the drag: on a mouse, hovering scrubs and
            // there is no drag-to-pan at all, so without these a desktop user
            // could zoom in and then never move the window.
            if (_isZoomed)
              Positioned(
                left: 4,
                bottom: 4,
                right: 56,
                child: Row(
                  children: [
                    _ZoomButton(
                      icon: Icons.chevron_left_rounded,
                      accent: widget.accent,
                      onTap: _start <= 0 ? null : () => _nudge(-1),
                    ),
                    const Spacer(),
                    _ZoomButton(
                      icon: Icons.chevron_right_rounded,
                      accent: widget.accent,
                      onTap: _start + _count >= _total ? null : () => _nudge(1),
                    ),
                  ],
                ),
              ),
            // Says what you are looking at. Without it a zoomed chart is
            // indistinguishable from a shorter timeframe.
            if (_isZoomed)
              Positioned(
                left: 40,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1F17).withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$_count of $_total bars',
                    style: GoogleFonts.quicksand(
                      color: widget.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
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

  static const Color _up = Color(0xFF9BE870);
  static const Color _down = Color(0xFFFF8A80);
  static const double _gutter = PriceChart.axisGutter;

  /// Height reserved at the bottom for date labels.
  static const double _axisHeight = 16;

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

    // Reserve a strip at the bottom for the date labels, so the plotted line
    // stops above them instead of running underneath the text. Only when
    // there is genuinely room — on a short sparkline the prices matter more
    // than the dates, and squeezing both makes neither readable.
    final axisRoom = showAxis && size.height > 90 ? _axisHeight : 0.0;
    final plotHeight = size.height - axisRoom;

    double y(double value) =>
        plotHeight - ((value - minV) / range) * plotHeight;

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

    if (axisRoom > 0) {
      _paintTimeAxis(canvas, size, chartWidth, bars);
    }
    _paintCrosshair(canvas, size, chartWidth, plotHeight, bars, y);
  }

  /// The scrub readout: a vertical line, a dot on the series, a price tag
  /// pinned to the axis, and a card naming the value and the moment.
  ///
  /// The dot alone used to be the whole thing, which meant scrubbing told
  /// you *where* you were pointing and never *what* was there — you could
  /// see the line dip and still have no idea what price the dip was. Every
  /// real trading app answers that question at the crosshair, because
  /// reading a value off a y-axis by eye is exactly the work a chart exists
  /// to save you.
  void _paintCrosshair(
    Canvas canvas,
    Size size,
    double chartWidth,
    // The plot area stops above the date labels; the crosshair has to stop
    // with it or the scrub line draws straight through the dates.
    double plotHeight,
    List<Candle> bars,
    double Function(double) y,
  ) {
    final index = hoverIndex;
    if (index == null || index < 0 || index >= bars.length) {
      return;
    }
    final bar = bars[index];
    final stepX = bars.length > 1 ? chartWidth / (bars.length - 1) : chartWidth;
    final x = (index * stepX).clamp(0.0, chartWidth);
    final cy = y(bar.close).clamp(0.0, plotHeight);

    // Dashed, so it reads as a measurement overlay rather than as another
    // series drawn on the chart.
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 1;
    const dash = 4.0;
    for (var dy = 0.0; dy < plotHeight; dy += dash * 2) {
      canvas.drawLine(
        Offset(x, dy),
        Offset(x, (dy + dash).clamp(0, plotHeight)),
        linePaint,
      );
    }
    for (var dx = 0.0; dx < chartWidth; dx += dash * 2) {
      canvas.drawLine(
        Offset(dx, cy),
        Offset((dx + dash).clamp(0, chartWidth), cy),
        linePaint,
      );
    }

    // The marker itself: a haloed dot with a white ring, so it stays visible
    // over both the filled area under the line and the empty space above it.
    canvas.drawCircle(
      Offset(x, cy),
      7,
      Paint()..color = accent.withValues(alpha: 0.25),
    );
    canvas.drawCircle(Offset(x, cy), 4.5, Paint()..color = Colors.white);
    canvas.drawCircle(Offset(x, cy), 3, Paint()..color = accent);

    if (showAxis) {
      _priceTag(canvas, size, chartWidth, cy, _fmt(bar.close), accent);
    }
    _scrubCard(canvas, size, chartWidth, x, bar);
  }

  /// The value, pinned into the right-hand gutter beside the axis labels.
  void _priceTag(
    Canvas canvas,
    Size size,
    double chartWidth,
    double cy,
    String text,
    Color color,
  ) {
    final tp = _textPainter(text, Colors.white, bold: true);
    final rect = Rect.fromLTWH(
      chartWidth + 2,
      cy - tp.height / 2 - 3,
      tp.width + 10,
      tp.height + 6,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      Paint()..color = color,
    );
    tp.paint(canvas, Offset(rect.left + 5, rect.top + 3));
  }

  /// The card above the marker: price, move since the bar opened, and when.
  ///
  /// Flipped to the other side of the crosshair near the right-hand edge, so
  /// it never runs off the canvas — a readout you cannot read is worse than
  /// no readout, and the right edge is exactly where the newest and most
  /// interesting bars live.
  void _scrubCard(
    Canvas canvas,
    Size size,
    double chartWidth,
    double x,
    Candle bar,
  ) {
    final change = bar.close - bar.open;
    final pct = bar.open == 0 ? 0.0 : change / bar.open * 100;
    final lines = <(String, Color)>[
      (_fmt(bar.close), Colors.white),
      (
        '${change >= 0 ? '+' : ''}${_fmt(change)} '
            '(${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(2)}%)',
        change >= 0 ? const Color(0xFF6CD34A) : const Color(0xFFFF6B6B),
      ),
      (_stamp(bar.time), Colors.white.withValues(alpha: 0.62)),
    ];

    final painters = [
      for (final (text, color) in lines)
        _textPainter(text, color, bold: text == lines.first.$1),
    ];
    final w = painters.map((p) => p.width).reduce(math.max) + 16;
    final h = painters.fold<double>(0, (sum, p) => sum + p.height + 2) + 10;

    // Prefer the right of the crosshair; flip when that would overflow.
    var left = x + 12;
    if (left + w > chartWidth) {
      left = x - 12 - w;
    }
    left = left.clamp(0.0, math.max(0.0, chartWidth - w)).toDouble();
    final top = 6.0.clamp(0.0, math.max(0.0, size.height - h)).toDouble();

    final rect = Rect.fromLTWH(left, top, w, h);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()..color = const Color(0xFF071710).withValues(alpha: 0.92),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      Paint()
        ..color = accent.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    var dy = top + 5;
    for (final tp in painters) {
      tp.paint(canvas, Offset(left + 8, dy));
      dy += tp.height + 2;
    }
  }

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// Whether these bars are finer than a day, so a clock time means anything.
  ///
  /// Measured from the **median gap between consecutive bars**, not from the
  /// series' total span. Two reasons, and the first is a bug this replaced:
  /// [candles] is the *visible window* when this sits inside an
  /// [InteractivePriceChart], so a total-span test changed its answer as the
  /// user zoomed — a 5D chart zoomed down to nineteen bars silently dropped
  /// from "25 Aug 10:40" to "10:40" mid-gesture. Bar spacing does not move
  /// when the window narrows.
  ///
  /// Median rather than mean because a daily series jumps three days across
  /// every weekend and a month across some holidays; an average of those
  /// lands between "daily" and "weekly" and decides nothing.
  bool get _barsAreIntraday {
    if (candles.length < 2) return false;
    final gaps = <int>[
      for (var i = 1; i < candles.length; i++)
        candles[i].time.difference(candles[i - 1].time).inMinutes.abs(),
    ]..sort();
    final median = gaps[gaps.length ~/ 2];
    return median > 0 && median < 24 * 60;
  }

  /// A human date for one bar, with the clock time only where it means
  /// something.
  ///
  /// The date is always present. An earlier version dropped it on intraday
  /// charts on the theory that a one-day series makes the date redundant —
  /// which is wrong the moment the chart can be zoomed and panned, because
  /// then "10:40" alone does not say *which* 10:40, and the whole point of
  /// scrubbing is to ask exactly that.
  ///
  /// The year appears only when the bar is not from the current year, so a
  /// 1D chart stays short while a 5Y chart stays unambiguous.
  String _stamp(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    final month = _months[(t.month - 1).clamp(0, 11)];
    var out = '${t.day} $month';
    if (t.year != DateTime.now().year) {
      out = '$out ${two(t.year % 100)}';
    }
    if (_barsAreIntraday) {
      out = '$out  ${two(t.hour)}:${two(t.minute)}';
    }
    return out;
  }

  /// A short axis label — the same date, trimmed hard enough to sit three
  /// across the bottom of a phone-width chart without colliding.
  String _axisStamp(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    if (_barsAreIntraday) {
      return '${two(t.hour)}:${two(t.minute)}';
    }
    final month = _months[(t.month - 1).clamp(0, 11)];
    if (t.year != DateTime.now().year) {
      return '$month ${two(t.year % 100)}';
    }
    return '${t.day} $month';
  }

  /// Dates along the bottom.
  ///
  /// The chart had **no horizontal axis at all** — it showed prices against
  /// nothing, so a shape was readable but never locatable in time. Three
  /// labels (first, middle, last) is the most a phone-width chart can carry
  /// without them colliding, and it is enough to answer "what period am I
  /// looking at", which is the question a range chart exists to answer.
  void _paintTimeAxis(
    Canvas canvas,
    Size size,
    double chartWidth,
    List<Candle> bars,
  ) {
    if (bars.length < 2 || chartWidth < 120) return;

    final slots = <(int, TextAlign)>[
      (0, TextAlign.left),
      (bars.length ~/ 2, TextAlign.center),
      (bars.length - 1, TextAlign.right),
    ];
    for (final (index, align) in slots) {
      final tp = _textPainter(
        _axisStamp(bars[index].time),
        Colors.white.withValues(alpha: 0.42),
      );
      final center = chartWidth * (index / (bars.length - 1));
      final x = switch (align) {
        TextAlign.left => 0.0,
        TextAlign.right => chartWidth - tp.width,
        _ => center - tp.width / 2,
      };
      tp.paint(
        canvas,
        Offset(
          x.clamp(0.0, math.max(0.0, chartWidth - tp.width)),
          size.height - tp.height,
        ),
      );
    }
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
      // A flat, light tint under the line rather than a glowing fade:
      // the fade was part of what a tester called "too AI".
      Paint()..color = accent.withValues(alpha: 0.12),
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
