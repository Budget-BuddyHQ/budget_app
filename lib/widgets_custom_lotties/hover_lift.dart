import 'package:flutter/material.dart';

import '../themes_colors/app_theme.dart';

/// Sits its child on a hard ledge ([AppTheme.ledgeShadow]) at rest, and lifts
/// it off that ledge on pointer hover (desktop/web only — touch never fires
/// hover events, so the resting ledge is what makes cards read as raised
/// rather than flat on mobile). Deliberately reacts only to an
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
              // The card rises by `lift`, so the ledge grows by the same
              // amount and the card still looks like it sits on it.
              ? AppTheme.ledgeShadow(
                  widget.accent,
                  restAlpha: 0.34,
                  depth: 4 + widget.lift,
                )
              : AppTheme.ledgeShadow(widget.accent),
        ),
        child: widget.child,
      ),
    );
  }
}
