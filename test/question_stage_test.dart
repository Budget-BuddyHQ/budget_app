import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/models_Like_Skins_and_lessons_templates/lesson.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/lesson_data.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/player_profile.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/question_stage.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/quiz_bank.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/reading_grade.dart';

/// Nobody is quizzed above their age.
///
/// # The two reports, which were one bug
///
/// > *"make sure that no 4 year old or someone will get the wrong questions"*
///
/// > *"the questions are a bit shift because my little brother of 10 year of
/// > age is struggling with questions that are 8 and below"*
///
/// The second is the diagnosis. He was served the under-9 set and found it
/// too hard, which means the **set was mislabelled**. It was: fifty questions
/// sat in the four-to-eight reading window, and among them were *"A 401(k) is
/// best described as:"*, *"Which best describes a bond?"* and *"Which form
/// tells your employer how much tax to withhold?"* — all of which score as
/// easy reading because Flesch-Kincaid counts syllables and nothing else.
///
/// Two gates were missing. The **topic** gate existed and was wired into the
/// life sim and Finance Brawl but never into the Academy quiz. The **stage**
/// gate did not exist, even though every unit has carried a hand-assigned
/// `ageStage` all along and `ageAppropriateQuestions` claimed in its own doc
/// comment to be using it.
///
/// These tests name the actual questions, so a regression reads as the
/// specific thing that went wrong rather than as a count changing.
void main() {
  /// Every question a band can be served, across the whole bank.
  List<QuizQuestion> served(AgeBand band) =>
      ageAppropriateQuestions(allQuizQuestions.toList(), band);

  group('a four-to-eight year old', () {
    late List<QuizQuestion> pool;
    late Set<String> prompts;

    setUp(() {
      pool = served(AgeBand.under9);
      prompts = pool.map((q) => q.prompt.toLowerCase()).toSet();
    });

    test('is never asked about a 401(k), a bond or a W-4', () {
      // The three that were actually being served. Named individually so a
      // failure says which one came back.
      for (final phrase in <String>[
        '401(k)',
        'describes a bond',
        'how much tax to withhold',
        'gross pay and net pay',
        'year to date',
      ]) {
        expect(
          prompts.any((p) => p.contains(phrase)),
          isFalse,
          reason: 'an under-9 is being asked about "$phrase"',
        );
      }
    });

    test('gets nothing from a unit written for older readers', () {
      for (final question in pool) {
        final stage = kQuestionStage[question.id];
        if (stage == null) continue;
        expect(
          stage.index,
          lessThanOrEqualTo(AgeStage.youngKids.index),
          reason:
              '"${question.prompt}" is from a ${stage.name} unit and was '
              'served to a four-year-old',
        );
      }
    });

    test('gets nothing naming an adult financial instrument', () {
      // The floor that does not relax. Checks options too: a question can ask
      // something innocent and offer four answers naming instruments.
      for (final question in pool) {
        expect(
          mentionsAdultTopic(question.prompt),
          isFalse,
          reason: '"${question.prompt}" names an adult topic',
        );
        for (final option in question.options) {
          expect(
            mentionsAdultTopic(option),
            isFalse,
            reason: '"${question.prompt}" offers "$option" as an answer',
          );
        }
      }
    });

    test('still has enough questions to not repeat itself', () {
      // A correct pool that is too small is its own failure: repetition
      // inside one sitting is what the spaced-repetition work exists to
      // avoid. Twenty is roughly three sittings without a repeat.
      expect(
        pool.length,
        greaterThanOrEqualTo(20),
        reason: 'the under-9 pool is too thin to draw from',
      );
    });
  });

  group('a ten year old', () {
    test('is not served the adult units either', () {
      // The actual complaint. A 10-year-old sits in `age9to12`, so the
      // ceiling is the middle-school units — not retirement and not credit
      // reports, both of which were reachable on reading grade alone.
      for (final question in served(AgeBand.age9to12)) {
        final stage = kQuestionStage[question.id];
        if (stage == null) continue;
        expect(
          stage.index,
          lessThanOrEqualTo(AgeStage.middleSchool.index),
          reason: '"${question.prompt}" is ${stage.name} content',
        );
      }
    });

    test('gets more than a four year old, and less than an adult', () {
      // The ladder has to actually be a ladder. If this ever inverts, a band
      // boundary was written backwards.
      final young = served(AgeBand.under9).length;
      final middle = served(AgeBand.age9to12).length;
      final adult = served(AgeBand.adult18plus).length;

      expect(young, lessThan(middle));
      expect(middle, lessThan(adult));
    });
  });

  group('the ladder', () {
    test('every band except adults is served strictly less than the bank', () {
      final total = allQuizQuestions.length;
      for (final band in AgeBand.values) {
        if (band == AgeBand.adult18plus) continue;
        expect(
          served(band).length,
          lessThan(total),
          reason: '${band.label} is being served the entire bank',
        );
      }
    });

    test('adults are not served the infant units', () {
      // Deliberate, and it is the floor doing its job. An eighteen-year-old
      // asking "what is a piggy bank for?" is the other way this can be
      // wrong. What matters is that the floor sits low enough to still reach
      // plain, easy questions — see `minQuizStage`, which replaced a reading
      // grade floor that was withholding 59% of the bank from adults.
      final adult = served(AgeBand.adult18plus);
      expect(adult.length, greaterThan(allQuizQuestions.length * 0.7));

      for (final question in adult) {
        final stage = kQuestionStage[question.id];
        if (stage == null) continue;
        expect(stage.index, greaterThanOrEqualTo(AgeStage.middleSchool.index));
      }
    });

    test('every question in the bank belongs to a unit', () {
      // The stage map is built by walking the units. A question reachable
      // from no unit gets no stage and is kept by default, which is the safe
      // failure — but it is still a gap, and it should be visible.
      final missing = [
        for (final q in allQuizQuestions)
          if (!kQuestionStage.containsKey(q.id)) q.id,
      ];
      expect(
        missing,
        isEmpty,
        reason: 'these questions have no unit, so no age: $missing',
      );
    });
  });

  group('reading above your age is still allowed', () {
    test('a young reader on an adult unit gets the lesson and no quiz', () {
      // The rule, stated once: **you may read above your age, you are not
      // tested above it.** The Academy warns and then lets you read; being
      // quizzed is different, because a quiz says "you should know this" and
      // telling a six-year-old they got vesting wrong teaches them they are
      // bad at money.
      //
      // `lesson_detail_screen.dart` renders the lesson body when the quiz is
      // empty, so this is a supported state rather than a broken screen.
      final retirement = lessonUnits.firstWhere((u) => u.id == 'unit_9');
      expect(retirement.ageStage, AgeStage.adult);

      final anyQuiz = [
        for (final lesson in retirement.lessons) ...quizFor(lesson.id),
      ];
      expect(anyQuiz, isNotEmpty, reason: 'the unit has questions at all');

      expect(
        ageAppropriateQuestions(anyQuiz, AgeBand.under9),
        isEmpty,
        reason: 'a four-year-old should not be tested on retirement',
      );
      expect(
        ageAppropriateQuestions(anyQuiz, AgeBand.adult18plus),
        isNotEmpty,
        reason: 'and an adult still gets the quiz',
      );
    });
  });
}
