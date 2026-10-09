import 'package:budget_app/models_Like_Skins_and_lessons_templates/daily_quest.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/lesson.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/lesson_data.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_achievements.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_record.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/quiz_bank.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/skill_lessons.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/academy/quiz_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// The app's own description, held to what the app does.
///
/// Written against the pitch: Home shows *"daily recommendations ... like
/// trying the daily budget question or beating their Finance Brawl high
/// score"*; a wrong answer *"gives the direct lessons that the user missed the
/// question on"*; Life has *"endings and different achievements"*. Each of
/// these was missing or only half there when the description was checked.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  DailyPlan plan({
    bool challengeDone = false,
    int brawlBest = 0,
    List<String> games = const ['finance_brawl'],
  }) {
    return const DailyPlanBuilder().build(
      dateKey: '2026-10-05',
      completedIds: const <String>{},
      streakDays: 0,
      weakSkills: const <String>[],
      completedLessons: const <String>{},
      arcadePlays: (_) => 0,
      activeArcadeGameIds: games,
      dailyChallengeDone: challengeDone,
      bestScore: (id) => id == 'finance_brawl' ? brawlBest : 0,
    );
  }

  group('Home recommends', () {
    test("today's budget question, second after the lesson", () {
      final p = plan();
      final challenge = p.quests.firstWhere(
        (q) => q.surface == QuestSurface.dailyChallenge,
      );
      expect(p.quests.indexOf(challenge), 1);
      expect(p.isDone(challenge.id), isFalse);
    });

    test('and it is done when the challenge is, not when tapped', () {
      final p = plan(challengeDone: true);
      final challenge = p.quests.firstWhere(
        (q) => q.surface == QuestSurface.dailyChallenge,
      );
      expect(p.isDone(challenge.id), isTrue);
    });

    test('beating the Finance Brawl high score, once there is one', () {
      expect(
        plan().quests.map((q) => q.title),
        contains('Play: Finance Brawl'),
      );
      final chase = plan(
        brawlBest: 1200,
      ).quests.firstWhere((q) => q.arcadeGameId == 'finance_brawl');
      expect(chase.title, 'Beat your Finance Brawl high score');
      expect(chase.detail, contains('1200'));
    });
  });

  group('a wrong answer points at its lesson', () {
    test('every skill in every quiz and test has a lesson in its unit', () {
      final missing = <String>[];
      for (final unit in lessonUnits) {
        for (final node in unit.lessons) {
          if (node.type == LessonNodeType.lesson) continue;
          for (final q in quizFor(node.id)) {
            final lesson = lessonForSkill(q.skillId, unitId: unit.id);
            if (lesson == null || !unit.lessons.any((l) => l.id == lesson.id)) {
              missing.add('${node.id}: ${q.skillId}');
            }
          }
        }
      }
      expect(missing, isEmpty, reason: missing.join('\n'));
    });

    testWidgets('and the results card names it, with a way back', (
      tester,
    ) async {
      final question = quizFor('test_1').first;
      final unitId = lessonUnits
          .firstWhere((u) => u.lessons.any((l) => l.id == 'test_1'))
          .id;
      final lesson = lessonForSkill(question.skillId, unitId: unitId)!;
      Lesson? opened;
      tester.view.physicalSize = const Size(430, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: QuizResultsCard(
                correct: 0,
                total: 1,
                missed: [question],
                unitId: unitId,
                onOpenLesson: (l) => opened = l,
              ),
            ),
          ),
        ),
      );
      expect(find.text('From the lesson: ${lesson.title}'), findsOneWidget);
      await tester.tap(find.text('Review this lesson'));
      expect(opened?.id, lesson.id);
    });
  });

  group('Life achievements', () {
    LifeRecord record({
      int age = 70,
      int netWorth = 5000,
      LifeDetail? detail,
    }) => LifeRecord(
      endingId: 'quietLife',
      name: 'Sam',
      age: age,
      netWorth: netWorth,
      happiness: 60,
      died: false,
      conceptsMet: 3,
      goldEarned: 0,
      finishedAt: DateTime(2026, 10, 5),
      detail: detail,
    );

    test('are earned by how a life went', () {
      final good = record(
        age: 88,
        netWorth: 150000,
        detail: const LifeDetail(
          ownedHome: true,
          promotions: 3,
          hadPartner: true,
          children: 2,
        ),
      );
      for (final a in [
        LifeAchievement.debtFree,
        LifeAchievement.homeowner,
        LifeAchievement.sixFigures,
        LifeAchievement.climber,
        LifeAchievement.familyLife,
        LifeAchievement.goldenYears,
      ]) {
        expect(a.earnedBy(good), isTrue, reason: a.label);
      }
    });

    test('and not by a life that did not', () {
      final poor = record(
        age: 40,
        netWorth: 300,
        detail: const LifeDetail(loansOwed: 900),
      );
      for (final a in LifeAchievement.values) {
        expect(a.earnedBy(poor), isFalse, reason: a.label);
      }
    });

    test('an old record with no details earns nothing it cannot prove', () {
      final old = record(age: 70);
      expect(LifeAchievement.debtFree.earnedBy(old), isFalse);
      expect(LifeAchievement.homeowner.earnedBy(old), isFalse);
    });
  });
}
