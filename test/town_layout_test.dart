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
