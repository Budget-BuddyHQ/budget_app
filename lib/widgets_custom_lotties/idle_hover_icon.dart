import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Wraps any icon/sprite so it reads as alive rather than a flat, static
/// pixel: a slow, continuous idle bob, plus a quick scale-up on hover for
/// mouse/trackpad users (desktop and web). Touch devices simply don't fire
/// hover events, so this degrades to just the idle bob there — no dead code
/// path needed for platform detection.
///
/// Honours the platform "reduce motion" setting the same way
/// [AmbientLottieCard] does, by holding the idle animation still rather than
/// ignoring the accessibility signal.
class IdleHoverIcon extends StatefulWidget {
  const IdleHoverIcon({
    super.key,
    required this.child,
    this.idleAmplitude = 2.5,
    this.period = const Duration(seconds: 3),
    this.hoverScale = 1.08,
    this.phaseShift = 0.0,
  });

  final Widget child;

  /// How many pixels the child drifts up/down at the peak of the bob.
  final double idleAmplitude;

  /// One full bob cycle. Kept slow so it reads as "gently alive", not busy.
  final Duration period;

  /// Scale applied while the pointer is hovering.
  final double hoverScale;

  /// 0..1 offset into the cycle, so a row of icons doesn't bob in lockstep.
  final double phaseShift;

  @override
  State<IdleHoverIcon> createState() => _IdleHoverIconState();
}

class _IdleHoverIconState extends State<IdleHoverIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.period,
  )..repeat();

  bool _hovering = false;

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

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedScale(
        scale: _hovering ? widget.hoverScale : 1.0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutBack,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final phase = (_controller.value + widget.phaseShift) % 1.0;
            final bob = reduceMotion
                ? 0.0
                : math.sin(phase * 2 * math.pi) * widget.idleAmplitude;
            return Transform.translate(offset: Offset(0, bob), child: child);
          },
          child: widget.child,
        ),
      ),
    );
  }
}
