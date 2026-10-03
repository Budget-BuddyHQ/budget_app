import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_assets.dart';
import '../themes_colors/app_theme.dart';

/// Pictures for the Market Board, so its screens are not all words.
///
/// **Reported as:** *"it's kinda looking bland right now ... it just looks like
/// all words and nothing else."* Every number on the holding screen and the
/// Analytics tab was a label over a figure. These draw the same figures as
/// shapes — bars, a slice, a range — and put the turtle and the kit's pixel
/// icons next to them, so a player can see the answer before reading it.

const Color kMarketUp = Color(0xFF9BE870);
const Color kMarketDown = Color(0xFFFF8A80);

/// One of the UI kit's pixel icons, kept crisp.
class KitIcon extends StatelessWidget {
  const KitIcon(this.asset, {super.key, this.size = 22});

  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: size,
      height: size,
      filterQuality: FilterQuality.none,
      errorBuilder: (_, _, _) => SizedBox(width: size, height: size),
    );
  }
}

/// How the turtle looks while it says something.
enum BuddyMood { happy, thinking, worried }

/// The mascot with one sentence about what the numbers below mean.
class BuddySaysCard extends StatelessWidget {
  const BuddySaysCard({
    super.key,
    required this.mood,
    required this.title,
    required this.message,
  });

  final BuddyMood mood;
  final String title;
  final String message;

  String get _art => switch (mood) {
    BuddyMood.happy => AppAssets.turtleMentorWave,
    BuddyMood.thinking => AppAssets.turtleMentorThinking,
    BuddyMood.worried => AppAssets.turtleMentorWorried,
  };

