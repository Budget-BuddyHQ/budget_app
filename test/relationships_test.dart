import 'dart:math';

import 'package:budget_app/controllers_that_updates_stats/life_sim_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_ending.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/relationship.dart';
import 'package:flutter_test/flutter_test.dart';

/// People who can drift away.
///
/// **What this replaced.** Relationships were a `List<String>` — bare names,
/// every one identical, nothing about any of them ever changing. You could
/// press "Spend time with Priya" forty times for +8 Happiness each and it
/// meant exactly as much the fortieth time as the first.
///
/// That left the game unable to say the thing it most needed to. There is an
/// ending called **Rich but Lonely** and nothing in the simulation could make
/// you lonely: it fired on `netWorth >= 3000 && happiness < 45`, so it was
/// reachable by simply overworking and had no more to do with people than any
/// other ending.
///
/// The tuning is the delicate part and it is what most of this file measures.
/// Drift has to be slow enough that a run must genuinely neglect somebody for
/// years, and fast enough that a whole life spent on work ends alone.
void main() {
  /// Ages [years] years, answering anything that comes up.
  ///
  /// `ageUp` refuses while an event is pending, so a bare loop of `ageUp()`
  /// spins on the spot without a single birthday — which is exactly what the
  /// first version of these tests did, and why they reported that nobody is
  /// ever lost after 200 years.
  void advance(LifeSimController life, int years) {
    for (var i = 0; i < years && !life.finished; i++) {
      if (life.currentEvent != null) life.chooseOption(0);
      life.ageUp();
    }
  }

  /// A run with one friend already in it.
  LifeSimController withFriend({int age = 20}) {
    final life = LifeSimController(
      random: Random(9),
      initialAge: age,
      startMoney: 2000,
    );
    life.debugAddPerson('Priya');
    return life;
  }

  group('closeness moves the right way', () {
    test(
      'a new person starts partway, not at nothing and not at everything',
      () {
        final life = withFriend();
        expect(life.people.single.closeness, kStartingCloseness);
        expect(kStartingCloseness, inInclusiveRange(40, 75));
      },
    );

    test('time together raises it more than a gift does', () {
      // The comparison the two actions exist to make, and the one this app
      // would want to teach even if it were not also true.
      final a = withFriend();
      a.spendTimeWith('Priya');
      final fromTime = a.people.single.closeness - kStartingCloseness;

      final b = withFriend();
      b.giveGift('Priya');
      final fromGift = b.people.single.closeness - kStartingCloseness;

      expect(fromTime, greaterThan(fromGift));
      expect(fromGift, greaterThan(0), reason: 'a gift should still count');
    });

    test('a year with no contact costs a little', () {
      final life = withFriend();
      final before = life.people.single.closeness;
      life.ageUp();
      expect(life.people.single.closeness, lessThan(before));
    });

    test('a visit buys several years of buffer', () {
      // Not a freeze -- the year still passes -- but time together is worth
      // several years of drift, so seeing somebody every few years holds the
      // relationship steady. With several people and sixty years to fill,
      // demanding an action every single year for each of them would be
      // book-keeping rather than a decision.
      final life = withFriend();
      final before = life.people.single.closeness;
      life.spendTimeWith('Priya');
      advance(life, 3);
      expect(
        life.people.single.closeness,
        greaterThanOrEqualTo(before),
        reason:
            'three years after a visit, a friendship should be no worse '
            'off than before it',
      );
    });

    test('closeness never leaves 0..100', () {
      final life = withFriend();
      for (var i = 0; i < 40; i++) {
        life.spendTimeWith('Priya');
      }
      expect(life.people.single.closeness, lessThanOrEqualTo(100));

      // By name, not `.single` -- eighty years of play meets people, so the
      // list is not one entry long any more. That is the simulation working.
      final ignored = withFriend();
      advance(ignored, 80);
      final priya = ignored.people.firstWhere((p) => p.name == 'Priya');
      expect(priya.closeness, greaterThanOrEqualTo(0));
      expect(priya.closeness, lessThanOrEqualTo(100));
    });
  });

  group('the drift is tuned, not arbitrary', () {
    /// Years of total neglect before somebody stops counting as present.
    int yearsToLose(RelationshipKind kind) {
      final life = LifeSimController(random: Random(3), initialAge: 20);
      life.debugAddPerson('Sam', kind: kind);
      var years = 0;
      while (life.people.single.isPresent && years < 200 && !life.finished) {
        if (life.currentEvent != null) life.chooseOption(0);
        life.ageUp();
        years++;
      }
      return years;
    }

    test('losing somebody takes years, not a couple of birthdays', () {
      // A relationship that evaporates in three years would make the whole
      // system feel like a punishment for playing.
      for (final kind in RelationshipKind.values) {
        expect(
          yearsToLose(kind),
          greaterThan(6),
          reason: '$kind is lost after only ${yearsToLose(kind)} years',
        );
      }
    });

    test('but a life spent entirely on work does lose people', () {
      // The other half. If neglect never costs anything then "Rich but
      // Lonely" is still unreachable and this was all decoration.
      for (final kind in RelationshipKind.values) {
        expect(
          yearsToLose(kind),
          lessThan(40),
          reason:
              '$kind survives ${yearsToLose(kind)} years of being '
              'ignored, which is most of a working life',
        );
      }
    });

    test('the kinds differ, and family holds on longest', () {
      final family = yearsToLose(RelationshipKind.family);
      final friend = yearsToLose(RelationshipKind.friend);
      final mentor = yearsToLose(RelationshipKind.mentor);
      expect(family, greaterThan(friend));
      expect(
        friend,
        greaterThan(mentor),
        reason: 'a mentor is the connection nobody maintains by accident',
      );
    });
  });

  group('loneliness reaches the ending', () {
    test('a rich, happy life with nobody left in it is Rich but Lonely', () {
      // The whole reason closeness exists. Happiness is deliberately high
      // here: before this, that alone would have ruled the ending out.
      expect(
        resolveLifeEnding(
          died: false,
          age: 70,
          netWorth: 90000,
          happiness: 75,
          smarts: 70,
          connection: 10,
        ),
        LifeEndingArchetype.richButLonely,
      );
    });

    test('the same life with people in it is not', () {
      expect(
        resolveLifeEnding(
          died: false,
          age: 70,
          netWorth: 90000,
          happiness: 75,
          smarts: 70,
          connection: 80,
        ),
        isNot(LifeEndingArchetype.richButLonely),
      );
    });

    test('an unhappy rich life still lands there, as it always did', () {
      // The original route has to keep working — this added a way in, it did
      // not replace one.
      expect(
        resolveLifeEnding(
          died: false,
          age: 70,
          netWorth: 90000,
          happiness: 30,
          smarts: 70,
          connection: 90,
        ),
        LifeEndingArchetype.richButLonely,
      );
    });

    test('connection defaults to neutral for callers that do not pass it', () {
      // Existing call sites and tests predate the parameter.
      expect(
        resolveLifeEnding(
          died: false,
          age: 70,
          netWorth: 90000,
          happiness: 75,
          smarts: 70,
        ),
        isNot(LifeEndingArchetype.richButLonely),
      );
    });
  });

  group('the summary still works', () {
    test('names come out for the epilogue, drifted people do not', () {
      final life = withFriend();
      expect(life.relationships, contains('Priya'));

      advance(life, 60);
      expect(
        life.relationships,
        isNot(contains('Priya')),
        reason: 'somebody you lost touch with is not still in your life',
      );
      expect(
        life.people.any((p) => p.name == 'Priya'),
        isTrue,
        reason:
            'they should still be listed as lost, not deleted — losing '
            'touch is a thing that happened in this run',
      );
    });

    test('connection is 0 when there is nobody', () {
      final alone = LifeSimController(random: Random(1), initialAge: 30);
      expect(alone.connection, 0);
    });
  });
}
