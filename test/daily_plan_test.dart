import 'package:budget_app/models_Like_Skins_and_lessons_templates/daily_quest.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/lesson.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/lesson_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const builder = DailyPlanBuilder();

  DailyPlan buildWith({
    Set<String> completedIds = const {},
    List<String> weakSkills = const [],
    Set<String> completedLessons = const {},
    Map<String, int> plays = const {},
    List<String> games = const ['finance_brawl', 'market_board'],
    AgeStage? readerStage,
  }) {
    return builder.build(
      dateKey: '2026-07-27',
      completedIds: completedIds,
      streakDays: 0,
      weakSkills: weakSkills,
      completedLessons: completedLessons,
      arcadePlays: (id) => plays[id] ?? 0,
      activeArcadeGameIds: games,
      readerStage: readerStage,
    );
  }

  group('daily plan builder', () {
    test('always produces a non-empty plan', () {
      // Even a maxed-out account (all lessons done, no weak skills) must have
      // something to do, or the home card renders empty.
      final plan = buildWith(
        completedLessons: {
          for (var i = 1; i <= 25; i++) 'lesson_$i',
        },
        plays: {'finance_brawl': 5, 'market_board': 5},
      );
      expect(plan.quests, isNotEmpty);
    });

    test('leads with the next uncompleted lesson', () {
      // Derived from `lessonUnits` rather than hardcoding ids. This test
      // used to assert `lesson_1 done -> lesson_2 next`, which quietly
      // depended on unit_1 being *first in the list*; once the curriculum
      // was reordered chronologically (ages 4-6 first) that stopped being
      // true and the test failed for a reason that had nothing to do with
      // the behavior it was checking.
      final firstUnit = lessonUnits.first;
      final firstTwo = firstUnit.lessons
          .where((l) => l.type == LessonNodeType.lesson)
          .take(2)
          .toList();

      final plan = buildWith(completedLessons: {firstTwo.first.id});
      expect(plan.quests.first.surface, QuestSurface.academyLesson);
      expect(
        plan.quests.first.id,
        'lesson_${firstTwo[1].id}',
        reason:
            'with ${firstTwo.first.id} done, the next lesson node in '
            '${firstUnit.id} should be picked',
      );
    });

    test('routes a weak skill to a practice quest', () {
      final plan = buildWith(weakSkills: ['budget_basics']);
      final practice = plan.quests
          .where((q) => q.surface == QuestSurface.academyPractice)
          .toList();
      expect(practice, isNotEmpty);
      expect(practice.first.unitId, isNotNull);
    });

    test('arcade quest targets the least-played active game', () {
      final plan = buildWith(
        completedLessons: {for (var i = 1; i <= 25; i++) 'lesson_$i'},
        plays: {'finance_brawl': 10, 'market_board': 2},
      );
      final arcade = plan.quests
          .where((q) => q.surface == QuestSurface.arcade)
          .toList();
      expect(arcade, isNotEmpty);
      expect(arcade.first.arcadeGameId, 'market_board');
    });

    test('completion count and progress reflect completedIds', () {
      var plan = buildWith();
      final firstId = plan.quests.first.id;
      expect(plan.completedCount, 0);
      expect(plan.nextQuest?.id, firstId);

      plan = buildWith(completedIds: {firstId});
      expect(plan.completedCount, 1);
      expect(plan.isDone(firstId), isTrue);
      expect(plan.nextQuest?.id, isNot(firstId));
    });

    test('every quest carries a positive reward and a routable surface', () {
      final plan = buildWith(weakSkills: ['credit']);
      for (final quest in plan.quests) {
        expect(quest.xpReward, greaterThan(0));
        if (quest.surface == QuestSurface.arcade) {
          expect(quest.arcadeGameId, isNotNull);
        }
        if (quest.surface == QuestSurface.academyLesson ||
            quest.surface == QuestSurface.academyPractice) {
          expect(quest.unitId, isNotNull);
        }
      }
    });
  });

  group('the learning quest respects the reader\'s age', () {
    // This is the guard that lets `lessonUnits` stay in chronological
    // order. Before `readerStage` existed, `_nextLesson` walked raw list
    // order — so with ages 4-6 now genuinely first in the list, an adult's
    // daily quest would be "What Is Money?" every single day.
    LessonUnit unitOf(DailyPlan plan) {
      final quest = plan.quests.firstWhere(
        (q) => q.surface == QuestSurface.academyLesson,
      );
      return lessonUnits.firstWhere((u) => u.id == quest.unitId);
    }

    test('an adult is never sent to the ages 4-6 unit', () {
      final plan = buildWith(readerStage: AgeStage.adult);
      final unit = unitOf(plan);
      expect(
        unit.ageStage.minAge,
        greaterThanOrEqualTo(AgeStage.adult.minAge),
        reason:
            'an adult with nothing completed was quested '
            '"${unit.title}" (${unit.ageStage.name})',
      );
    });

    test('a young child is sent to the youngest unit', () {
      final plan = buildWith(readerStage: AgeStage.earlyChildhood);
      expect(unitOf(plan).ageStage, AgeStage.earlyChildhood);
    });

    test('every age band gets a quest at or above its own level', () {
      for (final stage in AgeStage.values) {
        final unit = unitOf(buildWith(readerStage: stage));
        expect(
          unit.ageStage.minAge,
          greaterThanOrEqualTo(stage.minAge),
          reason:
              '$stage was quested "${unit.title}" '
              '(${unit.ageStage.name}), which is pitched younger',
        );
      }
    });

    test('an unknown age still gets a learning quest', () {
      // Plenty of players never share an age; the slot must not vanish.
      final plan = buildWith();
      expect(
        plan.quests.where((q) => q.surface == QuestSurface.academyLesson),
        isNotEmpty,
      );
    });

    test('finishing everything at your level falls back, not silent', () {
      // An adult who has completed every adult lesson should still be
      // offered something rather than losing the learning slot entirely.
      final adultLessons = <String>{
        for (final unit in lessonUnits)
          if (unit.ageStage.minAge >= AgeStage.adult.minAge)
            for (final lesson in unit.lessons) lesson.id,
      };
      final plan = buildWith(
        readerStage: AgeStage.adult,
        completedLessons: adultLessons,
      );
      expect(
        plan.quests.where((q) => q.surface == QuestSurface.academyLesson),
        isNotEmpty,
        reason: 'the learning slot disappeared instead of falling back',
      );
    });
  });
}
