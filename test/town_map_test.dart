import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:bonfire/bonfire.dart' show BlockMovementCollision;
import 'package:budget_app/models_Like_Skins_and_lessons_templates/town_spot_models.dart';
import 'package:budget_app/constants/app_assets.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/adventure/adventure_world_screen.dart';
import 'package:budget_app/screens_minigames_admin_etc/Gameplay/adventure/town_components.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reads the real exported map straight off disk (rather than through
/// `rootBundle`, which needs asset-bundle plumbing in a unit test) so these
/// checks run against exactly what ships.
Map<String, dynamic> _loadMap() {
  final file = File('assets/images/maps/map.json');
  if (!file.existsSync()) {
    // Thrown rather than `expect`ed because this runs at group-declaration
    // time, outside any test, where matchers aren't available yet.
    throw StateError(
      'assets/images/maps/map.json is missing — the Adventure screen would '
      'fall back to its "map on the way" placeholder',
    );
  }
  return json.decode(file.readAsStringSync()) as Map<String, dynamic>;
}

/// Compiles only for types that actually mix in [BlockMovementCollision].
bool _requiresBlockMovement<T extends BlockMovementCollision>() => true;

/// Four-way flood fill over walkable tiles.
///
/// Reachability rather than per-tile checks is the point: a per-tile
/// assertion still passes if a later map edit opens a route *around*
/// whatever it was guarding, and it can't notice a walkable area being
/// stranded at all.
Set<({int x, int y})> _reachableFrom(
  ({int x, int y}) start,
  Set<({int x, int y})> solid,
  int width,
  int height,
) {
  final seen = <({int x, int y})>{start};
  final queue = <({int x, int y})>[start];
  while (queue.isNotEmpty) {
    final cur = queue.removeLast();
    for (final step in <({int x, int y})>[
      (x: cur.x + 1, y: cur.y),
      (x: cur.x - 1, y: cur.y),
      (x: cur.x, y: cur.y + 1),
      (x: cur.x, y: cur.y - 1),
    ]) {
      if (step.x < 0 || step.x >= width) continue;
      if (step.y < 0 || step.y >= height) continue;
      if (seen.contains(step) || solid.contains(step)) continue;
      seen.add(step);
      queue.add(step);
    }
  }
  return seen;
}

Set<({int x, int y})> _solidTiles(Map<String, dynamic> map) {
  final solid = <({int x, int y})>{};
  for (final layer in map['layers'] as List) {
    final l = layer as Map<String, dynamic>;
    if (l['collider'] != true) continue;
    for (final tile in l['tiles'] as List) {
      final t = tile as Map<String, dynamic>;
      solid.add((x: int.parse('${t['x']}'), y: int.parse('${t['y']}')));
    }
  }
  return solid;
}

