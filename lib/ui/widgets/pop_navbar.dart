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

  // --- Geometry, published ------------------------------------------
  //
  // The tutorial spotlight has to draw a box around one of these tabs, and it
  // cannot use a `GlobalKey` to find one (see the note below). So it computed
  // the rectangle from constants of its own: full screen width divided by the
  // tab count, 72px tall, flush to the bottom of the screen.
  //
  // **Every one of those was wrong.** This bar is 80-106px tall depending on
  // the viewport, inset 10px on each side plus 4px of inner padding, and
  // lifted 6-12px off the bottom. So the spotlight was offset on both axes and
  // the wrong size, which is why it kept landing next to the tab it was
  // pointing at instead of on it — reported three times.
  //
  // The numbers now live here, once, and both the bar and the spotlight read
  // them. `tutorial_test` measures a real rendered tab against [tabRect] so
  // the two cannot drift apart again.

  /// Denser sizing on small viewports.
  static bool isDense(Size size) => size.width < 420 || size.height < 560;

  /// Tighter still, for short landscape windows.
  static bool isVeryTight(Size size) => size.height < 430;

  /// The bar's own height, excluding the gap beneath it.
  static double barHeight(Size size) =>
      isVeryTight(size) ? 80.0 : (isDense(size) ? 90.0 : 106.0);

  /// The gap between the bar and the bottom safe area.
  static double bottomGap(Size size) =>
      isVeryTight(size) ? 6.0 : (isDense(size) ? 8.0 : 12.0);

  /// The outer `Padding` either side of the bar.
  static const double outerMargin = 10.0;

  /// The bar's border. Easy to forget and it cost a wrong answer: a
  /// `Container`'s border is drawn *inside* its box and insets the child, so
  /// the row of tabs starts four pixels further in than the padding alone
  /// suggests. Leaving it out put the predicted columns 3.2px off on a
  /// 430px-wide screen — small, and more than enough to draw a highlight
  /// straddling two tabs.
  static const double borderWidth = 4.0;

  /// The container's own horizontal padding, inside the border.
  static const double innerPadding = 4.0;

  /// Total horizontal inset from the screen edge to the first tab.
  static const double sideInset = outerMargin + borderWidth + innerPadding;

  /// Where tab [index] of [tabCount] actually sits on screen.
  ///
  /// [padding] is the view padding, so the caller passes
  /// `MediaQuery.of(context).padding`.
  static Rect tabRect(
    Size size,
    EdgeInsets padding,
    int index, {
    int tabCount = 5,
  }) {
    final barWidth = size.width - sideInset * 2;
    final tabWidth = barWidth / tabCount;
    final height = barHeight(size);
    final bottom = size.height - padding.bottom - bottomGap(size);
    return Rect.fromLTWH(
      sideInset + tabWidth * index,
      bottom - height,
      tabWidth,
      height,
    );
  }

  // NOTE: no GlobalKeys on the tabs.
  //
  // An earlier version keyed each tile so the tutorial could spotlight the
  // real button. It crashed every Dashboard test with "Multiple widgets used
  // the same GlobalKey": `MainNavigation` keeps all seven screens alive in an
  // `IndexedStack`, and each renders its own bottom bar, so one static key per
  // tab was attached to seven widgets at once.
  //
  // The tab rect is derived from layout instead — see [tabRect] above, and
  // the geometry note with it for why the first attempt at that was wrong.

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
    final dense = isDense(screenSize);
    final veryTight = isVeryTight(screenSize);
    // Bumped a few px across the board for a friendlier, easier-to-hit tap
    // target — this bar is used by players well under teen age. Padded
    // further per tier on top of that so the label's own +3px bump (see
    // the label SizedBox below) and Home's larger circular badge both have
    // real slack instead of an exact pixel-for-pixel fit.
    final height = barHeight(screenSize);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          outerMargin,
          0,
          outerMargin,
          bottomGap(screenSize),
        ),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: _deepCharcoalStrong,
            borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
            border: Border.all(color: _deepCharcoal, width: borderWidth),
            boxShadow: AppTheme.puffyShadow(
              _activeAccent,
              restAlpha: 0.18,
              blurRadius: 22,
              spreadRadius: -8,
              offset: const Offset(0, 8),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: innerPadding),
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

/// How far the active tab is scaled up. Shared with [_HuggingPill], which
/// needs it to cap the pill so the scaled-up version still lands inside its
/// cell -- a `Transform` does not affect layout, so this is the only thing
/// stopping it painting over its neighbour.
const double _activeScale = 1.16;

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
              final scale = 1.0 + ((_activeScale - 1.0) * t);
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
                : _HuggingPill(
                    scale: _activeScale,
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 4,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: widget.dense ? 10 : 14,
                        vertical: widget.veryTight
                            ? 6
                            : (widget.dense ? 8 : 10),
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
                            color: widget.active
                                ? _deepCharcoal
                                : Colors.white70,
                            size: iconSize,
                          ),
                          SizedBox(
                            height: widget.veryTight
                                ? 2
                                : (widget.dense ? 3 : 4),
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
      ),
    );
  }
}

/// Sizes a nav pill to its own content instead of to the cell it sits in.
///
/// **The bug this fixes.** The tab tiles live in `Expanded`, which hands down
/// a *tight* width, and a `Container` with no width of its own fills whatever
/// it is given. So the gold active-tab treatment was not a pill at all — it
/// was a slab spanning the entire fifth of the bar, and on a wide window that
/// is a ~190px block of solid yellow. It reads as a rendering fault rather
/// than as a selection, which is exactly what it got reported as.
///
/// A `Center` is enough to loosen the constraint and let the pill hug its
/// label. The cap is the part that is doing real work: the active tab is
/// painted at [scale] by a `Transform`, and a transform does not participate
/// in layout, so a pill that exactly fills its cell paints 16% *outside* it
/// with nothing to catch it — a `Row` only reports overflow it can measure.
/// Capping the pill at `1 / scale` of the cell means the scaled-up version
/// still lands inside, by construction, at every width.
///
/// The tap target is unaffected: the `InkWell` is above this, so the whole
/// cell stays pressable even though only the middle of it is painted.
class _HuggingPill extends StatelessWidget {
  const _HuggingPill({required this.child, required this.scale});

  final Widget child;

  /// The `Transform.scale` factor applied to the active tab.
  final double scale;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final cell = constraints.maxWidth;
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: cell.isFinite ? cell / scale : double.infinity,
          ),
          child: child,
        ),
      );
    },
  );
}
