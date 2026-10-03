import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models_Like_Skins_and_lessons_templates/money_habit_models.dart';
import '../themes_colors/app_theme.dart';
import 'idle_hover_icon.dart';

/// The Money Habits companion: a glass jar that fills with coins.
///
/// **Why this is painted rather than assembled.** The first version was a
/// Material `savings` glyph scaled up inside a tinted circle, with two dots
/// and a curve drawn over it for a face and a brown rectangle underneath for
/// a shelf. It had two problems that no amount of tinting fixes:
///
/// * It did not read as a jar. A monochrome icon in a disc reads as *an
///   icon*, and the thing it was standing in for — "look how much you have
///   put away" — needs a container you can see into.
/// * Progress was quantised to four glyph sizes. The player earns habit
///   points continuously and the jar jumped in four steps, so most of the
///   work they did was invisible.
///
/// So the jar is drawn: a glass body with a rim and a lid, a highlight down
/// one side, and a pile of individual coins whose **count follows [fill]
/// continuously**. Every point earned moves something.
///
/// Nothing here needs an `AnimationController` of its own — [IdleHoverIcon]
/// supplies the idle bob, and the coin layout is a pure function of [fill],
/// so a rebuild with a new value simply draws more coins.
class SavingsJarWidget extends StatelessWidget {
  const SavingsJarWidget({
    super.key,
    required this.stage,
    required this.mood,
    this.fill,
    this.size = 220,
  });

  final JarStage stage;
  final JarMood mood;

  /// 0..1, how full the glass is drawn.
  ///
  /// Optional so existing callers keep working; when it is null the stage
  /// supplies a sensible level. Pass the real progress — that is the whole
  /// point of the redraw.
  final double? fill;

  final double size;

  /// Where the stage alone puts the coin line, used when [fill] is null.
  double get _stageFill => switch (stage) {
    JarStage.empty => 0.06,
    JarStage.started => 0.34,
    JarStage.halfFull => 0.62,
    JarStage.overflowing => 0.94,
  };

