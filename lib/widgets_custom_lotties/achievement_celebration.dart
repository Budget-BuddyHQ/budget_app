import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_assets.dart';

/// The "you just earned something" moment.
///
/// There is no pre-drawn celebrating-turtle sprite in the project — every
/// turtle asset is a single static pose — so the celebration is *composed*:
/// the Budget Buddy mascot ([AppAssets.pixelMainTurtle]) pops in with a
/// spring, sitting inside a burst of rotating rays and outward-flying
/// sparks. All painted, no new art needed.
class AchievementCelebration {
  AchievementCelebration._();

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String subtitle,
    Color accent = const Color(0xFFFFD45C),
  }) {
    HapticFeedback.mediumImpact();
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (_) => _AchievementDialog(
        title: title,
        subtitle: subtitle,
        accent: accent,
      ),
    );
  }
}

class _AchievementDialog extends StatefulWidget {
  const _AchievementDialog({
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final Color accent;

  @override
  State<_AchievementDialog> createState() => _AchievementDialogState();
}

class _AchievementDialogState extends State<_AchievementDialog>
    with TickerProviderStateMixin {
  // Two controllers on purpose: the burst plays once as an entrance, the
  // shimmer loops underneath it so the card keeps breathing afterwards.
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  @override
  void dispose() {
    _entrance.dispose();
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion && _loop.isAnimating) {
      _loop.stop();
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(const Color(0xFF15392D), widget.accent, 0.18)!,
                  const Color(0xFF0A1D17),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: widget.accent.withValues(alpha: 0.55),
                width: 1.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.accent.withValues(alpha: 0.28),
                  blurRadius: 40,
                  spreadRadius: -8,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 150,
                  width: 150,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_entrance, _loop]),
                    builder: (context, _) {
                      final pop = reduceMotion
                          ? 1.0
                          : Curves.elasticOut.transform(
                              _entrance.value.clamp(0.0, 1.0),
                            );
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          if (!reduceMotion)
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _CelebrationPainter(
                                  burst: _entrance.value,
                                  spin: _loop.value,
                                  accent: widget.accent,
                                ),
                              ),
                            ),
                          Transform.scale(
                            scale: pop.clamp(0.0, 1.4),
                            child: Image.asset(
                              AppAssets.pixelMainTurtle,
                              width: 88,
                              filterQuality: FilterQuality.none,
                              errorBuilder: (_, _, _) => Icon(
                                Icons.emoji_events_rounded,
                                size: 64,
                                color: widget.accent,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Achievement unlocked',
                  style: TextStyle(
                    color: widget.accent,
                    fontSize: 11.5,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.baloo2(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.quicksand(
                    color: Colors.white.withValues(alpha: 0.76),
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: widget.accent,
                      foregroundColor: const Color(0xFF06251A),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text(
                      'Nice!',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Rotating rays behind the mascot plus sparks that fly outward once on
/// entrance. Hand-painted for the same reason the charts are — no extra
/// dependency, and nothing to crash on odd sizes.
class _CelebrationPainter extends CustomPainter {
  const _CelebrationPainter({
    required this.burst,
    required this.spin,
    required this.accent,
  });

  /// 0..1 entrance progress — drives the outward spark travel and fade.
  final double burst;

  /// 0..1 looping value — drives the slow ray rotation.
  final double spin;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.shortestSide <= 0) {
      return;
    }
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.shortestSide / 2;

    // Soft rotating rays.
    final rayPaint = Paint()..color = accent.withValues(alpha: 0.10);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(spin * 2 * math.pi);
    const rayCount = 12;
    for (var i = 0; i < rayCount; i++) {
      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(maxRadius, -maxRadius * 0.10)
        ..lineTo(maxRadius, maxRadius * 0.10)
        ..close();
      canvas.drawPath(path, rayPaint);
      canvas.rotate(2 * math.pi / rayCount);
    }
    canvas.restore();

    // Sparks flying out, fading as they go.
    final eased = Curves.easeOutCubic.transform(burst.clamp(0.0, 1.0));
    if (eased <= 0) {
      return;
    }
    final sparkPaint = Paint()..style = PaintingStyle.fill;
    const sparkCount = 14;
    for (var i = 0; i < sparkCount; i++) {
      final angle = (i / sparkCount) * 2 * math.pi;
      // Alternate the travel distance so it reads as a scatter, not a ring.
      final reach = maxRadius * (i.isEven ? 0.95 : 0.72) * eased;
      final offset = Offset(
        center.dx + math.cos(angle) * reach,
        center.dy + math.sin(angle) * reach,
      );
      sparkPaint.color = accent.withValues(alpha: (1 - eased) * 0.9);
      canvas.drawCircle(offset, 3.5 * (1 - eased) + 1, sparkPaint);
    }
  }

  @override
  bool shouldRepaint(_CelebrationPainter oldDelegate) =>
      oldDelegate.burst != burst ||
      oldDelegate.spin != spin ||
      oldDelegate.accent != accent;
}
