import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services_backend_and_other_services/app_sound_service.dart';

/// A short, non-blocking confetti burst shown over whatever's on screen —
/// for "you did something good" moments (a great quiz score, a new high
/// score, a finished challenge) that don't warrant interrupting with a full
/// modal like [AchievementCelebration] does for badge unlocks.
///
/// Hand-rolled with a [CustomPainter] rather than a confetti package, same
/// reasoning as [MiniSparkline]/[PriceChart]: one fewer dependency, and full
/// control over how it looks against this app's palette.
class ConfettiBurst {
  ConfettiBurst._();

  static OverlayEntry? _activeEntry;

  static void show(
    BuildContext context, {
    int particleCount = 90,
    Duration duration = const Duration(milliseconds: 1700),
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    HapticFeedback.mediumImpact();
    AppSoundService.play(AppSoundEffect.celebration);
    _activeEntry?.remove();

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => IgnorePointer(
        child: _ConfettiOverlay(
          particleCount: particleCount,
          duration: duration,
          onDone: () {
            if (_activeEntry == entry) {
              _activeEntry = null;
            }
            entry.remove();
          },
        ),
      ),
    );

    _activeEntry = entry;
    overlay.insert(entry);
  }
}

const _confettiColors = <Color>[
  Color(0xFFFFD94A),
  Color(0xFF85EFAC),
  Color(0xFF58C7FF),
  Color(0xFFFF8FB1),
  Color(0xFFB388FF),
  Color(0xFFFFA451),
];

class _Particle {
  _Particle(math.Random rng)
    : startXFrac = rng.nextDouble(),
      delayFrac = rng.nextDouble() * 0.25,
      fallSpeed = 0.75 + rng.nextDouble() * 0.5,
      wobbleAmp = 14 + rng.nextDouble() * 22,
      wobbleFreq = 2 + rng.nextDouble() * 3,
      phase = rng.nextDouble() * math.pi * 2,
      rotSpeed = (rng.nextBool() ? 1 : -1) * (2 + rng.nextDouble() * 4),
      size = 5 + rng.nextDouble() * 5,
      isSquare = rng.nextBool(),
      color = _confettiColors[rng.nextInt(_confettiColors.length)];

  final double startXFrac;
  final double delayFrac;
  final double fallSpeed;
  final double wobbleAmp;
  final double wobbleFreq;
  final double phase;
  final double rotSpeed;
  final double size;
  final bool isSquare;
  final Color color;
}

class _ConfettiOverlay extends StatefulWidget {
  const _ConfettiOverlay({
    required this.particleCount,
    required this.duration,
    required this.onDone,
  });

  final int particleCount;
  final Duration duration;
  final VoidCallback onDone;

  @override
  State<_ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<_ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final rng = math.Random();
    _particles = List.generate(widget.particleCount, (_) => _Particle(rng));
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onDone();
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      // Confetti is celebratory garnish, not information — skipping it
      // entirely respects the setting instead of just holding a still frame.
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onDone());
      return const SizedBox.shrink();
    }

    // A full-size box, not `Positioned.fill`. This sits inside an
    // `IgnorePointer` inside an overlay entry, and `Positioned` is only legal
    // directly under a `Stack`. Release builds ignore the mistake; a debug build
    // throws "Incorrect use of ParentDataWidget" the first time confetti plays.
    return SizedBox.expand(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _ConfettiPainter(
            particles: _particles,
            t: _controller.value,
          ),
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.particles, required this.t});

  final List<_Particle> particles;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final local = ((t - p.delayFrac) / (1 - p.delayFrac)).clamp(0.0, 1.0);
      if (local <= 0) {
        continue;
      }
      final fadeOut = local > 0.8 ? (1 - local) / 0.2 : 1.0;
      final y = -20 + local * p.fallSpeed * (size.height + 40);
      final x =
          p.startXFrac * size.width +
          math.sin(local * p.wobbleFreq * math.pi * 2 + p.phase) * p.wobbleAmp;
      final rotation = local * p.rotSpeed * math.pi * 2;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      final paint = Paint()..color = p.color.withValues(alpha: fadeOut);
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: p.size,
        height: p.size * (p.isSquare ? 1.0 : 1.8),
      );
      if (p.isSquare) {
        canvas.drawRect(rect, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(p.size * 0.3)),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.t != t;
}