  @override
  Widget build(BuildContext context) {
    final level = (fill ?? _stageFill).clamp(0.0, 1.0);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ambient glow tinted by mood, not by how full it is. color
          // answers "hows it going", the coin line answers "how far have i
          // got". keeping them on separate channels means someone whos
          // slipped still sees their progress sat there intact
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  mood.color.withValues(alpha: 0.20),
                  mood.color.withValues(alpha: 0.0),
                ],
              ),
            ),
            child: SizedBox(width: size, height: size),
          ),

          // the shelf. soft ellipse of shadow now instead of the brown
          // rectangle it was — a hard bar under a floating jar reads as two
          // separate objects, a shadow reads as one thing stood on
          // something
          Positioned(
            bottom: size * 0.10,
            child: Container(
              width: size * 0.52,
              height: size * 0.07,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(
                  Radius.elliptical(size * 0.26, size * 0.035),
                ),
                gradient: RadialGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.42),
                    Colors.black.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          IdleHoverIcon(
            idleAmplitude: 4,
            pulseAmplitude: 0.02,
            period: const Duration(seconds: 4),
            child: SizedBox(
              width: size * 0.68,
              height: size * 0.78,
              child: CustomPaint(
                painter: _CoinJarPainter(fill: level, mood: mood),
                // semantic label, not decorative-only. the jar IS the
                // headline status of this screen so a screen reader should
                // get the same answer a glance does
                child: Semantics(
                  label:
                      '${stage.label}, ${mood.label}, '
                      '${(level * 100).round()} percent full',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Draws the jar and the coins in it.
class _CoinJarPainter extends CustomPainter {
  const _CoinJarPainter({required this.fill, required this.mood});

  /// 0..1.
  final double fill;
  final JarMood mood;

  // Glass, lid and coin colors. Deliberately not from [AppTheme]: this is a
  // physical object rather than a surface of the UI, and tinting it with the
  // app's greens made it read as another panel.
  static const Color _glass = Color(0xFF9FE8FF);
  static const Color _lid = Color(0xFFB9C4CC);
  static const Color _lidDark = Color(0xFF7C8892);
  static const Color _coin = Color(0xFFFFD45C);
  static const Color _coinDark = Color(0xFFC79A2E);
  static const Color _outline = Color(0xFF152126);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Jar geometry. The neck is narrower than the body, which is what makes
    // a rounded rectangle read as a jar rather than as a bottle or a box.
    final bodyTop = h * 0.22;
    final bodyRect = Rect.fromLTRB(w * 0.08, bodyTop, w * 0.92, h * 0.96);
    final body = RRect.fromRectAndCorners(
      bodyRect,
      topLeft: Radius.circular(w * 0.16),
      topRight: Radius.circular(w * 0.16),
      bottomLeft: Radius.circular(w * 0.22),
      bottomRight: Radius.circular(w * 0.22),
    );

    // Glass: a faint vertical wash so the bottom looks like it holds more
    // light than the top, plus a stroke to give it an edge.
    canvas.drawRRect(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _glass.withValues(alpha: 0.10),
            _glass.withValues(alpha: 0.20),
          ],
        ).createShader(bodyRect),
    );

    // Coins first, then the glass front over them, so the pile is *inside*.
    canvas.save();
    canvas.clipRRect(body);
    _paintCoins(canvas, bodyRect);
    canvas.restore();

    // The front face of the glass: a soft sheen and one bright highlight
    // stripe. Two cues are what sells "transparent" — an even tint alone
    // just looks like a colored shape.
    canvas.drawRRect(body, Paint()..color = _glass.withValues(alpha: 0.06));
    final highlight = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.16, bodyTop + h * 0.06, w * 0.09, h * 0.44),
      Radius.circular(w * 0.05),
    );
    canvas.drawRRect(
      highlight,
      Paint()..color = Colors.white.withValues(alpha: 0.26),
    );

    canvas.drawRRect(
      body,
      Paint()
        ..color = _glass.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.022,
    );

    _paintLid(canvas, size);
    _paintFace(canvas, bodyRect);
  }

  /// A pile of coins whose height follows [fill].
  ///
  /// Rows rather than a solid block: a filled rectangle would be a progress
  /// bar wearing a jar, and the thing that makes this readable at a glance is
  /// being able to *count* — a player can see three coins become four.
  void _paintCoins(Canvas canvas, Rect body) {
    if (fill <= 0.001) return;

    final coinH = body.height * 0.085;
    final rows = (fill * 9).ceil().clamp(1, 9);
    final coinPaint = Paint();

    for (var row = 0; row < rows; row++) {
      // Bottom-up. The last row is drawn partially when the fill lands
      // between two rows, so the pile grows smoothly instead of snapping.
      final rowFill = (fill * 9 - row).clamp(0.0, 1.0);
      final y = body.bottom - body.height * 0.045 - row * coinH * 0.86;

      // Alternate two and three coins per row and nudge them sideways, so
      // the stack looks tipped in rather than machine-packed.
      final perRow = row.isEven ? 3 : 2;
      for (var i = 0; i < perRow; i++) {
        final t = perRow == 1 ? 0.5 : i / (perRow - 1);
        final jitter = math.sin((row * 3 + i) * 2.1) * body.width * 0.035;
        final cx = body.left + body.width * (0.24 + t * 0.52) + jitter;
        final rx = body.width * 0.15;
        final ry = coinH * 0.5 * rowFill;
        if (ry < 0.4) continue;

        final rect = Rect.fromCenter(
          center: Offset(cx, y),
          width: rx * 2,
          height: ry * 2,
        );
        canvas.drawOval(rect, coinPaint..color = _coin);
        // A darker lower crescent gives each coin a thickness, which is what
        // stops the pile reading as flat confetti.
        canvas.drawArc(
          rect.translate(0, ry * 0.28),
          0,
          math.pi,
          false,
          Paint()
            ..color = _coinDark
            ..style = PaintingStyle.stroke
            ..strokeWidth = ry * 0.55,
        );
      }
    }
  }

  void _paintLid(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Overhangs the body slightly and overlaps its top edge, so the two read
    // as a lid *on* a jar. Floating clear of the rim — which is what a band
    // sitting entirely above the body looks like — reads as two shapes.
    final band = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.02, h * 0.115, w * 0.98, h * 0.255),
      Radius.circular(w * 0.055),
    );
    canvas.drawRRect(
      band,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [_lid, _lidDark],
        ).createShader(band.outerRect),
    );

    // The coin slot. One small dark line is what tells a four-year-old what
    // this object is for.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.185),
          width: w * 0.34,
          height: h * 0.028,
        ),
        Radius.circular(h * 0.02),
      ),
      Paint()..color = _outline.withValues(alpha: 0.7),
    );
  }

  /// Two eyes and a mouth on the glass.
  ///
  /// Kept from the original because it works — a face is why a savings
  /// tracker reads as a companion rather than as a chart — but moved onto the
  /// jar's upper body, where a face belongs, instead of over the middle of an
  /// icon.
  void _paintFace(Canvas canvas, Rect body) {
    final cx = body.center.dx;
    // High on the body: at full fill the coins reach the middle of the
    // glass, and a face drawn there disappears exactly when the player
    // has most earned the reaction.
    final eyeY = body.top + body.height * 0.19;
    final eyeDx = body.width * 0.17;
    final eyeR = body.width * 0.045;

    final ink = Paint()..color = _outline.withValues(alpha: 0.82);
    canvas.drawCircle(Offset(cx - eyeDx, eyeY), eyeR, ink);
    canvas.drawCircle(Offset(cx + eyeDx, eyeY), eyeR, ink);

    final mouthY = eyeY + body.height * 0.085;
    final half = body.width * 0.13;
    // Canvas y grows **downward**, so a control point below the endpoints
    // (positive offset) bows the middle of the mouth down and makes a smile.
    // The original had these the other way round, which meant the jar pulled
    // a face at you for keeping a streak and grinned when you had stopped
    // logging — the exact inverse of the feedback the screen exists to give.
    final curve = switch (mood) {
      JarMood.onARoll => half * 0.75,
      JarMood.steady => 0.0,
      JarMood.slipping => -half * 0.6,
    };
    canvas.drawPath(
      Path()
        ..moveTo(cx - half, mouthY)
        ..quadraticBezierTo(cx, mouthY + curve, cx + half, mouthY),
      Paint()
        ..color = _outline.withValues(alpha: 0.82)
        ..style = PaintingStyle.stroke
        ..strokeWidth = body.width * 0.028
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_CoinJarPainter old) =>
      old.fill != fill || old.mood != mood;
}

