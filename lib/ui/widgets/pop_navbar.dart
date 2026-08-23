import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services_backend_and_other_services/app_sound_service.dart';
import '../../themes_colors/app_theme.dart';

// Lightened a step alongside AppTheme's forest palette so the nav bar
// doesn't read darker than the screens it's docked on.
const _deepCharcoal = Color(0xFF21402C);
const _deepCharcoalStrong = Color(0xFF122A1E);
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
  /// Order must match [AppTabIndex] exactly — Home is index 2, the middle
  /// slot. Five tabs rather than six so each label has room to be read.
  static const appTabs = <PopNavBarItem>[
    PopNavBarItem(label: 'Life', icon: Icons.explore_rounded),
    PopNavBarItem(label: 'Learn', icon: Icons.school_rounded),
    PopNavBarItem(label: 'Home', icon: Icons.dashboard_rounded),
    PopNavBarItem(label: 'Daily', icon: Icons.savings_rounded),
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
    final screenSize = MediaQuery.sizeOf(context);
    final dense = screenSize.width < 360 || screenSize.height < 560;
    final veryTight = screenSize.height < 430;
    // Bumped a few px across the board for a friendlier, easier-to-hit tap
    // target — this bar is used by players well under teen age.
    final barHeight = veryTight ? 66.0 : (dense ? 74.0 : 90.0);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          10,
          0,
          10,
          veryTight ? 6 : (dense ? 8 : 12),
        ),
        child: Container(
          height: barHeight,
          decoration: BoxDecoration(
            color: _deepCharcoalStrong,
            borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
            border: Border.all(color: _deepCharcoal, width: 4),
            boxShadow: AppTheme.puffyShadow(
              _activeAccent,
              restAlpha: 0.18,
              blurRadius: 22,
              spreadRadius: -8,
              offset: const Offset(0, 8),
            ),
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
                    veryTight: veryTight,
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
    required this.veryTight,
    required this.onTap,
  });

  final PopNavBarItem item;
  final bool active;
  final bool dense;
  final bool veryTight;
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
                horizontal: widget.dense ? 8 : 10,
                vertical: widget.veryTight ? 6 : (widget.dense ? 8 : 10),
              ),
              decoration: BoxDecoration(
                color: widget.active
                    ? _activeAccent
                    : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
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
                    size: widget.veryTight ? 20 : (widget.dense ? 21 : 24),
                  ),
                  SizedBox(
                    height: widget.veryTight ? 2 : (widget.dense ? 3 : 4),
                  ),
                  // Bumped up from 8/9.2/10.2 — the labels were small
                  // enough to be decorative rather than readable. Dropping
                  // from six tabs to five freed the width to do it.
                  SizedBox(
                    height: widget.veryTight ? 13 : (widget.dense ? 15 : 17),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        widget.item.label,
                        style: GoogleFonts.pixelifySans(
                          color: widget.active ? _deepCharcoal : Colors.white70,
                          fontSize: widget.veryTight
                              ? 11
                              : (widget.dense ? 12.5 : 14),
                          fontWeight: widget.active
                              ? FontWeight.w700
                              : FontWeight.w600,
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
