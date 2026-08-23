import 'dart:convert';
import 'dart:io';

import 'package:bonfire/bonfire.dart' show BlockMovementCollision;
import 'package:budget_app/models_Like_Skins_and_lessons_templates/town_spot_models.dart';
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
        reason: 'no collider layers means nothing can block the player, '
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
        reason: 'these perimeter tiles are walkable, so the player can walk '
            'out of the map: $gaps',
      );
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
          reason: '${spot.id} ("${spot.title}") is at '
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
            reason: '${spot.id} has a choice with no outcome line, so it '
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
            reason: '${spot.id} / "${choice.label}" gives no gold, XP or '
                'literacy back',
          );
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
          reason: 'coin at (${coin.x}, ${coin.y}) is inside a wall and can '
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
}
