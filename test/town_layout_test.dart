import 'dart:convert';
import 'dart:io';

import 'package:budget_app/models_Like_Skins_and_lessons_templates/town_spot_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Where the town's markers actually sit on the map.
///
/// **What went wrong.** The coordinates were hand-placed and drifted. Measured
/// against the collider data, the cafe and the clinic sat *four tiles* from
/// the nearest solid thing and the market and library three, so on screen they
/// were coloured circles floating in the middle of a road with no building
/// near them. Nothing could catch that: they were on walkable tiles, inside
/// the map, and reachable. They were just nowhere.
///
/// So this reads the exported map and holds the three things that were
/// silently untrue: every marker is walkable, reachable, and *beside a
/// building*. `tool/place_town_spots.py` is what fixes a failure here.
void main() {
  _buildingAssignment();

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

  /// Solid tiles belonging to a cluster of six or more.
  ///
  /// The size floor is what separates a building from scenery. Trees, fences
  /// and bins are solid too, and a marker snapped to the side of a hedge is a
  /// different wrong answer rather than a fix.
  Set<(int, int)> buildingsIn(
    int width,
    int height,
    Set<(int, int)> solid,
  ) {
    final seen = <(int, int)>{};
    final out = <(int, int)>{};
    for (final start in solid) {
      if (seen.contains(start)) continue;
      final queue = <(int, int)>[start];
      final cluster = <(int, int)>{start};
      seen.add(start);
      while (queue.isNotEmpty) {
        final (x, y) = queue.removeLast();
        for (final n in <(int, int)>[(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]) {
          if (solid.contains(n) && seen.add(n)) {
            cluster.add(n);
            queue.add(n);
          }
        }
      }
      if (cluster.length >= 6) out.addAll(cluster);
    }
    return out;
  }

  group('map.json', () {
    late final map = loadMap('map.json');
    late final built = buildingsIn(map.width, map.height, map.solid);

    test('every spot stands on a tile you can walk on', () {
      for (final spot in kTownSpots) {
        expect(
          map.solid.contains((spot.tileX, spot.tileY)),
          isFalse,
          reason: '${spot.id} is inside a wall at (${spot.tileX}, '
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

    test('every spot is beside a building, not floating on a road', () {
      for (final spot in kTownSpots) {
        final touching = <(int, int)>[
          (spot.tileX + 1, spot.tileY),
          (spot.tileX - 1, spot.tileY),
          (spot.tileX, spot.tileY + 1),
          (spot.tileX, spot.tileY - 1),
        ].any(built.contains);
        expect(
          touching,
          isTrue,
          reason: '${spot.id} at (${spot.tileX}, ${spot.tileY}) has no '
              'building next to it — run tool/place_town_spots.py',
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
        for (final n in <(int, int)>[(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]) {
          if (free.contains(n) && seen.add(n)) queue.add(n);
        }
      }
      expect(
        seen.length / free.length,
        greaterThan(0.99),
        reason: 'the walkable area is split into pieces — '
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
        reason: 'only ${(walkable / (map.width * map.height) * 100).round()}% '
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
        reason: 'the largest reachable region is only '
            '${(best / free.length * 100).round()}% of the walkable space',
      );
    });
  });
}

/// Every marker gets its own building — on both maps.
///
/// **Why "next to a building" was not enough.** `place_town_spots.py` snapped
/// all twelve markers to a walkable tile touching a solid cluster, and it
/// worked: measured, every one of the 24 positions sat exactly one tile from
/// a building. The town still looked wrong, and the report was "I'm having a
/// cafe in the middle of the road".
///
/// Nothing stopped two markers snapping to the *same* building. On the second
/// map nine of twelve shared, with the bank, the notice board and the market
/// stalls all on one house — so walking up to a building told you nothing
/// about what was inside it, and a marker on the far wall of a house you had
/// mentally assigned to something else reads exactly like a marker floating
/// in a road.
///
/// `tool/assign_town_buildings.py` solves it as an assignment problem instead
/// of twelve independent snaps. This holds the result.
void _buildingAssignment() {
  group('every town marker has its own building', () {
    for (final map in TownMap.values) {
      test('on ${map.name}', () async {
        final data = jsonDecode(
          await File('assets/images/maps/${map.asset.split('/').last}')
              .readAsString(),
        ) as Map<String, dynamic>;

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

        // Flood-fill the solid tiles into buildings. Six tiles is the floor
        // that separates a house from a tree — snapping a shop marker to a
        // hedge is a different wrong answer, not a fix.
        final seen = <({int x, int y})>{};
        final owner = <({int x, int y}), int>{};
        var next = 0;
        for (final start in solid) {
          if (!seen.add(start)) continue;
          final queue = <({int x, int y})>[start];
          final group = <({int x, int y})>[];
          while (queue.isNotEmpty) {
            final cell = queue.removeLast();
            group.add(cell);
            for (final d in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
              final n = (x: cell.x + d.$1, y: cell.y + d.$2);
              if (solid.contains(n) && seen.add(n)) queue.add(n);
            }
          }
          if (group.length >= 6) {
            for (final cell in group) {
              owner[cell] = next;
            }
            next++;
          }
        }

        // Which buildings each marker touches. A doorstep can belong to two
        // buildings at once, so "the first one I find" is not an assignment —
        // an earlier version of this test did that and failed on a placement
        // that was actually correct.
        final touches = <String, Set<int>>{};
        for (final spot in kTownSpots) {
          final x = spot.xOn(map);
          final y = spot.yOn(map);
          final found = <int>{};
          for (final d in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
            final id = owner[(x: x + d.$1, y: y + d.$2)];
            if (id != null) found.add(id);
          }
          expect(
            found,
            isNotEmpty,
            reason:
                '${spot.id} at ($x,$y) on ${map.name} touches no building — '
                'that is the marker-in-a-road bug',
          );
          touches[spot.id] = found;
        }

        // The real property: can every marker be given a building of its
        // own? That is a bipartite matching, and asserting it directly means
        // the test passes for *any* valid placement rather than only the one
        // the tool happened to produce.
        final matchedBy = <int, String>{};
        bool augment(String spotId, Set<int> seen) {
          for (final building in touches[spotId]!) {
            if (!seen.add(building)) continue;
            final holder = matchedBy[building];
            if (holder == null || augment(holder, seen)) {
              matchedBy[building] = spotId;
              return true;
            }
          }
          return false;
        }

        final unmatched = <String>[];
        for (final spot in kTownSpots) {
          if (!augment(spot.id, <int>{})) unmatched.add(spot.id);
        }

        expect(
          unmatched,
          isEmpty,
          reason:
              'on ${map.name} these markers cannot be given a building of '
              'their own: $unmatched. Two different places sharing one house '
              'is why the town read as random. Re-run '
              'tool/assign_town_buildings.py --write',
        );
      });
    }
  });
}
