import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/controllers_that_updates_stats/life_sim_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_debrief.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_ending.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_run_record.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/minigames_pages/life_debrief_view.dart';

import 'support/app_fonts.dart';
import 'support/debrief_fixture.dart';

/// The end of a run tells the story of it.
///
/// **Asked for as:** *"make this more impressive and a detailed debrief after
/// each run, for anybody doing the main game."* Grading a run into a few areas
/// says *where* it was strong or weak. It does not say *when*, and the "when" is
/// the part a player can learn from: the year the money peaked, the bill that
/// arrived with nothing behind it, the one decision that cost the most and what
/// the other option would have done.
///
/// So a life now remembers itself as it goes, and these hold three things: what
/// it remembers is true, what the debrief builds from it is right, and what the
/// screen shows fits at every size.
void main() {
  setUpAll(loadAppFonts);

  group('the story', () {
    test('the turning point is the decision that left the most behind', () {
      final debrief = debriefLife(richRunFacts());
      final turning = debrief.story.turningPoint!;
      expect(turning.age, 24);
      expect(turning.chose, 'Buy it on credit');
      expect(turning.regret, 450);
    });

    test('a best call is a best option that saved the most', () {
      final best = debriefLife(richRunFacts()).story.bestCall!;
      expect(best.age, 31);
      expect(best.tookTheBest, isTrue);
      expect(best.edge, 240);
    });

    test('money left on the table sums what the decisions gave up', () {
      // 450 from the car, none from the phone plan, and shocks are not choices.
      expect(debriefLife(richRunFacts()).story.moneyLeftOnTable, 450);
    });

    test('the biggest hit can be a bill, not only a choice', () {
      final hit = debriefLife(richRunFacts()).story.biggestHit!;
      expect(hit.title, 'The boiler gave out');
      expect(hit.moneyDelta, -820);
    });

    test(
      'with no decisions the turning point falls back to the biggest hit',
      () {
        final story = debriefLife(roughRunFacts()).story;
        expect(story.regrets, isEmpty);
        expect(story.turningPoint, isNotNull);
        expect(story.turningPoint!.title, 'Your phone was stolen');
      },
    );

    test('a life that remembered nothing has no story, and no crash', () {
      final debrief = debriefLife(
        const LifeRunFacts(
          age: 60,
          netWorth: 100,
          cash: 100,
          investments: 0,
          emergencyFund: 0,
          debt: 0,
          health: 60,
          happiness: 60,
          conceptsMet: 3,
          died: false,
          everStarved: false,
          budgetSet: true,
        ),
      );
      expect(debrief.story.isEmpty, isTrue);
      expect(debrief.record.curve, isEmpty);
    });

    test('a shock that was borrowed for says so', () {
      final borrowed = richRunRecord().moments.firstWhere(
        (m) => m.title == 'A trip to the dentist',
      );
      expect(borrowed.covered, isFalse);
    });

    test('small choices are not moments', () {
      // Regret and edge both under the floor: nothing to look back on.
      const moment = LifeMoment(
        age: 30,
        kind: LifeMomentKind.decision,
        title: 't',
        chose: 'c',
        moneyDelta: -10,
        betterDelta: 0,
        worseDelta: -20,
      );
      expect(moment.regret, 10);
      expect(moment.edge, 10);
    });
  });

  group('the areas', () {
    test('a life with a working stretch is graded on career and people', () {
      final scores = debriefLife(richRunFacts()).scores;
      expect(scores.keys, contains(LifeArea.career));
      expect(scores.keys, contains(LifeArea.people));
    });

    test('a life with neither is not given a false zero', () {
      // Fixtures without a record or a connection reading leave both out, so a
      // child who died at nine is not marked down for having no career.
      final scores = debriefLife(
        const LifeRunFacts(
          age: 9,
          netWorth: 10,
          cash: 10,
          investments: 0,
          emergencyFund: 0,
          debt: 0,
          health: 70,
          happiness: 70,
          conceptsMet: 1,
          died: true,
          everStarved: false,
          budgetSet: false,
        ),
      ).scores;
      expect(scores.keys, isNot(contains(LifeArea.career)));
      expect(scores.keys, isNot(contains(LifeArea.people)));
    });

    test('losing the job costs the career score', () {
      final good = debriefLife(richRunFacts()).scores[LifeArea.career]!;
      final rough = debriefLife(roughRunFacts()).scores[LifeArea.career]!;
      expect(rough, lessThan(good));
    });

    test('a strong network lifts the people score', () {
      LifeRunFacts withNetwork(int strength) => LifeRunFacts(
        age: 50,
        netWorth: 5000,
        cash: 1000,
        investments: 1000,
        emergencyFund: 3000,
        debt: 0,
        health: 70,
        happiness: 70,
        conceptsMet: 8,
        died: false,
        everStarved: false,
        budgetSet: true,
        connection: 50,
        networkStrength: strength,
      );
      expect(
        debriefLife(withNetwork(90)).scores[LifeArea.people]!,
        greaterThan(debriefLife(withNetwork(0)).scores[LifeArea.people]!),
      );
    });

    test('saving reads how much was put aside, not only what was left', () {
      // Two lives ending with the same cushion. One saved 25% of everything it
      // earned; the other saved almost none and got lucky.
      LifeRunFacts life(int saved) => LifeRunFacts(
        age: 60,
        netWorth: 3000,
        cash: 0,
        investments: 0,
        emergencyFund: 3000,
        debt: 0,
        health: 70,
        happiness: 70,
        conceptsMet: 8,
        died: false,
        everStarved: false,
        budgetSet: true,
        record: LifeRunRecord(
          tally: LifeRunTally(
            adultYears: 40,
            workYears: 40,
            incomeTotal: 20000,
            savedTotal: saved,
          ),
        ),
      );
      expect(
        debriefLife(life(5000)).scores[LifeArea.saving]!,
        greaterThan(debriefLife(life(100)).scores[LifeArea.saving]!),
      );
    });
  });

  group('what it says', () {
    test('every evidence line still quotes a number from the run', () {
      for (final facts in [richRunFacts(), roughRunFacts()]) {
        for (final finding in debriefLife(facts).findings) {
          expect(finding.action.trim(), isNotEmpty, reason: finding.id);
          expect(
            RegExp(r'\d').hasMatch(finding.evidence),
            isTrue,
            reason: '${finding.id} cites no number from the run',
          );
        }
      }
    });

    test('the rough life is told why, in its own numbers', () {
      final ids = debriefLife(roughRunFacts()).findings.map((f) => f.id);
      expect(ids, containsAll(<String>['laid_off', 'shocks_borrowed']));
      expect(ids, contains('interest_cost'));
      expect(ids, contains('never_budgeted'));
    });

    test(
      'a layoff with no missed work is not blamed on missed work',
      () {
        // **Reported as:** "I don't understand how missed work cost me my
        // job, if I literally never missed work" -- `timesLaidOff` counts
        // three unrelated causes as one number (missed-work strain, poor
        // performance reviews, a story event taking the job away), and the
        // debrief used to credit all of them to missed work regardless,
        // producing evidence that read "you missed about 0 weeks of work
        // and were let go once."
        final facts = LifeRunFacts(
          age: 40,
          netWorth: 0,
          cash: 0,
          investments: 0,
          emergencyFund: 0,
          debt: 0,
          health: 70,
          happiness: 70,
          conceptsMet: 1,
          died: false,
          everStarved: false,
          budgetSet: true,
          record: const LifeRunRecord(
            tally: LifeRunTally(
              adultYears: 22,
              workYears: 20,
              timesLaidOff: 1,
              weeksMissed: 0,
            ),
          ),
        );
        final findings = debriefLife(facts).findings;
        final ids = findings.map((f) => f.id);

        expect(
          ids,
          isNot(contains('laid_off')),
          reason: '"Missed work cost you the job" cites weeksMissed as '
              'evidence -- it must not fire when weeksMissed is 0',
        );
        expect(ids, contains('laid_off_other'));

        final other = findings.firstWhere((f) => f.id == 'laid_off_other');
        expect(
          other.evidence.contains('0 weeks'),
          isFalse,
          reason: 'the replacement finding must not smuggle the same '
              'contradiction back in',
        );
      },
    );

    test('the good life is told what worked', () {
      final ids = debriefLife(richRunFacts()).findings.map((f) => f.id);
      expect(ids, contains('saved_well'));
      expect(ids, contains('network_paid'));
      expect(ids, contains('raises_earned'));
    });

    test('never shows only faults', () {
      // Five problems and one thing done well. A screen with room for four must
      // still find room for the one that went right.
      final many = debriefLife(roughRunFacts());
      final problems = many.findings.where(
        (f) => f.kind != LifeFindingKind.strength,
      );
      expect(problems.length, greaterThan(4));

      const strength = LifeFinding(
        id: 'good',
        kind: LifeFindingKind.strength,
        area: LifeArea.saving,
        title: 'Something went right',
        evidence: 'You did 1 good thing.',
        action: 'Keep it.',
      );
      final withStrength = LifeDebrief(
        scores: many.scores,
        findings: [...many.findings, strength],
        headline: 'x',
      );
      final shown = withStrength.shown(max: 4);
      expect(shown, hasLength(4));
      expect(shown.last.kind, LifeFindingKind.strength);
      expect(shown.first.kind, isNot(LifeFindingKind.strength));
    });

    test('the first line is the one that cost the most', () {
      // The headline says "start with the first line", so it has to be true.
      // Being let go and going hungry outrank a missing budget, whatever order
      // the rules happened to run in.
      final debrief = debriefLife(roughRunFacts());
      final ids = debrief.findings.map((f) => f.id).toList();
      expect(ids.first, 'went_hungry');
      expect(ids.indexOf('laid_off'), lessThan(ids.indexOf('never_budgeted')));
      expect(
        debrief.shown().map((f) => f.id),
        contains('laid_off'),
        reason: 'the most costly career finding was cut off the screen',
      );
    });

    test('a short list is shown whole', () {
      final debrief = debriefLife(richRunFacts());
      final shown = debrief.shown(max: 99);
      expect(shown, debrief.findings);
    });

    test(
      'there is always a challenge, aimed at the weakest area, with a number',
      () {
        for (final facts in [richRunFacts(), roughRunFacts()]) {
          final debrief = debriefLife(facts);
          expect(debrief.nextRun.trim(), isNotEmpty);
          expect(
            RegExp(r'\d|once|one|two|three|thirty').hasMatch(debrief.nextRun),
            isTrue,
            reason: 'the challenge names nothing to play against',
          );
        }
      },
    );

    test('the same life always tells the same story', () {
      final a = debriefLife(richRunFacts());
      final b = debriefLife(richRunFacts());
      expect(a.findings.map((f) => f.id), b.findings.map((f) => f.id));
      expect(a.nextRun, b.nextRun);
      expect(a.grade, b.grade);
    });
  });

  group('a real life remembers itself', () {
    /// Plays a life to its end taking the first option every time.
    LifeSimController play(int seed) {
      final life = LifeSimController(random: Random(seed));
      for (var year = 0; year < 90 && !life.finished; year++) {
        life.takeLesson();
        life.ageUp();
        if (life.currentEvent != null) life.chooseOption(0);
      }
      if (!life.finished) life.retire();
      return life;
    }

    test('the curve has a point for every year lived, in order', () {
      for (var seed = 0; seed < 25; seed++) {
        final life = play(seed);
        final curve = life.yearCurve;
        expect(curve.first.age, life.startAge, reason: 'seed $seed');
        expect(curve.last.age, life.age, reason: 'seed $seed');
        for (var i = 1; i < curve.length; i++) {
          expect(
            curve[i].age,
            curve[i - 1].age + 1,
            reason: 'seed $seed skipped or repeated a year',
          );
        }
      }
    });

    test('the last point on the curve is where the life ended', () {
      for (var seed = 0; seed < 25; seed++) {
        final life = play(seed);
        expect(
          life.yearCurve.last.netWorth,
          life.netWorth,
          reason: 'seed $seed: the chart ends somewhere the score does not',
        );
      }
    });

    test('the peak and the low are read off the curve', () {
      for (var seed = 0; seed < 25; seed++) {
        final life = play(seed);
        final tally = life.runTally;
        final worths = life.yearCurve.map((p) => p.netWorth);
        expect(tally.peakNetWorth, worths.reduce(max), reason: 'seed $seed');
        expect(tally.lowNetWorth, worths.reduce(min), reason: 'seed $seed');
      }
    });

    test('nothing in the tally is impossible', () {
      for (var seed = 0; seed < 25; seed++) {
        final t = play(seed).runTally;
        expect(t.savingsRate, inInclusiveRange(0, 1), reason: 'seed $seed');
        expect(t.shocksCovered, lessThanOrEqualTo(t.shocksHit));
        expect(t.workYears + t.yearsUnemployed + t.studentYears, t.adultYears);
        expect(t.savedTotal, lessThanOrEqualTo(t.incomeTotal + 1));
        expect(t.interestPaid, greaterThanOrEqualTo(0));
      }
    });

    test('every moment is one worth looking back on', () {
      var seen = 0;
      for (var seed = 0; seed < 40; seed++) {
        for (final m in play(seed).moments) {
          seen++;
          expect(m.regret, greaterThanOrEqualTo(0));
          expect(m.edge, greaterThanOrEqualTo(0));
          if (m.kind == LifeMomentKind.decision) {
            expect(
              m.moneyDelta.abs() >= 40 || m.regret >= 40 || m.edge >= 40,
              isTrue,
              reason: '"${m.title}" moved no money and would not have',
            );
          } else {
            expect(m.moneyDelta, lessThan(0));
          }
        }
      }
      expect(seen, greaterThan(20), reason: 'no life recorded anything');
    });

    test('a shock is recorded with how it was paid for', () {
      final life = LifeSimController(
        random: Random(1),
        initialAge: 30,
        startMoney: 0,
        startJob: 'Barista',
        startSalary: 500,
      );
      life.applyShock(300, 'The boiler gave out');
      final moment = life.moments.single;
      expect(moment.kind, LifeMomentKind.shock);
      expect(moment.covered, isFalse, reason: 'there was nothing to pay with');
      expect(life.runTally.shocksHit, 1);
      expect(life.runTally.shocksCovered, 0);

      life.debugSetStats(money: 5000);
      life.applyShock(300, 'A leak');
      expect(life.moments.last.covered, isTrue);
      expect(life.runTally.shocksCovered, 1);
    });

    test('the first job is remembered', () {
      final life = LifeSimController(random: Random(3), initialAge: 20);
      expect(life.runTally.firstJobAge, isNull);
      life.findJob();
      expect(life.runTally.firstJobAge, 20);
    });

    test('a finished life hands the whole memory to its summary', () {
      final life = play(7);
      final summary = LifeSummary.fromController(life);
      final debrief = summary.debrief!;
      expect(debrief.record.curve, isNotEmpty);
      expect(debrief.record.curve.length, life.yearCurve.length);
      expect(debrief.scores, isNotEmpty);
    });
  });

  group('the screen', () {
    Widget host(Widget child) => MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );

    testWidgets('a full debrief shows every section', (tester) async {
      tester.view.physicalSize = const Size(430, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        host(LifeDebriefView(debrief: debriefLife(richRunFacts()))),
      );
      await tester.pump();

      expect(find.text('Coach read this run'), findsOneWidget);
      expect(find.text('Your money, year by year'), findsOneWidget);
      expect(find.text('How each part went'), findsOneWidget);
      expect(find.text('This life in numbers'), findsOneWidget);
      expect(find.text('The story of it'), findsOneWidget);
      expect(find.text('What to do differently'), findsOneWidget);
      expect(find.text('Your challenge for next time'), findsOneWidget);
      expect(find.textContaining('Turning point, age 24'), findsOneWidget);
      expect(find.textContaining('Best call, age 31'), findsOneWidget);
    });

    testWidgets('the rough life leads with what went wrong', (tester) async {
      tester.view.physicalSize = const Size(430, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        host(LifeDebriefView(debrief: debriefLife(roughRunFacts()))),
      );
      await tester.pump();

      expect(find.textContaining('let go'), findsWidgets);
      expect(find.textContaining('borrowed'), findsWidgets);
    });

    testWidgets('it says where this life ranks among the others', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(430, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        host(
          LifeDebriefView(
            debrief: debriefLife(richRunFacts()),
            thisNetWorth: 8400,
            netWorthsOfEveryLife: const <int>[12000, 8400, 3000, -200],
          ),
        ),
      );
      await tester.pump();
      expect(
        find.text('This life ranks 2nd of 4 by net worth.'),
        findsOneWidget,
      );
    });

    testWidgets('the best life so far says so', (tester) async {
      tester.view.physicalSize = const Size(430, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        host(
          LifeDebriefView(
            debrief: debriefLife(richRunFacts()),
            thisNetWorth: 8400,
            netWorthsOfEveryLife: const <int>[8400, 3000],
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('Your best life so far'), findsOneWidget);
    });

    testWidgets('one life has nothing to compare against', (tester) async {
      tester.view.physicalSize = const Size(430, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        host(
          LifeDebriefView(
            debrief: debriefLife(richRunFacts()),
            thisNetWorth: 8400,
            netWorthsOfEveryLife: const <int>[8400],
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('ranks'), findsNothing);
      expect(find.textContaining('best life'), findsNothing);
    });

    testWidgets('a life with no memory still draws, without the chart', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(430, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final debrief = debriefLife(
        const LifeRunFacts(
          age: 60,
          netWorth: 100,
          cash: 100,
          investments: 0,
          emergencyFund: 0,
          debt: 0,
          health: 60,
          happiness: 60,
          conceptsMet: 3,
          died: false,
          everStarved: false,
          budgetSet: true,
        ),
      );
      await tester.pumpWidget(host(LifeDebriefView(debrief: debrief)));
      await tester.pump();
      expect(find.text('Your money, year by year'), findsNothing);
      expect(find.text('Coach read this run'), findsOneWidget);
    });

    for (final size in const <String, Size>{
      'small phone': Size(320, 4200),
      'phone': Size(390, 3600),
      'tablet': Size(800, 3000),
    }.entries) {
      testWidgets('fits at ${size.key} without an overflow', (tester) async {
        final errors = <FlutterErrorDetails>[];
        final previous = FlutterError.onError;
        FlutterError.onError = errors.add;

        tester.view.physicalSize = size.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        for (final facts in [richRunFacts(), roughRunFacts()]) {
          await tester.pumpWidget(
            host(
              LifeDebriefView(
                debrief: debriefLife(facts),
                practice: true,
                thisNetWorth: facts.netWorth,
                netWorthsOfEveryLife: <int>[facts.netWorth, 100, -50],
                seedText: 'K3F9QZ',
              ),
            ),
          );
          await tester.pump();
        }
        FlutterError.onError = previous;

        expect(
          errors.map((e) => e.exceptionAsString()).toList(),
          isEmpty,
          reason: 'the debrief overflows at ${size.key}',
        );
      });
    }
  });
}
