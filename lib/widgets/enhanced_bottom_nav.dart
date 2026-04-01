import 'package:flutter/material.dart';

class EnhancedBottomNav extends StatefulWidget {
  final int currentIndex;
  final List<BottomNavItem> items;
  final Function(int) onTap;
  final Color backgroundColor;
  final Color indicatorColor;
  final double height;

  const EnhancedBottomNav({
    Key? key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
    this.backgroundColor = const Color(0xFF1A4D3D),
    this.indicatorColor = const Color(0xFF76FF03),
    this.height = 80,
  }) : super(key: key);

  @override
  State<EnhancedBottomNav> createState() => _EnhancedBottomNavState();
}

class _EnhancedBottomNavState extends State<EnhancedBottomNav> {
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.1),
            Colors.black.withValues(alpha: 0.2),
          ],
        ),
        color: widget.backgroundColor,
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          widget.items.length,
          (index) => _BottomNavItemWidget(
            item: widget.items[index],
            isActive: widget.currentIndex == index,
            onTap: () => widget.onTap(index),
            indicatorColor: widget.indicatorColor,
            isMobile: isMobile,
          ),
        ),
      ),
    );
  }
}

class BottomNavItem {
  final IconData icon;
  final String label;
  final Color activeColor;
  final Color inactiveColor;

  BottomNavItem({
    required this.icon,
    required this.label,
    this.activeColor = const Color(0xFF76FF03),
    this.inactiveColor = const Color.fromRGBO(255, 255, 255, 0.6),
  });
}

class _BottomNavItemWidget extends StatefulWidget {
  final BottomNavItem item;
  final bool isActive;
  final VoidCallback onTap;
  final Color indicatorColor;
  final bool isMobile;

  const _BottomNavItemWidget({
    required this.item,
    required this.isActive,
    required this.onTap,
    required this.indicatorColor,
    required this.isMobile,
  });

  @override
  State<_BottomNavItemWidget> createState() => _BottomNavItemWidgetState();
}

class _BottomNavItemWidgetState extends State<_BottomNavItemWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isActive) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(_BottomNavItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.forward();
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: Icon(
                  widget.item.icon,
                  color: widget.isActive
                      ? widget.item.activeColor
                      : widget.item.inactiveColor,
                  size: 24,
                ),
              ),
              const SizedBox(height: 6),
              if (!widget.isMobile)
                Opacity(
                  opacity: _opacityAnimation.value,
                  child: Text(
                    widget.item.label,
                    style: TextStyle(
                      color: widget.isActive
                          ? widget.item.activeColor
                          : widget.item.inactiveColor,
                      fontSize: 11,
                      fontWeight:
                          widget.isActive ? FontWeight.w700 : FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                )
              else if (widget.isActive)
                Opacity(
                  opacity: _opacityAnimation.value,
                  child: Text(
                    widget.item.label,
                    style: TextStyle(
                      color: widget.isActive
                          ? widget.item.activeColor
                          : widget.item.inactiveColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
