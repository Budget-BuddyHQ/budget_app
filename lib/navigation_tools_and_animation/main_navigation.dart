import 'package:budget_app/screens_minigames_admin_etc/Gameplay/academy/learning_path_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/core_bottom_pages/main_game_page.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/core_bottom_pages/minigames_page.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/customize_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/dashboard/home_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/money_habits/money_habits_screen.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/tutorial_steps.dart';
import 'package:budget_app/screens_minigames_admin_etc/onboarding/coach_mark.dart';
import 'package:budget_app/screens_minigames_admin_etc/profile/personal_details_sheet.dart';
import 'package:budget_app/screens_minigames_admin_etc/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../controllers_that_updates_stats/app_settings_controller.dart';
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
  AppSettingsController? _settings;
  bool _askedForPersonalDetails = false;

  /// Set once the tutorial question has been answered for this session —
  /// either it was shown and dismissed, or it was never due. Gates the
  /// personal-details sheet so the two first-run interruptions queue instead
  /// of stacking on top of each other.
  bool _tutorialResolved = false;

  /// Whether the guided tour is currently on screen.
  ///
  /// The tour is a **layer over this widget**, not a route pushed on top of
  /// it. That is the whole difference between the old deck and this one: a
  /// route replaces the app with a description of the app, so a player who
  /// read all seven pages still had to go and find everything afterwards.
  /// Drawn here, each step spotlights the real widget on the real screen, and
  /// switching steps switches tabs underneath — so by the time the tour ends
  /// the player has already been everywhere it talks about.
  bool _touring = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, AppTabIndex.count - 1).toInt();
    // Music starts here rather than in `main()` so it begins when the player
    // reaches the app proper — a loop playing under the sign-in screen is
    // music over a form, which is not what anybody means by ambience.
    // `startMusic` is idempotent and no-ops when the preference is off.
    AppSoundService.startMusic();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final settings = context.read<AppSettingsController>();
    if (!identical(settings, _settings)) {
      _settings?.removeListener(_maybeShowTutorial);
      _settings = settings..addListener(_maybeShowTutorial);
      _maybeShowTutorial();
    }

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
    AppSoundService.stopMusic();
    _controller?.removeListener(_maybeAskForPersonalDetails);
    _settings?.removeListener(_maybeShowTutorial);
    super.dispose();
  }

  /// Opens the guided tour on a genuine first run, then hands off to the
  /// personal-details sheet.
  ///
  /// Waits on `isInitialized` rather than firing immediately: the seen flag
  /// lives in SharedPreferences, and acting on its pre-read default would
  /// show the whole tour again to an existing player on every cold start.
  void _maybeShowTutorial() {
    final settings = _settings;
    if (settings == null || !mounted || _touring) {
      return;
    }
    // A replay request is honoured even for a player who has already seen the
    // tour — that is the whole point of the button in Profile — and it does
    // *not* wait on `isInitialized`. That gate exists so the automatic
    // first-run decision is never made from a pre-read default; an explicit
    // "show me the tour again" has nothing to read.
    final replay = settings.tutorialReplayRequested;
    if (replay) {
      settings.consumeTutorialReplay();
    } else {
      if (_tutorialResolved) {
        return;
      }
      if (!settings.isInitialized) {
        return;
      }
      _tutorialResolved = true;
      if (!settings.isTutorialDue) {
        _maybeAskForPersonalDetails();
        return;
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() => _touring = true);
    });
  }

  /// Ends the tour — finished or skipped, same result — and hands off to the
  /// personal-details sheet so the two first-run interruptions queue.
  Future<void> _finishTour() async {
    if (!_touring) {
      return;
    }
    setState(() => _touring = false);
    await _settings?.markTutorialSeen();
    if (!mounted) {
      return;
    }
    _maybeAskForPersonalDetails();
  }

  /// Switches tabs for a tour step and waits for the new screen to lay out.
  ///
  /// The wait is not politeness. `IndexedStack` keeps every screen alive, but
  /// a screen that has never been the visible child has no laid-out geometry
  /// to measure, so a spotlight that asks for its target in the same frame
  /// gets the *previous* screen's rectangle and lands on whatever happened to
  /// be in that spot.
  Future<void> _tourWantsTab(int index) async {
    if (_currentIndex != index) {
      setState(() => _currentIndex = index);
    }
    await WidgetsBinding.instance.endOfFrame;
  }

  /// Prompts once per app run for the age/gender details, but only after the
  /// profile has finished loading — otherwise the defaults would make an
  /// existing player look like a brand new one.
  void _maybeAskForPersonalDetails() {
    final controller = _controller;
    if (_askedForPersonalDetails || controller == null || !mounted) {
      return;
    }
    // Never in front of the tour — `_maybeShowTutorial` calls back here once
    // it's done, so nothing is lost by waiting.
    if (!_tutorialResolved) {
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
    final app = _buildApp(context);
    if (!_touring) {
      return app;
    }
    return Stack(
      children: [
        app,
        Positioned.fill(
          child: CoachMarkOverlay(
            steps: kTutorialSteps,
            onFinished: _finishTour,
            onWantTab: _tourWantsTab,
          ),
        ),
      ],
    );
  }

  Widget _buildApp(BuildContext context) {
    return Column(
      children: [
        _TopIconBar(currentIndex: _currentIndex, onSelected: _selectTab),
        Expanded(
          // Order is load-bearing: this must match AppTabIndex and
          // PopNavBar.appTabs position for position for the bottom five.
          // Daily/Profile still get real IndexedStack slots (so tapping
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
              LearningPathScreen(
                activeTabIndex: AppTabIndex.academy,
                onNavSelected: _selectTab,
              ),
              CustomizeScreen(
                activeTabIndex: AppTabIndex.customize,
                onNavSelected: _selectTab,
              ),
              MoneyHabitsScreen(
                activeTabIndex: AppTabIndex.daily,
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

/// The app bar: **Daily — Budget Buddy — 🏆 Profile**.
///
/// Daily and Profile moved off the bottom bar (seven tabs down there read as
/// crowded). Learn was here first and swapped places with Daily by request —
/// this file and `AppTabIndex`'s doc comment are the only two places that
/// need to change if it swaps again; every other file references the named
/// constants, never a literal tab.
///
/// First version of this bar was flat-filled and text-only, and read as
/// "generic row of buttons" rather than as the app's own identity — hence
/// "I'm not getting that top nav bar feeling". What gives it that now: the
/// fill is a gradient rather than one flat colour, matching the puffy-card
/// look used everywhere else in the app; and the leaderboard — previously
/// reachable only from a small button buried in Home's now-removed AppBar
/// — gets its own permanent trophy pill here, next to Profile, so it is
/// visible from every tab instead of only from Home.
///
/// The turtle mascot was tried next to the wordmark and removed by
/// request: at 22px it read as clutter beside an already-strong pixel
/// wordmark rather than as branding. Left as text.
///
/// It sits above the `IndexedStack` rather than inside any screen's own
/// `AppBar`, so it is identical on all seven tabs.
class _TopIconBar extends StatelessWidget {
  const _TopIconBar({required this.currentIndex, required this.onSelected});

  final int currentIndex;
  final ValueChanged<int> onSelected;

  static const _barTop = Color(0xFF15382A);
  static const _barBottom = Color(0xFF0C2018);
  static const _activeAccent = Color(0xFFFFD94A);

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 380;

    return Material(
      color: _barBottom,
      child: SafeArea(
        bottom: false,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_barTop, _barBottom],
            ),
            // A hairline under the bar separates it from whatever screen is
            // showing without needing a heavy shadow.
            border: Border(
              bottom: BorderSide(
                color: _activeAccent.withValues(alpha: 0.22),
                width: 2,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(10, 7, 10, 8),
          child: Row(
            children: [
              _TopIconButton(
                label: 'Daily',
                icon: Icons.savings_rounded,
                active: currentIndex == AppTabIndex.daily,
                compact: narrow,
                tourId: 'daily',
                onTap: () => onSelected(AppTabIndex.daily),
              ),
              // Expanded on both sides keeps the wordmark optically centred
              // no matter how wide the two side groups end up.
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Budget Buddy',
                          maxLines: 1,
                          style: GoogleFonts.pixelifySans(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Builder(
                builder: (context) {
                  final key = _tourKeys.putIfAbsent(
                    'leaderboard',
                    GlobalKey.new,
                  );
                  TutorialTargets.register('leaderboard', key);
                  return _LeaderboardIconButton(key: key, compact: narrow);
                },
              ),
              SizedBox(width: narrow ? 6 : 8),
              _TopIconButton(
                label: 'Profile',
                icon: Icons.person_rounded,
                active: currentIndex == AppTabIndex.profile,
                compact: narrow,
                tourId: 'profile',
                onTap: () => onSelected(AppTabIndex.profile),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A permanent way into the leaderboard from every tab — not a tab switch
/// (the leaderboard isn't one of the seven `IndexedStack` screens), a real
/// push, same as Home's promo card already did.
class _LeaderboardIconButton extends StatelessWidget {
  const _LeaderboardIconButton({super.key, required this.compact});

  final bool compact;

  static const _gold = Color(0xFFFFD45C);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Leaderboard',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            AppSoundService.play(AppSoundEffect.navigation);
            Navigator.of(context).pushNamed('/leaderboard');
          },
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: compact ? 30 : 34,
            height: compact ? 30 : 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(
                color: _gold.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.emoji_events_rounded,
              color: _gold,
              size: compact ? 17 : 19,
            ),
          ),
        ),
      ),
    );
  }
}

/// One `GlobalKey` per top-bar button, kept outside the widget so a rebuild
/// hands back the same key instead of orphaning the registered one.
final Map<String, GlobalKey> _tourKeys = <String, GlobalKey>{};

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
    this.compact = false,
    this.tourId,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  /// Registers this button as a coach-mark target under [tourId].
  ///
  /// Daily, the leaderboard and Profile live up here rather than in the
  /// bottom bar, so `TutorialTargets.navTabRect` — which derives its
  /// rectangle from the bottom bar's geometry — cannot find them. Without a
  /// key the tour simply centred its card and pointed at nothing for three of
  /// its eleven steps.
  ///
  /// Safe as a `GlobalKey` where the bottom tabs were not: this bar is built
  /// once by `MainNavigation`, not once per screen in the `IndexedStack`.
  final String? tourId;

  /// Tighter padding + slightly smaller text below ~380px wide, so the
  /// wordmark in the middle keeps its room on small phones. The label is
  /// deliberately **never** dropped — this bar's whole job is to be
  /// obvious, and an unlabelled icon is the opposite of that.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final id = tourId;
    if (id != null) {
      TutorialTargets.register(id, _tourKeys.putIfAbsent(id, GlobalKey.new));
    }
    return Semantics(
      key: id == null ? null : _tourKeys[id],
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
