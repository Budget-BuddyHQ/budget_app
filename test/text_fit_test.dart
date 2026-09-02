import 'dart:math';

import 'package:budget_app/controllers_that_updates_stats/app_settings_controller.dart';
import 'package:budget_app/controllers_that_updates_stats/daily_plan_controller.dart';
import 'package:budget_app/controllers_that_updates_stats/life_sim_controller.dart';
import 'package:budget_app/controllers_that_updates_stats/money_habit_controller.dart';
import 'package:budget_app/controllers_that_updates_stats/user_stats_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/lesson.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/progression_service.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/lesson_data.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_ending.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_sim_models.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/town_spot_models.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/academy/lesson_detail_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/academy/practice_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/minigames_pages/finance_brawl_game.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/minigames_pages/life_epilogue_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/profile/feedback_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/academy/lesson_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/adventure/town_interior_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/core_bottom_pages/main_game_page.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/core_bottom_pages/minigames_page.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/customize_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/dashboard/home_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/dashboard/leaderboard_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/minigames_pages/coin_cascade_page.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/minigames_pages/life_sim_page.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/minigames_pages/past_lives_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/minigames_pages/stock_market_page.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/money_habits/money_habits_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/profile/profile_screen.dart';
import 'package:budget_app/services_backend_and_other_services/market_data_service.dart';
import 'package:budget_app/services_backend_and_other_services/supabase_service.dart';
import 'package:budget_app/themes_colors/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/app_fonts.dart';

/// Finds text the app is cutting off.
///
/// **Why this exists.** "fix the words clipping into that one" was reported
/// against a chip in the Academy, and chasing it by reading source found two
/// separate causes and missed a third — the one that only shows up once
/// `FittedLabel` has scaled a title to its 62% floor and *still* has to
/// ellipsise. None of those are visible in a `Text(...)` call site. They are
/// only visible after layout.
///
/// So this asks the renderer. Every laid-out paragraph in the tree knows
/// whether it ran out of room: `didExceedMaxLines` is true exactly when the
/// text was ellipsised, faded or clipped. Walking for that turns "does any
/// label get cut off anywhere" from a thing you notice in a screenshot into a
/// thing the build knows.
///
/// **What is deliberately allowed.** Body copy in a card is *supposed* to
/// truncate — a lesson blurb capped at two lines with an ellipsis is a design,
/// not a bug. The rule that separates the two is line count: a paragraph
/// limited to one line has been given a slot it must fit, so overflowing it
/// means the slot is wrong. Multi-line text that runs long is prose being
/// clamped on purpose.
///
/// **This measures the real typeface, and it did not always.** The first
/// version of this audit reported a dozen clipped labels that are perfectly
/// legible in the running app. `flutter_test` substitutes a fallback for
/// anything `google_fonts` would fetch over the network, and that fallback is
/// Ahem — every glyph, from `i` to `M`, exactly one em wide. "Retirement and
/// the 401(k)" measured 350px at 14px: 14.0px a character with no variation
/// at all, against 10.7 for an `M` and 3.1 for an `i` in real Pixelify Sans.
/// Every width the environment reported was about 1.7x the truth.
///
/// Bundling the two faces (see `tool/fetch_fonts.py`) fixed that at the
/// source rather than by calibrating around it: `AssetManifest` resolves
/// inside `flutter test`, so the package loads the same files the app ships
/// and every suite in this repo now lays out in the face a player sees.
/// `didExceedMaxLines` can therefore be taken at face value, and
/// [FittedLabel] is measured like anything else — if it had to truncate below
/// its 62% floor, that is a real finding rather than an artefact.
///
/// The narrowest supported viewport is the one that matters. Anything that
/// fits at 320px fits everywhere.

/// The first lesson of a given type anywhere in the curriculum.
///
/// Picked by type rather than by index because the unit layout changes with
/// every content pass, and a hardcoded `lessons[2]` silently starts testing
/// a different screen the moment a lesson is inserted above it.
({Lesson lesson, LessonUnit unit}) _firstOfType(LessonNodeType type) {
  for (final unit in lessonUnits) {
    for (final lesson in unit.lessons) {
      if (lesson.type == type) return (lesson: lesson, unit: unit);
    }
  }
  throw StateError('no lesson of type $type in the curriculum');
}

LessonDetailScreen _detail(LessonNodeType type) {
  final found = _firstOfType(type);
  return LessonDetailScreen(
    lesson: found.lesson,
    unit: found.unit,
    progressionService: ProgressionService(),
  );
}

