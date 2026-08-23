import 'package:budget_app/screens_minigames_admin_etc/Gameplay/academy/learning_path_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/core_bottom_pages/main_game_page.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/core_bottom_pages/minigames_page.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/customize_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/dashboard/home_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/money_habits/money_habits_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/profile/personal_details_sheet.dart';
import 'package:budget_app/screens_minigames_admin_etc/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../controllers_that_updates_stats/user_stats_controller.dart';
import '../services_backend_and_other_services/app_sound_service.dart';
import '../../../navigation_tools_and_animation/app_tab_index.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key, this.initialIndex = AppTabIndex.dashboard});

  final int initialIndex;

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _currentIndex;
  UserStatsController? _controller;
  bool _askedForPersonalDetails = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, AppTabIndex.count - 1).toInt();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = context.read<UserStatsController>();
    if (identical(controller, _controller)) {
      return;
    }
    _controller?.removeListener(_maybeAskForPersonalDetails);
    _controller = controller..addListener(_maybeAskForPersonalDetails);
    _maybeAskForPersonalDetails();
  }

  @override
  void dispose() {
    _controller?.removeListener(_maybeAskForPersonalDetails);
    super.dispose();
  }

  /// Prompts once per app run for the age/gender details, but only after the
  /// profile has finished loading — otherwise the defaults would make an
  /// existing player look like a brand new one.
  void _maybeAskForPersonalDetails() {
    final controller = _controller;
    if (_askedForPersonalDetails || controller == null || !mounted) {
      return;
    }
    if (controller.isLoading || !controller.isAuthenticated) {
      return;
    }

    _askedForPersonalDetails = true;
    if (controller.stats.hasCompletedPersonalDetails) {
      return;
    }

    // Defer past the current build/notify pass before pushing a route.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      PersonalDetailsSheet.show(
        context,
        ageBand: controller.stats.ageBand,
        gender: controller.stats.gender,
        isFirstRun: true,
      );
    });
  }

  void _selectTab(int index) {
    if (_currentIndex == index) {
      return;
    }
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TopIconBar(currentIndex: _currentIndex, onSelected: _selectTab),
        Expanded(
          // Order is load-bearing: this must match AppTabIndex and
          // PopNavBar.appTabs position for position for the bottom five.
          // Academy/Profile still get real IndexedStack slots (so tapping
          // the top icons works exactly like any other tab switch) — they
          // just are not among PopNavBar's five, so the bottom bar never
          // tries to highlight them.
          child: IndexedStack(
            index: _currentIndex,
            children: [
              MainGamePage(
                activeTabIndex: AppTabIndex.adventure,
                onNavSelected: _selectTab,
              ),
              MinigamesPage(
                activeTabIndex: AppTabIndex.minigames,
                onNavSelected: _selectTab,
              ),
              HomeScreen(
                activeTabIndex: AppTabIndex.dashboard,
                onNavSelected: _selectTab,
              ),
              MoneyHabitsScreen(
                activeTabIndex: AppTabIndex.daily,
                onNavSelected: _selectTab,
              ),
              CustomizeScreen(
                activeTabIndex: AppTabIndex.customize,
                onNavSelected: _selectTab,
              ),
              LearningPathScreen(
                activeTabIndex: AppTabIndex.academy,
                onNavSelected: _selectTab,
              ),
              ProfileScreen(
                activeTabIndex: AppTabIndex.profile,
                onNavSelected: _selectTab,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The app bar: **Learn — Budget Buddy — Profile**.
///
/// Learn and Profile moved off the bottom bar (seven tabs down there read as
/// crowded, and these two are visited far less often than the five that
/// stayed). Putting the wordmark between them turns what was two floating
/// buttons into a real, symmetrical app bar — it reads as app chrome, gives
/// the brand a permanent home on every screen, and visually balances the two
/// pills against each other instead of leaving a dead gap in the middle.
///
/// It sits above the `IndexedStack` rather than inside any screen's own
/// `AppBar`, so it is identical on all seven tabs.
class _TopIconBar extends StatelessWidget {
  const _TopIconBar({required this.currentIndex, required this.onSelected});

  final int currentIndex;
  final ValueChanged<int> onSelected;

  static const _barFill = Color(0xFF102A1D);
  static const _activeAccent = Color(0xFFFFD94A);

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 380;

    return Material(
      color: _barFill,
      child: SafeArea(
        bottom: false,
        child: Container(
          // A hairline under the bar separates it from whatever screen is
          // showing without needing a heavy shadow.
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: _activeAccent.withValues(alpha: 0.18),
                width: 2,
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(12, 7, 12, 8),
          child: Row(
            children: [
              _TopIconButton(
                label: 'Learn',
                icon: Icons.school_rounded,
                active: currentIndex == AppTabIndex.academy,
                compact: narrow,
                onTap: () => onSelected(AppTabIndex.academy),
              ),
              // Expanded on both sides keeps the wordmark optically centred
              // no matter how wide the two pills end up.
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Budget Buddy',
                      maxLines: 1,
                      style: GoogleFonts.pixelifySans(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
              _TopIconButton(
                label: 'Profile',
                icon: Icons.person_rounded,
                active: currentIndex == AppTabIndex.profile,
                compact: narrow,
                onTap: () => onSelected(AppTabIndex.profile),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  /// Tighter padding + slightly smaller text below ~380px wide, so the
  /// wordmark in the middle keeps its room on small phones. The label is
  /// deliberately **never** dropped — this bar's whole job is to be
  /// obvious, and an unlabelled icon is the opposite of that.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: '$label tab',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (active) return;
            HapticFeedback.lightImpact();
            AppSoundService.play(AppSoundEffect.navigation);
            onTap();
          },
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 9 : 12,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: active
                  ? _TopIconBar._activeAccent
                  : Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: active
                    ? const Color(0xFF21402C)
                    : Colors.white.withValues(alpha: 0.16),
                width: 2,
              ),
              // A soft accent glow on the active pill so "where am I" is
              // readable at a glance, matching the bottom bar's treatment.
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: _TopIconBar._activeAccent.withValues(
                          alpha: 0.30,
                        ),
                        blurRadius: 10,
                        spreadRadius: -2,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: compact ? 15 : 17,
                  color: active ? const Color(0xFF21402C) : Colors.white70,
                ),
                SizedBox(width: compact ? 4 : 6),
                Text(
                  label,
                  style: GoogleFonts.pixelifySans(
                    fontSize: compact ? 11 : 12.5,
                    fontWeight: FontWeight.w700,
                    color: active ? const Color(0xFF21402C) : Colors.white70,
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
