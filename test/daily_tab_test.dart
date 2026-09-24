import 'package:budget_app/controllers_that_updates_stats/app_settings_controller.dart';
import 'package:budget_app/controllers_that_updates_stats/daily_plan_controller.dart';
import 'package:budget_app/controllers_that_updates_stats/money_habit_controller.dart';
import 'package:budget_app/controllers_that_updates_stats/user_stats_controller.dart';
import 'package:budget_app/navigation_tools_and_animation/app_tab_index.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/dashboard/daily_plan_card.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/dashboard/home_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/money_habits/money_habits_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/money_habits/today_tab.dart';
import 'package:budget_app/services_backend_and_other_services/supabase_service.dart';
import 'package:budget_app/themes_colors/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/app_fonts.dart';

/// The Daily tab, and the one thing on Home that points at it.
///
/// **What these are guarding.** Every piece below was, until this change,
/// either unreachable or wrong, and none of it was caught by the existing
/// suite because none of it was ever built:
///
///  * [DailyPlanCard] — documented as "the home screen's spine" — was
///    referenced by no file in `lib/`. A widget nothing mounts cannot fail a
///    widget test.
///  * Home's daily card pushed a second live `MoneyHabitsScreen` on top of
///    the one already alive in the tab stack.
///  * The daily-challenge call site passed a literal `isCompleted: false`,
///    so the "already cleared" branch of that card could never render.
///
/// So the tests here are mostly of the form "this is on screen at all",
/// which is unglamorous but is exactly the class of bug that was present.
void main() {
  setUpAll(loadAppFonts);

  Widget wrap(Widget child) => MultiProvider(
    providers: [
      ChangeNotifierProvider<UserStatsController>(
        create: (_) => UserStatsController(service: SupabaseService.instance),
      ),
      ChangeNotifierProvider<AppSettingsController>(
        create: (_) => AppSettingsController(),
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
    child: MaterialApp(theme: AppTheme.getLightTheme(), home: child),
  );

  Future<void> pumpAt(WidgetTester tester, Widget child, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(child));
    await tester.pump(const Duration(milliseconds: 400));
  }

  group('the streak week', () {
    // Pure, so these need no widget tree and no clock — the whole point of
    // deriving the week from the counter rather than storing it.
    DateTime day(int d) => DateTime(2026, 9, d);

    test('a three-day streak ending today lights the last three cells', () {
      final week = StreakBanner.weekFor(
        streakDays: 3,
        lastKeptDateKey: '2026-09-02',
        today: day(2),
      );

      expect(week.length, 7);
      expect(week.map((e) => e.kept).toList(), <bool>[
        false,
        false,
        false,
        false,
        true,
        true,
        true,
      ]);
      expect(week.last.day, day(2));
      expect(week.first.day, DateTime(2026, 8, 27));
    });

    test('a streak that ended yesterday leaves today dark', () {
      final week = StreakBanner.weekFor(
        streakDays: 2,
        lastKeptDateKey: '2026-09-01',
        today: day(2),
      );

      expect(week.last.kept, isFalse, reason: 'today has not been kept yet');
      expect(week[5].kept, isTrue);
      expect(week[4].kept, isTrue);
      expect(week[3].kept, isFalse);
    });

    test('a streak longer than a week fills every cell', () {
      final week = StreakBanner.weekFor(
        streakDays: 40,
        lastKeptDateKey: '2026-09-02',
        today: day(2),
      );
      expect(week.every((e) => e.kept), isTrue);
    });

    test('an old streak that was never broken forward does not leak', () {
      // Kept up to the 20th of August, nothing since. None of the last seven
      // days should light up even though the counter is non-zero.
      final week = StreakBanner.weekFor(
        streakDays: 5,
        lastKeptDateKey: '2026-08-20',
        today: day(2),
      );
      expect(week.any((e) => e.kept), isFalse);
    });

    test('a player who has never kept a day gets an empty week', () {
      final week = StreakBanner.weekFor(
        streakDays: 0,
        lastKeptDateKey: '',
        today: day(2),
      );
      expect(week.length, 7);
      expect(week.any((e) => e.kept), isFalse);
    });
  });

  group('the Daily tab', () {
    testWidgets('opens on Today, with the plan actually on it', (tester) async {
      await pumpAt(tester, const MoneyHabitsScreen(), const Size(430, 932));

      // The tab exists and is the one that opened.
      expect(find.text('Today'), findsOneWidget);
      // The plan card is mounted. This is the assertion with history: the
      // widget existed, was complete, and was in no build method anywhere.
      expect(find.byType(DailyPlanCard), findsOneWidget);
      expect(find.text("Today's Plan"), findsOneWidget);
      // And the day strip, which is what makes the streak legible.
      expect(find.byType(StreakBanner), findsOneWidget);
    });

    testWidgets('the daily challenge belongs to Today', (tester) async {
      await pumpAt(tester, const MoneyHabitsScreen(), const Size(430, 932));
      expect(
        find.descendant(
          of: find.byType(TodayTab),
          matching: find.byType(DailyChallengeCard),
        ),
        findsOneWidget,
      );
    });

    // A separate mount rather than a second pump in the test above:
    // `initialTab` is read once in `initState`, and pumping a new
    // `MoneyHabitsScreen` into the same slot *updates* the existing element
    // instead of rebuilding it, so the TabController keeps whichever tab it
    // already had. The first version of this test looked like it proved
    // something and was really still looking at Today.
    testWidgets('My Week is the habit grid and nothing else', (tester) async {
      await pumpAt(
        tester,
        const MoneyHabitsScreen(initialTab: MoneyHabitsTab.week),
        const Size(430, 932),
      );

      expect(find.text('This week'), findsOneWidget);
      expect(
        find.byType(DailyChallengeCard),
        findsNothing,
        reason:
            'the reflex minigame used to lead the habit grid, which put '
            "\"Today's Challenge\" at the top of a screen about the week",
      );
    });

    testWidgets('hosted as the tab it is titled Daily, pushed it is not', (
      tester,
    ) async {
      await pumpAt(
        tester,
        MoneyHabitsScreen(
          activeTabIndex: AppTabIndex.daily,
          onNavSelected: (_) {},
        ),
        const Size(430, 932),
      );
      // The top strip's own "Daily" pill is already highlighted, so as a tab
      // the toolbar has nothing worth repeating it for and collapses to
      // nothing — no second "Daily" stacked under the first.
      expect(find.widgetWithText(AppBar, 'Daily'), findsNothing);
      expect(find.widgetWithText(AppBar, 'Money Habits'), findsNothing);

      // Pushed as its own route there is no pill above naming it, so the
      // heading comes back.
      await pumpAt(tester, const MoneyHabitsScreen(), const Size(430, 932));
      expect(find.widgetWithText(AppBar, 'Money Habits'), findsOneWidget);
    });

    testWidgets('every inner tab index still names the tab it used to', (
      tester,
    ) async {
      // A "Today" tab was inserted at the front, so every literal index in
      // the app and its tests shifted by one. These are the names those
      // literals were standing for.
      const expected = <int, String>{
        MoneyHabitsTab.today: 'Today',
        MoneyHabitsTab.week: 'My Week',
        MoneyHabitsTab.find: 'Habits',
        MoneyHabitsTab.challenges: 'Challenges',
        MoneyHabitsTab.jar: 'My Jar',
        MoneyHabitsTab.coach: 'Coach',
      };
      expect(expected.length, MoneyHabitsTab.count);

      await pumpAt(tester, const MoneyHabitsScreen(), const Size(430, 932));

      // Read off the rendered strip rather than casting `TabBar.tabs`. The
      // tabs are a small widget of their own now — an icon beside a word in
      // a pill — so `as Tab` no longer holds, and what this test is actually
      // about is the label a player reads.
      final bar = find.byType(TabBar);
      for (final entry in expected.entries) {
        expect(
          find.descendant(of: bar, matching: find.text(entry.value)),
          findsOneWidget,
          reason: 'tab ${entry.key} is not labelled "${entry.value}"',
        );
      }
    });
  });

  group('Home points at the Daily tab', () {
    testWidgets('the Today card switches tab rather than pushing a screen', (
      tester,
    ) async {
      final selected = <int>[];
      await pumpAt(
        tester,
        HomeScreen(onNavSelected: selected.add),
        const Size(430, 932),
      );

      await tester.tap(find.text('Today'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(selected, <int>[AppTabIndex.daily]);
      expect(
        find.byType(MoneyHabitsScreen),
        findsNothing,
        reason:
            'this used to push a second live copy of the screen that is '
            'already alive in the IndexedStack at AppTabIndex.daily',
      );
    });

    testWidgets('Home shows the next quest, not the whole plan', (
      tester,
    ) async {
      await pumpAt(
        tester,
        HomeScreen(onNavSelected: (_) {}),
        const Size(430, 932),
      );

      // The plan lives on the Daily tab. Home repeating it would make Home a
      // second copy of that screen.
      expect(find.byType(DailyPlanCard), findsNothing);
      expect(find.text('Today'), findsOneWidget);
    });
  });
}
