import 'dart:math';

import 'package:budget_app/controllers_that_updates_stats/app_settings_controller.dart';
import 'package:budget_app/controllers_that_updates_stats/daily_plan_controller.dart';
import 'package:budget_app/controllers_that_updates_stats/life_sim_controller.dart';
import 'package:budget_app/controllers_that_updates_stats/money_habit_controller.dart';
import 'package:budget_app/controllers_that_updates_stats/user_stats_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/lesson_data.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/academy/lesson_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/core_bottom_pages/main_game_page.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/core_bottom_pages/minigames_page.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/customize_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/dashboard/home_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/dashboard/leaderboard_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/minigames_pages/coin_cascade_page.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/minigames_pages/life_sim_page.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/minigames_pages/past_lives_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/money_habits/money_habits_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/minigames_pages/finance_brawl_game.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/minigames_pages/stock_market_page.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/adventure/town_interior_screen.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/town_spot_models.dart';
import 'package:budget_app/screens_minigames_admin_etc/profile/profile_screen.dart';
import 'package:budget_app/services_backend_and_other_services/market_data_service.dart';
import 'package:budget_app/services_backend_and_other_services/supabase_service.dart';
import 'package:budget_app/themes_colors/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/app_fonts.dart';

/// A playtest: open each screen and *use* it.
///
/// **What this catches that the other suites do not.** The viewport sweep
/// checks that screens lay out; the contrast audit checks that text is legible;
/// the unit tests check that rules are right. None of them presses a button.
/// Almost every bug a player has reported in this project came from an
/// interaction rather than from a first paint — a sensor firing during build, a
/// dialog opening over a scrolling list, a state change on a screen that had
/// already been disposed.
///
/// So this taps things. Every tappable control on each screen gets pressed, and
/// any exception — thrown, or reported through `FlutterError.onError` as an
/// overflow — fails the test with the screen and the control that caused it.
///
/// Errors are *collected* rather than asserted inside the loop: asserting while
/// `FlutterError.onError` is overridden trips an assertion inside the binding
/// itself, and the resulting failure describes the harness instead of the app.
void main() {
  // registers the real typefaces up front. google_fonts resolves a bundled
  // face async on first use, so without this only the faces the first build
  // happened to touch are loaded by the time anything gets measured.
  // see test/support/app_fonts.dart
  setUpAll(loadAppFonts);

  Widget wrap(Widget child) => MultiProvider(
    providers: [
      ChangeNotifierProvider<UserStatsController>(
        // never initialised on purpose — the service reads through a
        // nullable client so an uninitialised Supabase just gives you
        // signed-out defaults instead of throwing. thats the state a
        // brand new player is in anyway
        create: (_) => UserStatsController(service: SupabaseService.instance),
      ),
      ChangeNotifierProvider<AppSettingsController>(
        create: (_) => AppSettingsController(),
      ),
      ChangeNotifierProvider<MarketDataService>(
        create: (_) => MarketDataService(),
      ),
      ChangeNotifierProxyProvider<UserStatsController, DailyPlanController>(
        create: (context) =>
            DailyPlanController(context.read<UserStatsController>()),
        update: (_, stats, previous) => previous ?? DailyPlanController(stats),
      ),
      ChangeNotifierProxyProvider<UserStatsController, MoneyHabitController>(
        create: (context) =>
            MoneyHabitController(context.read<UserStatsController>()),
        update: (_, stats, previous) => previous ?? MoneyHabitController(stats),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.getLightTheme(),
      home: child,
      // the named routes the screens actually push. without these a tap
      // that navigates dies with "Could not find a generator for route",
      // which looks like an app bug in the report but is really a hole in
      // the
      // harness — and worse, it masks whatever the destination screen would
      // have done.
      routes: <String, WidgetBuilder>{
        '/life': (_) => const LifeSimPage(),
        '/leaderboard': (_) => const LeaderboardScreen(),
        '/daily': (_) => const MoneyHabitsScreen(),
        '/customize': (_) => const CustomizeScreen(),
        '/minigames': (_) => const MinigamesPage(),
        '/lessons': (_) => const LessonScreen(),
      },
    ),
  );

  LifeSimController midLife() {
    final life = LifeSimController(random: Random(24), initialAge: 0);
    while (life.age < 30 && !life.finished) {
      if (life.currentEvent != null) life.chooseOption(0);
      life.ageUp();
    }
    return life;
  }

  /// Presses every tappable control on the screen, one at a time, returning
  /// to the screen between presses.
  ///
  /// Rebuilt from scratch for each press rather than tapping down a captured
  /// list: a tap can push a route, open a dialog or rebuild the tree, which
  /// invalidates every finder captured before it. Re-pumping is slower and is
  /// the only version that is actually testing the screen.
  Future<List<String>> pressEverything(
    WidgetTester tester,
    String screen,
    Widget Function() build, {
    int limit = 40,
  }) async {
    final problems = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) =>
        problems.add('$screen: ${details.exceptionAsString().split('\n').first}');

    try {
      for (var index = 0; index < limit; index++) {
        await tester.pumpWidget(wrap(build()));
        await tester.pump(const Duration(milliseconds: 400));

        final taps = find.byWidgetPredicate(
          (widget) =>
              widget is InkWell && widget.onTap != null ||
              widget is GestureDetector && widget.onTap != null ||
              widget is IconButton && widget.onPressed != null,
        );
        final count = taps.evaluate().length;
        if (index >= count) break;

        // `warnIfMissed: false`: plenty of these are laid out off-screen in a
        // scroll view, and a missed tap is not what this is looking for.
        await tester.tap(taps.at(index), warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));
      }

      // Tear the tree down: a screen that leaves a timer or a listener behind
      // fails here rather than in whatever test happens to run next.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 400));
    } finally {
      FlutterError.onError = previous;
    }
    return problems;
  }

  final screens = <String, Widget Function()>{
    'Home': () => const HomeScreen(),
    'Life hub': () => const MainGamePage(),
    'Life sim': () => LifeSimPage(debugInitialLife: midLife()),
    'Past lives': () => const PastLivesScreen(),
    'Arcade': () => const MinigamesPage(),
    'Coin Cascade': () => const CoinCascadePage(),
    'Finance Brawl': () => const FinanceBrawlScreen(),
    'Market Board': () => const StockMarketPage(),
    'Academy': () => const LessonScreen(),
    'Money Habits — today': () => const MoneyHabitsScreen(),
    'Money Habits — week': () =>
        const MoneyHabitsScreen(initialTab: MoneyHabitsTab.week),
    'Money Habits — challenges': () => const MoneyHabitsScreen(initialTab: MoneyHabitsTab.challenges),
    'Money Habits — jar': () => const MoneyHabitsScreen(initialTab: MoneyHabitsTab.jar),
    'Money Habits — coach': () => const MoneyHabitsScreen(initialTab: MoneyHabitsTab.coach),
    'Customize': () => const CustomizeScreen(),
    'Profile': () => const ProfileScreen(),
    'Leaderboard': () => const LeaderboardScreen(),
    // The two interiors with the most controls: the store is a buy screen and
    // the bank is the one that moves money between accounts. Both open a
    // scenario dialog on entry, so the first press lands on a dialog rather
    // than on the page underneath — which is exactly the case the sweep of
    // plain screens was missing.
    'Corner Store': () =>
        TownInteriorScreen(spot: kTownSpots.firstWhere((s) => s.kind == TownSpotKind.store)),
    'Bank': () =>
        TownInteriorScreen(spot: kTownSpots.firstWhere((s) => s.kind == TownSpotKind.bank)),
  };

  group('playtest: pressing things does not break anything', () {
    for (final entry in screens.entries) {
      testWidgets('${entry.key} survives being used', (tester) async {
        tester.view.physicalSize = const Size(430, 932);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final problems = await pressEverything(tester, entry.key, entry.value);
        expect(
          problems,
          isEmpty,
          reason: 'using ${entry.key} produced:\n  ${problems.join('\n  ')}',
        );
      });
    }
  });

  group('playtest: a first-time player', () {
    testWidgets('lands on something to do rather than an empty screen', (
      tester,
    ) async {
      // A brand-new account has no progress, no habits and no history. Every
      // "your recent…" list is empty, and an app that shows six empty cards on
      // first launch has failed before the player has done anything.
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(wrap(const HomeScreen()));
      await tester.pump(const Duration(milliseconds: 400));

      // Something actionable has to be on screen.
      final buttons = find.byWidgetPredicate(
        (widget) =>
            widget is InkWell && widget.onTap != null ||
            widget is GestureDetector && widget.onTap != null,
      );
      expect(
        buttons.evaluate().length,
        greaterThan(3),
        reason: 'Home offers a new player almost nothing to press',
      );
    });

    testWidgets('the Academy opens on the first unit, not the last', (
      tester,
    ) async {
      // The curriculum is age-ordered, so a new reader must land at the start
      // of it. Landing on "Retirement and the 401(k)" would be the app's
      // first impression for a nine-year-old.
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(wrap(const LessonScreen()));
      await tester.pump(const Duration(milliseconds: 400));

      final firstUnit = lessonUnits.first;
      final shown = firstUnit.title.split(': ').last;
      expect(
        find.textContaining(shown, findRichText: true),
        findsWidgets,
        reason: 'the Academy did not open on "$shown"',
      );
    });
  });
}
