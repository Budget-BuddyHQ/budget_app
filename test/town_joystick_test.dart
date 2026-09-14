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

  Offset stickCentre(Vector2 screen) => Offset(
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
      final centre = stickCentre(size);

      test('a thumb on the stick is not a tap on the map', () {
        expect(TownJoystickLayout.owns(centre, size), isTrue);
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
            TownJoystickLayout.owns(centre + offset, size),
            isTrue,
            reason:
                'a drag starting at ${centre + offset} moves the stick '
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
}
