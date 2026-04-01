import 'package:flutter/material.dart';

class ModernCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  final Color backgroundColor;
  final List<BoxShadow>? boxShadow;
  final Border? border;
  final bool isInteractive;
  final VoidCallback? onTap;
  final Gradient? gradient;

  const ModernCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 20,
    this.backgroundColor = const Color(0xFF2D5A4A),
    this.boxShadow,
    this.border,
    this.isInteractive = false,
    this.onTap,
    this.gradient,
  }) : super(key: key);

  @override
  State<ModernCard> createState() => _ModernCardState();
}

class _ModernCardState extends State<ModernCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _elevationAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (widget.isInteractive) _controller.forward();
      },
      onExit: (_) {
        if (widget.isInteractive) _controller.reverse();
      },
      child: GestureDetector(
        onTapDown: (_) {
          if (widget.isInteractive) _controller.forward();
        },
        onTapUp: (_) {
          if (widget.isInteractive) _controller.reverse();
          widget.onTap?.call();
        },
        onTapCancel: () {
          if (widget.isInteractive) _controller.reverse();
        },
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedBuilder(
            animation: _elevationAnimation,
            builder: (context, _) {
              return Container(
                decoration: BoxDecoration(
                  gradient: widget.gradient,
                  color: widget.gradient == null ? widget.backgroundColor : null,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  border: widget.border,
                  boxShadow: [
                    ...(widget.boxShadow ?? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]),
                    if (widget.isInteractive)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: _elevationAnimation.value * 2,
                        offset: Offset(0, _elevationAnimation.value),
                      ),
                  ],
                ),
                padding: widget.padding,
                child: widget.child,
              );
            },
          ),
        ),
      ),
    );
  }
}
