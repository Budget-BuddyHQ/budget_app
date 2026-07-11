import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services_backend_and_other_services/app_sound_service.dart';

const _deepCharcoal = Color(0xFF17301F);
const _deepCharcoalStrong = Color(0xFF0A1D17);
const _activeAccent = Color(0xFFFFD94A);
const _activeAccentDeep = Color(0xFFB38C10);

class PopNavBarItem {
  const PopNavBarItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

/// Always-bottom-docked navigation bar with a spring-animated active tab.
class PopNavBar extends StatelessWidget {
  /// The app's shared 6-tab set (Home/Adventure/Arcade/Style/Academy/
  /// Profile), so every caller wiring up nav stays in sync.
  static const appTabs = <PopNavBarItem>[
    PopNavBarItem(label: 'Home', icon: Icons.dashboard_rounded),
    PopNavBarItem(label: 'Adventure', icon: Icons.explore_rounded),
    PopNavBarItem(label: 'Arcade', icon: Icons.sports_esports_rounded),
    PopNavBarItem(label: 'Style', icon: Icons.auto_awesome_rounded),
    PopNavBarItem(label: 'Academy', icon: Icons.school_rounded),
    PopNavBarItem(label: 'Profile', icon: Icons.person_rounded),
  ];

  const PopNavBar({
    super.key,
    required this.items,
    required this.activeIndex,
    this.onSelected,
  });

  final List<PopNavBarItem> items;
  final int activeIndex;
  final ValueChanged<int>? onSelected;

  void _handleTap(BuildContext context, int index) {
    if (onSelected == null || index == activeIndex) {
      return;
    }
    HapticFeedback.lightImpact();
    AppSoundService.play(AppSoundEffect.navigation);
    onSelected!(index);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final dense = screenWidth < 360;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(10, 0, 10, dense ? 8 : 12),
        child: Container(
          height: dense ? 78 : 86,
          decoration: BoxDecoration(
            color: _deepCharcoalStrong,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _deepCharcoal, width: 4),
            boxShadow: const [
              BoxShadow(color: Color(0xFF04120C), offset: Offset(0, 6)),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _PopNavTile(
                    item: items[i],
                    active: i == activeIndex,
                    dense: dense,
                    onTap: () => _handleTap(context, i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared tab tile: spring-animated lift + scale on the active tab.
class _PopNavTile extends StatefulWidget {
  const _PopNavTile({
    required this.item,
    required this.active,
    required this.dense,
    required this.onTap,
  });

  final PopNavBarItem item;
  final bool active;
  final bool dense;
  final VoidCallback onTap;

  @override
  State<_PopNavTile> createState() => _PopNavTileState();
}

class _PopNavTileState extends State<_PopNavTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _spring = SpringDescription(
    mass: 1,
    stiffness: 420,
    damping: 16,
  );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)
      ..value = widget.active ? 1 : 0;
  }

  @override
  void didUpdateWidget(covariant _PopNavTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      final target = widget.active ? 1.0 : 0.0;
      final simulation = SpringSimulation(
        _spring,
        _controller.value,
        target,
        0,
      );
      _controller.animateWith(simulation);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: widget.active,
      label: '${widget.item.label} tab',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = _controller.value.clamp(0.0, 1.0);
              final scale = 1.0 + (0.16 * t);
              return Transform.translate(
                offset: Offset(0, -6.0 * t),
                child: Transform.scale(scale: scale, child: child),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
              padding: EdgeInsets.symmetric(
                horizontal: widget.dense ? 6 : 8,
                vertical: widget.dense ? 6 : 8,
              ),
              decoration: BoxDecoration(
                color: widget.active
                    ? _activeAccent
                    : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: widget.active ? _deepCharcoal : Colors.transparent,
                  width: 3,
                ),
                boxShadow: widget.active
                    ? const [
                        BoxShadow(
                          color: _activeAccentDeep,
                          offset: Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.item.icon,
                    color: widget.active ? _deepCharcoal : Colors.white70,
                    size: widget.dense ? 19 : 22,
                  ),
                  SizedBox(height: widget.dense ? 3 : 4),
                  SizedBox(
                    height: widget.dense ? 12 : 14,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        widget.item.label,
                        style: GoogleFonts.pixelifySans(
                          color: widget.active ? _deepCharcoal : Colors.white70,
                          fontSize: widget.dense ? 9.2 : 10.2,
                          fontWeight: widget.active
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
