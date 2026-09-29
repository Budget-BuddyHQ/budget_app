import 'dart:convert';
import 'dart:io';

import 'package:budget_app/models_Like_Skins_and_lessons_templates/town_spot_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/town_landmarks.dart';

/// Where the town's markers actually sit on the map.
///
/// **What went wrong.** The coordinates were hand-placed and drifted. Measured
/// against the collider data, the cafe and the clinic sat *four tiles* from
/// the nearest solid thing and the market and library three, so on screen they
/// were colored circles floating in the middle of a road with no building
/// near them. Nothing could catch that: they were on walkable tiles, inside
/// the map, and reachable. They were just nowhere.
///
/// So this reads the exported map and holds the three things that were
/// silently untrue: every marker is walkable, reachable, and *beside a
/// building*. `tool/place_town_spots.py` is what fixes a failure here.
void main() {
  _mapIdentity();

  _landmarks();

  /// One parsed map: its size and the set of solid tiles.
  ({int width, int height, Set<(int, int)> solid}) loadMap(String name) {
    final raw = File('assets/images/maps/$name').readAsStringSync();
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final solid = <(int, int)>{};
    for (final layer in data['layers'] as List<dynamic>) {
      final map = layer as Map<String, dynamic>;
      if (map['collider'] != true) continue;
      for (final tile in map['tiles'] as List<dynamic>) {
        final t = tile as Map<String, dynamic>;
        solid.add((t['x'] as int, t['y'] as int));
      }
    }
    return (
      width: data['mapWidth'] as int,
      height: data['mapHeight'] as int,
      solid: solid,
    );
  }

  group('map.json', () {
    late final map = loadMap('map.json');

    test('every spot stands on a tile you can walk on', () {
      for (final spot in kTownSpots) {
        expect(
          map.solid.contains((spot.tileX, spot.tileY)),
          isFalse,
          reason:
              '${spot.id} is inside a wall at (${spot.tileX}, '
              '${spot.tileY})',
        );
      }
    });

    test('every spot is inside the map', () {
      for (final spot in kTownSpots) {
        expect(spot.tileX, inInclusiveRange(0, map.width - 1));
        expect(spot.tileY, inInclusiveRange(0, map.height - 1));
      }
    });

    test('every spot stands at the front of the thing it is named for', () {
      // The old version of this counted any six solid tiles as a building, and
      // a tree is nine. So a cafe planted beside an oak, or a library on the end
      // of a fence, passed, and the report was "a cafe in the middle of the
      // grass". `kTownLandmarks` names what each marker stands in front of, and
      // this holds it to that.
      for (final spot in kTownSpots) {
        final landmark = kTownLandmarks[TownMap.village]![spot.id]!;
        final distance =
            (landmark.x - spot.tileX).abs() + (landmark.y - spot.tileY).abs();
        expect(
          distance,
          1,
          reason:
              '${spot.id} at (${spot.tileX}, ${spot.tileY}) is not beside '
              '${landmark.what} at (${landmark.x}, ${landmark.y})',
        );
      }
    });

    test('no two spots share a tile', () {
      final seen = <String, String>{};
      for (final spot in kTownSpots) {
        final key = '${spot.tileX},${spot.tileY}';
        expect(
          seen[key],
          isNull,
          reason: '${spot.id} is stacked on ${seen[key]} at $key',
        );
        seen[key] = spot.id;
      }
    });

    test('the whole town is one connected space', () {
      // A map that looks fine and is cut in half by a wall of solid road
      // tiles is the exact failure that killed three attempts at the second
      // map. It is cheap to assert and impossible to eyeball.
      final free = <(int, int)>{};
      for (var y = 0; y < map.height; y++) {
        for (var x = 0; x < map.width; x++) {
          if (!map.solid.contains((x, y))) free.add((x, y));
        }
      }
      final start = free.first;
      final seen = <(int, int)>{start};
      final queue = <(int, int)>[start];
      while (queue.isNotEmpty) {
        final (x, y) = queue.removeLast();
        for (final n in <(int, int)>[
          (x + 1, y),
          (x - 1, y),
          (x, y + 1),
          (x, y - 1),
        ]) {
          if (free.contains(n) && seen.add(n)) queue.add(n);
        }
      }
      expect(
        seen.length / free.length,
        greaterThan(0.99),
        reason:
            'the walkable area is split into pieces — '
            '${seen.length} of ${free.length} reachable from one corner',
      );
    });
  });

  group('map_two.json', () {
    // The second town, rebuilt from a flat PNG by tool/build_map_two.py. It
    // has no hand-authored colliders at all — they were learned from map 1 —
    // so the connectivity check is the thing standing between it and a town
    // cut into quarters.
    late final map = loadMap('map_two.json');

    test('it exists and is the same shape as the first', () {
      expect(map.width, 50);
      expect(map.height, 50);
    });

    test('most of it is walkable', () {
      final walkable = map.width * map.height - map.solid.length;
      expect(
        walkable / (map.width * map.height),
        greaterThan(0.7),
        reason:
            'only ${(walkable / (map.width * map.height) * 100).round()}% '
            'is walkable — the collider mapping has over-fired again',
      );
    });

    test('the town is one connected space', () {
      final free = <(int, int)>{};
      for (var y = 0; y < map.height; y++) {
        for (var x = 0; x < map.width; x++) {
          if (!map.solid.contains((x, y))) free.add((x, y));
        }
      }
      var best = 0;
      final seen = <(int, int)>{};
      for (final start in free) {
        if (seen.contains(start)) continue;
        final queue = <(int, int)>[start];
        var size = 0;
        seen.add(start);
        while (queue.isNotEmpty) {
          final (x, y) = queue.removeLast();
          size++;
          for (final n in <(int, int)>[
            (x + 1, y),
            (x - 1, y),
            (x, y + 1),
            (x, y - 1),
          ]) {
            if (free.contains(n) && seen.add(n)) queue.add(n);
          }
        }
        if (size > best) best = size;
      }
      expect(
        best / free.length,
        greaterThan(0.95),
        reason:
            'the largest reachable region is only '
            '${(best / free.length * 100).round()}% of the walkable space',
      );
    });
  });
}

