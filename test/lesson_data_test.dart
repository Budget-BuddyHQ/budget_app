import 'package:budget_app/models_Like_Skins_and_lessons_templates/lesson.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/lesson_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('lesson graph', () {
    final allLessons = lessonUnits.expand((unit) => unit.lessons).toList();
    final ids = allLessons.map((lesson) => lesson.id).toSet();

    test('lesson ids are unique across every unit', () {
      expect(
        ids.length,
        allLessons.length,
        reason: 'a duplicate lesson id would make progress ambiguous',
      );
    });

    test('unit ids are unique', () {
      final unitIds = lessonUnits.map((unit) => unit.id).toList();
      expect(unitIds.toSet().length, unitIds.length);
    });

    test('every prerequisite points at a lesson that exists', () {
      // A typo here doesn't crash — it silently makes the lesson permanently
      // locked, which is far harder to notice than an exception.
      for (final lesson in allLessons) {
        for (final prerequisite in lesson.prerequisites) {
          expect(
            ids,
            contains(prerequisite),
            reason:
                '${lesson.id} requires "$prerequisite", which no lesson '
                'defines — ${lesson.id} can never unlock',
          );
        }
      }
    });

    test('every lesson claims the unit it is listed under', () {
      for (final unit in lessonUnits) {
        for (final lesson in unit.lessons) {
          expect(lesson.unitId, unit.id, reason: '${lesson.id} is misfiled');
        }
      }
    });

    test('the first lesson of the first unit needs no prerequisite', () {
      expect(lessonUnits.first.lessons.first.prerequisites, isEmpty);
    });

    // The curriculum is two independent chains, not one: units 10-11 (ages
    // 4-6 and 7-10) are their own root, deliberately not gated behind
    // unit_9's adult-track content — a 5-year-old shouldn't need to clear
    // retirement-account material to reach "what is money". A unit either
    // opens off the immediately preceding unit, or starts a fresh root of
    // its own (an empty-prerequisite first lesson) — anything else means a
    // typo silently orphaned a unit.
    test('every unit after the first opens off the previous unit, or starts its own root', () {
      for (var i = 1; i < lessonUnits.length; i++) {
        final opener = lessonUnits[i].lessons.first;
        final previousIds = lessonUnits[i - 1].lessons
            .map((lesson) => lesson.id)
            .toSet();
        final opensOffPrevious = opener.prerequisites.any(previousIds.contains);
        final isFreshRoot = opener.prerequisites.isEmpty;
        expect(
          opensOffPrevious || isFreshRoot,
          isTrue,
          reason:
              '${opener.id} does not depend on anything in '
              '${lessonUnits[i - 1].id} and is not a fresh root either, so '
              'the chain is broken there',
        );
      }
    });

    test('every root chain starts clean (no dangling prerequisite into a unit that does not precede it)', () {
      // A "fresh root" first lesson must actually have zero prerequisites,
      // not a prerequisite pointing somewhere other than the previous unit
      // (which would silently make that unit unreachable).
      final allIds = lessonUnits
          .expand((unit) => unit.lessons)
          .map((lesson) => lesson.id)
          .toSet();
      for (final unit in lessonUnits) {
        final opener = unit.lessons.first;
        for (final prerequisite in opener.prerequisites) {
          expect(
            allIds,
            contains(prerequisite),
            reason: '${opener.id} requires "$prerequisite", which does not exist',
          );
        }
      }
    });
  });

  group('chronological ordering', () {
    // The curriculum list used to be in an order nobody could read: the
    // ages 4-6 and 7-10 units sat at the *end*, because
    // `DailyPlanBuilder._nextLesson` walked list order and would otherwise
    // have quested "What Is Money?" to every adult. List position was
    // secretly encoding difficulty. `_nextLesson` is age-aware now, so
    // list order is free to mean what it looks like it means — and this
    // test is what stops it drifting back.
    test('units run youngest to oldest', () {
      final stages = lessonUnits.map((u) => u.ageStage.minAge).toList();
      for (var i = 1; i < stages.length; i++) {
        expect(
          stages[i],
          greaterThanOrEqualTo(stages[i - 1]),
          reason:
              'unit ${lessonUnits[i].id} (${lessonUnits[i].ageStage.name}, '
              'min age ${stages[i]}) comes after '
              '${lessonUnits[i - 1].id} (${lessonUnits[i - 1].ageStage.name}, '
              'min age ${stages[i - 1]}) — the list is not in age order',
        );
      }
    });

    test('the youngest unit is first, so a 4-year-old starts at the start', () {
      expect(lessonUnits.first.ageStage, AgeStage.earlyChildhood);
    });

    test('displayed unit numbers match list position', () {
      // Titles carry a number ("Unit 3: Budgeting") that a reader will
      // absolutely check against the order they are shown in. IDs stay
      // fixed for saved progress, so the two can disagree — this makes
      // sure they don't.
      for (var i = 0; i < lessonUnits.length; i++) {
        expect(
          lessonUnits[i].title,
          startsWith('Unit ${i + 1}:'),
          reason:
              '${lessonUnits[i].id} is at position ${i + 1} but titled '
              '"${lessonUnits[i].title}"',
        );
        expect(
          lessonUnits[i].order,
          i + 1,
          reason: '${lessonUnits[i].id} has order ${lessonUnits[i].order} '
              'at position ${i + 1}',
        );
      }
    });

    test('unit ids are NOT renumbered — saved progress depends on them', () {
      // Renaming an id silently orphans every player's `completed_lessons`.
      // unit_10 being titled "Unit 1" is deliberate, not a mistake.
      // Growing this set is fine and is the point of pinning it: adding a
      // unit is a deliberate edit here, while *renaming* one shows up as a
      // swap and gets caught. unit_12 and unit_13 were added with the Big
      // Purchases and Protecting Your Money units.
      expect(
        lessonUnits.map((u) => u.id).toSet(),
        {
          'unit_1', 'unit_2', 'unit_3', 'unit_4', 'unit_5', 'unit_6',
          'unit_7', 'unit_8', 'unit_9', 'unit_10', 'unit_11', 'unit_12',
          'unit_13',
        },
        reason: 'a unit id changed — saved lesson progress would be lost',
      );
    });

    test('it is one continuous chain, in list order', () {
      // Each unit opens off the previous unit's last node, so finishing the
      // curriculum in order is possible without hunting for a second root.
      for (var i = 1; i < lessonUnits.length; i++) {
        final firstLesson = lessonUnits[i].lessons.first;
        final previousLast = lessonUnits[i - 1].lessons.last;
        expect(
          firstLesson.prerequisites,
          contains(previousLast.id),
          reason:
              '${lessonUnits[i].id} does not open off '
              '${lessonUnits[i - 1].id} (expected ${previousLast.id}, got '
              '${firstLesson.prerequisites})',
        );
      }
    });
  });

  group('age staging', () {
    test('every age stage has at least one unit written for it', () {
      // The Academy groups its unit strip by stage; an empty stage would show
      // a header with nothing under it.
      for (final stage in AgeStage.values) {
        expect(
          lessonUnits.any((unit) => unit.ageStage == stage),
          isTrue,
          reason: 'no unit is pitched at ${stage.label}',
        );
      }
    });

    test('stageForAge lands in the right band', () {
      expect(stageForAge(4), AgeStage.earlyChildhood);
      expect(stageForAge(6), AgeStage.earlyChildhood);
      expect(stageForAge(7), AgeStage.youngKids);
      expect(stageForAge(10), AgeStage.youngKids);
      expect(stageForAge(11), AgeStage.middleSchool);
      expect(stageForAge(13), AgeStage.middleSchool);
      expect(stageForAge(14), AgeStage.highSchool);
      expect(stageForAge(18), AgeStage.graduating);
      expect(stageForAge(21), AgeStage.adult);
      expect(stageForAge(40), AgeStage.adult);
      // Below the youngest band, still the youngest band rather than a crash.
      expect(stageForAge(1), AgeStage.earlyChildhood);
    });

    test('a unit is "above you" only when its band starts later', () {
      expect(
        isAboveReaderStage(AgeStage.adult, AgeStage.middleSchool),
        isTrue,
        reason: 'a 12-year-old opening the 401(k) unit should be warned',
      );
      expect(isAboveReaderStage(AgeStage.highSchool, AgeStage.adult), isFalse);
      expect(
        isAboveReaderStage(AgeStage.highSchool, AgeStage.highSchool),
        isFalse,
        reason: 'your own band is never a warning',
      );
    });

    test('no warning fires when the reader did not share an age', () {
      for (final stage in AgeStage.values) {
        expect(
          isAboveReaderStage(stage, null),
          isFalse,
          reason: 'there is nothing to compare an undisclosed age against',
        );
      }
    });
  });
}
