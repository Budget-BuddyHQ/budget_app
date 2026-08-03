import 'package:flutter/material.dart';

/// Lifts and glows its child on pointer hover (desktop/web); a no-op on
/// touch, which never fires hover events. Used on tappable cards so they
/// read as alive rather than flat, without the continuous idle bob
/// [IdleHoverIcon] uses — a whole grid of things bobbing at once reads as
/// noisy, where this only reacts to an actual pointer.
class HoverLift extends StatefulWidget {
  const HoverLift({
    super.key,
    required this.accent,
    required this.child,
    this.borderRadius = 24,
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
              ? [
                  BoxShadow(
                    color: widget.accent.withValues(alpha: 0.30),
                    blurRadius: 24,
                    spreadRadius: -4,
                    offset: const Offset(0, 10),
                  ),
                ]
              : const [],
        ),
        child: widget.child,
      ),
    );
  }
}