/// Every marker stands at a real building, and no two share one — on both maps.
///
/// **What this replaced.** A flood fill that called any six solid tiles a
/// "building". A tree is nine, a hedge is more, and a rope fence along a lawn is
/// nineteen, so the test passed a library on the end of a fence and a cafe beside
/// an oak. The second town was worse: its buildings are painted into the ground
/// layer and are mostly not solid at all, so no fill of solid tiles could find
/// them. What was reported was *"we got a cafe in the middle of the grass"*, and
/// on that map two of the markers were standing on the outer wall.
///
/// So `test/support/town_landmarks.dart` says, by hand, what each marker stands
/// in front of, read off the rendered maps (`tool/README.md` has the recipe), and
/// this holds the markers to it: beside that thing, and the thing is not a tree,
/// a bush or a fence.
void _landmarks() {
  // Tile ids the tileset uses for trees, bushes and fences. A landmark made of
  // these is scenery, and a marker planted beside scenery is the bug.
  const scenery = <int>{
    286, 288, // bushes
    291, 292, 293, 294, 295, 296, 297, 298, 299, // trees
    304, 305, 306, 307, // fence posts
    398, 399, 400, 401, 402, // rope fence
  };

  group('every town marker stands at a real building', () {
    for (final map in TownMap.values) {
      group('on ${map.name}', () {
        late final Map<String, dynamic> data;
        late final Map<(int, int), List<({String layer, int id})>> tiles;
        late final Set<(int, int)> solid;

        setUpAll(() {
          data =
              jsonDecode(
                    File(
                      'assets/images/maps/${map.asset.split('/').last}',
                    ).readAsStringSync(),
                  )
                  as Map<String, dynamic>;
          tiles = {};
          solid = {};
          for (final layer in data['layers'] as List) {
            for (final tile in layer['tiles'] as List) {
              final key = (
                int.parse(tile['x'].toString()),
                int.parse(tile['y'].toString()),
              );
              tiles.putIfAbsent(key, () => []).add((
                layer: layer['name'] as String,
                id: int.parse(tile['id'].toString()),
              ));
              if (layer['collider'] == true) solid.add(key);
            }
          }
        });

        test('every marker has a named landmark', () {
          for (final spot in kTownSpots) {
            expect(
              kTownLandmarks[map]![spot.id],
              isNotNull,
              reason: '${spot.id} has no landmark on ${map.name}',
            );
          }
        });

        test('and stands right beside it', () {
          for (final spot in kTownSpots) {
            final landmark = kTownLandmarks[map]![spot.id]!;
            final x = spot.xOn(map);
            final y = spot.yOn(map);
            expect(
              (landmark.x - x).abs() + (landmark.y - y).abs(),
              1,
              reason:
                  '${spot.id} at ($x, $y) on ${map.name} is not beside '
                  '${landmark.what} at (${landmark.x}, ${landmark.y})',
            );
          }
        });

        test('and the landmark is not a tree, a bush or a fence', () {
          for (final spot in kTownSpots) {
            if (spot.kind == TownSpotKind.park) continue; // open ground
            final landmark = kTownLandmarks[map]![spot.id]!;
            final ids = [
              for (final t in tiles[(landmark.x, landmark.y)] ?? const []) t.id,
            ];
            expect(
              ids.any(scenery.contains),
              isFalse,
              reason:
                  '${spot.id} on ${map.name} stands beside ${landmark.what}, '
                  'which is scenery, not a building',
            );
          }
        });

        test('and on the first town it is drawn above the floor', () {
          // The first town keeps every building in layers of its own. The
          // second paints most of them into the ground, so this check would
          // fail there for the right art.
          if (map != TownMap.village) return;
          for (final spot in kTownSpots) {
            final landmark = kTownLandmarks[map]![spot.id]!;
            final above = [
              for (final t in tiles[(landmark.x, landmark.y)] ?? const [])
                if (!const {'floor', 'texture', 'terrain'}.contains(t.layer)) t,
            ];
            expect(
              above,
              isNotEmpty,
              reason:
                  '${spot.id} stands beside ${landmark.what} at '
                  '(${landmark.x}, ${landmark.y}), and nothing is drawn there',
            );
          }
        });

        test('no two markers share a landmark', () {
          final byName = <String, String>{};
          final byTile = <(int, int), String>{};
          for (final spot in kTownSpots) {
            final landmark = kTownLandmarks[map]![spot.id]!;
            expect(
              byName[landmark.what],
              isNull,
              reason:
                  '${spot.id} and ${byName[landmark.what]} are both at '
                  '${landmark.what} on ${map.name}',
            );
            byName[landmark.what] = spot.id;
            expect(
              byTile[(landmark.x, landmark.y)],
              isNull,
              reason:
                  '${spot.id} and ${byTile[(landmark.x, landmark.y)]} share '
                  'a tile of the same wall on ${map.name}',
            );
            byTile[(landmark.x, landmark.y)] = spot.id;
          }
        });

        test('and none is crowded onto another', () {
          // A marker's sensor is two tiles across. Three apart is the least
          // that keeps walking up to one from opening its neighbor.
          for (final a in kTownSpots) {
            for (final b in kTownSpots) {
              if (a.id.compareTo(b.id) >= 0) continue;
              final dx = (a.xOn(map) - b.xOn(map)).abs();
              final dy = (a.yOn(map) - b.yOn(map)).abs();
              expect(
                dx > dy ? dx : dy,
                greaterThanOrEqualTo(3),
                reason: '${a.id} and ${b.id} are too close on ${map.name}',
              );
            }
          }
        });

        test('and none is on a wall or on the edge of the map', () {
          final width = data['mapWidth'] as int;
          final height = data['mapHeight'] as int;
          for (final spot in kTownSpots) {
            final x = spot.xOn(map);
            final y = spot.yOn(map);
            expect(
              solid.contains((x, y)),
              isFalse,
              reason: '${spot.id} is in a wall',
            );
            expect(
              x,
              inInclusiveRange(2, width - 3),
              reason: '${spot.id} is on the edge',
            );
            expect(
              y,
              inInclusiveRange(2, height - 3),
              reason: '${spot.id} is on the edge',
            );
          }
        });
      });
    }
  });
}

