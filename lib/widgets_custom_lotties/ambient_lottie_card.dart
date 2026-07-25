import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/app_assets.dart';

/// Decorative motifs used for the ambient accent panels around the app.
///
/// Each motif pairs a real sprite with the accent colour it should glow in.
enum AmbientMotif {
  turtle(AppAssets.pixelMainTurtle, Color(0xFF85EFAC)),
  coin(AppAssets.tileCoin, Color(0xFFFFD45C)),
  arcade(AppAssets.iconMarket, Color(0xFF69C6FF)),
  academy(AppAssets.coolTurtle, Color(0xFFB7F7D7));

  const AmbientMotif(this.sprite, this.accent);

  final String sprite;
  final Color accent;
}

/// A soft, slowly drifting art panel used as background decoration.
///
/// This used to point at Lottie files that were never shipped, so it always
/// fell back to a static sparkle icon. It now renders one of the app's own
/// pixel sprites with a gentle bob plus orbiting motes, and honours the
/// platform "reduce motion" setting by holding still.
class AmbientLottieCard extends StatefulWidget {
  const AmbientLottieCard({
    super.key,
    required this.motif,
    required this.semanticLabel,
    this.height = 180,
    this.width,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor = const Color(0x14FFFFFF),
    this.borderColor = const Color(0x24FFFFFF),
  });

  final AmbientMotif motif;
  final String semanticLabel;
  final double height;
  final double? width;
  final EdgeInsets padding;
  final Color backgroundColor;
  final Color borderColor;

  @override
  State<AmbientLottieCard> createState() => _AmbientLottieCardState();
}

class _AmbientLottieCardState extends State<AmbientLottieCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  @override
  void initState() {
    super.initState();
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion && _controller.isAnimating) {
      _controller.stop();
    } else if (!reduceMotion && !_controller.isAnimating) {
      _controller.repeat();
    }

    final accent = widget.motif.accent;

    return Semantics(
      label: widget.semanticLabel,
      image: true,
      child: Container(
        width: widget.width,
        height: widget.height,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: widget.borderColor),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = _controller.value;
              return Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.15),
                        radius: 0.95,
                        colors: [
                          accent.withValues(alpha: 0.20),
                          accent.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                  CustomPaint(
                    painter: _MotePainter(progress: t, accent: accent),
                  ),
                  Center(
                    child: Transform.translate(
                      // Gentle vertical bob so the sprite reads as alive.
                      offset: Offset(0, math.sin(t * 2 * math.pi) * 4),
                      child: child,
                    ),
                  ),
                ],
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Image.asset(
                widget.motif.sprite,
                filterQuality: FilterQuality.none,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stack) => Icon(
                  Icons.auto_awesome_rounded,
                  color: accent.withValues(alpha: 0.8),
                  size: 32,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Three motes orbiting on offset phases behind the sprite.
class _MotePainter extends CustomPainter {
  const _MotePainter({required this.progress, required this.accent});

  final double progress;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.36;
    final paint = Paint()..style = PaintingStyle.fill;

    for (var i = 0; i < 3; i++) {
      final phase = progress * 2 * math.pi + (i * 2 * math.pi / 3);
      final offset = Offset(
        center.dx + math.cos(phase) * radius,
        center.dy + math.sin(phase) * radius * 0.55,
      );
      // Motes at the back of the orbit fade out, giving a sense of depth.
      final depth = (math.sin(phase) + 1) / 2;
      paint.color = accent.withValues(alpha: 0.10 + (depth * 0.22));
      canvas.drawCircle(offset, 2.0 + depth, paint);
    }
  }

  @override
  bool shouldRepaint(_MotePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.accent != accent;
}
