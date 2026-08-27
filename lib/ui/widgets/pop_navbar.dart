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
  /// The app's shared 5-tab bottom set, so every caller wiring up nav stays
  /// in sync. Order must match [AppTabIndex] exactly — Home is index 2, the
  /// middle slot, and is rendered as a circular badge (see [_PopNavTile])
  /// rather than the rounded pill every other tab gets. Daily and Profile
  /// are reached from the top strip instead (see `_TopIconBar` in
  /// `main_navigation.dart`) — not listed here, so the bar never tries to
  /// highlight them.
  static const appTabs = <PopNavBarItem>[
    PopNavBarItem(label: 'Life', icon: Icons.explore_rounded),
    PopNavBarItem(label: 'Arcade', icon: Icons.sports_esports_rounded),
    PopNavBarItem(label: 'Home', icon: Icons.dashboard_rounded),
    PopNavBarItem(label: 'Learn', icon: Icons.school_rounded),
    PopNavBarItem(label: 'Style', icon: Icons.auto_awesome_rounded),
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

  // NOTE: no GlobalKeys on the tabs.
  //
  // An earlier version keyed each tile so the tutorial could spotlight the
  // real button. It crashed every Dashboard test with "Multiple widgets used
  // the same GlobalKey": `MainNavigation` keeps all seven screens alive in an
  // `IndexedStack`, and each renders its own bottom bar, so one static key per
  // tab was attached to seven widgets at once.
  //
  // The tab rect is derived from layout instead — see
  // `TutorialTargets.navTabRect`, which is exact because the bar's height and
  // tab count are both known.

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
    // Widened from 360 — seven tabs need the denser sizing on more phones
    // than the old five-tab bar did.
    final dense = screenSize.width < 420 || screenSize.height < 560;
    final veryTight = screenSize.height < 430;
    // Bumped a few px across the board for a friendlier, easier-to-hit tap
    // target — this bar is used by players well under teen age. Padded
    // further per tier on top of that so the label's own +3px bump (see
    // the label SizedBox below) and Home's larger circular badge both have
    // real slack instead of an exact pixel-for-pixel fit.
    final barHeight = veryTight ? 80.0 : (dense ? 90.0 : 106.0);

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
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _PopNavTile(
                    item: items[i],
                    active: i == activeIndex,
                    // Home occupies the middle slot of the 7-tab set — see
                    // AppTabIndex.dashboard and the appTabs list above.
                    isCenter: i == items.length ~/ 2,
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
    required this.isCenter,
    required this.dense,
    required this.veryTight,
    required this.onTap,
  });

  final PopNavBarItem item;
  final bool active;
  // Home's slot: a circular icon badge instead of the rounded pill every
  // other tab gets, so the bar reads as anchored around it — see
  // AppTabIndex's doc comment and PopNavBar.appTabs above.
  final bool isCenter;
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
    final iconSize = widget.veryTight ? 20.0 : (widget.dense ? 21.0 : 24.0);
    final labelHeight = widget.veryTight ? 13.0 : (widget.dense ? 15.0 : 17.0);
    final labelFontSize = widget.veryTight
        ? 11.0
        : (widget.dense ? 12.5 : 14.0);
    // Home's badge is bigger than the other tabs' plain icons — it's the
    // one thing on the bar that isn't a rounded pill, so it needs its own
    // presence to read as deliberate rather than a rendering glitch.
    final badgeSize = widget.veryTight ? 36.0 : (widget.dense ? 40.0 : 46.0);

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
            child: widget.isCenter
                ? Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 4,
                    ),
                    padding: EdgeInsets.symmetric(
                      vertical: widget.veryTight ? 4 : (widget.dense ? 8 : 10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: badgeSize,
                          height: badgeSize,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.active
                                ? _activeAccent
                                : _deepCharcoal,
                            border: Border.all(
                              color: widget.active
                                  ? _deepCharcoal
                                  : _activeAccent.withValues(alpha: 0.55),
                              width: widget.active ? 3 : 2,
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
                          child: Icon(
                            widget.item.icon,
                            color: widget.active ? _deepCharcoal : Colors.white,
                            size: badgeSize * 0.5,
                          ),
                        ),
                        SizedBox(
                          height: widget.veryTight ? 2 : (widget.dense ? 3 : 4),
                        ),
                        SizedBox(
                          height: labelHeight,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              widget.item.label,
                              style: GoogleFonts.pixelifySans(
                                color: widget.active
                                    ? _activeAccent
                                    : Colors.white70,
                                fontSize: labelFontSize,
                                fontWeight: widget.active
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 4,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.dense ? 6 : 8,
                      vertical: widget.veryTight ? 6 : (widget.dense ? 8 : 10),
                    ),
                    decoration: BoxDecoration(
                      color: widget.active
                          ? _activeAccent
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusMedium,
                      ),
                      border: Border.all(
                        color: widget.active
                            ? _deepCharcoal
                            : Colors.transparent,
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
                          size: iconSize,
                        ),
                        SizedBox(
                          height: widget.veryTight ? 2 : (widget.dense ? 3 : 4),
                        ),
                        SizedBox(
                          height: labelHeight,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              widget.item.label,
                              style: GoogleFonts.pixelifySans(
                                color: widget.active
                                    ? _deepCharcoal
                                    : Colors.white70,
                                fontSize: labelFontSize,
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
