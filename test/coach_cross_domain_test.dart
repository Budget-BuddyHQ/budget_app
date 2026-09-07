import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/models_Like_Skins_and_lessons_templates/finance_concepts.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/money_analyzer.dart';
import 'package:budget_app/widgets_custom_lotties/coach_spot.dart';

/// The coach's cross-domain reasoning, and the card that carries it.
///
/// **Why these rules get their own file.** Every other rule in the analyser
/// reads one area and reports on it, which is a report card. These read two
/// and report on the *gap* — a quiz score against how somebody actually
/// plays — and that is the only part of the analyser no single screen in the
/// app could produce on its own. The Academy sees a good score. The arcade
/// sees a finished run. Only this sees that they disagree.
///
/// They are also the easiest rules to break silently, because a threshold
/// typo does not throw: it just makes the coach quiet, and a coach that says
/// nothing looks identical to a player with nothing wrong.
void main() {
  /// A player with enough history that `isNewcomer` is false.
  MoneySnapshot player({
    Map<FinanceConcept, double> accuracy = const <FinanceConcept, double>{},
    int cascadeRuns = 0,
    int cascadeLevelsCleared = 0,
    double wantsShare = 0,
    double savesShare = 0,
    List<int> lives = const <int>[],
    int lessons = 1,
  }) => MoneySnapshot(
    loggedDaysLast14: 5,
    daysSinceLastLog: 1,
    pinnedHabits: 2,
    habitsLoggedLast14: 2,
    lessonsCompleted: lessons,
    lessonsAvailable: 20,
    conceptAccuracy: accuracy,
    pastLifeNetWorths: lives,
    cascadeRuns: cascadeRuns,
    cascadeLevelsCleared: cascadeLevelsCleared,
    cascadeWantsShare: wantsShare,
    cascadeSavesShare: savesShare,
  );

  Set<String> idsOf(MoneyReport r) => r.findings.map((f) => f.id).toSet();

  group('knowing it versus doing it', () {
    test('a high quiz score with a high wants share is called out', () {
      final report = analyseMoney(
        player(
          accuracy: const {FinanceConcept.needsVsWants: 0.9},
          cascadeRuns: 4,
          wantsShare: 0.42,
          savesShare: 0.12,
        ),
      );

      expect(idsOf(report), contains('knows_split_plays_otherwise'));

      final finding = report.findings.firstWhere(
        (f) => f.id == 'knows_split_plays_otherwise',
      );
      // The evidence has to carry both numbers. A finding that says "you do
      // not play what you know" without showing the two figures it compared
      // is an accusation rather than a coaching note, and a child cannot
      // check it.
      expect(finding.evidence, contains('90%'));
      expect(finding.evidence, contains('42%'));
      expect(finding.kind, MoneyFindingKind.fix);
    });

    test('one run is not a pattern', () {
      // `hasCascadeHistory` requires two. A single high-wants afternoon is a
      // bad afternoon, and telling somebody it is a character flaw after one
      // game is how an analyser loses trust it cannot get back.
      final report = analyseMoney(
        player(
          accuracy: const {FinanceConcept.needsVsWants: 0.9},
          cascadeRuns: 1,
          wantsShare: 0.42,
        ),
      );
      expect(idsOf(report), isNot(contains('knows_split_plays_otherwise')));
    });

    test('playing it well without ever being assessed points at the unit', () {
      final report = analyseMoney(
        player(cascadeRuns: 3, cascadeLevelsCleared: 4, wantsShare: 0.31),
      );

      expect(idsOf(report), contains('plays_split_never_read_it'));
      final finding = report.findings.firstWhere(
        (f) => f.id == 'plays_split_never_read_it',
      );
      expect(finding.concept, FinanceConcept.budgetRule);
      // Never assessed is deliberately different from scoring badly, so this
      // is a `watch` rather than a `fix`. There is nothing going wrong.
      expect(finding.kind, MoneyFindingKind.watch);
    });

    test('a 50/30/20 split played rather than read is named as a strength', () {
      final report = analyseMoney(
        player(cascadeRuns: 5, wantsShare: 0.28, savesShare: 0.24),
      );
      expect(idsOf(report), contains('split_healthy'));
      expect(
        report.findings.firstWhere((f) => f.id == 'split_healthy').kind,
        MoneyFindingKind.strength,
      );
    });

    test('the three split rules are mutually exclusive', () {
      // They share a branch, so exactly one can fire. If a refactor ever
      // turns those into independent `if`s, a player could be told they
      // budget well and badly in the same list.
      const splitIds = <String>{
        'knows_split_plays_otherwise',
        'plays_split_never_read_it',
        'split_healthy',
      };
      for (final snap in <MoneySnapshot>[
        player(
          accuracy: const {FinanceConcept.budgetRule: 0.85},
          cascadeRuns: 4,
          wantsShare: 0.5,
        ),
        player(cascadeRuns: 4, cascadeLevelsCleared: 6, wantsShare: 0.2),
        player(cascadeRuns: 4, wantsShare: 0.25, savesShare: 0.3),
      ]) {
        expect(idsOf(analyseMoney(snap)).intersection(splitIds), hasLength(1));
      }
    });
  });

  group('the same habit in two unrelated games', () {
    test('high wants plus lives that are not improving is one finding', () {
      final report = analyseMoney(
        player(
          cascadeRuns: 3,
          wantsShare: 0.45,
          savesShare: 0.1,
          lives: const <int>[400, 900, 1200],
        ),
      );

      expect(idsOf(report), contains('wants_pattern_across_games'));
      final finding = report.findings.firstWhere(
        (f) => f.id == 'wants_pattern_across_games',
      );
      // The point of the finding is that the two systems are independent.
      // If the wording ever stops saying so it stops being interesting.
      expect(finding.action, contains('share no code'));
    });

    test('improving lives do not trigger it, even with a high wants share', () {
      final report = analyseMoney(
        player(
          cascadeRuns: 3,
          wantsShare: 0.45,
          lives: const <int>[1500, 900, 400],
        ),
      );
      expect(idsOf(report), isNot(contains('wants_pattern_across_games')));
    });
  });

  group('reading without deciding', () {
    test('lessons finished but nothing ever played', () {
      final report = analyseMoney(player(lessons: 6));
      expect(idsOf(report), contains('reads_never_plays'));
    });

    test('a single life played is enough to stop saying it', () {
      final report = analyseMoney(player(lessons: 6, lives: const <int>[250]));
      expect(idsOf(report), isNot(contains('reads_never_plays')));
    });
  });

  group('CoachSpot', () {
    const finding = MoneyFinding(
      id: 'x',
      kind: MoneyFindingKind.fix,
      dimension: MoneyDimension.learning,
      title: 'A thing worth knowing',
      evidence: 'Because of this number.',
      action: 'Do this today.',
    );

    Widget host(MoneyReport report, {Set<MoneyDimension>? only}) => MaterialApp(
      home: Scaffold(
        body: CoachSpot(debugReport: report, onlyDimensions: only),
      ),
    );

    testWidgets('says nothing at all to a brand-new account', (tester) async {
      await tester.pumpWidget(
        host(
          const MoneyReport(
            scores: {},
            findings: <MoneyFinding>[],
            isNewcomer: true,
          ),
        ),
      );
      // Not an encouraging placeholder. A coach with no history to read has
      // nothing honest to say, and filling the space with warmth is how the
      // findings that *are* real stop being read.
      expect(find.text('A thing worth knowing'), findsNothing);
      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('shows the headline finding with its evidence', (tester) async {
      await tester.pumpWidget(
        host(
          const MoneyReport(
            scores: {},
            findings: <MoneyFinding>[finding],
            isNewcomer: false,
          ),
        ),
      );
      expect(find.text('A thing worth knowing'), findsOneWidget);
      expect(find.text('Because of this number.'), findsOneWidget);
    });

    testWidgets('renders nothing rather than something off-topic', (
      tester,
    ) async {
      // The arcade asks for learning/saving. The only finding is about
      // showing up. Falling back to it would be the coach talking to fill
      // space in a room where it has nothing to say.
      await tester.pumpWidget(
        host(
          const MoneyReport(
            scores: {},
            findings: <MoneyFinding>[
              MoneyFinding(
                id: 'y',
                kind: MoneyFindingKind.watch,
                dimension: MoneyDimension.consistency,
                title: 'Off topic here',
                evidence: 'e',
                action: 'a',
              ),
            ],
            isNewcomer: false,
          ),
          only: const {MoneyDimension.learning, MoneyDimension.saving},
        ),
      );
      expect(find.text('Off topic here'), findsNothing);
    });

    testWidgets('the margin disappears with the card', (tester) async {
      // The bug this guards: a silent coach between two SizedBoxes leaves a
      // double gap on exactly the screens a new player sees first.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CoachSpot(
              margin: EdgeInsets.only(top: 40),
              debugReport: MoneyReport(
                scores: {},
                findings: <MoneyFinding>[],
                isNewcomer: true,
              ),
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byType(CoachSpot)).height, 0);
    });
  });
}
