import 'package:budget_app/controllers_that_updates_stats/app_settings_controller.dart';
import 'package:budget_app/controllers_that_updates_stats/daily_plan_controller.dart';
import 'package:budget_app/controllers_that_updates_stats/money_habit_controller.dart';
import 'package:budget_app/controllers_that_updates_stats/user_stats_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/finance_concepts.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/money_analyzer.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/money_habits/money_habits_screen.dart';
import 'package:budget_app/services_backend_and_other_services/supabase_service.dart';
import 'package:budget_app/themes_colors/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'support/app_fonts.dart';

/// The budget and habit analyzer.
///
/// These are the rules, not the screen. The interesting cases are all players
/// with an odd history — somebody with a hundred ticks and no money, somebody
/// who pins six habits a week and logs none — and a UI test never reaches any
/// of them, because getting a widget into that state means playing the app
/// for a fortnight first.
void main() {
  /// A plausible mid-way player, for tests that only want to vary one thing.
  MoneySnapshot steady({
    int loggedDaysLast14 = 11,
    int daysSinceLastLog = 0,
    int longestStreak = 9,
    int pinnedHabits = 3,
    int habitsLoggedLast14 = 3,
    double moneySaved = 64,
    double choicesKept = 40,
    int lessonsCompleted = 20,
    int lessonsAvailable = 63,
    Map<FinanceConcept, double> conceptAccuracy = const {
      FinanceConcept.needsVsWants: 0.9,
      FinanceConcept.budgetRule: 0.8,
      FinanceConcept.emergencyFund: 0.75,
      FinanceConcept.compoundGrowth: 0.7,
    },
    List<int> pastLifeNetWorths = const <int>[41000, 22000],
    int townSpotsVisited = 8,
    int townSpotsAvailable = 12,
    int challengesStarted = 3,
    int challengesFinished = 3,
  }) => MoneySnapshot(
    loggedDaysLast14: loggedDaysLast14,
    daysSinceLastLog: daysSinceLastLog,
    longestStreak: longestStreak,
    pinnedHabits: pinnedHabits,
    habitsLoggedLast14: habitsLoggedLast14,
    moneySaved: moneySaved,
    choicesKept: choicesKept,
    lessonsCompleted: lessonsCompleted,
    lessonsAvailable: lessonsAvailable,
    conceptAccuracy: conceptAccuracy,
    pastLifeNetWorths: pastLifeNetWorths,
    townSpotsVisited: townSpotsVisited,
    townSpotsAvailable: townSpotsAvailable,
    challengesStarted: challengesStarted,
    challengesFinished: challengesFinished,
  );

  Set<String> idsOf(MoneyReport report) =>
      report.findings.map((f) => f.id).toSet();

  group('it says nothing it cannot back up', () {
    test('a brand-new player gets one line, not five faults', () {
      // Every rule below would fire at once for somebody three minutes in.
      // All of them would be true and none of them would be useful.
      final report = analyzeMoney(const MoneySnapshot());
      expect(report.isNewcomer, isTrue);
      expect(report.findings, hasLength(1));
      expect(report.findings.single.id, 'start_here');
      expect(report.scores, isEmpty);
    });

    test('every finding carries evidence and one action', () {
      // A finding without a number out of their own data is a slogan, and a
      // finding without an action hands the hard part back.
      for (final snap in <MoneySnapshot>[
        steady(),
        steady(daysSinceLastLog: 40, loggedDaysLast14: 0),
        steady(pinnedHabits: 7, habitsLoggedLast14: 1),
        steady(moneySaved: 0, choicesKept: 60),
        steady(conceptAccuracy: {FinanceConcept.creditScore: 0.2}),
      ]) {
        for (final finding in analyzeMoney(snap).findings) {
          expect(finding.evidence, isNotEmpty, reason: finding.id);
          expect(finding.action, isNotEmpty, reason: finding.id);
          expect(
            finding.evidence.contains(RegExp(r'\d')),
            isTrue,
            reason: '${finding.id} cites no number from their data',
          );
        }
      }
    });

    test('finding ids are unique within a report', () {
      final report = analyzeMoney(steady(pinnedHabits: 7, habitsLoggedLast14: 1));
      final ids = report.findings.map((f) => f.id).toList();
      expect(ids.toSet().length, ids.length);
    });
  });

  group('showing up', () {
    test('a long gap is a fix, not a nudge', () {
      final report = analyzeMoney(
        steady(daysSinceLastLog: 21, loggedDaysLast14: 0),
      );
      final lapsed = report.findings.firstWhere((f) => f.id == 'lapsed');
      expect(lapsed.kind, MoneyFindingKind.fix);
      expect(lapsed.evidence, contains('3 weeks'));
    });

    test('never having logged is not the same as a long gap', () {
      // 999 is the store's "never" sentinel. Reporting it as "last logged 999
      // days ago" is how it used to reach players, and it is nonsense.
      final report = analyzeMoney(
        steady(daysSinceLastLog: MoneySnapshot.neverLogged, loggedDaysLast14: 0),
      );
      for (final finding in report.findings) {
        expect(finding.evidence, isNot(contains('999')));
      }
    });

    test('turning up regularly is called out as a strength', () {
      final report = analyzeMoney(steady(loggedDaysLast14: 13));
      expect(idsOf(report), contains('steady'));
    });
  });

  group('finishing', () {
    test('pinning far more than you log is the headline fault', () {
      // The most common shape of failure in any habit app: pinning is free
      // and feels like progress, logging is neither.
      final report = analyzeMoney(steady(pinnedHabits: 6, habitsLoggedLast14: 1));
      expect(idsOf(report), contains('too_many_habits'));
      final finding =
          report.findings.firstWhere((f) => f.id == 'too_many_habits');
      expect(finding.evidence, contains('6'));
      expect(finding.evidence, contains('1'));
    });

    test('two pinned and one logged is not a fault', () {
      // The rule needs three to fire. With two habits, "you logged one of
      // them" is a normal week, and nagging about it is how an analyzer
      // teaches people to ignore it.
      final report = analyzeMoney(steady(pinnedHabits: 2, habitsLoggedLast14: 1));
      expect(idsOf(report), isNot(contains('too_many_habits')));
    });

    test('abandoned challenges are watched, not scolded', () {
      final report =
          analyzeMoney(steady(challengesStarted: 5, challengesFinished: 1));
      final finding =
          report.findings.firstWhere((f) => f.id == 'challenges_abandoned');
      expect(finding.kind, MoneyFindingKind.watch);
      expect(finding.concept, FinanceConcept.sunkCost);
    });
  });

  group('money moving', () {
    test('lots of ticks and no money is caught', () {
      // The failure this app is most at risk of. Habit points, jar fill and
      // streaks are all satisfying and none of them is money — somebody can
      // be a model user and no better off, and the analyzer has to be the
      // thing that says so.
      final report = analyzeMoney(steady(choicesKept: 80, moneySaved: 0));
      final finding =
          report.findings.firstWhere((f) => f.id == 'motion_not_money');
      expect(finding.kind, MoneyFindingKind.fix);
      expect(finding.dimension, MoneyDimension.saving);
      expect(finding.evidence, contains('80'));
    });

    test('real savings are named and given a job', () {
      final report = analyzeMoney(steady(moneySaved: 240));
      final finding = report.findings.firstWhere((f) => f.id == 'real_money');
      expect(finding.kind, MoneyFindingKind.strength);
      expect(finding.concept, FinanceConcept.emergencyFund);
    });

    test('a few ticks and no money yet is neither', () {
      // Below the threshold there is nothing to conclude — three kept choices
      // saving nothing is a Tuesday, not a pattern.
      final report = analyzeMoney(steady(choicesKept: 4, moneySaved: 0));
      expect(idsOf(report), isNot(contains('motion_not_money')));
      expect(idsOf(report), isNot(contains('real_money')));
    });
  });

  group('understanding', () {
    test('the weakest concept is the one surfaced', () {
      final report = analyzeMoney(
        steady(
          conceptAccuracy: const {
            FinanceConcept.needsVsWants: 0.9,
            FinanceConcept.interestCost: 0.25,
            FinanceConcept.creditScore: 0.45,
          },
        ),
      );
      final finding = report.findings.firstWhere(
        (f) => f.id.startsWith('weak_concept_'),
      );
      expect(finding.concept, FinanceConcept.interestCost);
      expect(finding.evidence, contains('25%'));
    });

    test('a concept never assessed is not treated as a zero', () {
      // Absent and wrong are different, and conflating them would tell
      // somebody they are bad at a lesson they have never opened.
      final report = analyzeMoney(
        steady(conceptAccuracy: const {FinanceConcept.needsVsWants: 0.95}),
      );
      expect(
        report.findings.where((f) => f.id.startsWith('weak_concept_')),
        isEmpty,
      );
    });

    test('every weak-concept finding links to the concept', () {
      // The hook into the Academy, and through it to the lesson's source.
      // The curriculum refuses to ship an uncited fact; advice should not get
      // a free pass either.
      for (final concept in FinanceConcept.values) {
        final report = analyzeMoney(steady(conceptAccuracy: {concept: 0.1}));
        final finding = report.findings.firstWhere(
          (f) => f.id.startsWith('weak_concept_'),
        );
        expect(finding.concept, concept);
        expect(finding.action, contains(concept.label));
      }
    });
  });

  group('trying things', () {
    test('an unopened town is worth mentioning', () {
      final report =
          analyzeMoney(steady(townSpotsVisited: 2, townSpotsAvailable: 12));
      expect(idsOf(report), contains('town_unexplored'));
    });

    test('improving lives are credited', () {
      final report = analyzeMoney(steady(pastLifeNetWorths: const [50000, 10000]));
      expect(idsOf(report), contains('lives_improving'));
    });

    test('flat lives point at the early years', () {
      final report =
          analyzeMoney(steady(pastLifeNetWorths: const [900, 1200, 1100]));
      final finding = report.findings.firstWhere((f) => f.id == 'lives_flat');
      expect(finding.concept, FinanceConcept.compoundGrowth);
    });

    test('one life is not a trend', () {
      final report = analyzeMoney(steady(pastLifeNetWorths: const [4000]));
      expect(idsOf(report), isNot(contains('lives_improving')));
      expect(idsOf(report), isNot(contains('lives_flat')));
    });
  });

  group('the read-out', () {
    test('faults come before things that are going well', () {
      // Somebody who reads one line should read the useful one.
      final report = analyzeMoney(
        steady(
          loggedDaysLast14: 13,
          moneySaved: 300,
          pinnedHabits: 8,
          habitsLoggedLast14: 1,
        ),
      );
      final kinds = report.findings.map((f) => f.kind).toList();
      expect(kinds.first, MoneyFindingKind.fix);
      expect(
        kinds.indexOf(MoneyFindingKind.fix),
        lessThan(kinds.lastIndexOf(MoneyFindingKind.strength)),
      );
      expect(report.headline!.kind, MoneyFindingKind.fix);
    });

    test('scores stay inside 0..100', () {
      for (final snap in <MoneySnapshot>[
        steady(),
        steady(loggedDaysLast14: 14, moneySaved: 99999, lessonsCompleted: 999),
        steady(loggedDaysLast14: 0, moneySaved: 0, lessonsCompleted: 0),
      ]) {
        for (final entry in analyzeMoney(snap).scores.entries) {
          expect(entry.value, inInclusiveRange(0, 100), reason: '${entry.key}');
        }
      }
    });

    test('the weakest area is the one with the lowest score', () {
      final report = analyzeMoney(
        steady(loggedDaysLast14: 12, moneySaved: 0, choicesKept: 2),
      );
      expect(report.weakest, MoneyDimension.saving);
    });

    test('a zero-length curriculum does not divide by zero', () {
      final report = analyzeMoney(steady(lessonsAvailable: 0));
      expect(report.scores[MoneyDimension.learning], 0);
    });

    test('every dimension has a label and a plain-English weakness', () {
      for (final dimension in MoneyDimension.values) {
        expect(dimension.label, isNotEmpty);
        expect(dimension.weakness.length, greaterThan(20));
      }
    });
  });

  group('the Coach tab shows what the rules found', () {
    // Thin on purpose. The rules are covered above without a widget tree;
    // what a widget test adds is that the screen actually renders a finding
    // rather than swallowing it, which is the only part the pure tests
    // cannot see.
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
          update: (_, stats, previous) =>
              previous ?? MoneyHabitController(stats),
        ),
      ],
      child: MaterialApp(theme: AppTheme.getLightTheme(), home: child),
    );

    testWidgets('a fault reaches the screen with its evidence', (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        wrap(
          const MoneyHabitsScreen(
            initialTab: MoneyHabitsTab.coach,
            debugSnapshot: MoneySnapshot(
              loggedDaysLast14: 9,
              daysSinceLastLog: 1,
              pinnedHabits: 7,
              habitsLoggedLast14: 2,
              moneySaved: 3,
              choicesKept: 46,
              lessonsCompleted: 14,
              lessonsAvailable: 63,
              townSpotsVisited: 2,
              townSpotsAvailable: 12,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('More habits pinned than kept'), findsOneWidget);
      expect(
        find.textContaining('7 habits saved', findRichText: true),
        findsOneWidget,
        reason: 'the finding rendered without the number behind it',
      );
      expect(find.text('Lots of ticks, almost no money'), findsOneWidget);
    });

    testWidgets('a brand-new player is told so, not scored', (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        wrap(
          const MoneyHabitsScreen(
            initialTab: MoneyHabitsTab.coach,
            debugSnapshot: MoneySnapshot(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Nothing to analyze yet'), findsOneWidget);
      // No score bars: five red zeroes is a true and thoroughly discouraging
      // way to open an app somebody installed ten minutes ago.
      expect(find.text('Showing up'), findsNothing);
    });
  });
}
