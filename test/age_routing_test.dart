import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/models_Like_Skins_and_lessons_templates/player_profile.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/question_reading_levels.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/quiz_bank.dart';

/// Serving a six-year-old and an eighteen-year-old out of one question bank.
///
/// **The state this replaced.** 177 questions measured at Flesch-Kincaid
/// reading grades -2.4 to 18.4, served identically to everybody, with only 35
/// of them carrying any difficulty tag at all. A six-year-old was shown
/// *"Diversification reduces risk by:"* and an adult was shown *"you do the
/// dishes every day and get \$1 each time"*. Both are good questions; neither
/// reached the person it was written for.
///
/// The `under13` band was also one bucket from four to twelve — the comment
/// on `prefersSimpleWording` admitted it: *"there is no single honest age for
/// it"*.
void main() {
  final everything = allQuizQuestions.toList();

  group('the bank is measured, and the measurement is current', () {
    test('every question has a reading grade', () {
      // The lookup is generated from the bank by
      // `tool/measure_question_reading_level.py`. A missing entry means
      // somebody added a question and did not re-run the tool.
      final missing = everything
          .where((q) => !kQuestionReadingGrade.containsKey(q.id))
          .map((q) => q.id)
          .toList();
      expect(
        missing,
        isEmpty,
        reason:
            '${missing.length} questions have no measured reading grade — '
            'run: python tool/measure_question_reading_level.py --write',
      );
    });

    test('the bank really does span a usable range', () {
      // If every question landed at one grade, banding would be theatre.
      final grades = kQuestionReadingGrade.values.toList()..sort();
      expect(grades.first, lessThan(3.0));
      expect(grades.last, greaterThan(12.0));
    });
  });

  group('no band is starved', () {
    test('every band gets a workable number of questions', () {
      final counts = questionsPerBand;
      for (final entry in counts.entries) {
        expect(
          entry.value,
          greaterThanOrEqualTo(30),
          reason:
              '${entry.key.name} can only be served ${entry.value} questions '
              'out of ${everything.length}. A band that thin repeats itself '
              'inside one sitting, which is what the spaced-repetition work '
              'exists to prevent',
        );
      }
    });

    test('the youngest and oldest bands get different sets', () {
      final young = ageAppropriateQuestions(everything, AgeBand.under9)
          .map((q) => q.id)
          .toSet();
      final adult = ageAppropriateQuestions(everything, AgeBand.adult18plus)
          .map((q) => q.id)
          .toSet();

      expect(young, isNotEmpty);
      expect(adult, isNotEmpty);
      // Some overlap is right — plenty of money ideas are worth asking at any
      // age. Being *identical* is the bug.
      expect(
        young.difference(adult),
        isNotEmpty,
        reason: 'the youngest band gets nothing the adult band does not',
      );
      expect(
        adult.difference(young),
        isNotEmpty,
        reason: 'an adult is being served exactly the six-year-old set',
      );
    });

    test('the hardest questions never reach the youngest band', () {
      final young = ageAppropriateQuestions(everything, AgeBand.under9);
      for (final q in young) {
        final grade = kQuestionReadingGrade[q.id];
        if (grade == null) continue;
        expect(
          grade,
          lessThanOrEqualTo(AgeBand.under9.maxReadingGrade),
          reason: '"${q.prompt}" is grade $grade and went to a 4-8 year old',
        );
      }
    });

    test('an adult is not fed years-below material', () {
      final adult = ageAppropriateQuestions(everything, AgeBand.adult18plus);
      for (final q in adult) {
        final grade = kQuestionReadingGrade[q.id];
        if (grade == null) continue;
        expect(grade, greaterThanOrEqualTo(AgeBand.adult18plus.minReadingGrade));
      }
    });
  });

  group('it fails safe', () {
    test('an empty source stays empty rather than inventing questions', () {
      expect(
        ageAppropriateQuestions(const [], AgeBand.under9),
        isEmpty,
      );
    });

    test('a node with nothing in range returns the unfiltered set', () {
      // A quiz that is slightly too hard beats a quiz with no questions in
      // it. This is the branch that guarantees a player who asked for a quiz
      // gets one.
      final hardOnly = everything
          .where((q) => (kQuestionReadingGrade[q.id] ?? 0) > 12)
          .toList();
      expect(hardOnly, isNotEmpty, reason: 'no hard questions to test with');

      final served = ageAppropriateQuestions(hardOnly, AgeBand.under9);
      expect(
        served.length,
        hardOnly.length,
        reason:
            'filtering emptied the list and it was not restored — a player '
            'would see a quiz with nothing in it',
      );
    });

    test('undisclosed gets the middle, not the easiest or the hardest', () {
      // Guessing young is patronising; guessing old locks them out.
      expect(
        AgeBand.undisclosed.maxReadingGrade,
        greaterThan(AgeBand.age9to12.maxReadingGrade),
      );
      expect(
        AgeBand.undisclosed.maxReadingGrade,
        lessThan(AgeBand.adult18plus.maxReadingGrade),
      );
    });
  });

  group('splitting the bucket did not open a gate', () {
    test('both halves of the old under-13 band keep every protection', () {
      for (final band in [AgeBand.under9, AgeBand.age9to12]) {
        expect(band.allowsWagering, isFalse, reason: '${band.name} can wager');
        expect(band.isMinorUnder13, isTrue);
        expect(band.prefersSimpleWording, isTrue);
      }
    });

    test('the 9-to-12 band keeps the old stored id, so nobody is re-aged', () {
      // Every account created before the split is stored as `under_13`.
      // Reading that back has to land somebody in 9-12, not in 4-8.
      expect(AgeBand.age9to12.id, 'under_13');
      expect(AgeBand.fromId('under_13'), AgeBand.age9to12);
      expect(AgeBand.fromId('under_9'), AgeBand.under9);
    });

    test('bands get harder in order', () {
      const ordered = [
        AgeBand.under9,
        AgeBand.age9to12,
        AgeBand.teen13to15,
        AgeBand.teen16to17,
        AgeBand.adult18plus,
      ];
      for (var i = 1; i < ordered.length; i++) {
        expect(
          ordered[i].maxReadingGrade,
          greaterThan(ordered[i - 1].maxReadingGrade),
          reason: '${ordered[i].name} is not harder than ${ordered[i - 1].name}',
        );
      }
    });
  });
}
