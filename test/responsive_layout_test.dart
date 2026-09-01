import 'dart:math';

import 'package:budget_app/controllers_that_updates_stats/app_settings_controller.dart';
import 'package:budget_app/controllers_that_updates_stats/life_sim_controller.dart';
import 'package:budget_app/controllers_that_updates_stats/daily_plan_controller.dart';
import 'package:budget_app/controllers_that_updates_stats/money_habit_controller.dart';
import 'package:budget_app/controllers_that_updates_stats/user_stats_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/lesson.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/lesson_data.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/player_profile.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/progression_service.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/academy/lesson_detail_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/academy/lesson_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/academy/practice_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/adventure/adventure_world_screen.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/town_spot_models.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/adventure/town_interior_screen.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_ending.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_sim_models.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/minigames_pages/life_epilogue_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/minigames_pages/life_sim_page.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/money_habits/money_habits_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/profile/feedback_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/profile/profile_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/dashboard/leaderboard_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/minigames_pages/past_lives_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/profile/personal_details_sheet.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/core_bottom_pages/main_game_page.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/core_bottom_pages/minigames_page.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/customize_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/minigames_pages/coin_cascade_page.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/minigames_pages/finance_brawl_game.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/minigames_pages/stock_market_page.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/dashboard/dashboard_shell.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/dashboard/home_screen.dart';
import 'package:budget_app/services_backend_and_other_services/market_data_service.dart';
import 'package:budget_app/services_backend_and_other_services/supabase_service.dart';
import 'package:budget_app/themes_colors/app_theme.dart';
import 'package:budget_app/widgets_custom_lotties/ambient_lottie_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/app_fonts.dart';

/// Screen sizes the app has to survive.
///
/// The landscape entries are the ones that used to be untested, because the
/// app locked itself to portrait at launch.
const Map<String, Size> _viewports = <String, Size>{
  'small phone portrait': Size(320, 568),
  'phone portrait': Size(375, 812),
  'mid phone portrait': Size(393, 852),
  'large phone portrait': Size(430, 932),
  'phone landscape': Size(812, 375),
  'small phone landscape': Size(568, 320),
  'tablet portrait': Size(768, 1024),
  'tablet landscape': Size(1024, 768),
};

/// A handful of fake quotes, including some of the Market Board's
/// logo-carrying symbols, so the ticker tape and trending-now strip
/// actually render during the layout sweep below instead of staying empty
/// (no test environment ever completes a real live-price fetch).
List<LiveQuote> _fakeQuotes() {
  final now = DateTime.now();
  const symbols = <(String, String, double, double)>[
    ('AAPL', 'Apple Inc.', 1900.0, 1.8),
    ('TSLA', 'Tesla, Inc.', 2200.0, -2.4),
    ('MSFT', 'Microsoft Corp.', 3600.0, 0.6),
    ('SBUX', 'Starbucks Corp.', 850.0, -0.3),
  ];
  return [
    for (final (symbol, company, price, pct) in symbols)
      LiveQuote(
        symbol: symbol,
        company: company,
        current: price,
        change: price * pct / 100,
        percentChange: pct,
        high: price * 1.02,
        low: price * 0.98,
        open: price * 0.995,
        previousClose: price / (1 + pct / 100),
        fetchedAt: now,
      ),
  ];
}


/// A freshly created character, bypassing the character sheet.
LifeSimController _newborn() =>
    LifeSimController(random: Random(5), initialAge: 0);

/// A life partway through, with the feed carrying everything it can carry:
/// a salary (so the budget bar and runway line render), an event to answer,
/// and whatever chain chips the run picked up on the way.
LifeSimController _midLife() {
  final life = LifeSimController(
    random: Random(7),
    initialAge: 0,
    startMoney: 0,
  );
  final picker = Random(99);
  // Play forward until an event is on screen at an age where the budget
  // controls exist, so the widest version of the feed is what gets measured.
  // Taking a job is part of that: without a salary `canBudget` stays false
  // and the budget bar, the runway line and the paycheck history never
  // render, which would make this the same test as the newborn one.
  for (var i = 0; i < 40 && !life.finished; i++) {
    if (life.canJobHunt) life.findJob();
    final event = life.currentEvent;
    if (event != null) {
      if (life.age >= 30 && life.canBudget) break;
      life.chooseOption(picker.nextInt(event.choices.length));
    }
    life.ageUp();
  }
  return life;
}

