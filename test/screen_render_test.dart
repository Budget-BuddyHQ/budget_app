import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:budget_app/controllers_that_updates_stats/app_settings_controller.dart';
import 'package:budget_app/controllers_that_updates_stats/daily_plan_controller.dart';
import 'package:budget_app/controllers_that_updates_stats/life_sim_controller.dart';
import 'package:budget_app/controllers_that_updates_stats/money_habit_controller.dart';
import 'package:budget_app/controllers_that_updates_stats/user_stats_controller.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/academy/lesson_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/core_bottom_pages/minigames_page.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/customize_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/dashboard/home_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/minigames_pages/coin_cascade_page.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/minigames_pages/life_sim_page.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/money_habits/money_habits_screen.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/finance_concepts.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/lesson.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/money_analyzer.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/lesson_data.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_ending.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_sim_models.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/progression_service.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/town_spot_models.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/academy/lesson_detail_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/academy/practice_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/onboarding/welcome_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/adventure/town_interior_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/core_bottom_pages/main_game_page.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/dashboard/leaderboard_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/minigames_pages/finance_brawl_game.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/minigames_pages/life_epilogue_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/minigames_pages/past_lives_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/profile/profile_screen.dart';
import 'package:budget_app/services_backend_and_other_services/market_data_service.dart';
import 'package:budget_app/services_backend_and_other_services/supabase_service.dart';
import 'package:budget_app/themes_colors/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/app_fonts.dart';

/// Renders every main screen to a PNG so the layout can be *looked at*.
///
/// **Why this is a test rather than a script.** Everything needed to paint a
/// screen — the providers, a mid-life save, the real typefaces — already
/// exists in the test harness, and nothing outside it can drive a Flutter
/// widget tree to a frame. So this borrows the harness and writes the frame
/// out instead of asserting about it.
///
/// **What it is not.** It asserts nothing and cannot fail on a visual
/// regression; there are no golden files to diff. `contrast_audit_test`,
/// `text_fit_test` and `responsive_layout_test` are the ones that hold the
/// line. This exists for the class of problem those cannot describe — copy
/// that truncates into nonsense, a brand-new player greeted by a frowning
/// jar labelled "Slipping", two cards whose spacing disagrees. Every one of
/// those was found by opening these files and looking.
///
/// Output goes to `build/screens/`, which is gitignored. Run:
///
///     flutter test test/screen_render_test.dart
///
/// Two caveats when reading the results. Material icons and emoji render as
/// empty boxes — those fonts are not in the test bundle — and `MoneyGlyphs`
/// renders blank, because it draws from a bitmap sheet that the test asset
/// loader does not decode. All three are fine in the running app.
const outDir = 'build/screens';

void main() {
  setUpAll(() async {
    await loadAppFonts();
    Directory(outDir).createSync(recursive: true);
  });

  Widget wrap(Widget child) => MultiProvider(
    providers: [
      ChangeNotifierProvider<UserStatsController>(
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
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getLightTheme(),
      home: child,
    ),
  );

  LifeSimController midLife() {
    final life = LifeSimController(random: Random(24), initialAge: 0);
    while (life.age < 34 && !life.finished) {
      if (life.currentEvent != null) life.chooseOption(0);
      life.ageUp();
    }
    return life;
  }

  final shotKey = GlobalKey();
  // Matches the window the bottom-bar bug was reported from.
  const shotSize = Size(892, 744);

  final screens = <String, Widget Function()>{
    'home': () => const HomeScreen(),
    'life': () => LifeSimPage(debugInitialLife: midLife()),
    'arcade': () => const MinigamesPage(),
    'cascade': () => const CoinCascadePage(),
    'academy': () => const LessonScreen(),
    'habits_week': () => const MoneyHabitsScreen(),
    'habits_jar': () => const MoneyHabitsScreen(initialTab: 3),
    // A player a fortnight in with a real, mixed history: turning up, but
    // pinning far more than they keep and saving almost nothing by it.
    'habits_coach': () => const MoneyHabitsScreen(
      initialTab: 4,
      debugSnapshot: MoneySnapshot(
        loggedDaysLast14: 9,
        daysSinceLastLog: 1,
        longestStreak: 5,
        pinnedHabits: 7,
        habitsLoggedLast14: 2,
        moneySaved: 3,
        choicesKept: 46,
        jarXp: 120,
        lessonsCompleted: 14,
        lessonsAvailable: 63,
        conceptAccuracy: {
          FinanceConcept.needsVsWants: 0.88,
          FinanceConcept.budgetRule: 0.72,
          FinanceConcept.interestCost: 0.31,
        },
        pastLifeNetWorths: [1200, 1500, 1100],
        townSpotsVisited: 2,
        townSpotsAvailable: 12,
        challengesStarted: 4,
        challengesFinished: 1,
      ),
    ),
    'customize': () => const CustomizeScreen(),
    'profile': () => const ProfileScreen(),
    'life_hub': () => const MainGamePage(),
    'practice': () => PracticeScreen(unit: lessonUnits.first),
    'welcome': () => const WelcomeScreen(),
    // Sign-in is absent for the same reason as the Market Board: it mounts a
    // webview and there is no `WebViewPlatform` in a unit test.
    'past_lives': () => const PastLivesScreen(),
    'leaderboard': () => const LeaderboardScreen(),
    'brawl': () => const FinanceBrawlScreen(),
    // The Market Board is deliberately absent: it reaches for a platform
    // channel on mount and throws MissingPluginException in this harness.
    // `responsive_layout_test` covers it properly, with seeded quotes.
    'store': () => TownInteriorScreen(
      spot: kTownSpots.firstWhere((s) => s.kind == TownSpotKind.store),
    ),
    'lesson': () {
      final unit = lessonUnits.first;
      return LessonDetailScreen(
        lesson: unit.lessons.firstWhere(
          (lesson) => lesson.type == LessonNodeType.lesson,
        ),
        unit: unit,
        progressionService: ProgressionService(),
      );
    },
    'quiz': () {
      final unit = lessonUnits.first;
      return LessonDetailScreen(
        lesson: unit.lessons.firstWhere(
          (lesson) => lesson.type == LessonNodeType.quiz,
        ),
        unit: unit,
        progressionService: ProgressionService(),
      );
    },
    'epilogue': () => const LifeEpilogueScreen(
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
        relationships: ['Jordan', 'Priya', 'Marcus', 'Grandma Lucille'],
        goldReward: 512,
        archetype: LifeEndingArchetype.legacyBuilder,
      ),
    ),
  };

  for (final entry in screens.entries) {
    testWidgets('shoot ${entry.key}', (tester) async {
      tester.view.physicalSize = shotSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        RepaintBoundary(key: shotKey, child: wrap(entry.value())),
      );
      await tester.pump(const Duration(milliseconds: 600));

      await tester.runAsync(() async {
        final layer =
            shotKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await layer.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File(
          '$outDir/${entry.key}.png',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    });
  }
}
