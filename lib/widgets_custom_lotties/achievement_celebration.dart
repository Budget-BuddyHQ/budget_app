import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_assets.dart';
import '../themes_colors/app_theme.dart';
import 'sprite_sheet_image.dart';
import '../models_Like_Skins_and_lessons_templates/avatar_skin.dart';
import 'avatar_sprite.dart';
import 'confetti_burst.dart';

/// The "you just earned something" moment.
///
/// Plays the 8-frame celebration sprite sheet
/// ([AppAssets.turtleCelebrateSheet]) at ~10 fps, sitting inside a burst of
/// rotating rays and outward-flying sparks. This replaced an earlier
/// composed-mascot version — the real animated art landed later.
class AchievementCelebration {
  AchievementCelebration._();

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String subtitle,
    Color accent = const Color(0xFFFFD45C),
    AvatarSkin? skin,
  }) {
    HapticFeedback.mediumImpact();

    // Confetti over the top, not instead of the modal.
    //
    // `ConfettiBurst` already existed and was used in five other places — a
    // good quiz score, a new high score, a finished challenge — and was never
    // called from the one moment the app calls an *achievement*. Unlocking a
    // badge was quieter than answering a question right.
    //
    // It also plays `AppSoundEffect.celebration`, which is why this modal was
    // silent: it fired haptics and nothing else.
    ConfettiBurst.show(context);

    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (_) => _AchievementDialog(
        title: title,
        subtitle: subtitle,
        accent: accent,
        skin: skin,
      ),
    );
  }
}

class _AchievementDialog extends StatefulWidget {
  const _AchievementDialog({
    required this.title,
    required this.subtitle,
    required this.accent,
    this.skin,
  });

  final String title;
  final String subtitle;
  final Color accent;

  /// The player's equipped skin, or null to fall back to the turtle.
  ///
  /// **Why this had to be plumbed through.** The sheet was hardcoded to
  /// `AppAssets.turtleCelebrateSheet`, so a player who had unlocked and
  /// equipped any of the other 23 skins still watched a turtle celebrate
  /// their achievement. Skins are the app's main reward, and the biggest
  /// congratulatory moment in it ignored the one the player chose.
  final AvatarSkin? skin;

  /// Only the classic turtle has an eight-frame celebrate sheet drawn for it.
  bool get usesCelebrateSheet => skin == null || skin!.id == 'classic_turtle';

  @override
  State<_AchievementDialog> createState() => _AchievementDialogState();
}

class _AchievementDialogState extends State<_AchievementDialog>
    with TickerProviderStateMixin {
  // Three controllers: the burst plays once as an entrance, and the shimmer
  // rays and the sprite both loop underneath it.
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  // 8 frames at ~10 fps is an 800ms cycle, repeated.
  //
  // **This used to `..forward()`**, so the sprite ran its eight frames once
  // and then froze on the last one for as long as the modal stayed open. The
  // character celebrated for eight tenths of a second and then stood
  // perfectly still, which reads as the animation having broken rather than
  // finished. Only the background rays were looping.
  late final AnimationController _sprite = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat();

  @override
  void dispose() {
    _entrance.dispose();
    _loop.dispose();
    _sprite.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion && _loop.isAnimating) {
      _loop.stop();
    }
    // The sprite loops now, so reduce-motion has to stop it too — otherwise
    // the setting silences the rays and leaves the character dancing.
    if (reduceMotion && _sprite.isAnimating) {
      _sprite.stop();
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
              color: Color.lerp(const Color(0xFF10291F), widget.accent, 0.12),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: widget.accent.withValues(alpha: 0.55),
                width: 2,
              ),
              boxShadow: AppTheme.ledgeShadow(
                widget.accent,
                restAlpha: 0.3,
                depth: 6,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 150,
                  width: 150,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_entrance, _loop, _sprite]),
                    builder: (context, _) {
                      final pop = reduceMotion
                          ? 1.0
                          : Curves.elasticOut.transform(
                              _entrance.value.clamp(0.0, 1.0),
                            );
                      // Cycle the 8 frames, on repeat. Reduce-motion pins
                      // to the final pose and stops the controller above.
                      final frame = reduceMotion
                          ? AppAssets.turtleCelebrateFrames - 1
                          : (_sprite.value * AppAssets.turtleCelebrateFrames)
                                .floor()
                                .clamp(0, AppAssets.turtleCelebrateFrames - 1);
                      final column = frame % AppAssets.turtleCelebrateColumns;
                      final row = frame ~/ AppAssets.turtleCelebrateColumns;
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
                            child: SizedBox(
                              width: 96,
                              height: 96,
                              // Only the classic turtle has an eight-frame
                              // celebrate sheet drawn for it. Rather than
                              // fake one for the other 23 skins, anything
                              // else shows its own portrait inside the same
                              // ray-and-spark burst — it is still *their*
                              // character, which is the part that matters,
                              // and a badly faked animation would read worse
                              // than an honest still.
                              child: widget.usesCelebrateSheet
                                  ? SpriteSheetImage(
                                      sheetAsset:
                                          AppAssets.turtleCelebrateSheet,
                                      columns: AppAssets.turtleCelebrateColumns,
                                      rows: AppAssets.turtleCelebrateRows,
                                      column: column,
                                      row: row,
                                      cellWidth:
                                          AppAssets.turtleCelebrateCellSize,
                                      cellHeight:
                                          AppAssets.turtleCelebrateCellSize,
                                      width: 96,
                                      height: 96,
                                      errorBuilder: (_, _, _) => Icon(
                                        Icons.emoji_events_rounded,
                                        size: 64,
                                        color: widget.accent,
                                      ),
                                    )
                                  : AvatarSprite(skin: widget.skin!, size: 96),
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
                  style: GoogleFonts.pixelifySans(
                    color: widget.accent,
                    fontSize: 11.5,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.pixelifySans(
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
                    child: Text(
                      'Nice!',
                      style: GoogleFonts.pixelifySans(
                        fontWeight: FontWeight.w700,
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