Widget _wrap(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<UserStatsController>(
        // Never initialised: the service reads through a nullable client, so
        // an uninitialised Supabase yields signed-out defaults rather than
        // throwing. That is exactly the state we want to lay out.
        create: (_) => UserStatsController(service: SupabaseService.instance),
      ),
      ChangeNotifierProvider<AppSettingsController>(
        create: (_) => AppSettingsController(),
      ),
      ChangeNotifierProvider<MarketDataService>(
        create: (_) => MarketDataService()..seedQuotesForTest(_fakeQuotes()),
      ),
      ChangeNotifierProxyProvider<UserStatsController, DailyPlanController>(
        create: (context) =>
            DailyPlanController(context.read<UserStatsController>()),
        update: (_, userStats, previous) =>
            previous ?? DailyPlanController(userStats),
      ),
      ChangeNotifierProxyProvider<UserStatsController, MoneyHabitController>(
        create: (context) =>
            MoneyHabitController(context.read<UserStatsController>()),
        update: (_, userStats, previous) =>
            previous ?? MoneyHabitController(userStats),
      ),
    ],
    child: MaterialApp(theme: AppTheme.getLightTheme(), home: child),
  );
}

void main() {
  // Registers the real typefaces up front rather than letting google_fonts
  // resolve them asynchronously on first use, which loaded only the faces the
  // first build happened to touch — see test/support/app_fonts.dart.
  setUpAll(loadAppFonts);

  final unit = lessonUnits.first;
  final readingLesson = unit.lessons.firstWhere(
    (lesson) => lesson.type == LessonNodeType.lesson,
  );
  final quizNode = unit.lessons.firstWhere(
    (lesson) => lesson.type == LessonNodeType.quiz,
  );
  final testNode = lessonUnits[1].lessons.firstWhere(
    (lesson) => lesson.type == LessonNodeType.unitTest,
  );

  LessonDetailScreen detail(Lesson lesson, LessonUnit inUnit) =>
      LessonDetailScreen(
        lesson: lesson,
        unit: inUnit,
        progressionService: ProgressionService(),
      );

  final screens = <String, Widget Function()>{
    'Dashboard shell': () => const DashboardShell(),
    'Home': () => const HomeScreen(),
    'Adventure': () => const MainGamePage(),
    'Arcade': () => const MinigamesPage(),
    'Customize': () => const CustomizeScreen(),
    'Academy': () => const LessonScreen(),
    'Lesson reading': () => detail(readingLesson, unit),
    'Lesson quiz': () => detail(quizNode, unit),
    'Unit test': () => detail(testNode, lessonUnits[1]),
    'Practice': () => PracticeScreen(unit: unit),
    'Personal details sheet': () => Scaffold(
      body: PersonalDetailsSheet(
        initialAgeBand: AgeBand.teen13to15,
        initialGender: GenderIdentity.undisclosed,
        isFirstRun: true,
      ),
    ),
    // The main game itself, not just its ending screen. The feed carries
    // the money panel and the stat meters, both of which reflow rather
    // than truncate, so they need every viewport in the sweep.
    // Age 0, straight out of character creation.
    'Life sim': () => LifeSimPage(debugInitialLife: _newborn()),
    // Mid-life, with money in four places, debt, an event on screen and a
    // row of chain chips. This is the state the feed is actually busiest
    // in, and none of it had viewport coverage before the test seam.
    'Life sim (mid-life)': () => LifeSimPage(debugInitialLife: _midLife()),
    // The town interiors. The Corner Store is the one with the animated
    // stall and the widest choice list, so it is the worst case; the bank
    // takes the NPC branch instead of the stall branch.
    'Corner Store interior': () => TownInteriorScreen(
      spot: kTownSpots.firstWhere((s) => s.kind == TownSpotKind.store),
    ),
    'Bank interior': () => TownInteriorScreen(
      spot: kTownSpots.firstWhere((s) => s.kind == TownSpotKind.bank),
    ),
    'Finance Brawl': () => const FinanceBrawlScreen(),
    // The board fits itself to whatever space it gets, which is exactly the
    // kind of claim that needs the landscape and small-phone entries.
    'Coin Cascade': () => const CoinCascadePage(),
    'Market Board': () => const StockMarketPage(),
    'Feedback': () => const FeedbackScreen(),
    // The three screens this sweep never covered. Profile and the
    // leaderboard are where a player spends the least time and the most
    // attention -- an account page that overflows on a 320px phone is the
    // screenshot that gets posted -- and Past Lives grows a row per run, so
    // it is the one screen whose height is set by how much the player has
    // done rather than by the design.
    'Profile': () => const ProfileScreen(),
    'Leaderboard': () => const LeaderboardScreen(),
    'Past lives': () => const PastLivesScreen(),
    // Money Habits has four inner tabs and the sweep only ever saw the
    // first. My Jar is the one that got rebuilt — a painted jar, a milestone
    // row and two stat cards — so it is the one most likely to overflow a
    // small phone.
    'Money Habits — My Week': () => const MoneyHabitsScreen(),
    'Money Habits — Challenges': () => const MoneyHabitsScreen(initialTab: 2),
    'Money Habits — My Jar': () => const MoneyHabitsScreen(initialTab: 3),
    'Money Habits — Coach': () => const MoneyHabitsScreen(initialTab: 4),
    // No map file exists yet, so this exercises the "waiting for the map"
    // fallback screen, not the Bonfire game canvas itself.
    'Adventure (map pending)': () => const AdventureWorldScreen(),
    'Life epilogue': () => LifeEpilogueScreen(
      summary: LifeSummary(
        name: 'Alexandria Montgomery-Whitfield',
        gender: Gender.nonBinary,
        origin: LifeOrigin.comfortable,
        job: 'Senior Financial Wellness Consultant',
        age: 84,
        yearsLived: 84,
        died: false,
        netWorth: 128400,
        happiness: 76,
        health: 62,
        smarts: 91,
        looks: 58,
        relationships: const ['Jordan', 'Priya', 'Marcus', 'Grandma Lucille'],
        goldReward: 512,
        archetype: LifeEndingArchetype.legacyBuilder,
      ),
    ),
  };

  for (final screenEntry in screens.entries) {
    group(screenEntry.key, () {
      for (final viewport in _viewports.entries) {
        testWidgets('lays out without overflow on ${viewport.key}', (
          tester,
        ) async {
          final errors = <FlutterErrorDetails>[];
          final previousOnError = FlutterError.onError;
          FlutterError.onError = errors.add;

          tester.view.physicalSize = viewport.value;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          try {
            await tester.pumpWidget(_wrap(screenEntry.value()));
            await tester.pump(const Duration(milliseconds: 300));
          } finally {
            FlutterError.onError = previousOnError;
          }

          // Every exception, not just "overflowed by". Filtering to overflow
          // messages meant a screen could throw a null-check failure or fail
          // to lay out entirely and this sweep would still report it clean --
          // which is exactly how the Market Board's unbounded-Expanded crash
          // survived a full pass at 320px wide.
          final overflows = errors
              .map((error) => error.exception.toString())
              .toList(growable: false);

          expect(
            overflows,
            isEmpty,
            reason:
                '${screenEntry.key} at ${viewport.key} '
                '(${viewport.value.width.toInt()}x${viewport.value.height.toInt()}):\n'
                '${overflows.join('\n')}',
          );
        });
      }
    });
  }

  testWidgets('Dashboard shell keeps rich visuals at the normal Windows size', (
    tester,
  ) async {
    final errors = <FlutterErrorDetails>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = errors.add;

    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    try {
      await tester.pumpWidget(_wrap(const DashboardShell()));
      await tester.pump(const Duration(milliseconds: 300));

      // The hero card's floating turtle decoration was removed by design
      // (2026-08-22 redesign pass — see docs/ARCHITECTURE.md §14); this test
      // now checks a decoration that's still there instead.
      await tester.tap(find.text('Academy').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is AmbientLottieCard &&
              widget.semanticLabel == 'Animated academy illustration',
        ),
        findsOneWidget,
      );
    } finally {
      FlutterError.onError = previousOnError;
    }

    expect(errors.map((e) => e.exception.toString()), isEmpty);
  });

  testWidgets('compact dashboard keeps the arcade and academy visuals', (
    tester,
  ) async {
    final errors = <FlutterErrorDetails>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = errors.add;

    tester.view.physicalSize = const Size(340, 480);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    try {
      await tester.pumpWidget(_wrap(const DashboardShell()));
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is AmbientLottieCard &&
              widget.semanticLabel == 'Arcade decoration',
        ),
        findsOneWidget,
      );

      // At this width the quick-action row drops each button's label (see
      // _ObjectiveIconButton's iconOnly threshold), so the tooltip is the
      // only reliable way to find the Academy button — the icon alone
      // isn't unique across the row. The row also sits below the fold at
      // this height, inside Home's SingleChildScrollView, so it must be
      // scrolled into view before tapping.
      final academyButton = find.byTooltip('Academy').last;
      await tester.ensureVisible(academyButton);
      await tester.pump();
      await tester.tap(academyButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is AmbientLottieCard &&
              widget.semanticLabel == 'Animated academy illustration',
        ),
        findsOneWidget,
      );
    } finally {
      FlutterError.onError = previousOnError;
    }

    expect(errors.map((e) => e.exception.toString()), isEmpty);
  });

  testWidgets('Finance Brawl accepts touch drag movement on phones', (
    tester,
  ) async {
    final errors = <FlutterErrorDetails>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = errors.add;

    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    try {
      await tester.pumpWidget(_wrap(const FinanceBrawlScreen()));
      await tester.pump(const Duration(milliseconds: 300));
      final gesture = await tester.startGesture(const Offset(196, 520));
      await gesture.moveBy(const Offset(72, 0));
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.byWidgetPredicate(
          (widget) => widget.runtimeType.toString() == '_TouchJoystick',
        ),
        findsOneWidget,
      );

      await gesture.up();
      await tester.pump(const Duration(milliseconds: 100));
    } finally {
      FlutterError.onError = previousOnError;
    }

    expect(errors.map((e) => e.exception.toString()), isEmpty);
  });

  group('Dashboard shell tabs', () {
    // Life/Arcade/Home/Learn/Style are PopNavBar's bottom five (Home in the
    // middle); Daily/Profile are the top strip's two icons instead — same
    // `find.text(tab).last` + tap works for either, since both render a
    // Text widget with this exact label.
    const tabs = <String>[
      'Life',
      'Learn',
      'Arcade',
      'Home',
      'Daily',
      'Style',
      'Profile',
    ];

    for (final viewport in _viewports.entries) {
      for (final tab in tabs) {
        testWidgets('$tab tab lays out on ${viewport.key}', (tester) async {
          final errors = <FlutterErrorDetails>[];
          final previousOnError = FlutterError.onError;
          FlutterError.onError = errors.add;

          tester.view.physicalSize = viewport.value;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          try {
            await tester.pumpWidget(_wrap(const DashboardShell()));
            await tester.pump(const Duration(milliseconds: 300));
            await tester.tap(find.text(tab).last);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 500));
          } finally {
            FlutterError.onError = previousOnError;
          }

          final overflows = errors
              .map((error) => error.exception.toString())
              .toList(growable: false);

          expect(
            overflows,
            isEmpty,
            reason:
                'Dashboard shell "$tab" at ${viewport.key} '
                '(${viewport.value.width.toInt()}x'
                '${viewport.value.height.toInt()}):\n'
                '${overflows.join('\n')}',
          );
        });
      }
    }
  });

  // The Market Board's tabs are a TabBarView, which builds children lazily —
  // so the sweep above only ever laid out the default "Assets" tab and
  // reported the whole screen clean. Trade / Orders / P&L / Analytics were
  // never rendered by any test. This walks each tab explicitly.
  group('Market Board tabs', () {
    const tabs = <String>['Assets', 'Trade', 'Orders', 'P&L', 'Analytics'];

    for (final viewport in _viewports.entries) {
      for (var tabIndex = 0; tabIndex < tabs.length; tabIndex++) {
        testWidgets('${tabs[tabIndex]} tab lays out on ${viewport.key}', (
          tester,
        ) async {
          final errors = <FlutterErrorDetails>[];
          final previousOnError = FlutterError.onError;
          FlutterError.onError = errors.add;

          tester.view.physicalSize = viewport.value;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          try {
            await tester.pumpWidget(_wrap(const StockMarketPage()));
            await tester.pump(const Duration(milliseconds: 300));

            if (tabIndex > 0) {
              await tester.tap(find.text(tabs[tabIndex]));
              await tester.pump();
              await tester.pump(const Duration(milliseconds: 400));
            }
          } finally {
            FlutterError.onError = previousOnError;
          }

          // Every exception, not just "overflowed by". Filtering to overflow
          // messages meant a screen could throw a null-check failure or fail
          // to lay out entirely and this sweep would still report it clean --
          // which is exactly how the Market Board's unbounded-Expanded crash
          // survived a full pass at 320px wide.
          final overflows = errors
              .map((error) => error.exception.toString())
              .toList(growable: false);

          expect(
            overflows,
            isEmpty,
            reason:
                'Market Board "${tabs[tabIndex]}" at ${viewport.key} '
                '(${viewport.value.width.toInt()}x'
                '${viewport.value.height.toInt()}):\n'
                '${overflows.join('\n')}',
          );
        });
      }
    }
  });
}