void main() {
  // Registers the real typefaces up front. `google_fonts` resolves a
  // bundled face asynchronously on first use, so without this only the
  // faces touched by the first build are loaded when anything is
  // measured — see test/support/app_fonts.dart.
  setUpAll(loadAppFonts);

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
    child: MaterialApp(theme: AppTheme.getLightTheme(), home: child),
  );

  LifeSimController midLife() {
    final life = LifeSimController(random: Random(24), initialAge: 0);
    while (life.age < 34 && !life.finished) {
      if (life.currentEvent != null) life.chooseOption(0);
      life.ageUp();
    }
    return life;
  }

  /// Every single-line paragraph that did not fit its slot.
  ///
  /// `maxLines == 1` is the filter, for the reason in the class doc: a
  /// one-line cap is a promise that the text fits, and the renderer telling
  /// us it did not is that promise being broken.
  List<String> clipped(WidgetTester tester) {
    final found = <String>[];
    for (final element in find.byType(RichText).evaluate()) {
      final node = element.renderObject;
      if (node is! RenderParagraph) continue;
      if (node.maxLines != 1 || !node.didExceedMaxLines) continue;

      final text = node.text.toPlainText().replaceAll('\n', ' ');
      // Emoji still fall back to a glyph this environment does not have, and
      // a missing glyph measures as a full em. That is a property of the
      // environment rather than of the layout.
      if (text.trim().length <= 2) continue;

      final available = node.constraints.maxWidth;
      // Unbounded is not a finding -- nothing is constraining the text, so
      // it cannot have been cut off.
      if (!available.isFinite) continue;

      // Zero *is* a finding, and this used to `continue` past it. That skip
      // is what let the Life sim's bottom bar ship with `horizontal: 192`
      // padding inside an `Expanded`: the four menu slots were handed zero
      // width, every label scaled to nothing and disappeared, and the audit
      // waved it through as uninteresting. A label with no room at all is
      // the worst case, not the boring one.
      if (available <= 0) {
        found.add('"$text" was given no width at all');
        continue;
      }

      final painter = TextPainter(
        text: node.text,
        maxLines: 1,
        textDirection: node.textDirection,
        textScaler: node.textScaler,
      )..layout();
      found.add(
        '"$text" needs ${painter.width.round()}px of ${available.round()}px',
      );
    }
    return found;
  }

  final screens = <String, Widget Function()>{
    'Home': () => const HomeScreen(),
    'Life hub': () => const MainGamePage(),
    'Life sim': () => LifeSimPage(debugInitialLife: midLife()),
    'Past lives': () => const PastLivesScreen(),
    'Arcade': () => const MinigamesPage(),
    'Coin Cascade': () => const CoinCascadePage(),
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
    'Corner Store': () => TownInteriorScreen(
      spot: kTownSpots.firstWhere((s) => s.kind == TownSpotKind.store),
    ),
    'Bank': () => TownInteriorScreen(
      spot: kTownSpots.firstWhere((s) => s.kind == TownSpotKind.bank),
    ),
    'Finance Brawl': () => const FinanceBrawlScreen(),
    'Feedback': () => const FeedbackScreen(),
    // The reading screens. These carry the longest strings in the app —
    // lesson titles, question stems, option labels — so they are where a
    // one-line slot is most likely to be the wrong shape.
    'Lesson reading': () => _detail(LessonNodeType.lesson),
    'Lesson quiz': () => _detail(LessonNodeType.quiz),
    'Unit test': () => _detail(LessonNodeType.unitTest),
    'Practice': () => PracticeScreen(unit: lessonUnits.first),
    // Deliberately built from the longest plausible values: a hyphenated
    // double-barrelled name and a four-word job title. A run's summary is
    // the one screen whose content is supplied by the player.
    'Life epilogue': () => LifeEpilogueScreen(
      summary: const LifeSummary(
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

  // 320x568 is the narrowest phone the app supports and 812x375 is landscape,
  // where the vertical budget collapses and single-line slots get squeezed
  // from the other direction.
  const viewports = <String, Size>{
    'small phone portrait': Size(320, 568),
    'phone landscape': Size(812, 375),
  };

  for (final screen in screens.entries) {
    for (final viewport in viewports.entries) {
      testWidgets('${screen.key} fits its text on ${viewport.key}', (
        tester,
      ) async {
        tester.view.physicalSize = viewport.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(wrap(screen.value()));
        await tester.pump(const Duration(milliseconds: 400));

        final cut = clipped(tester);
        expect(
          cut,
          isEmpty,
          reason:
              '${screen.key} at ${viewport.key} cuts off single-line text:\n'
              '  ${cut.map((t) => '"$t"').join('\n  ')}',
        );
      });
    }
  }
}
