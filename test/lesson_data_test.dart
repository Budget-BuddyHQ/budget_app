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

    test('every unit after the first opens off the previous unit', () {
      for (var i = 1; i < lessonUnits.length; i++) {
        final opener = lessonUnits[i].lessons.first;
        final previousIds = lessonUnits[i - 1].lessons
            .map((lesson) => lesson.id)
            .toSet();
        expect(
          opener.prerequisites.any(previousIds.contains),
          isTrue,
          reason:
              '${opener.id} does not depend on anything in '
              '${lessonUnits[i - 1].id}, so the chain is broken there',
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
      expect(stageForAge(11), AgeStage.middleSchool);
      expect(stageForAge(13), AgeStage.middleSchool);
      expect(stageForAge(14), AgeStage.highSchool);
      expect(stageForAge(18), AgeStage.graduating);
      expect(stageForAge(21), AgeStage.adult);
      expect(stageForAge(40), AgeStage.adult);
      // Below the youngest band, still the youngest band rather than a crash.
      expect(stageForAge(5), AgeStage.middleSchool);
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
