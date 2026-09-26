import 'package:budget_app/models_Like_Skins_and_lessons_templates/lesson.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/lesson_data.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/player_profile.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/quiz_bank.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/reading_grade.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('nobody meets an empty quiz they cannot avoid', () {
    // Reported by playing the app: a played-through quiz screen showed a
    // one-line placeholder and a "Complete Lesson" button with no question on
    // it. Root cause was `AgeBand.minQuizStage` — the floor that keeps an
    // older reader from feeling patronised by an early-childhood question —
    // zeroing out a whole node when *every* question in it was tagged for the
    // youngest band. Unit 1, "Money Is Real", is written for the very
    // youngest players on purpose, and every band above them still passes
    // through it, since units chain by prerequisite.
    //
    // The floor is still real for the *other* direction (a young reader must
    // never see an advanced or adult-topic unit's quiz) — the second test
    // below holds that.
    test('an adult never meets a quiz or unit test with nothing in it', () {
      final empty = <String>[];
      for (final unit in lessonUnits) {
        for (final lesson in unit.lessons) {
          if (lesson.type == LessonNodeType.lesson) continue;
          final raw = quizFor(lesson.id);
          if (raw.isEmpty) continue; // not a real assessment node
          if (ageAppropriateQuestions(raw, AgeBand.adult18plus).isEmpty) {
            empty.add('${unit.id}/${lesson.id}');
          }
        }
      }
      expect(
        empty,
        isEmpty,
        reason:
            'these nodes have questions but none pass the adult floor: $empty',
      );
    });

    test(
      'a young reader still gets nothing on an advanced, adult-topic unit',
      () {
        // The ceiling this fix must never touch: an under-9 reader must never
        // be handed a question written for an older stage or naming an adult
        // topic, even when relaxing the floor elsewhere.
        final advanced = lessonUnits.firstWhere(
          (u) => u.ageStage.index >= AgeStage.highSchool.index,
        );
        for (final lesson in advanced.lessons) {
          if (lesson.type == LessonNodeType.lesson) continue;
          for (final q in ageAppropriateQuestions(
            quizFor(lesson.id),
            AgeBand.under9,
          )) {
            expect(mentionsAdultTopic(q.prompt), isFalse, reason: q.id);
            expect(q.options.any(mentionsAdultTopic), isFalse, reason: q.id);
          }
        }
      },
    );
  });

  group('answer key', () {
    test('is not gameable by always picking one position', () {
      // Regression guard: the original bank had 30 of 34 answers at index 1,
      // so "always pick B" scored ~88% without reading the questions.
      final counts = <int, int>{};
      for (final question in allQuizQuestions) {
        counts.update(
          question.correctIndex,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
      final total = allQuizQuestions.length;
      final worst = counts.values.reduce((a, b) => a > b ? a : b);

      expect(
        worst / total,
        lessThanOrEqualTo(0.4),
        reason:
            'One option position holds $worst of $total answers: $counts. '
            'Spread the key so guessing a single position cannot pass.',
      );
      expect(answerKeyIsBalanced, isTrue);
    });

    test('every correctIndex is within range', () {
      for (final question in allQuizQuestions) {
        expect(
          question.correctIndex,
          inInclusiveRange(0, question.options.length - 1),
          reason: '${question.id} points outside its option list',
        );
      }
    });
  });

  group('question quality', () {
    test('every question explains itself', () {
      for (final question in allQuizQuestions) {
        expect(
          question.explanation.trim(),
          isNotEmpty,
          reason: '${question.id} has no explanation',
        );
      }
    });

    test('every question offers four distinct options', () {
      for (final question in allQuizQuestions) {
        expect(
          question.options.length,
          4,
          reason: '${question.id} should offer exactly four options',
        );
        expect(
          question.options.toSet().length,
          question.options.length,
          reason: '${question.id} repeats an option',
        );
      }
    });

    test('question ids are unique', () {
      final ids = allQuizQuestions.map((question) => question.id).toList();
      expect(ids.toSet().length, ids.length, reason: 'duplicate question id');
    });
  });

  group('coverage', () {
    test('every quiz and unit-test node has questions', () {
      final assessmentNodes = lessonUnits
          .expand((unit) => unit.lessons)
          .where((lesson) => lesson.type != LessonNodeType.lesson);

      for (final node in assessmentNodes) {
        expect(
          quizFor(node.id),
          isNotEmpty,
          reason: '${node.id} (${node.title}) has no questions',
        );
      }
    });

    test('every unit has practice questions', () {
      for (final unit in lessonUnits) {
        expect(
          practiceFor(unit.id),
          isNotEmpty,
          reason: '${unit.id} has no practice set',
        );
      }
    });
  });
}
