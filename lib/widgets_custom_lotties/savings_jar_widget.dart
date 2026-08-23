import 'package:flutter/material.dart';

import '../models_Like_Skins_and_lessons_templates/money_habit_models.dart';
import '../themes_colors/app_theme.dart';
import 'idle_hover_icon.dart';

/// The Money Habits companion: a savings jar that fills up. No dedicated
/// sprite art exists or was generated for this feature — built the same
/// way [AmbientLottieCard] turns existing primitives into something that
/// reads as alive: a Material icon (already carried by [JarStage.icon])
/// sized up per stage, a soft mood-tinted glow, a hand-painted two-dot-and-
/// a-curve face for character, and [IdleHoverIcon] for the idle bob/
/// breathing motion — no new `AnimationController` needed.
class SavingsJarWidget extends StatelessWidget {
  const SavingsJarWidget({
    super.key,
    required this.stage,
    required this.mood,
    this.size = 220,
  });

  final JarStage stage;
  final JarMood mood;
  final double size;

  /// Icon grows visibly larger stage over stage so progress reads at a
  /// glance, not just via the label underneath.
  double get _iconSize {
    return switch (stage) {
      JarStage.empty => size * 0.22,
      JarStage.started => size * 0.34,
      JarStage.halfFull => size * 0.46,
      JarStage.overflowing => size * 0.58,
    };
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ambient glow, tinted by mood rather than growth stage — colour
          // is what should read as "how's it doing", size is what reads as
          // "how full has it gotten".
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  mood.color.withValues(alpha: 0.22),
                  mood.color.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          // A little shelf anchors the jar so a lone icon doesn't float in
          // empty space.
          Positioned(
            bottom: size * 0.06,
            child: Container(
              width: size * 0.5,
              height: size * 0.1,
              decoration: BoxDecoration(
                color: const Color(0xFF6B4A2A),
                borderRadius: BorderRadius.circular(size * 0.03),
              ),
            ),
          ),
          IdleHoverIcon(
            idleAmplitude: 5,
            pulseAmplitude: 0.03,
            period: const Duration(seconds: 4),
            child: Padding(
              padding: EdgeInsets.only(bottom: size * 0.14),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(_iconSize * 0.18),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFD45C).withValues(alpha: 0.16),
                      boxShadow: AppTheme.puffyShadow(
                        const Color(0xFFFFD45C),
                        restAlpha: 0.24,
                      ),
                    ),
                    child: Icon(
                      stage.icon,
                      size: _iconSize,
                      color: const Color(0xFFFFD45C),
                    ),
                  ),
                  SizedBox(
                    width: _iconSize * 1.4,
                    height: _iconSize * 1.4,
                    child: CustomPaint(painter: _JarFacePainter(mood: mood)),
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

/// Two dot eyes and a curve for a mouth — enough to read as an expression
/// without needing real character art. Positioned in the upper-half of its
/// bounds so it sits on the "face" of whatever icon it's layered over.
class _JarFacePainter extends CustomPainter {
  const _JarFacePainter({required this.mood});

  final JarMood mood;

  @override
  void paint(Canvas canvas, Size size) {
    final eyePaint = Paint()..color = const Color(0xFF0B2419);
    final eyeY = size.height * 0.38;
    final eyeDx = size.width * 0.14;
    final eyeRadius = size.width * 0.035;
    canvas.drawCircle(
      Offset(size.width / 2 - eyeDx, eyeY),
      eyeRadius,
      eyePaint,
    );
    canvas.drawCircle(
      Offset(size.width / 2 + eyeDx, eyeY),
      eyeRadius,
      eyePaint,
    );

    final mouthPaint = Paint()
      ..color = const Color(0xFF0B2419)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.025
      ..strokeCap = StrokeCap.round;

    final mouthY = size.height * 0.5;
    final mouthWidth = size.width * 0.16;
    final curve = switch (mood) {
      JarMood.onARoll => -mouthWidth * 0.5,
      JarMood.steady => 0.0,
      JarMood.slipping => mouthWidth * 0.45,
    };
    final path = Path()
      ..moveTo(size.width / 2 - mouthWidth, mouthY)
      ..quadraticBezierTo(
        size.width / 2,
        mouthY + curve,
        size.width / 2 + mouthWidth,
        mouthY,
      );
    canvas.drawPath(path, mouthPaint);
  }

  @override
  bool shouldRepaint(_JarFacePainter oldDelegate) => oldDelegate.mood != mood;
}
