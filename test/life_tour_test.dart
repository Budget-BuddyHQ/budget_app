import 'dart:math';

import 'package:budget_app/controllers_that_updates_stats/life_sim_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/life_tutorial_steps.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/tutorial_steps.dart';
import 'package:flutter_test/flutter_test.dart';

/// The in-game tour, and the thing it was written to make visible.
void main() {
  group('the life tour', () {
    test('step ids are unique and stable', () {
      final ids = kLifeTutorialSteps.map((s) => s.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('covers every control a player has to find', () {
      // The failure this guards is quiet: somebody ages up, reads an event,
      // picks an option, and never finds the money panel, the town or the
      // career menu — because nothing said they were there. They end up
      // playing the simulation as a multiple-choice quiz, which is the one
      // reading of it that teaches nothing.
      expect(
        kLifeTutorialSteps.map((s) => s.id).toSet(),
        containsAll(<String>[
          'life_age',
          'life_money',
          'life_event',
          'life_town',
          'life_menus',
        ]),
      );
    });

    test('every step has copy worth reading', () {
      for (final step in kLifeTutorialSteps) {
        expect(step.title, isNotEmpty, reason: step.id);
        expect(step.tagline.length, greaterThan(40), reason: step.id);
        expect(step.bullets.length, greaterThanOrEqualTo(2), reason: step.id);
        expect(step.teaches.length, greaterThan(20), reason: step.id);
      }
    });

    test('it does not try to switch tabs', () {
      // This tour runs over a pushed route, not over the tab bar. A step that
      // asked for a tab would send the shell somewhere while the overlay kept
      // spotlighting widgets on the screen underneath.
      for (final step in kLifeTutorialSteps) {
        expect(step.jumpTab, isNull, reason: step.id);
      }
    });

    test('it is a different tour from the app tour', () {
      // Sharing ids would make the two indistinguishable in the target
      // registry, and a spotlight meant for the Life tab would land on a
      // widget inside the game.
      final appIds = kTutorialSteps.map((s) => s.id).toSet();
      final lifeIds = kLifeTutorialSteps.map((s) => s.id).toSet();
      expect(appIds.intersection(lifeIds), isEmpty);
    });
  });

  group('a decision made in the town lands on the life', () {
    // Before this, walking into a building changed the *account* — gold, XP,
    // literacy — and nothing about the character. The one part of the app
    // where you physically go somewhere to make a money decision had no
    // bearing on the money simulation it was launched from.
    /// A brand-new character with money in hand.
    ///
    /// Deliberately not aged forward: driving a life to 25 by taking the
    /// first option every year maxes smarts at 100, and a capped stat cannot
    /// demonstrate that anything raised it.
    LifeSimController fresh() =>
        LifeSimController(random: Random(7), initialAge: 0, startMoney: 500);

    test('gold spent in town is money gone from the life', () {
      final life = fresh();
      final before = life.money;
      life.applyTownOutcome(gold: -12, xp: 0, literacy: 0);
      expect(life.money, before - 12);
    });

    test('what you understood there raises smarts', () {
      final life = fresh();
      final before = life.smarts;
      life.applyTownOutcome(gold: 0, xp: 0, literacy: 10);
      expect(life.smarts, greaterThan(before));
    });

    test('going out at all is a small lift, not a large one', () {
      // XP is "you turned up", which is the easiest part of any of this, so
      // it moves the least.
      final life = fresh();
      final happy = life.happiness;
      final smart = life.smarts;
      life.applyTownOutcome(gold: 0, xp: 10, literacy: 10);
      expect(life.happiness - happy, lessThan(life.smarts - smart));
    });

    test('a finished run is not changed by a late outcome', () {
      // The town screen is pushed on top of the game and can outlive it —
      // retiring while a building dialog is open should not write to a life
      // that has already been scored and saved.
      final life = fresh();
      for (var i = 0; i < 200 && !life.finished; i++) {
        if (life.currentEvent != null) life.chooseOption(0);
        life.ageUp();
      }
      expect(life.finished, isTrue, reason: 'the life never ended');
      final money = life.money;
      life.applyTownOutcome(gold: 500, xp: 50, literacy: 50);
      expect(life.money, money);
    });
  });
}
