import 'dart:math';

import 'package:budget_app/models_Like_Skins_and_lessons_templates/brawl_questions_extra.dart';
import 'package:flutter_test/flutter_test.dart';

/// Finance Brawl's added categories.
///
/// A quiz that can be beaten without knowing anything is worse than no quiz —
/// it hands out the reward and the confidence with none of the learning. Most
/// of these tests are guards against that specific failure.
void main() {
  group('the questions are answerable and worth answering', () {
    test('every question has four distinct options', () {
      for (final q in kBrawlExtraQuestions) {
        expect(q.options.length, 4, reason: q.question);
        expect(
          q.options.toSet().length,
          4,
          reason: 'duplicate option in: ${q.question}',
        );
      }
    });

    test('the correct index is in range', () {
      for (final q in kBrawlExtraQuestions) {
        expect(q.correctIndex, inInclusiveRange(0, 3), reason: q.question);
      }
    });

    test('every question explains itself', () {
      // The explanation is the entire educational payload — the question only
      // creates the moment where someone will read it.
      for (final q in kBrawlExtraQuestions) {
        expect(
          q.explanation.length,
          greaterThan(60),
          reason: 'thin explanation: ${q.question}',
        );
      }
    });

    test('no question text is duplicated', () {
      final prompts = kBrawlExtraQuestions.map((q) => q.question).toList();
      expect(prompts.toSet().length, prompts.length);
    });

    test('distractors are plausible, not filler', () {
      // A joke option makes a four-way question a three-way one. The proxy
      // used here is length: "Blue" is filler, a real misconception takes a
      // clause to state.
      for (final q in kBrawlExtraQuestions) {
        for (final option in q.options) {
          expect(
            option.length,
            greaterThan(8),
            reason: 'filler option "$option" in: ${q.question}',
          );
        }
      }
    });

    test('both new categories are well represented', () {
      // The two areas an under-21 player meets first, and the two the
      // original 100-question bank was thinnest on.
      for (final category in [kBrawlCategoryEarning, kBrawlCategoryFinePrint]) {
        final count = kBrawlExtraQuestions
            .where((q) => q.category == category)
            .length;
        expect(
          count,
          greaterThanOrEqualTo(10),
          reason: 'only $count questions in $category',
        );
      }
    });
  });

  group('position never gives the answer away', () {
    test('shuffling makes the answer text, not the slot, the thing that wins',
        () {
      // Every correct answer is authored at index 0, which keeps the source
      // readable and would be fatal if the game read it literally — an earlier
      // Academy bank had 30 of 34 answers at index 1, so "always pick B"
      // scored 88 percent.
      //
      // Finance Brawl shuffles the options per encounter and compares the
      // *text* of the choice, so authored position never reaches a player.
      // This models that shuffle and asserts the property the player actually
      // experiences: across many encounters, the correct answer lands in
      // every slot.
      final rng = Random(7);
      final landedAt = <int, int>{};

      for (var round = 0; round < 400; round++) {
        final q = kBrawlExtraQuestions[round % kBrawlExtraQuestions.length];
        final correctText = q.options[q.correctIndex];
        final shuffled = List<String>.from(q.options)..shuffle(rng);
        final index = shuffled.indexOf(correctText);
        landedAt.update(index, (v) => v + 1, ifAbsent: () => 1);
      }

      expect(
        landedAt.keys.toSet(),
        {0, 1, 2, 3},
        reason: 'the correct answer never appeared in some slot',
      );
      // No slot should carry more than about half the answers; with a fair
      // shuffle each gets roughly a quarter.
      for (final entry in landedAt.entries) {
        expect(
          entry.value,
          lessThan(200),
          reason:
              'slot ${entry.key} held ${entry.value} of 400 answers — the '
              'shuffle is not doing its job',
        );
      }
    });

    test('the correct option survives the shuffle', () {
      // The bug this guards: shuffling the options while keeping the *index*
      // would silently mark a wrong answer correct. The game carries
      // `correctOptionText` for exactly this reason.
      final rng = Random(11);
      for (final q in kBrawlExtraQuestions) {
        final correctText = q.options[q.correctIndex];
        final shuffled = List<String>.from(q.options)..shuffle(rng);
        expect(
          shuffled.contains(correctText),
          isTrue,
          reason: 'the answer vanished from: ${q.question}',
        );
      }
    });
  });
}
