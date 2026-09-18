import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:budget_app/controllers_that_updates_stats/user_stats_controller.dart';
import 'package:budget_app/services_backend_and_other_services/supabase_service.dart';

import 'package:budget_app/models_Like_Skins_and_lessons_templates/finance_concepts.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_debrief.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_ending.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_sim_models.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/minigames_pages/life_epilogue_screen.dart';

import 'support/app_fonts.dart';

/// The end of a run has to say what the player *did*, not only what happened.
///
/// The epilogue named the ending, listed five stats and paid the gold.
/// Somebody who retired at 68 with no emergency fund, everything in cash and
/// a thousand owed got exactly the same screen as somebody who did none of
/// that. These hold the debrief that now sits there.
void main() {
  LifeRunFacts careless({int age = 60}) => LifeRunFacts(
    age: age,
    netWorth: 900,
    cash: 900,
    investments: 0,
    emergencyFund: 0,
    debt: 700,
    health: 40,
    happiness: 35,
    conceptsMet: 1,
    conceptsAvailable: 16,
    died: false,
    everStarved: true,
    budgetSet: false,
  );

  LifeRunFacts careful({int age = 68}) => LifeRunFacts(
    age: age,
    netWorth: 28000,
    cash: 4000,
    investments: 20000,
    emergencyFund: 4000,
    debt: 0,
    health: 70,
    happiness: 72,
    conceptsMet: 11,
    conceptsAvailable: 16,
    died: false,
    everStarved: false,
    budgetSet: true,
    savingsPct: 20,
    wantsPct: 25,
  );

  group('every finding is usable', () {
    test('carries evidence and an action, always', () {
      for (final facts in [careless(), careful()]) {
        final debrief = debriefLife(facts);
        expect(debrief.findings, isNotEmpty);
        for (final finding in debrief.findings) {
          expect(finding.evidence.trim(), isNotEmpty, reason: finding.id);
          expect(finding.action.trim(), isNotEmpty, reason: finding.id);
          // The evidence has to quote a number out of the run, or it is a
          // general claim wearing a specific voice.
          expect(
            RegExp(r'\d').hasMatch(finding.evidence),
            isTrue,
            reason: '${finding.id} cites no number from the run',
          );
        }
      }
    });

    test('faults come before praise', () {
      final debrief = debriefLife(careless());
      final kinds = debrief.findings.map((f) => f.kind.index).toList();
      final sorted = [...kinds]..sort();
      expect(kinds, sorted, reason: 'a strength was shown above a fault');
      expect(debrief.findings.first.kind, LifeFindingKind.fix);
    });

    test('names the concept where the Academy teaches one', () {
      final debrief = debriefLife(careless());
      final withConcept = debrief.findings.where((f) => f.concept != null);
      expect(withConcept, isNotEmpty);
      for (final finding in withConcept) {
        expect(FinanceConcept.values, contains(finding.concept));
      }
    });
  });

  group('the grade reflects the run', () {
    test('a careless life grades below a careful one', () {
      final bad = debriefLife(careless());
      final good = debriefLife(careful());
      expect(bad.overall, lessThan(good.overall));
      expect(good.grade, anyOf('A', 'B'));
      expect(bad.grade, anyOf('C', 'D'));
    });

    test('never lower than D, on purpose', () {
      final ruined = debriefLife(
        const LifeRunFacts(
          age: 71,
          netWorth: -400,
          cash: 0,
          investments: 0,
          emergencyFund: 0,
          debt: 400,
          health: 10,
          happiness: 10,
          conceptsMet: 0,
          died: true,
          everStarved: true,
          budgetSet: false,
        ),
      );
      expect(ruined.grade, 'D');
      expect(ruined.overall, greaterThanOrEqualTo(0));
    });

    test('points at the weakest area', () {
      // Saved well, never invested a penny.
      final lopsided = debriefLife(
        const LifeRunFacts(
          age: 50,
          netWorth: 9000,
          cash: 4500,
          investments: 0,
          emergencyFund: 4500,
          debt: 0,
          health: 70,
          happiness: 70,
          conceptsMet: 9,
          died: false,
          everStarved: false,
          budgetSet: true,
        ),
      );
      expect(lopsided.weakest, LifeArea.growth);
      expect(
        lopsided.findings.any((f) => f.id == 'all_in_cash'),
        isTrue,
        reason: 'nothing told them the cash was doing nothing',
      );
    });

    test('a headline is always written', () {
      for (final facts in [careless(), careful()]) {
        expect(debriefLife(facts).headline.trim(), isNotEmpty);
      }
    });
  });

  group('the epilogue shows it', () {
    LifeSummary summaryWith({required bool withDebrief}) => LifeSummary(
      name: 'Ellis Silva',
      gender: Gender.nonBinary,
      origin: LifeOrigin.workingClass,
      job: 'Retired',
      age: 60,
      yearsLived: 60,
      died: false,
      netWorth: 900,
      happiness: 35,
      health: 40,
      smarts: 50,
      looks: 50,
      relationships: const <String>[],
      goldReward: 86,
      archetype: LifeEndingArchetype.quietLife,
      conceptsMet: 1,
      debrief: withDebrief ? debriefLife(careless()) : null,
    );

    setUpAll(loadAppFonts);
    setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

    // The epilogue reads the player's ending collection to suggest the next
    // one, so it needs the same provider the real screen sits under.
    Widget host(Widget child) => ChangeNotifierProvider<UserStatsController>(
      create: (_) => UserStatsController(service: SupabaseService.instance),
      child: MaterialApp(home: child),
    );

    testWidgets('a graded run gets the debrief', (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        host(LifeEpilogueScreen(summary: summaryWith(withDebrief: true))),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Coach read this run'), findsOneWidget);
      expect(find.text('Saving'), findsOneWidget);
      expect(find.text('Growing it'), findsOneWidget);
      expect(find.textContaining('never set a budget'), findsOneWidget);
    });

    testWidgets('an ungraded run does not', (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        host(
          LifeEpilogueScreen(
            summary: summaryWith(withDebrief: true),
            graded: false,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        find.text('Coach read this run'),
        findsNothing,
        reason:
            'somebody wrecking a life on purpose is not asking to be '
            'marked on it',
      );
    });
  });
}
