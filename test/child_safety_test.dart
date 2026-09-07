import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/models_Like_Skins_and_lessons_templates/avatar_skin.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/player_profile.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/reading_grade.dart';

/// What a child must not be able to reach.
///
/// **Reported as:** *"we are basically promoting gambling to 4-8 year olds"*,
/// alongside a screenshot of an account set to "8 or under" being asked *"What
/// is a CD Ladder strategy?"*
///
/// Both were true, and both had passed every test in the suite, because the
/// suite tested the paths that had gates and nothing tested the paths that
/// did not:
///
///   * `openSkinCase()` charges 180 gold for a weighted-random pull across
///     four rarity tiers — a loot box — with **no age check anywhere on the
///     path to it**.
///   * Finance Brawl kept its own question bank and never went through the
///     age filter the Academy used.
///
/// Google Play's Families policy requires content accessible to children be
/// appropriate for children, and its developer programme policy requires loot
/// box odds be disclosed before purchase. These tests hold both.
void main() {
  const childBands = <AgeBand>[AgeBand.under9, AgeBand.age9to12];

  group('nothing gambling-shaped reaches a child', () {
    test('under-13s cannot open a randomised case', () {
      for (final band in childBands) {
        expect(
          band.allowsRandomisedRewards,
          isFalse,
          reason: '${band.name} can open a loot box',
        );
      }
    });

    test('teens and adults still can', () {
      // The fix is an age gate, not a removal. Blocking everybody would be a
      // different product, and would not be what the policy asks for.
      for (final band in [
        AgeBand.teen13to15,
        AgeBand.teen16to17,
        AgeBand.adult18plus,
      ]) {
        expect(band.allowsRandomisedRewards, isTrue);
      }
    });

    test('undisclosed age is treated as an adult, deliberately', () {
      // Guessing "child" would gate features behind answering a personal
      // question, which teaches children to over-share to unlock things —
      // the same reasoning the wagering gate already uses.
      expect(AgeBand.undisclosed.allowsRandomisedRewards, isTrue);
    });

    test('no child band can wager, on any surface', () {
      for (final band in childBands) {
        expect(band.allowsWagering, isFalse);
        expect(band.isMinorUnder13, isTrue);
      }
    });

    test('the odds exist and are complete, so they can be disclosed', () {
      // Play requires loot box odds be shown before purchase. That is only
      // possible if every rarity actually has a published number.
      for (final rarity in SkinRarity.values) {
        final odds = oddsForRarity(rarity);
        expect(odds.rarity, rarity);
        expect(
          odds.percent,
          greaterThan(0),
          reason: '${rarity.name} has no published drop rate',
        );
      }

      final total = SkinRarity.values
          .map((r) => oddsForRarity(r).percent)
          .reduce((a, b) => a + b);
      expect(
        total,
        closeTo(100, 0.51),
        reason: 'published odds sum to $total%, which is not a probability '
            'distribution and would be a false disclosure',
      );
    });
  });

  group('adult financial instruments do not reach children', () {
    test('the CD ladder question is caught', () {
      // The exact question from the report. It is four short words and scores
      // as easy prose, which is why a reading grade alone let it through.
      const prompt = 'What is a CD Ladder strategy?';
      expect(
        readingGrade(prompt),
        lessThan(AgeBand.under9.maxReadingGrade + 4),
        reason: 'this is short, plain English — the grade was never going to '
            'catch it, which is the whole point of the topic check',
      );
      expect(mentionsAdultTopic(prompt), isTrue);
    });

    test('other adult instruments are caught too', () {
      for (final prompt in const <String>[
        'How does a Roth IRA differ from a traditional one?',
        'What does a vesting schedule decide?',
        'What is the APR on this card?',
        'What are capital gains?',
        'What does escrow mean?',
      ]) {
        expect(
          mentionsAdultTopic(prompt),
          isTrue,
          reason: '"$prompt" would reach an eight-year-old',
        );
      }
    });

    test('ordinary money words are NOT blocked', () {
      // The list names instruments a child cannot have met, not anything that
      // sounds financial. A nine-year-old can and should learn about saving,
      // borrowing and tax — blocking those would make the youngest band
      // useless, which is a worse failure than the one being fixed.
      for (final prompt in const <String>[
        'You save 3 coins a week. How much after 4 weeks?',
        'Is a bus fare a need or a want?',
        'Why do people pay tax?',
        'What happens if you borrow money and do not pay it back?',
        'Which costs less per litre?',
      ]) {
        expect(
          mentionsAdultTopic(prompt),
          isFalse,
          reason: '"$prompt" is fine for a child and is being withheld',
        );
      }
    });

    test('only the youngest bands get the topic block', () {
      for (final band in childBands) {
        expect(band.blocksAdultTopics, isTrue);
      }
      for (final band in [
        AgeBand.teen13to15,
        AgeBand.teen16to17,
        AgeBand.adult18plus,
      ]) {
        expect(
          band.blocksAdultTopics,
          isFalse,
          reason: 'a ${band.label} reader should meet a mortgage by name',
        );
      }
    });
  });

  group('the reading formula agrees with the generated lookup', () {
    test('the Dart and Python implementations do not drift', () {
      // Two callers, one formula. The Academy uses a generated table and
      // Finance Brawl computes at runtime; if these ever disagree, one of the
      // two games is banding its questions wrongly and nothing would say so.
      const samples = <String, double>{
        'You do the dishes every day and get 1 dollar each time. '
            'After 5 days, how much have you earned?': 3.6,
        'Diversification reduces risk by:': 18.4,
      };
      samples.forEach((text, expected) {
        expect(
          readingGrade(text),
          closeTo(expected, 3.0),
          reason: 'the runtime grader has drifted from the measured values',
        );
      });
    });

    test('a simple sentence grades below a complex one', () {
      expect(
        readingGrade('You have 3 coins. You get 2 more. How many now?'),
        lessThan(readingGrade(
          'Amortisation schedules determine how principal and interest are '
          'apportioned across the life of a secured obligation.',
        )),
      );
    });
  });
}
