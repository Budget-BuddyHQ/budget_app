import 'dart:math';
import 'dart:ui';

/// Where things stand in Finance Brawl, and how the fighter moves around them.
///
/// **Reported as:** *"a player tester called the game janky: the hitboxes are
/// weird and sometimes the joystick just stops."* Both came from this file's
/// subject, and neither was one bug.
///
///  * **The trees were solid in the wrong place.** A tree's collision circle sat
///    on the point the picture was drawn from, but the picture is a canopy on a
///    trunk and almost all of its opaque pixels are in the lower half of the
///    frame. The circle was about 46 units above the tree you could see, so the
///    fighter stopped against empty grass and walked straight through the trunk.
///    [kBrawlTreeArtShift] moves the picture so its visible body sits on the
///    circle, and a test measures the real PNG to keep it there.
///  * **Movement tested each axis on its own.** Step in x, refuse it if it lands
///    inside something, then step in y and do the same. Against a round obstacle
///    that catches and lets go on alternating frames, which reads as sticking and
///    stuttering, and it leaves no way out at all if the fighter is ever inside
///    one. [moveAndSlide] pushes out along the surface instead, so walking into a
///    tree turns into walking around it.

/// Where to draw the tree sprite, relative to the point its collision circle is
/// centered on, so that the part of the picture that is a tree lands on the
/// circle.
///
/// Measured off `brawl_tree.png`: the opaque part is the bottom 47% of the frame
/// and 41% of its width, centered a little right of the middle. Drawn at the size
/// the game uses, that puts its middle about 46.5 units below the frame's center
/// and 3.5 to the right, so the frame is drawn that far up and to the left.
const Offset kBrawlTreeArtShift = Offset(-3.5, -46.5);

/// The same for a rock. Its opaque part sits a little above the frame's middle,
/// so the frame is drawn a little down.
const Offset kBrawlRockArtShift = Offset(0, 3.3);

/// How wide the rock is drawn, as a multiple of its collision radius. The
/// opaque part of the sprite is 75% of the frame, so 2.6 makes what you can see
/// about as wide as what you bump into.
const double kBrawlRockArtScale = 2.6;

/// Moves a circle of [radius] by [step], keeping it inside the arena and out of
/// every tree and rock, and returns where it ends up.
///
/// The step is applied whole, then anything it overlaps pushes it back out along
/// the line from that obstacle's center. A few passes settle a fighter wedged
/// between two obstacles or between one and a wall. Called with a zero step it
/// only does the pushing out, which is how a fighter that ended up inside
/// something is freed.
Offset moveAndSlide({
  required Offset from,
  required Offset step,
  required double radius,
  required double mapWidth,
  required double mapHeight,
  required List<Offset> trees,
  required double treeRadius,
  required List<Offset> rocks,
  required double rockRadius,
}) {
  Offset clampToArena(Offset p) => Offset(
    p.dx.clamp(radius, mapWidth - radius),
    p.dy.clamp(radius, mapHeight - radius),
  );

  var pos = clampToArena(from + step);

  Offset pushOut(Offset p, Offset center, double obstacleRadius) {
    final away = p - center;
    final distance = away.distance;
    final reach = obstacleRadius + radius;
    if (distance >= reach) return p;
    // Dead center has no direction to be pushed in. Back along the step, or
    // failing that, to the right.
    final normal = distance > 1e-6
        ? away / distance
        : (step.distance > 1e-6 ? -step / step.distance : const Offset(1, 0));
    return center + normal * reach;
  }

  for (var pass = 0; pass < 4; pass++) {
    final before = pos;
    for (final tree in trees) {
      pos = pushOut(pos, tree, treeRadius);
    }
    for (final rock in rocks) {
      pos = pushOut(pos, rock, rockRadius);
    }
    pos = clampToArena(pos);
    if ((pos - before).distance < 1e-6) break;
  }
  return pos;
}

/// Whether a circle at [pos] overlaps anything solid.
bool overlapsObstacle({
  required Offset pos,
  required double radius,
  required List<Offset> trees,
  required double treeRadius,
  required List<Offset> rocks,
  required double rockRadius,
}) {
  for (final tree in trees) {
    if ((pos - tree).distance < radius + treeRadius) return true;
  }
  for (final rock in rocks) {
    if ((pos - rock).distance < radius + rockRadius) return true;
  }
  return false;
}

/// What a touch on the screen means, as a direction and a strength.
///
/// **Why the strength.** The stick used to report a unit vector the moment the
/// finger left a six-unit dead zone, so every touch was full speed in some
/// direction and there was no way to creep. Strength now rises from a floor at
/// the edge of the dead zone to full at [maxTravel], which is what makes a thumb
/// feel like it is steering.
class StickReading {
  const StickReading(this.vector, this.knob);

  /// Direction times strength, at most length 1. Zero inside the dead zone.
  final Offset vector;

  /// Where to draw the knob, relative to the ring's center.
  final Offset knob;

  static const StickReading rest = StickReading(Offset.zero, Offset.zero);

  static const double deadZone = 6;
  static const double maxTravel = 38;

  /// The slowest a deliberate touch moves. Just outside the dead zone the stick
  /// should nudge, not do nothing.
  static const double floor = 0.3;

  /// Reads a finger that is [delta] away from where it first landed.
  factory StickReading.from(Offset delta) {
    final distance = delta.distance;
    if (distance <= deadZone) {
      return rest;
    }
    final direction = delta / distance;
    final t = ((distance - deadZone) / (maxTravel - deadZone)).clamp(0.0, 1.0);
    final strength = floor + (1 - floor) * t;
    return StickReading(
      direction * strength,
      direction * min(distance, maxTravel),
    );
  }
}
