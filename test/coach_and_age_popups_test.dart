import 'package:budget_app/controllers_that_updates_stats/user_stats_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/age_fit_check.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/coach_nudge.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/money_analyzer.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/player_profile.dart';
import 'package:budget_app/screens_minigames_admin_etc/profile/personal_details_sheet.dart';
import 'package:budget_app/services_backend_and_other_services/supabase_service.dart';
import 'package:budget_app/widgets_custom_lotties/coach_and_age_popups.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pop-ups that send players to their Coach, and that tell them how to change
/// their age when the questions are too easy.
///
/// **Asked for as:** *"make pop ups for the user to check their coach and
/// guide them how they can check, and then change their age if the questions
/// are too easy, and tell them they might be on the wrong age group, and then
/// tell them how to change it."*
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  MoneyFinding finding(String id, {MoneyFindingKind? kind}) => MoneyFinding(
    id: id,
    kind: kind ?? MoneyFindingKind.watch,
    dimension: MoneyDimension.saving,
    title: 'Title of $id',
    evidence: '',
    action: '',
  );

  MoneyReport report(List<MoneyFinding> f) =>
      MoneyReport(scores: const {}, findings: f, isNewcomer: false);

  final now = DateTime(2026, 10, 17, 12);

  group('when the Coach pop-up shows', () {
    CoachNudge? next({
      List<MoneyFinding> findings = const [],
      Map<String, String> lastOpen = const {},
      Map<String, String> fixed = const {},
      Map<String, DateTime> nudged = const {},
      DateTime? lastShown,
    }) => nextCoachNudge(
      report: report(findings),
      weakSkills: const [],
      lastOpen: lastOpen,
      unclaimedFixed: fixed,
      nudged: nudged,
      now: now,
      lastShown: lastShown,
    );

    test('something new the Coach has not shown yet', () {
      final n = next(findings: [finding('lives_flat')]);
      expect(n?.kind, CoachNudgeKind.found);
      expect(n?.title, 'Title of lives_flat');
    });

    test('something fixed since last time comes first', () {
      final n = next(
        findings: [finding('lives_flat')],
        lastOpen: {'never_owned_a_home': 'None of these lives owned a home'},
      );
      expect(n?.kind, CoachNudgeKind.fixed);
      expect(n?.title, 'None of these lives owned a home');
    });

    test('nothing already seen in the Coach, and no good news', () {
      expect(
        next(findings: [finding('lives_flat')], lastOpen: {'lives_flat': 'x'}),
        isNull,
      );
      expect(
        next(findings: [finding('ok', kind: MoneyFindingKind.strength)]),
        isNull,
      );
    });

    test('once a day at most, and not the same thing again for a month', () {
      expect(next(findings: [finding('a')], lastShown: now), isNull);
      expect(
        next(
          findings: [finding('a')],
          nudged: {'a': now.subtract(const Duration(days: 3))},
        ),
        isNull,
      );
      expect(
        next(
          findings: [finding('a')],
          nudged: {'a': now.subtract(const Duration(days: 31))},
        ),
        isNotNull,
      );
    });
  });

  group('when "too easy?" asks', () {
    ({AgeFitState state, bool ask}) quiz(
      AgeFitState s,
      int correct, {
      AgeBand band = AgeBand.age9to12,
      int total = 5,
      DateTime? at,
    }) => recordQuizForAgeFit(
      s,
      correct: correct,
      total: total,
      band: band,
      now: at ?? now,
    );

    test('after three near-perfect quizzes in a row', () {
      var s = const AgeFitState();
      for (var i = 0; i < kAgeFitStreak - 1; i++) {
        final r = quiz(s, 5);
        expect(r.ask, isFalse);
        s = r.state;
      }
      expect(quiz(s, 5).ask, isTrue);
    });

    test('a miss resets the run', () {
      var s = quiz(quiz(const AgeFitState(), 5).state, 5).state;
      s = quiz(s, 2).state;
      expect(s.streak, 0);
      expect(quiz(s, 5).ask, isFalse);
    });

    test('never for adults, short quizzes, or a confirmed age', () {
      const streak = AgeFitState(streak: 5);
      expect(quiz(streak, 5, band: AgeBand.adult18plus).ask, isFalse);
      expect(quiz(streak, 2, total: 2).ask, isFalse);
      expect(
        quiz(AgeFitState(streak: 5, confirmedBand: AgeBand.age9to12.id), 5).ask,
        isFalse,
      );
    });

    test('waits two weeks before asking again', () {
      final asked = quiz(const AgeFitState(streak: 5), 5);
      expect(asked.ask, isTrue);
      final soon = AgeFitState(streak: 5, lastAsked: asked.state.lastAsked);
      expect(quiz(soon, 5).ask, isFalse);
      expect(quiz(soon, 5, at: now.add(const Duration(days: 15))).ask, isTrue);
    });
  });

  group('the pop-ups', () {
    Future<void> host(
      WidgetTester tester,
      Future<void> Function(BuildContext) open, {
      AgeBand band = AgeBand.age9to12,
    }) async {
      final base = UserStats.defaults('test_user');
      final stats = base.copyWith(
        spendingHabits: {...base.spendingHabits, 'age_band': band.id},
      );
      await tester.pumpWidget(
        ChangeNotifierProvider<UserStatsController>(
          create: (_) =>
              UserStatsController(service: SupabaseService.instance)
                ..seedStatsForTest(stats),
          child: MaterialApp(
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () => open(context),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
    }

    testWidgets('"too easy?" says why and how to change it', (tester) async {
      await host(tester, (c) => showAgeHelp(c, tooEasy: true));
      expect(find.text('Are these too easy?'), findsOneWidget);
      expect(find.textContaining('wrong age group'), findsOneWidget);
      expect(find.textContaining('"9 to 12"'), findsOneWidget);
      expect(find.text('Tap Profile at the top right.'), findsOneWidget);
      expect(find.text('Tap About You.'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('popup-primary')));
      await tester.pumpAndSettle();
      expect(find.byType(PersonalDetailsSheet), findsOneWidget);
    });

    testWidgets('"my age is right" stops it asking for that age', (
      tester,
    ) async {
      await host(tester, (c) => showAgeHelp(c, tooEasy: true));
      await tester.tap(find.byKey(const ValueKey('popup-secondary')));
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('age_fit_confirmed_band_v1'), AgeBand.age9to12.id);
    });

    testWidgets('the Coach pop-up says how to check, and opens it', (
      tester,
    ) async {
      var opened = false;
      SharedPreferences.setMockInitialValues(<String, Object>{
        'coach_open_findings_v1':
            '{"lives_flat":"Your lives are not getting richer"}',
      });
      await host(
        tester,
        (c) => maybeShowCoachNudge(c, onOpenCoach: () => opened = true),
      );
      // A fresh account no longer has that finding, so it reads as fixed.
      expect(find.text('You fixed something!'), findsOneWidget);
      expect(find.textContaining('yellow Coach button'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('popup-primary')));
      await tester.pumpAndSettle();
      expect(opened, isTrue);

      // And not again today.
      opened = false;
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      expect(find.text('You fixed something!'), findsNothing);
    });
  });
}