/// The four jar stages as a row of milestones.
///
/// Answers the question the old screen left open — "how many of these are
/// there, and which one am I on?" A single bar toward the *next* stage says
/// how far to the next step but never how far through the whole thing you
/// are, which is the number people actually want.
class JarMilestones extends StatelessWidget {
  const JarMilestones({super.key, required this.stage, required this.xp});

  final JarStage stage;
  final int xp;

  @override
  Widget build(BuildContext context) {
    final reachedIndex = JarStage.values.indexOf(stage);

    return Row(
      children: [
        for (var i = 0; i < JarStage.values.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: i <= reachedIndex
                      ? AppTheme.greenPrimary
                      : Colors.white.withValues(alpha: 0.14),
                ),
              ),
            ),
          _MilestonePip(
            stage: JarStage.values[i],
            reached: i <= reachedIndex,
            current: i == reachedIndex,
            xp: xp,
          ),
        ],
      ],
    );
  }
}

class _MilestonePip extends StatelessWidget {
  const _MilestonePip({
    required this.stage,
    required this.reached,
    required this.current,
    required this.xp,
  });

  final JarStage stage;
  final bool reached;
  final bool current;
  final int xp;

  @override
  Widget build(BuildContext context) {
    // Reached pips are solid so the row reads left-to-right as filled-up;
    // the current one gets a ring so "where am I" survives a glance.
    //
    // The mint is measured against the 22% mint wash it sits on rather than
    // used raw — a 11px glyph in the app's mint on a mint chip is 3.2:1, and
    // these pips are how a player finds where they are in the ladder.
    final chip = AppTheme.tintedChip(AppTheme.greenPrimary, alpha: 0.22);
    final color = reached ? chip.ink : AppTheme.textMuted;

    return Tooltip(
      message: '${stage.label} — ${stage.xpThreshold} points',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: current ? 26 : 20,
            height: current ? 26 : 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: reached ? chip.fill : Colors.white.withValues(alpha: 0.06),
              border: Border.all(
                color: current
                    ? AppTheme.greenPrimary
                    : color.withValues(alpha: 0.4),
                width: current ? 2 : 1,
              ),
            ),
            child: Icon(
              reached ? Icons.check_rounded : stage.icon,
              size: current ? 14 : 11,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 62,
            child: Text(
              stage.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.5,
                height: 1.15,
                fontWeight: FontWeight.w800,
                color: reached ? AppTheme.textPrimary : AppTheme.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
