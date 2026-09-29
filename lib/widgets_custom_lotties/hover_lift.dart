import 'package:flutter/material.dart';

import '../themes_colors/app_theme.dart';

/// Glows its child with a soft, color-tinted "puffy" shadow at rest, and
/// lifts + intensifies that glow on pointer hover (desktop/web only — touch
/// never fires hover events, so the resting glow is what makes cards read
/// as raised rather than flat on mobile). Deliberately reacts only to an
/// actual pointer rather than a continuous idle bob — a whole grid of
/// things bobbing at once (see [IdleHoverIcon]) reads as noisy.
class HoverLift extends StatefulWidget {
  const HoverLift({
    super.key,
    required this.accent,
    required this.child,
    this.borderRadius = AppTheme.radiusXLarge,
    this.lift = 4,
  });

  final Color accent;
  final Widget child;
  final double borderRadius;
  final double lift;

  @override
  State<HoverLift> createState() => _HoverLiftState();
}

class _HoverLiftState extends State<HoverLift> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(
          0,
          _hovering ? -widget.lift : 0,
          0,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: _hovering
              ? AppTheme.puffyShadow(
                  widget.accent,
                  restAlpha: 0.34,
                  blurRadius: 30,
                  spreadRadius: -3,
                  offset: const Offset(0, 14),
                )
              : AppTheme.puffyShadow(widget.accent),
        ),
        child: widget.child,
      ),
    );
  }
}