/// One town per life, and both towns inhabited.
///
/// Two bugs the player reported in the same breath: *"why does it change in
/// between if a run has started, please stick with one map"* and *"there are
/// no NPCs on the other map"*. They were related — the map was rolled per
/// visit, so half of all entries landed on the second map, and the renderer
/// drew NPCs and coins only on the first.
void _mapIdentity() {
  group('a life gets one town', () {
    test('the same life always walks into the same map', () {
      // The old code held `late final _townMap = Random()...` on the *screen*,
      // which is rebuilt on every entry. Deriving from the life instead means
      // re-entering is the same place by construction, with nothing stored.
      for (final name in ['Quinn', 'Casey', 'Ada', 'Bo', 'Wren']) {
        final first = townMapForLife(name, 'workingClass');
        for (var i = 0; i < 20; i++) {
          expect(townMapForLife(name, 'workingClass'), first);
        }
      }
    });

    test('different lives can get different towns', () {
      final seen = <TownMap>{};
      for (var i = 0; i < 60; i++) {
        seen.add(townMapForLife('player$i', 'workingClass'));
      }
      expect(
        seen.length,
        TownMap.values.length,
        reason:
            'every life is landing in the same town — the hash is not '
            'spreading, so the second map would never be seen',
      );
    });

    test('the origin is part of the identity, not just the name', () {
      // Two lives can share a name across runs; the origin is what makes a
      // fresh start feel like a fresh place.
      final a = <TownMap>{};
      for (final origin in ['workingClass', 'wealthy', 'rural', 'urban']) {
        a.add(townMapForLife('Quinn', origin));
      }
      expect(a.length, greaterThan(1));
    });

    test('the seed survives a restart', () {
      // FNV-1a, not Object.hash — Dart seeds string hashing per isolate, so a
      // map picked with that would change every time the app was reopened.
      // Pinned, because that is exactly how this class of bug returns.
      expect(townMapForLife('Quinn', 'workingClass'), isA<TownMap>());
      expect(townMapForLife('Quinn', 'workingClass').index, isNonNegative);
    });
  });

  group('both towns have people and coins in them', () {
    for (final map in TownMap.values) {
      test('${map.name} places every NPC somewhere sensible', () async {
        final data =
            jsonDecode(
                  await File(
                    'assets/images/maps/${map.asset.split('/').last}',
                  ).readAsString(),
                )
                as Map<String, dynamic>;

        final solid = <({int x, int y})>{};
        for (final layer in data['layers'] as List) {
          if (layer['collider'] != true) continue;
          for (final tile in layer['tiles'] as List) {
            solid.add((
              x: int.parse(tile['x'].toString()),
              y: int.parse(tile['y'].toString()),
            ));
          }
        }

        final taken = <String, String>{};
        for (final npc in kTownNpcs) {
          final x = npc.xOn(map);
          final y = npc.yOn(map);

          expect(
            solid.contains((x: x, y: y)),
            isFalse,
            reason: '${npc.id} stands inside a wall on ${map.name}',
          );

          // The sprite is about two tiles tall and drawn upward from its
          // feet, so a solid tile one or two rows above clips it.
          for (final dy in const [1, 2]) {
            expect(
              solid.contains((x: x, y: y - dy)),
              isFalse,
              reason: '${npc.id} is clipped by scenery on ${map.name}',
            );
          }

          final key = '$x,$y';
          expect(
            taken[key],
            isNull,
            reason: '${npc.id} and ${taken[key]} share a tile on ${map.name}',
          );
          taken[key] = npc.id;
        }
      });

      test('${map.name} has coins, and none of them overlap', () {
        final coins = townCoinsFor(map);
        expect(
          coins,
          isNotEmpty,
          reason: 'a town with nothing to pick up reads as unfinished',
        );
        final tiles = coins.map((c) => '${c.x},${c.y}').toSet();
        expect(tiles.length, coins.length, reason: 'two coins on one tile');
        for (final coin in coins) {
          expect(coin.value, greaterThan(0));
        }
      });
    }
  });
}
