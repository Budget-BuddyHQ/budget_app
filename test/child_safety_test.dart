import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_sim_models.dart';
import 'package:budget_app/controllers_that_updates_stats/life_sim_controller.dart';
import 'dart:math';

import 'package:budget_app/models_Like_Skins_and_lessons_templates/age_scaling_facts.dart';
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
///     four rarity tiers — a loot box — and its odds were not published.
///     They are now, for everyone, and every skin can be bought outright.
///   * Finance Brawl kept its own question bank and never went through the
///     age filter the Academy used.
///
/// Google Play's Families policy requires content accessible to children be
/// appropriate for children, and its developer programme policy requires loot
/// box odds be disclosed before purchase. These tests hold both.
void main() {
  const childBands = <AgeBand>[AgeBand.under9, AgeBand.age9to12];

  group('nothing gambling-shaped reaches a child', () {
    test('no age is promised a case restriction the app does not apply', () {
      // The case used to be gated for under-13s and the age card said so.
      // The team removed the gate, so every band now sees the same case with
      // the same disclosed odds. What must never happen is the card still
      // telling a child it is closed to them: a safety claim that is not true
      // is worse than none, because a parent reads it and stops checking.
      for (final band in AgeBand.values) {
        for (final fact in ageScalingFacts(band)) {
          expect(
            fact.detail.toLowerCase(),
            isNot(contains('random case')),
            reason: '${band.label} is told something about the case',
          );
        }
      }
    });

    test('the youngest band is shown no paid game of chance at all', () {
      // The two events that put a loot box or a skin-trading site on screen
      // gate on the *character's* age, 10 and 13. A small child can tap a
      // character up to 13 in about a minute, so the account's own band has
      // to be the gate. Nine to twelve keep it, because a loot box with its
      // real odds written out is the most useful thing in the set for them.
      expect(AgeBand.under9.hidesGamblingMechanics, isTrue);
      for (final band in AgeBand.values) {
        if (band == AgeBand.under9) continue;
        expect(band.hidesGamblingMechanics, isFalse, reason: band.name);
      }
    });

    test('and never draws one, over many lives', () {
      final gambling = kLifeEvents
          .where((e) => e.showsGamblingMechanic)
          .map((e) => e.id)
          .toSet();
      expect(gambling, isNotEmpty, reason: 'nothing carries the flag');

      for (var seed = 0; seed < 40; seed++) {
        final life = LifeSimController(
          random: Random(seed),
          allowWagering: false,
          hideGamblingMechanics: true,
        );
        for (var year = 0; year < 80 && !life.finished; year++) {
          life.takeLesson();
          life.ageUp();
          final event = life.currentEvent;
          if (event == null) continue;
          expect(
            gambling.contains(event.id),
            isFalse,
            reason: 'seed $seed served ${event.id} to a 4-to-8 account',
          );
          expect(event.isWager, isFalse);
          life.chooseOption(0);
        }
      }
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
        reason:
            'published odds sum to $total%, which is not a probability '
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
        reason:
            'this is short, plain English — the grade was never going to '
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
                'After 5 days, how much have you earned?':
            3.6,
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
        lessThan(
          readingGrade(
            'Amortisation schedules determine how principal and interest are '
            'apportioned across the life of a secured obligation.',
          ),
        ),
      );
    });
  });

  group('a child is not published to the leaderboard', () {
    // **The bug this exists to prevent, which had already happened.**
    //
    // The leaderboard view filtered with `age_band <> 'under_13'`. That was
    // correct while `under_13` was the only child band. Splitting the bucket
    // into `under_9` (ages 4-8) and `age9to12` — which deliberately **kept
    // the stored id `under_13`** so existing accounts were not re-aged —
    // created a band the filter had never heard of, and it was the youngest
    // one.
    //
    // Result: a four-to-eight-year-old's username, gold and profile image
    // were selected into a view granted to every authenticated user. Nothing
    // threw and nothing logged, because the filter was still excluding a real
    // band. It looked like it was working.
    //
    // This is a source check on the SQL rather than a database test, because
    // the migration is run by hand in a web console and the failure is
    // silent. A test that only runs against a live database is a test that
    // was not run.
    final sql = File(
      'supabase/migrations/0005_leaderboard_profile.sql',
    ).readAsStringSync();

    test('every band that reports itself as a child is excluded by name', () {
      final childBands = AgeBand.values.where((b) => b.blocksAdultTopics);
      expect(childBands, isNotEmpty, reason: 'no band identifies as a child');

      for (final band in childBands) {
        expect(
          sql.contains("'${band.id}'"),
          isTrue,
          reason:
              '${band.name} (stored as "${band.id}") is not excluded from the '
              'leaderboard view, so those players are published to every '
              'authenticated user',
        );
      }
    });

    test('the filter is a set, not a single comparison', () {
      // `<> 'under_13'` is the shape that could only ever exclude one band,
      // and is what made adding a second band silently unsafe.
      expect(
        sql.contains('not in ('),
        isTrue,
        reason: 'the age filter cannot exclude more than one band',
      );
    });

    test('the new columns are appended, so the view can be replaced', () {
      // `create or replace view` may only append columns. The first draft put
      // the new ones in the middle and failed with 42P16 in the SQL editor,
      // which is a bad place to discover it.
      final updatedAt = sql.indexOf('  updated_at,');
      final firstNew = sql.indexOf('as profile_image_url');
      expect(updatedAt, greaterThan(-1));
      expect(
        updatedAt,
        lessThan(firstNew),
        reason:
            'new columns sit before updated_at, so CREATE OR REPLACE will '
            'fail with 42P16: cannot change name of view column',
      );
    });
  });
}
