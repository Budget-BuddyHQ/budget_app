import 'package:budget_app/models_Like_Skins_and_lessons_templates/lesson.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/lesson_data.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/quiz_bank.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
