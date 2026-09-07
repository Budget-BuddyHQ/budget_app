import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/models_Like_Skins_and_lessons_templates/npc_encounters.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/town_missions.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/town_spot_models.dart';

/// Townspeople who do things, and the missions they hand out.
///
/// **Two reports, twice each.** *"The NPCs still just give out dialogue, we
/// want action from the NPC — like that NPC stealing from you and running away
/// with your money"*, and separately that `town_missions.dart` existed while
/// nobody could see a mission: the file was 346 lines referenced by **nothing
/// in the entire repo**.
///
/// The losses here are the part that needs guarding. This is played by
/// four-year-olds, so a pickpocket that can empty a run or push somebody into
/// debt would teach avoidance of the town rather than care with money — and
/// the town is where the game is.
void main() {
  group('nothing can take more than you are carrying', () {
    test('a loss never exceeds carried cash', () {
      for (final action in kNpcActions) {
        for (final carried in const [0, 1, 5, 40, 500, 100000]) {
          final delta = action.resolveGold(carried);
          expect(
            delta,
            greaterThanOrEqualTo(-carried),
            reason: '${action.id} took more than the player had, which would '
                'mean being robbed into debt',
          );
        }
      }
    });

    test('a broke player cannot be robbed', () {
      for (final action in kNpcActions) {
        expect(action.resolveGold(0), greaterThanOrEqualTo(0));
      }
    });

    test('losses are capped, so a rich run is not wiped', () {
      for (final action in kNpcActions) {
        final delta = action.resolveGold(1000000);
        if (delta < 0) {
          expect(
            delta.abs(),
            lessThanOrEqualTo(action.maxLoss),
            reason: '${action.id} scales without limit',
          );
        }
      }
    });

    test('losses are proportional, not flat', () {
      // A flat 200 is nothing to a teenager with 4,000 and the end of the run
      // for a six-year-old with 40. The same encounter has to mean the same
      // thing to both.
      final thief = kNpcActions.firstWhere((a) => a.id == 'npc_pickpocket');
      final small = thief.resolveGold(100).abs();
      final large = thief.resolveGold(300).abs();
      expect(large, greaterThan(small));
    });
  });

  group('what you can and cannot refuse', () {
    test('being robbed is not a choice, and neither is a gift', () {
      // Offering a "decline" button on being pickpocketed would be a lie
      // about what the moment is.
      expect(isDeclinable(NpcActionKind.pickpocket), isFalse);
      expect(isDeclinable(NpcActionKind.kindness), isFalse);
    });

    test('scams and work are choices', () {
      expect(isDeclinable(NpcActionKind.scam), isTrue);
      expect(isDeclinable(NpcActionKind.hustle), isTrue);
      expect(isDeclinable(NpcActionKind.fairDeal), isTrue);
    });
  });

  group('the town is not a mugging simulator', () {
    test('most visits are still just a conversation', () {
      var encounters = 0;
      const rolls = 200;
      for (var i = 0; i < rolls; i++) {
        final action = encounterFor(
          'npc_worker',
          age: 16,
          roll: i / rolls,
        );
        if (action != null) encounters++;
      }
      // An encounter every time would make the town exhausting and would
      // turn the pickpocket into routine rather than a shock.
      expect(encounters / rolls, lessThan(0.45));
      expect(encounters, greaterThan(0));
    });

    test('the same encounter never repeats back to back', () {
      for (var i = 0; i <= 100; i++) {
        final action = encounterFor(
          'npc_shopper',
          age: 16,
          roll: i / 100,
          lastActionId: 'npc_hustle_deliveries',
        );
        expect(action?.id, isNot('npc_hustle_deliveries'));
      }
    });

    test('young players never meet the scam or the pickpocket', () {
      for (var i = 0; i <= 100; i++) {
        for (final npc in kTownNpcs) {
          final action = encounterFor(npc.id, age: 6, roll: i / 100);
          if (action == null) continue;
          expect(action.kind, isNot(NpcActionKind.scam));
          expect(action.kind, isNot(NpcActionKind.pickpocket));
        }
      }
    });
  });

  group('somebody in this town is simply decent', () {
    test('at least one encounter asks nothing in return', () {
      final kind = kNpcActions.where(
        (a) => a.kind == NpcActionKind.kindness,
      );
      expect(
        kind,
        isNotEmpty,
        reason: 'a town where every stranger is a threat teaches suspicion, '
            'which is not financial literacy',
      );
      for (final a in kind) {
        expect(a.resolveGold(100), greaterThan(0));
      }
    });

    test('honest work pays without a catch', () {
      final work = kNpcActions.where((a) => a.kind == NpcActionKind.hustle);
      expect(work, isNotEmpty);
      for (final a in work) {
        expect(a.resolveGold(100), greaterThan(0));
      }
    });
  });

  group('every action explains itself', () {
    test('both outcomes name the lesson', () {
      for (final a in kNpcActions) {
        expect(a.headline.trim(), isNotEmpty);
        expect(a.detail.trim().length, greaterThan(20));
        expect(a.outcomeAccepted.trim().length, greaterThan(30));
        expect(a.outcomeDeclined.trim().length, greaterThan(30));
      }
    });

    test('ids are unique and every npc exists', () {
      final ids = kNpcActions.map((a) => a.id).toSet();
      expect(ids.length, kNpcActions.length);

      final real = kTownNpcs.map((n) => n.id).toSet();
      for (final a in kNpcActions) {
        expect(
          real,
          contains(a.npcId),
          reason: '${a.id} belongs to ${a.npcId}, who is not in this town',
        );
      }
    });
  });

  group('missions are reachable and finishable', () {
    test('every mission belongs to a real person', () {
      final real = kTownNpcs.map((n) => n.id).toSet();
      for (final m in kTownMissions) {
        expect(real, contains(m.npcId), reason: '${m.id} has no owner');
      }
    });

    test('a fresh player is offered something', () {
      final offered = <String>{};
      for (final npc in kTownNpcs) {
        final m = nextMissionFor(npc.id, age: 14, completed: const {});
        if (m != null) offered.add(m.id);
      }
      expect(offered, isNotEmpty);
    });

    test('finishing one moves you to the next', () {
      final first = nextMissionFor(
        'npc_shopper',
        age: 16,
        completed: const {},
      );
      expect(first, isNotNull);

      final second = nextMissionFor(
        'npc_shopper',
        age: 16,
        completed: {first!.id},
      );
      expect(second?.id, isNot(first.id));
    });

    test('completion is judged on counters the app actually keeps', () {
      for (final m in kTownMissions) {
        final done = missionComplete(
          m,
          coinsSaved: 100000,
          placesVisited: 100,
          challengesSolved: 100,
          age: 99,
          lessonsFinished: 100,
        );
        expect(done, isTrue, reason: '${m.id} can never be completed');

        final notYet = missionComplete(
          m,
          coinsSaved: 0,
          placesVisited: 0,
          challengesSolved: 0,
          age: 0,
          lessonsFinished: 0,
        );
        expect(notYet, isFalse, reason: '${m.id} completes itself for free');
      }
    });

    test('progress runs 0 to 1 and never overflows the bar', () {
      for (final m in kTownMissions) {
        final p = missionProgress(
          m,
          coinsSaved: 100000,
          placesVisited: 100,
          challengesSolved: 100,
          age: 99,
          lessonsFinished: 100,
        );
        expect(p, lessThanOrEqualTo(1.0));
        expect(p, greaterThanOrEqualTo(0.0));
      }
    });
  });
}
