import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/constants/app_assets.dart';
import 'package:budget_app/controllers_that_updates_stats/life_sim_controller.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/avatar_skin.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/tutorial_steps.dart';
import 'package:budget_app/services_backend_and_other_services/supabase_service.dart';

/// Two skins, worn at once: the turtle that guides you and who you walk as.
///
/// With one `equipped_skin`, picking a villager to walk the town as also
/// replaced the turtle that explains every lesson, and picking one of the
/// Budget Buddy turtles to guide you made the player walk into town as a
/// turtle with no walk cycle. They do two different jobs, so they are two
/// slots.
void main() {
  UserStats withHabits(Map<String, dynamic> habits) =>
      UserStats.defaults('slot-test').copyWith(spendingHabits: habits);

  group('every skin belongs to exactly one slot', () {
    test('turtles are mascots; villagers and critters are players', () {
      for (final skin in budgetBuddySkins) {
        expect(
          skin.slot,
          skin.family == SkinFamily.turtle ? SkinSlot.mascot : SkinSlot.player,
          reason: skin.id,
        );
      }
    });

    test('the defaults sit in their own slots', () {
      expect(fitsSlot(kDefaultMascotSkinId, SkinSlot.mascot), isTrue);
      expect(fitsSlot(kDefaultPlayerSkinId, SkinSlot.player), isTrue);
      expect(fitsSlot(kDefaultMascotSkinId, SkinSlot.player), isFalse);
      expect(fitsSlot('not_a_skin', SkinSlot.mascot), isFalse);
    });
  });

  group('saved stats', () {
    test('a new player owns and wears both defaults', () {
      final stats = UserStats.defaults('new');
      expect(stats.equippedMascot, kDefaultMascotSkinId);
      expect(stats.equippedSkin, kDefaultPlayerSkinId);
      expect(
        stats.unlockedSkins,
        containsAll(<String>[kDefaultMascotSkinId, kDefaultPlayerSkinId]),
      );
    });

    test('an old save with a turtle in the one slot keeps it as the guide', () {
      // Before the split, `equipped_skin` held whatever was worn. A player who
      // had chosen a turtle chose it as their character; that choice moves to
      // the mascot, and they walk as the default villager until they pick one.
      final stats = withHabits({'equipped_skin': 'buddy_space'});
      expect(stats.equippedMascot, 'buddy_space');
      expect(stats.equippedSkin, kDefaultPlayerSkinId);
    });

    test('an old save with a villager keeps it as the player', () {
      final stats = withHabits({'equipped_skin': 'villager_classic'});
      expect(stats.equippedSkin, 'villager_classic');
      expect(stats.equippedMascot, kDefaultMascotSkinId);
    });

    test('a skin written into the wrong slot is not worn there', () {
      final stats = withHabits({
        'equipped_skin': 'buddy_golden',
        'equipped_mascot': 'villager_classic',
      });
      expect(stats.equippedSkin, kDefaultPlayerSkinId);
      // The mascot slot is invalid, so the legacy turtle is used.
      expect(stats.equippedMascot, 'buddy_golden');
    });

    test('both slots survive a save round trip', () {
      final stats = withHabits({
        'equipped_skin': 'villager_classic',
        'equipped_mascot': 'buddy_rocket',
      });
      final habits =
          stats.toStorageMap()['spending_habits'] as Map<String, dynamic>;
      final back = withHabits(habits);
      expect(back.equippedMascot, 'buddy_rocket');
      expect(back.equippedSkin, 'villager_classic');
    });
  });

  group('the guide is the turtle the player chose', () {
    test('turtles with drawn poses keep their poses', () {
      for (final id in <String>[
        kDefaultMascotSkinId,
        ...AppAssets.mentorSkinIds,
      ]) {
        expect(
          TutorialMascot.wave.assetFor(id),
          AppAssets.turtleMentorPose('wave', id),
        );
      }
    });

    test('a Budget Buddy turtle guides as itself', () {
      for (final skin in budgetBuddySkins.where(
        (s) => s.id.startsWith('buddy_'),
      )) {
        for (final pose in TutorialMascot.values) {
          expect(pose.assetFor(skin.id), skin.previewAsset, reason: skin.id);
        }
      }
    });

    test('a player skin never becomes the guide', () {
      expect(
        TutorialMascot.idle.assetFor('villager_classic'),
        TutorialMascot.idle.asset,
      );
    });

    test('turtles no longer need town walk sheets', () {
      for (final skin in budgetBuddySkins.where((s) => s.isMascot)) {
        expect(AppAssets.townSheet(skin.id), isNull, reason: skin.id);
      }
    });
  });

  group('a life seed decides the life', () {
    List<String> play(int seed) {
      final life = LifeSimController(random: Random(seed));
      final log = <String>[];
      for (var year = 0; year < 60 && !life.finished; year++) {
        life.takeLesson();
        life.ageUp();
        final event = life.currentEvent;
        if (event != null) {
          log.add('${life.age}:${event.id}');
          life.chooseOption(0);
        }
      }
      log.add('money:${life.money} age:${life.age}');
      return log;
    }

    test('the same seed and the same choices replay the same life', () {
      expect(play(20260913), play(20260913));
    });

    test('a different seed is a different life', () {
      expect(play(1), isNot(play(2)));
    });
  });
}
