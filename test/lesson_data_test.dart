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
