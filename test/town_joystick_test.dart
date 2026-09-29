import 'dart:io';

import 'package:bonfire/bonfire.dart' show Vector2;
import 'package:flutter_test/flutter_test.dart';

import 'package:budget_app/screens_minigames_admin_etc/Gameplay/adventure/town_components.dart';

/// The joystick and tap-to-walk must not both answer the same touch.
///
/// **Reported as:** "the joystick is broken". Bonfire gives every touch-down
/// to the joystick *and* to the player's `onTapDownScreen`, which set a walk
/// path to wherever the finger landed. A thumb on the stick therefore also
/// sent the player walking to the bottom-left corner, and the path and the
/// stick fought for the rest of the drag.
void main() {
  const radius = TownJoystickLayout.size / 2;

  Offset stickCenter(Vector2 screen) => Offset(
    TownJoystickLayout.margin.left + radius,
    screen.y - TownJoystickLayout.margin.bottom - radius,
  );

  for (final screen in <String, Vector2>{
    'phone portrait': Vector2(390, 844),
    'phone landscape': Vector2(844, 390),
    'tablet': Vector2(1024, 768),
  }.entries) {
    group(screen.key, () {
      final size = screen.value;
      final center = stickCenter(size);

      test('a thumb on the stick is not a tap on the map', () {
        expect(TownJoystickLayout.owns(center, size), isTrue);
      });

      test('anywhere Bonfire would start a drag is the joystick\'s', () {
        // Bonfire grabs up to `grabSlop` outside the stick's circle.
        final reach = radius + TownJoystickLayout.grabSlop;
        for (final offset in [
          Offset(reach, 0),
          Offset(-reach, 0),
          Offset(0, reach),
          Offset(0, -reach),
          Offset(reach, reach),
        ]) {
          expect(
            TownJoystickLayout.owns(center + offset, size),
            isTrue,
            reason:
                'a drag starting at ${center + offset} moves the stick '
                'and would also walk the player there',
          );
        }
      });

      test('a tap on the open map still walks there', () {
        for (final point in [
          Offset(size.x / 2, size.y / 2),
          Offset(size.x - 60, 60),
          Offset(size.x - 60, size.y - 60),
        ]) {
          expect(
            TownJoystickLayout.owns(point, size),
            isFalse,
            reason: '$point is nowhere near the stick',
          );
        }
      });
    });
  }

  group('tap-to-walk uses real pathfinding', () {
    // **Reported as:** "I moved my character on the map once and after that
    // it just kept glitching like that back and forth." `moveAlongThePath`
    // and `moveToPositionWithPathFinding` sound interchangeable and are not:
    // the former walks straight toward whatever point it is given, with no
    // idea the map has buildings in it; the latter runs Bonfire's A* over
    // the map's actual collision barriers first. `onTapDownScreen` used to
    // call the straight-line version directly on the tapped point, so a tap
    // on or behind a building sent the player walking straight into it --
    // and once blocked, nothing rerouted or gave up. Bonfire's own
    // `moveToPosition` reports "keep going" for anything that has not
    // physically arrived, with no concept of "blocked", so the per-frame
    // walk loop re-issued the same collision forever: the character glitching
    // in place, back and forth, exactly as reported.
    //
    // This is a source check, not a live one, because driving a real Bonfire
    // `TownPlayer` through a tap needs a running game loop and an actual map
    // -- see the comment on `TownPlayer opts into BlockMovementCollision` in
    // town_map_test.dart for the same constraint.
    final source = File(
      'lib/screens_minigames_admin_etc/Gameplay/adventure/town_components.dart',
    ).readAsStringSync();

    test('onTapDownScreen routes around obstacles instead of into them', () {
      expect(
        source.contains('moveToPositionWithPathFinding(event.worldPosition)'),
        isTrue,
        reason: 'a tap has to be pathfound around buildings, not walked to '
            'in a straight line',
      );
      expect(
        source.contains('moveAlongThePath([event.worldPosition])'),
        isFalse,
        reason: 'this is the exact bug that shipped: a straight-line walk '
            'has no idea a building is in the way, and once blocked by it '
            'never stops trying',
      );
    });
  });
}
