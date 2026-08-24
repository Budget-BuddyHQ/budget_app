import 'package:budget_app/models_Like_Skins_and_lessons_templates/money_habit_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('habit catalog', () {
    test('habit ids are unique', () {
      final ids = habitCatalog.map((t) => t.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('every category has at least one habit', () {
      for (final category in HabitCategory.values) {
        expect(
          habitCatalog.any((t) => t.category == category),
          isTrue,
          reason: 'no catalog habit is tagged ${category.label}',
        );
      }
    });

    test('adjustable habits have a sane min/max/step/default', () {
      for (final habit in habitCatalog) {
        final param = habit.adjustable;
        if (param == null) continue;
        expect(param.min, lessThan(param.max), reason: habit.id);
        expect(param.defaultValue, greaterThanOrEqualTo(param.min), reason: habit.id);
        expect(param.defaultValue, lessThanOrEqualTo(param.max), reason: habit.id);
        expect(param.step, greaterThan(0), reason: habit.id);
      }
    });

    test('impactFor scales linearly with units', () {
      final habit = habitCatalog.first;
      final one = habit.impactFor(1);
      final three = habit.impactFor(3);
      expect(three.moneySavedUsd, closeTo(one.moneySavedUsd * 3, 0.0001));
      expect(three.choicesKept, closeTo(one.choicesKept * 3, 0.0001));
    });

    test('habitById resolves every catalog id and rejects unknown ones', () {
      for (final habit in habitCatalog) {
        expect(habitById(habit.id), isNotNull, reason: habit.id);
      }
      expect(habitById('not_a_real_habit'), isNull);
    });

    test('custom habits round-trip through storage maps', () {
      final habit = customHabitFromMap(const <String, dynamic>{
        'id': 'custom_habit_1',
        'title': 'Bike instead of rideshare',
        'blurb': 'Use the bike for one short trip.',
        'money_saved_usd': 8.5,
      });

      expect(habit.id, 'custom_habit_1');
      expect(habit.title, 'Bike instead of rideshare');
      expect(habit.impactFor(1).moneySavedUsd, 8.5);
      expect(habit.impactFor(1).choicesKept, 1);
      expect(customHabitToMap(habit), <String, dynamic>{
        'id': 'custom_habit_1',
        'title': 'Bike instead of rideshare',
        'blurb': 'Use the bike for one short trip.',
        'money_saved_usd': 8.5,
      });
    });

    test('habitTemplateById can resolve custom habits', () {
      final custom = customHabitFromMap(const <String, dynamic>{
        'id': 'custom_habit_resolve',
        'title': 'Use leftovers',
        'blurb': 'Turn leftovers into dinner.',
        'money_saved_usd': 12,
      });

      expect(
        habitTemplateById(
          'custom_habit_resolve',
          customHabits: <HabitTemplate>[custom],
        ),
        custom,
      );
      expect(habitTemplateById(habitCatalog.first.id), habitCatalog.first);
    });
  });

  group('habit challenges', () {
    final allTasks = habitChallenges.expand((c) => c.tasks).toList();
    final ids = allTasks.map((t) => t.id).toSet();

    test('challenge task ids are unique across every challenge', () {
      expect(ids.length, allTasks.length);
    });

    test('every challenge task links to a real catalog template', () {
      for (final task in allTasks) {
        expect(
          task.template,
          isNotNull,
          reason: '${task.id} points at templateId "${task.templateId}", '
              'which no catalog entry defines',
        );
      }
    });

    test('every prerequisite points at a challenge task that exists', () {
      for (final task in allTasks) {
        for (final prerequisite in task.prerequisites) {
          expect(
            ids,
            contains(prerequisite),
            reason: '${task.id} requires "$prerequisite", which does not exist',
          );
        }
      }
    });

    test('the first task of every challenge needs no prerequisite', () {
      for (final challenge in habitChallenges) {
        expect(
          challenge.tasks.first.prerequisites,
          isEmpty,
          reason: '${challenge.id} cannot ever start',
        );
      }
    });

    test('challenge ids are unique', () {
      final challengeIds = habitChallenges.map((c) => c.id).toList();
      expect(challengeIds.toSet().length, challengeIds.length);
    });
  });

  group('jar stage', () {
    test('forXp lands in the right band', () {
      expect(JarStage.forXp(0), JarStage.empty);
      expect(JarStage.forXp(59), JarStage.empty);
      expect(JarStage.forXp(60), JarStage.started);
      expect(JarStage.forXp(219), JarStage.started);
      expect(JarStage.forXp(220), JarStage.halfFull);
      expect(JarStage.forXp(600), JarStage.overflowing);
      expect(JarStage.forXp(10000), JarStage.overflowing);
    });

    test('progressToNext is 0 right at a stage boundary and 1 right before the next', () {
      expect(JarStage.empty.progressToNext(0), 0);
      expect(JarStage.empty.progressToNext(59), closeTo(1, 0.02));
    });

    test('the final stage always reports full progress', () {
      expect(JarStage.overflowing.progressToNext(600), 1.0);
      expect(JarStage.overflowing.progressToNext(999999), 1.0);
      expect(JarStage.overflowing.next, isNull);
    });

    test('stage thresholds strictly increase', () {
      final values = JarStage.values;
      for (var i = 1; i < values.length; i++) {
        expect(values[i].xpThreshold, greaterThan(values[i - 1].xpThreshold));
      }
    });
  });

  group('jar mood', () {
    test('forDaysSinceActive lands in the right band', () {
      expect(JarMood.forDaysSinceActive(0), JarMood.onARoll);
      expect(JarMood.forDaysSinceActive(1), JarMood.onARoll);
      expect(JarMood.forDaysSinceActive(2), JarMood.steady);
      expect(JarMood.forDaysSinceActive(4), JarMood.steady);
      expect(JarMood.forDaysSinceActive(5), JarMood.slipping);
      expect(JarMood.forDaysSinceActive(999), JarMood.slipping);
    });
  });

  group('HabitImpact arithmetic', () {
    test('addition sums each field independently', () {
      const a = HabitImpact(moneySavedUsd: 1, choicesKept: 2);
      const b = HabitImpact(moneySavedUsd: 4, choicesKept: 5);
      final sum = a + b;
      expect(sum.moneySavedUsd, 5);
      expect(sum.choicesKept, 7);
    });

    test('round-trips through toMap/fromMap', () {
      const impact = HabitImpact(moneySavedUsd: 1.5, choicesKept: 2.25);
      final restored = HabitImpact.fromMap(impact.toMap());
      expect(restored.moneySavedUsd, impact.moneySavedUsd);
      expect(restored.choicesKept, impact.choicesKept);
    });
  });

  group('HabitDateKeys', () {
    test('lastDayKeys returns count days, oldest first, ending today', () {
      final now = DateTime(2026, 8, 22);
      final keys = HabitDateKeys.lastDayKeys(7, now: now);
      expect(keys.length, 7);
      expect(keys.last, '2026-08-22');
      expect(keys.first, '2026-08-16');
    });

    test('daysSince is 0 for today and grows for older dates', () {
      final now = DateTime(2026, 8, 22);
      expect(HabitDateKeys.daysSince('2026-08-22', now: now), 0);
      expect(HabitDateKeys.daysSince('2026-08-20', now: now), 2);
      expect(HabitDateKeys.daysSince(null, now: now), 999);
      expect(HabitDateKeys.daysSince('not-a-date', now: now), 999);
    });

    test('pruneToTrailing drops entries older than the window', () {
      final now = DateTime(2026, 8, 22);
      final log = <String, int>{
        '2026-08-22': 1,
        '2026-08-15': 1,
        '2026-08-01': 1,
      };
      final pruned = HabitDateKeys.pruneToTrailing(log, 14, now: now);
      expect(pruned.containsKey('2026-08-22'), isTrue);
      expect(pruned.containsKey('2026-08-15'), isTrue);
      expect(pruned.containsKey('2026-08-01'), isFalse);
    });
  });
}
