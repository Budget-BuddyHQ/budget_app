import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/models_Like_Skins_and_lessons_templates/lesson.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/lesson_data.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/progression_service.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/academy/curriculum_sources_card.dart';

/// The Academy has to agree with itself about how big it is.
///
/// Two counts were on screen in the same tab, both called "lessons", and they
/// disagreed: the sourcing card said 63 (teaching nodes only, because it
/// counts the questions separately in the same sentence) and Your Learning
/// Stats said X/89 (every node, quizzes and unit tests included). Neither was
/// a bug on its own. Together they made the app contradict itself about its
/// own curriculum, on the one screen whose entire pitch is that the content
/// is checked and trustworthy.
///
/// These tests pin them to the same *definition* rather than to a number, so
/// writing lesson 64 does not fail the suite — only disagreeing does.
void main() {
  List<Lesson> allNodes() => lessonUnits.expand((unit) => unit.lessons).toList();

  group('the two lesson counts agree', () {
    test('the sourcing card and the stats card use one definition', () {
      expect(
        CurriculumSourcesCard.lessonCount,
        ProgressionService().teachingTotal,
        reason:
            'the Academy is claiming two different sizes for itself — the '
            '"Every lesson is sourced" card and "Your learning stats" have '
            'drifted apart again',
      );
    });

    test('teaching lessons exclude quizzes and unit tests', () {
      final teaching = allNodes()
          .where((n) => n.type == LessonNodeType.lesson)
          .length;

      expect(ProgressionService().teachingTotal, teaching);
      // The whole-path total is deliberately still bigger. It drives the
      // progress bar and the unlock rules, where a quiz genuinely is a step
      // you have to finish.
      expect(ProgressionService().totalCount, greaterThan(teaching));
    });
  });

  group('completed can never exceed the total shown beside it', () {
    test('finishing every quiz does not inflate the lesson count', () {
      // The bug this guards against is the tempting half-fix: change the
      // denominator to 63 and leave the numerator counting all 89 node
      // completions. A player who had done the quizzes would then be shown
      // something like 71/63.
      final assessmentIds = allNodes()
          .where((n) => n.type != LessonNodeType.lesson)
          .map((n) => n.id);

      final progression = ProgressionService(
        initialCompletedLessons: assessmentIds,
      );

      expect(progression.teachingCompleted, 0);
      expect(
        progression.teachingCompleted,
        lessThanOrEqualTo(progression.teachingTotal),
      );
    });

    test('completing everything reads as full, not over', () {
      final progression = ProgressionService(
        initialCompletedLessons: allNodes().map((n) => n.id),
      );

      expect(progression.teachingCompleted, progression.teachingTotal);
    });
  });
}
