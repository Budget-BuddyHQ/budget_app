import 'package:budget_app/constants/app_assets.dart';
import 'package:budget_app/models_Like_Skins_and_lessons_templates/town_spot_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// The town's people.
///
/// A town of figures standing perfectly still reads as a diorama, which was
/// the note — "the main game is pretty stale, I want moving parts". Patrols
/// fix that, and they are constrained on purpose: an NPC that wanders freely
/// needs pathfinding, can walk into the sea, and can walk *away* from a player
/// who is trying to reach it.
void main() {
  group('the town is inhabited', () {
    test('most people move', () {
      // Not all: the ones behind counters should stay behind their counters.
      // But a town where nobody moves is the thing being fixed.
      final moving = kTownNpcs.where((n) => n.patrolTiles > 0).length;
      expect(
        moving,
        greaterThanOrEqualTo((kTownNpcs.length / 2).ceil()),
        reason: 'only $moving of ${kTownNpcs.length} NPCs ever move',
      );
    });

    test('patrols are short enough to stay on the map', () {
      // Every NPC position was authored against the collider data with a
      // clear 3x3 around it. A long patrol walks straight out of that
      // guarantee and into a wall or the water.
      for (final npc in kTownNpcs) {
        expect(
          npc.patrolTiles,
          lessThanOrEqualTo(5),
          reason: '${npc.id} paces ${npc.patrolTiles} tiles, which is far '
              'enough to leave the area its position was checked against',
        );
        expect(npc.patrolTiles, greaterThanOrEqualTo(0));
      }
    });

    test('a patrol never runs off the 50x50 map', () {
      const mapTiles = 50;
      for (final npc in kTownNpcs) {
        final endX = npc.tileX + (npc.patrolHorizontal ? npc.patrolTiles : 0);
        final endY = npc.tileY + (npc.patrolHorizontal ? 0 : npc.patrolTiles);
        expect(endX, lessThan(mapTiles), reason: npc.id);
        expect(endY, lessThan(mapTiles), reason: npc.id);
      }
    });

    test('everyone still has something to say', () {
      // The patrol is decoration; the line is the reason the NPC exists.
      for (final npc in kTownNpcs) {
        expect(npc.lines, isNotEmpty, reason: npc.id);
        for (final line in npc.lines) {
          expect(line.length, greaterThan(20), reason: '${npc.id}: "$line"');
        }
      }
    });
  });

  group('the walk cycles exist', () {
    // These frames shipped in the bundle and nothing referenced them, which
    // is why the town had been standing still since the map existed.
    test('every look has a walk animation', () {
      for (final frames in [
        AppAssets.taxerWalkFrames,
        AppAssets.customerWalkFrames,
        AppAssets.fancyWalkFrames,
        AppAssets.workerWalkFrames,
      ]) {
        expect(frames, isNotEmpty);
        for (final path in frames) {
          expect(path, endsWith('.png'));
          expect(path, contains('walk'));
        }
      }
    });

    test('the worker asks for two frames, not three', () {
      // Its sheet only ships two. Asking for a third loads a missing asset,
      // which in Flame throws during map load rather than showing a gap.
      expect(AppAssets.workerWalkFrames.length, 2);
    });
  });
}
