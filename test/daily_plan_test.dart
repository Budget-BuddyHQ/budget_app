import 'package:budget_app/models_Like_Skins_and_lessons_templates/daily_quest.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const builder = DailyPlanBuilder();

  DailyPlan buildWith({
    Set<String> completedIds = const {},
    List<String> weakSkills = const [],
    Set<String> completedLessons = const {},
    Map<String, int> plays = const {},
    List<String> games = const ['finance_brawl', 'market_board'],
  }) {
    return builder.build(
      dateKey: '2026-07-27',
      completedIds: completedIds,
      streakDays: 0,
      weakSkills: weakSkills,
      completedLessons: completedLessons,
      arcadePlays: (id) => plays[id] ?? 0,
      activeArcadeGameIds: games,
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
      final plan = buildWith(completedLessons: {'lesson_1'});
      expect(plan.quests.first.surface, QuestSurface.academyLesson);
      // lesson_1 is done, so the next lesson node (lesson_2) should be picked.
      expect(plan.quests.first.id, 'lesson_lesson_2');
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
}