  Color get _accent => switch (mood) {
    BuddyMood.happy => kMarketUp,
    BuddyMood.thinking => const Color(0xFF7FD8F2),
    BuddyMood.worried => const Color(0xFFFFC36B),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 12, 16, 12),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          _accent.withValues(alpha: 0.10),
          const Color(0xFF202F36),
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accent.withValues(alpha: 0.5), width: 1.5),
        boxShadow: AppTheme.ledgeShadow(_accent, restAlpha: 0.15),
      ),
      child: Row(
        children: [
          Image.asset(
            _art,
            width: 76,
            height: 76,
            filterQuality: FilterQuality.none,
            errorBuilder: (_, _, _) =>
                Image.asset(AppAssets.coolTurtle, width: 76, height: 76),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.pixelifySans(
                    color: _accent,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Up and down bars around a zero line, one per label: how a price moved
/// over each stretch, drawn so a bad month looks like a hole.
class ReturnBars extends StatelessWidget {
  const ReturnBars({super.key, required this.entries, this.height = 150});

  /// (label, percent change).
  final List<(String, double)> entries;
  final double height;

  @override
  Widget build(BuildContext context) {
    final biggest = entries.fold<double>(1, (m, e) => math.max(m, e.$2.abs()));
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (label, pct) in entries)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Column(
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, c) {
                          final half = (c.maxHeight - 18) / 2;
                          final bar = math.max(3.0, half * pct.abs() / biggest);
                          final up = pct >= 0;
                          return Stack(
                            children: [
                              Positioned(
                                left: 0,
                                right: 0,
                                top: 9 + half,
                                child: Container(
                                  height: 1,
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              Positioned(
                                left: 0,
                                right: 0,
                                top: up ? 9 + half - bar : 9 + half,
                                height: bar,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: up ? kMarketUp : kMarketDown,
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(up ? 4 : 0),
                                      bottom: Radius.circular(up ? 0 : 4),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 0,
                                right: 0,
                                top: up
                                    ? 9 + half - bar - 16
                                    : 9 + half + bar + 2,
                                // scaleDown, not the default: the box is
                                // the bar's full width, and a FittedBox
                                // left to fill it blows a short label up
                                // to headline size.
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '${up ? '+' : ''}${pct.toStringAsFixed(1)}%',
                                    style: AppTheme.numeric(
                                      color: up ? kMarketUp : kMarketDown,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: AppTheme.numeric(
                        color: AppTheme.textMuted,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A ring with one slice filled: how much of the whole one part is.
class SliceRing extends StatelessWidget {
  const SliceRing({
    super.key,
    required this.fraction,
    required this.color,
    this.size = 92,
    this.center,
  });

  final double fraction;
  final Color color;
  final double size;
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SlicePainter(fraction.clamp(0.0, 1.0), color),
        child: Center(child: center),
      ),
    );
  }
}

class _SlicePainter extends CustomPainter {
  _SlicePainter(this.fraction, this.color);

  final double fraction;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 12.0;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (size.shortestSide - stroke) / 2,
    );
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = const Color(0xFF18252B),
    );
    if (fraction <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2 * fraction,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_SlicePainter old) =>
      old.fraction != fraction || old.color != color;
}

/// A ring split two ways, for "this many up, this many down".
class SplitRing extends StatelessWidget {
  const SplitRing({
    super.key,
    required this.left,
    required this.right,
    this.size = 92,
    this.center,
  });

  final int left;
  final int right;
  final double size;
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    final total = left + right;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SplitPainter(total == 0 ? 0 : left / total, total > 0),
        child: Center(child: center),
      ),
    );
  }
}

class _SplitPainter extends CustomPainter {
  _SplitPainter(this.fraction, this.any);

  final double fraction;
  final bool any;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 12.0;
    const gap = 0.06;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (size.shortestSide - stroke) / 2,
    );
    Paint p(Color c) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = c;
    if (!any) {
      canvas.drawArc(rect, 0, math.pi * 2, false, p(const Color(0xFF18252B)));
      return;
    }
    final upSweep = math.pi * 2 * fraction;
    if (fraction >= 1 || fraction <= 0) {
      canvas.drawArc(
        rect,
        0,
        math.pi * 2,
        false,
        p(fraction >= 1 ? kMarketUp : kMarketDown),
      );
      return;
    }
    canvas.drawArc(
      rect,
      -math.pi / 2 + gap / 2,
      upSweep - gap,
      false,
      p(kMarketUp),
    );
    canvas.drawArc(
      rect,
      -math.pi / 2 + upSweep + gap / 2,
      math.pi * 2 - upSweep - gap,
      false,
      p(kMarketDown),
    );
  }

  @override
  bool shouldRepaint(_SplitPainter old) =>
      old.fraction != fraction || old.any != any;
}

/// Where a value sits between a low and a high, with the three points
/// labelled under the track: the rough year, today, the good year.
class RangeTrack extends StatelessWidget {
  const RangeTrack({
    super.key,
    required this.low,
    required this.mid,
    required this.high,
    required this.lowLabel,
    required this.midLabel,
    required this.highLabel,
  });

  final double low;
  final double mid;
  final double high;
  final String lowLabel;
  final String midLabel;
  final String highLabel;

  @override
  Widget build(BuildContext context) {
    final t = high > low ? ((mid - low) / (high - low)).clamp(0.0, 1.0) : 0.5;
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        Widget label(String text, Color color, double x, {bool end = false}) =>
            Positioned(
              left: end ? null : x,
              right: end ? 0 : null,
              top: 26,
              child: Text(
                text,
                style: AppTheme.numeric(color: color, fontSize: 11.5),
              ),
            );
        return SizedBox(
          height: 44,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Three flat segments: down, around today, up.
              Positioned(
                left: 0,
                right: 0,
                top: 8,
                height: 10,
                child: Row(
                  children: [
                    Expanded(
                      flex: math.max(1, (t * 100).round()),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: kMarketDown,
                          borderRadius: BorderRadius.horizontal(
                            left: Radius.circular(5),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: math.max(1, ((1 - t) * 100).round()),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: kMarketUp,
                          borderRadius: BorderRadius.horizontal(
                            right: Radius.circular(5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: (w - 4) * t,
                top: 2,
                child: Container(
                  width: 4,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              label(lowLabel, kMarketDown, 0),
              Positioned(
                left: ((w * t) - 30).clamp(60.0, math.max(60.0, w - 130)),
                top: 26,
                child: Text(
                  midLabel,
                  style: AppTheme.numeric(color: Colors.white, fontSize: 11.5),
                ),
              ),
              label(highLabel, kMarketUp, 0, end: true),
            ],
          ),
        );
      },
    );
  }
}

/// Bars that grow left for a loss and right for a gain, one row per stock,
/// so "where is my money coming from" is a picture.
class GainLossBars extends StatelessWidget {
  const GainLossBars({super.key, required this.rows});

  /// (leading picture, label, gain or loss in coins, value text, onTap).
  final List<(Widget, String, double, String, VoidCallback?)> rows;

  @override
  Widget build(BuildContext context) {
    final biggest = rows.fold<double>(1, (m, r) => math.max(m, r.$3.abs()));
    return Column(
      children: [
        for (final (lead, label, value, text, onTap) in rows)
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(width: 30, height: 30, child: lead),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 52,
                    child: Text(
                      label,
                      style: AppTheme.numeric(
                        color: Colors.white,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final half = c.maxWidth / 2;
                        final len = math.max(2.0, half * value.abs() / biggest);
                        final up = value >= 0;
                        return SizedBox(
                          height: 18,
                          child: Stack(
                            children: [
                              Positioned(
                                left: half,
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  width: 1,
                                  color: Colors.white.withValues(alpha: 0.25),
                                ),
                              ),
                              Positioned(
                                left: up ? half : half - len,
                                width: len,
                                top: 3,
                                bottom: 3,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: up ? kMarketUp : kMarketDown,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 84,
                    child: FittedBox(
                      alignment: Alignment.centerRight,
                      fit: BoxFit.scaleDown,
                      child: Text(
                        text,
                        style: AppTheme.numeric(
                          color: value >= 0 ? kMarketUp : kMarketDown,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
