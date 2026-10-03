import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services_backend_and_other_services/app_sound_service.dart';
import '../../themes_colors/app_theme.dart';

/// Gold for "you are here", the same gold as coins: one bright colour in the
/// bar, so the eye goes straight to it.
const _active = Color(0xFFFFC800);
const _inactive = Color(0xFF8FA3AE);
const _barColor = Color(0xFF182429);

class PopNavBarItem {
  const PopNavBarItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

/// The bottom tab bar.
///
/// **What it was, and why it changed.** A floating, rounded slab lifted off
/// the bottom of the screen, a thick border, a coloured glow, each active tab
/// springing up and scaling to 116%, and Home as a special yellow circle in
/// the middle. Testers said the app "looks AI", and the menu was named
/// specifically. The apps the user pointed at — Prodigy, and game apps like
/// Duolingo — use a plain bar fixed to the bottom edge: equal tabs, an icon
/// over a label, and the current one outlined in a bright colour. That is
/// what this is now. Nothing bounces, nothing floats, and Home is a tab like
/// the others.
class PopNavBar extends StatelessWidget {
  /// The app's shared 5-tab bottom set, so every caller wiring up nav stays
  /// in sync. Order must match [AppTabIndex] exactly — Home is index 2.
  /// Daily and Profile are reached from the top bar instead (see
  /// `_TopIconBar` in `main_navigation.dart`).
  static const appTabs = <PopNavBarItem>[
    PopNavBarItem(label: 'Life', icon: Icons.explore_rounded),
    PopNavBarItem(label: 'Arcade', icon: Icons.sports_esports_rounded),
    PopNavBarItem(label: 'Home', icon: Icons.home_rounded),
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
  // The tutorial spotlight draws a box around one of these tabs and cannot
  // use a `GlobalKey` to find it (see the note further down), so it reads
  // these numbers. `nav_geometry_test` renders a real bar and checks a real
  // tab against [tabRect], so the two cannot drift apart.

  /// Denser sizing on small viewports.
  static bool isDense(Size size) => size.width < 420 || size.height < 560;

  /// Tighter still, for short landscape windows.
  static bool isVeryTight(Size size) => size.height < 430;

  /// The height of the row of tabs, excluding the top rule and the safe area.
  static double barHeight(Size size) =>
      isVeryTight(size) ? 56.0 : (isDense(size) ? 64.0 : 70.0);

  /// The bar sits on the bottom edge now, so there is no gap under it.
  static double bottomGap(Size size) => 0.0;

  /// Full width: no margin either side.
  static const double outerMargin = 0.0;

  /// The bar only has a rule along its top, which does not inset the tabs
  /// sideways.
  static const double borderWidth = 0.0;

  /// The row's own horizontal padding.
  static const double innerPadding = 6.0;

  /// Total horizontal inset from the screen edge to the first tab.
  static const double sideInset = outerMargin + borderWidth + innerPadding;

  /// The 2px rule along the top of the bar.
  static const double topRule = 2.0;

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

  // NOTE: no GlobalKeys on the tabs. `MainNavigation` keeps all seven screens
  // alive in an `IndexedStack` and each renders its own bottom bar, so one
  // static key per tab would be attached to seven widgets at once. The tab
  // rect is derived from layout instead — see [tabRect].

  void _handleTap(int index) {
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
    final dense = isDense(screenSize);
    final veryTight = isVeryTight(screenSize);

    return Container(
      decoration: const BoxDecoration(
        color: _barColor,
        border: Border(
          top: BorderSide(color: AppTheme.outline, width: topRule),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: barHeight(screenSize),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: innerPadding),
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: _NavTab(
                      item: items[i],
                      active: i == activeIndex,
                      dense: dense,
                      veryTight: veryTight,
                      onTap: () => _handleTap(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One tab: an icon over its label. The current tab is outlined in gold on a
/// faint gold fill, the way a game app marks where you are.
class _NavTab extends StatelessWidget {
  const _NavTab({
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
  Widget build(BuildContext context) {
    final iconSize = veryTight ? 22.0 : (dense ? 24.0 : 26.0);
    final labelSize = veryTight ? 10.5 : (dense ? 11.5 : 12.5);
    final color = active ? _active : _inactive;

    return Semantics(
      button: true,
      selected: active,
      label: '${item.label} tab',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: EdgeInsets.symmetric(
              horizontal: 3,
              vertical: veryTight ? 4 : 6,
            ),
            decoration: BoxDecoration(
              color: active
                  ? Color.alphaBlend(_active.withValues(alpha: 0.10), _barColor)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: active ? _active : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, color: color, size: iconSize),
                SizedBox(height: veryTight ? 1 : 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    item.label,
                    maxLines: 1,
                    style: GoogleFonts.pixelifySans(
                      color: color,
                      fontSize: labelSize,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