void main() {
  group('player collision', () {
    // The regression this guards: Bonfire's SimplePlayer mixes in Movement
    // but NOT BlockMovementCollision, and ships with no hitbox — so the
    // map's colliders existed and did nothing, and the player walked
    // straight off the edge of the world into the void. TownPlayer opts in.
    //
    // Constructing a real TownPlayer needs sprite sheets and a running game
    // loop, so this proves the relationship through the *type system*
    // instead: `_requiresBlockMovement<TownPlayer>()` only compiles while
    // TownPlayer is a subtype of BlockMovementCollision. Drop the mixin and
    // this file stops compiling, which is a louder failure than an
    // assertion.
    test('TownPlayer opts into BlockMovementCollision', () {
      expect(_requiresBlockMovement<TownPlayer>(), isTrue);
    });
  });

  group('town map data', () {
    final map = _loadMap();
    final solid = _solidTiles(map);
    final width = int.parse('${map['mapWidth']}');
    final height = int.parse('${map['mapHeight']}');

    test('the map declares the size the spots were placed against', () {
      expect(width, 50);
      expect(height, 50);
      expect(int.parse('${map['tileSize']}'), 16);
    });

    test('at least one layer is marked solid', () {
      expect(
        solid,
        isNotEmpty,
        reason:
            'no collider layers means nothing can block the player, '
            'however correct the player class is',
      );
    });

    test('the outer ring is fully sealed, so the player cannot leave', () {
      final gaps = <({int x, int y})>[];
      for (var x = 0; x < width; x++) {
        for (final y in <int>[0, height - 1]) {
          if (!solid.contains((x: x, y: y))) gaps.add((x: x, y: y));
        }
      }
      for (var y = 0; y < height; y++) {
        for (final x in <int>[0, width - 1]) {
          if (!solid.contains((x: x, y: y))) gaps.add((x: x, y: y));
        }
      }
      expect(
        gaps,
        isEmpty,
        reason:
            'these perimeter tiles are walkable, so the player can walk '
            'out of the map: $gaps',
      );
    });

    // Replaces an earlier test that asserted the exact opposite — that
    // nothing south of row 34 was reachable. That "hill band" turned out to
    // be a flat tan ROAD (tile ids 91/92/289/290), which had been exported
    // into collider-marked layers by mistake; sealing it walled off 357
    // walkable tiles including the whole southern strip. The real hill is
    // the stepped cliff-face art on the west side (ids 106/107/109/110),
    // now in its own `terrain_cliff` layer.
    //
    // The invariant worth testing is not "this specific band is sealed" but
    // "no walkable tile is stranded" — that catches both over-blocking (a
    // road wrongly made solid) and under-blocking, and doesn't have to be
    // rewritten every time the level design shifts.
    test('every walkable tile is reachable from spawn — nothing stranded', () {
      const spawn = (x: 25, y: 25);
      expect(
        solid.contains(spawn),
        isFalse,
        reason: 'the spawn tile itself is solid',
      );

      final seen = _reachableFrom(spawn, solid, width, height);

      final walkable = <({int x, int y})>{};
      for (var x = 0; x < width; x++) {
        for (var y = 0; y < height; y++) {
          final tile = (x: x, y: y);
          if (!solid.contains(tile)) walkable.add(tile);
        }
      }

      final stranded = walkable.difference(seen).toList();
      expect(
        stranded,
        isEmpty,
        reason:
            '${stranded.length} walkable tile(s) cannot be reached from '
            'spawn — something walkable got walled off. Examples: '
            '${stranded.take(8).toList()}',
      );
    });

    test('the player spawns outside their own house, on a clear tile', () {
      // The spawn is now derived from `spot_home` rather than written
      // down beside it, so the distance check below can no longer fail —
      // which is the point. It stays because the *other* assertions here
      // (walkable, two clear rows overhead) are still real, and because a
      // future change that reintroduces a separate constant should fail.
      final t = townSpawnTile(TownMap.village);
      final spawn = (x: t.x, y: t.y);
      expect(
        solid.contains(spawn),
        isFalse,
        reason: 'the spawn tile $spawn is inside something solid',
      );
      // Same overhead check the NPCs get: the villager sprite is ~2 tiles
      // tall and drawn upward from its feet, so a solid tile one or two
      // rows above means the character spawns clipped into the house.
      for (final dy in <int>[1, 2]) {
        expect(
          solid.contains((x: spawn.x, y: spawn.y - dy)),
          isFalse,
          reason: 'solid tile $dy row(s) above the spawn clips the sprite',
        );
      }

      final home = kTownSpots.firstWhere((s) => s.id == 'spot_home');
      final distance =
          (home.tileX - spawn.x).abs() + (home.tileY - spawn.y).abs();
      expect(
        distance,
        lessThanOrEqualTo(2),
        reason:
            'spawn $spawn is $distance tiles from the house '
            '(${home.tileX},${home.tileY}) — you should start at your door, '
            'not across town',
      );
    });

    // Replaced the old "the west cliff face is solid" check, which guarded
    // a stepped ledge the previous hand-drawn map had. The town is composed
    // by `tool/make_town_map.py` now and has no cliff, so that test had
    // quietly become vacuous — it scanned for four tile ids that no longer
    // appear anywhere and passed on an empty set, which looks identical to
    // passing for a good reason.
    //
    // This is the invariant the new layout actually needs. The first draft
    // of it dropped the player's house squarely across the south avenue:
    // every existing test still passed, because you could walk around the
    // house on grass, so "reachable" was true and the map was still wrong.
    test('both avenues run unobstructed end to end', () {
      const vertical = [24, 25, 26];
      const horizontal = [23, 24, 25];

      final blockedV = <({int x, int y})>[];
      for (final x in vertical) {
        for (var y = 3; y < 47; y++) {
          if (solid.contains((x: x, y: y))) blockedV.add((x: x, y: y));
        }
      }
      expect(
        blockedV,
        isEmpty,
        reason:
            'something solid is standing on the north-south avenue: '
            '$blockedV',
      );

      final blockedH = <({int x, int y})>[];
      for (final y in horizontal) {
        for (var x = 3; x < 47; x++) {
          if (solid.contains((x: x, y: y))) blockedH.add((x: x, y: y));
        }
      }
      expect(
        blockedH,
        isEmpty,
        reason:
            'something solid is standing on the east-west avenue: '
            '$blockedH',
      );
    });

    test('every money-decision building is a short walk from the square', () {
      // The point of the radial layout: no spot should be a hike. Measured
      // as Manhattan distance to the plaza centre rather than by pathing,
      // which is enough to catch a building placed out in a far corner.
      const squareCentre = (x: 25, y: 24);
      for (final spot in kTownSpots) {
        final distance =
            (spot.tileX - squareCentre.x).abs() +
            (spot.tileY - squareCentre.y).abs();
        expect(
          distance,
          lessThanOrEqualTo(30),
          reason:
              '${spot.id} is $distance tiles from the square — the town is '
              'meant to be walkable from its centre',
        );
      }
    });
  });

  group('town spots', () {
    final map = _loadMap();
    final solid = _solidTiles(map);
    final width = int.parse('${map['mapWidth']}');
    final height = int.parse('${map['mapHeight']}');

    test('spot ids are unique', () {
      final ids = kTownSpots.map((s) => s.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('every spot sits on a walkable tile', () {
      // Without this, a spot placed inside a building is unreachable — the
      // prompt could never fire and the objective could never complete.
      for (final spot in kTownSpots) {
        expect(
          solid.contains((x: spot.tileX, y: spot.tileY)),
          isFalse,
          reason:
              '${spot.id} ("${spot.title}") is at '
              '(${spot.tileX}, ${spot.tileY}), which is a solid tile — the '
              'player can never stand there to trigger it',
        );
      }
    });

    test('every spot is inside the map bounds', () {
      for (final spot in kTownSpots) {
        expect(spot.tileX, inInclusiveRange(0, width - 1), reason: spot.id);
        expect(spot.tileY, inInclusiveRange(0, height - 1), reason: spot.id);
      }
    });

    test('every spot offers at least one choice, each with an outcome', () {
      for (final spot in kTownSpots) {
        expect(spot.choices, isNotEmpty, reason: spot.id);
        for (final choice in spot.choices) {
          expect(choice.label.trim(), isNotEmpty, reason: spot.id);
          expect(
            choice.outcome.trim(),
            isNotEmpty,
            reason:
                '${spot.id} has a choice with no outcome line, so it '
                'would change stats without ever explaining why',
          );
        }
      }
    });

    test('no choice is purely punishing — each gives something back', () {
      // A choice that only costs gold and teaches nothing is a trap, not a
      // lesson. Every option should pay in at least one currency.
      for (final spot in kTownSpots) {
        for (final choice in spot.choices) {
          expect(
            choice.gold > 0 || choice.xp > 0 || choice.literacy > 0,
            isTrue,
            reason:
                '${spot.id} / "${choice.label}" gives no gold, XP or '
                'literacy back',
          );
        }
      }
    });
  });

  group('town NPCs', () {
    final map = _loadMap();
    final solid = _solidTiles(map);
    final width = int.parse('${map['mapWidth']}');
    final height = int.parse('${map['mapHeight']}');
    final reachable = _reachableFrom((x: 25, y: 25), solid, width, height);

    test('npc ids are unique', () {
      final ids = kTownNpcs.map((n) => n.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('every npc stands somewhere the player can actually walk to', () {
      final bad = <String>[];
      for (final npc in kTownNpcs) {
        final at = (x: npc.tileX, y: npc.tileY);
        if (solid.contains(at)) {
          bad.add('${npc.id} is inside a solid tile at $at');
        } else if (!reachable.contains(at)) {
          bad.add('${npc.id} at $at cannot be reached from spawn');
        }
      }
      expect(bad, isEmpty, reason: bad.join('; '));
    });

    test('no npc sprite clips into scenery above it', () {
      // The villager sheet is ~2 tiles tall and is drawn *upward* from the
      // character's feet tile, so a solid tile one or two rows above an NPC
      // means its head visibly overlaps a wall/tree. This caught the
      // Student, who was standing right against the west ledge.
      final clipping = <String>[];
      for (final npc in kTownNpcs) {
        for (final dy in <int>[1, 2]) {
          final above = (x: npc.tileX, y: npc.tileY - dy);
          if (solid.contains(above)) {
            clipping.add(
              '${npc.id} at (${npc.tileX},${npc.tileY}) has solid tile '
              '$above $dy row(s) above it',
            );
          }
        }
      }
      expect(clipping, isEmpty, reason: clipping.join('; '));
    });

    test('no two npcs share a tile', () {
      final tiles = kTownNpcs.map((n) => '${n.tileX},${n.tileY}').toList();
      expect(tiles.toSet().length, tiles.length);
    });

    test('every npc has something to say', () {
      for (final npc in kTownNpcs) {
        expect(npc.lines, isNotEmpty, reason: '${npc.id} has no dialogue');
        for (final line in npc.lines) {
          expect(line.trim(), isNotEmpty, reason: '${npc.id} has a blank line');
        }
      }
    });
  });

  group('town coins', () {
    final map = _loadMap();
    final solid = _solidTiles(map);

    test('every coin sits on a walkable tile', () {
      for (final coin in kTownCoins) {
        expect(
          solid.contains((x: coin.x, y: coin.y)),
          isFalse,
          reason:
              'coin at (${coin.x}, ${coin.y}) is inside a wall and can '
              'never be picked up',
        );
      }
    });

    test('every coin is worth something', () {
      for (final coin in kTownCoins) {
        expect(coin.value, greaterThan(0));
      }
    });

    test('no two coins share a tile', () {
      final tiles = kTownCoins.map((c) => '${c.x},${c.y}').toList();
      expect(tiles.toSet().length, tiles.length);
    });
  });

  group('side walk cycle', () {
    // Columns 0 and 4 used to be skipped: the old sheets drew those two
    // neutral poses with front-facing legs on a profile body, so the walk
    // snapped face-on twice per cycle. `tool/redraw_villagers.py` redrew
    // every sheet with a true eight-frame profile loop, so the workaround is
    // gone — and this asserts it stays gone, because reintroducing the skip
    // would silently shorten the cycle again.
    test('skips the front-facing neutral frames', () {
      // Columns 0 and 4 draw front-facing legs on a profile body, so the walk
      // would snap face-on twice per cycle. A procedural redraw briefly made
      // those frames true profiles and the skip was removed; the hand-drawn
      // original was then chosen over the redraw, so the skip is back and
      // this is what stops it being removed again by accident.
      expect(kSideWalkFrames, isNot(contains(0)));
      expect(kSideWalkFrames, isNot(contains(4)));
    });

    test('idles on a profile pose, not the front-facing one', () {
      // Frame 0 is the front-on stance, so an idle character facing west
      // would stand with their legs pointing at the camera.
      expect(kSideIdleFrame, 1);
    });

    test('is a whole number of half-cycles', () {
      // One entry per leg per step, so an odd count would make the
      // character limp — the same leg would lead twice in a row at the
      // loop point.
      expect(kSideWalkFrames.length.isEven, isTrue);
      expect(kSideWalkFrames, isNotEmpty);
    });

    test('every frame is a real column of the sheet', () {
      for (final column in kSideWalkFrames) {
        expect(column, inInclusiveRange(0, AppAssets.villagerSheetColumns - 1));
      }
      expect(kSideWalkFrames.toSet().length, kSideWalkFrames.length);
    });

    /// Reads one villager sheet and returns its raw RGBA bytes.
    ///
    /// `dart:ui` rather than the `image` package: decoding a PNG is the only
    /// thing needed here and it is not worth a dependency the app does not
    /// otherwise have.
    Future<(ByteData, int)> loadSheet() async {
      final bytes = File(
        'assets/self_made_skins/villager_female_aurora_prime.png',
      ).readAsBytesSync();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final data = await frame.image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      return (data!, frame.image.width);
    }

    testWidgets('both halves of the stride are the same size character', (
      tester,
    ) async {
      // **The bug this exists for.** Columns 5-7 used to be the same poses as
      // 1-3 drawn 16% bulkier — 7,820 opaque pixels at 79.5px wide against
      // 6,740 at 65px. Animated together the character swelled and shrank
      // twice a second, which is what got reported as clanking, and no amount
      // of redrawing an individual frame could fix it because every frame was
      // fine on its own.
      //
      // `tool/fix_side_walk_cycle.py` rebuilds 5-7 from 1-2 with only the leg
      // band mirrored, so the bodies are identical by construction. This
      // measures that they still are.
      late ByteData data;
      late int stride;
      await tester.runAsync(() async {
        final (d, w) = await loadSheet();
        data = d;
        stride = w;
      });

      const cellW = 104;
      const cellH = 162;

      int opaquePixels(int column, int row) {
        var count = 0;
        for (var y = 0; y < cellH; y++) {
          for (var x = 0; x < cellW; x++) {
            final px = ((row * cellH + y) * stride + column * cellW + x) * 4;
            if (data.getUint8(px + 3) > 10) count++;
          }
        }
        return count;
      }

      for (final row in <int>[2, 3]) {
        final slim = opaquePixels(1, row);
        final other = opaquePixels(5, row);
        expect(
          (slim - other).abs() / slim,
          lessThan(0.03),
          reason:
              'row $row: the halves of the stride differ by '
              '${((slim - other).abs() / slim * 100).round()}% in body mass — '
              'the character will swell as it walks',
        );
      }
    });

    testWidgets('the two halves are not the identical frame', (tester) async {
      // The other way this can go wrong: making them the same size by making
      // them the same picture, which removes the swell and the walk with it.
      late ByteData data;
      late int stride;
      await tester.runAsync(() async {
        final (d, w) = await loadSheet();
        data = d;
        stride = w;
      });

      var differences = 0;
      for (var y = 112; y < 162; y++) {
        for (var x = 0; x < 104; x++) {
          final a = ((2 * 162 + y) * stride + 1 * 104 + x) * 4;
          final b = ((2 * 162 + y) * stride + 5 * 104 + x) * 4;
          if (data.getUint32(a) != data.getUint32(b)) differences++;
        }
      }
      expect(
        differences,
        greaterThan(50),
        reason:
            'the legs are identical in both halves — the character is '
            'gliding, not walking',
      );
    });

    test('the idle pose is one of the good frames', () {
      // Standing still facing sideways used to show column 0 — the worst
      // instance of the bug, because it held the bad pose indefinitely
      // instead of flashing past it.
      expect(kSideWalkFrames, contains(kSideIdleFrame));
    });
  });
}
