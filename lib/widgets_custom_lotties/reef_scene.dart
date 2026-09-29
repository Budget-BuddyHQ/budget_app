import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The underwater art pack, as paths plus the one number Flutter cannot work
/// out for itself: how much of each 128x128 box is actually drawn.
///
/// **Why the content sizes are written down.** Every file in the pack is a
/// 128x128 box with the art floating inside it and transparent padding
/// around it — a starfish fills 58 of those 128 rows, a tall seaweed fills
/// 114. Flutter fits an image to its *file* bounds, not to the art inside
/// them, so sizing these by the box makes a rock and a seaweed that were
/// drawn at completely different scales come out the same height, and a
/// plant asked to stand on the sea floor hovers above it by however much
/// padding it happens to carry. This is the same trap `AppAssets` documents
/// for the nine-slice kit, and it is why the props below are sized by their
/// *visible* height with the box derived from it.
///
/// Every prop is bottom-anchored in its box (content bottom == 128), which is
/// what makes "stand this on the floor line" a plain bottom alignment.
abstract final class ReefArt {
  static const String root = 'assets/map_assets_coins/underwater_UI_svgs';

  /// Native tile/box edge. Everything in the pack is square at this size.
  static const double tile = 128;

  /// The sea floor. Both halves tile seamlessly left-to-right: [sandTop] is
  /// the wavy surface lip (transparent above the crest, so water shows
  /// through the dips), [sandBody] is the solid fill that runs underneath.
  static const List<String> sandTop = <String>[
    '$root/terrain_sand_top_a.png',
    '$root/terrain_sand_top_b.png',
    '$root/terrain_sand_top_c.png',
    '$root/terrain_sand_top_d.png',
  ];
  static const String sandBody = '$root/terrain_sand_a.png';

  /// The same wave painted in the pack's haze blue rather than sand — the
  /// far bank, behind the near one.
  static const String distantTop = '$root/background_terrain_top.png';
}

/// One piece of scenery that stands on the floor.
@immutable
class ReefProp {
  const ReefProp(this.asset, {required this.contentHeight});

  final String asset;

  /// Rows of the 128px box the art actually occupies, measured off the alpha
  /// channel. See [ReefArt] for why this is not optional.
  final double contentHeight;

  /// The box to hand [Image.asset] so the *drawn* part comes out
  /// [visibleHeight] tall.
  double boxFor(double visibleHeight) =>
      visibleHeight * ReefArt.tile / contentHeight;

  static const ReefProp kelpTall = ReefProp(
    '${ReefArt.root}/seaweed_green_a.png',
    contentHeight: 114,
  );
  static const ReefProp kelpShort = ReefProp(
    '${ReefArt.root}/seaweed_green_c.png',
    contentHeight: 84,
  );
  static const ReefProp kelpStub = ReefProp(
    '${ReefArt.root}/seaweed_green_d.png',
    contentHeight: 70,
  );
  static const ReefProp grass = ReefProp(
    '${ReefArt.root}/seaweed_grass_a.png',
    contentHeight: 115,
  );
  static const ReefProp coralTall = ReefProp(
    '${ReefArt.root}/seaweed_pink_a.png',
    contentHeight: 114,
  );
  static const ReefProp coralShort = ReefProp(
    '${ReefArt.root}/seaweed_pink_c.png',
    contentHeight: 84,
  );
  static const ReefProp starfish = ReefProp(
    '${ReefArt.root}/seaweed_orange_b.png',
    contentHeight: 71,
  );
  static const ReefProp rockWide = ReefProp(
    '${ReefArt.root}/rock_a.png',
    contentHeight: 60,
  );
  static const ReefProp rockTall = ReefProp(
    '${ReefArt.root}/rock_b.png',
    contentHeight: 65,
  );

  /// The haze-blue silhouettes. Same shapes, flat pale blue — the pack's own
  /// depth cue, meant to sit behind the near layer.
  static const ReefProp hazeKelp = ReefProp(
    '${ReefArt.root}/background_seaweed_a.png',
    contentHeight: 114,
  );
  static const ReefProp hazeRock = ReefProp(
    '${ReefArt.root}/background_rock_a.png',
    contentHeight: 60,
  );
  static const ReefProp hazeRockTall = ReefProp(
    '${ReefArt.root}/background_rock_b.png',
    contentHeight: 65,
  );
}

/// A fish, and how wide the drawn part of it is.
///
/// Every fish in the pack is drawn **facing right**, so swimming left is a
/// horizontal flip — checked against the art rather than assumed, because a
/// fish reversing into its own destination is the sort of thing nobody
/// notices in code and everybody notices on screen.
@immutable
class ReefFish {
  const ReefFish(this.asset, {required this.contentWidth});

  final String asset;
  final double contentWidth;

  double boxFor(double visibleWidth) =>
      visibleWidth * ReefArt.tile / contentWidth;

  static const ReefFish orange = ReefFish(
    '${ReefArt.root}/fish_orange.png',
    contentWidth: 108,
  );
  static const ReefFish blue = ReefFish(
    '${ReefArt.root}/fish_blue.png',
    contentWidth: 114,
  );
  static const ReefFish pink = ReefFish(
    '${ReefArt.root}/fish_pink.png',
    contentWidth: 78,
  );
  static const ReefFish green = ReefFish(
    '${ReefArt.root}/fish_green.png',
    contentWidth: 108,
  );

  static const List<ReefFish> shoal = <ReefFish>[orange, blue, pink, green];
}

/// The water itself: the stops a scene is graded between.
@immutable
class ReefWater {
  const ReefWater({
    required this.surface,
    required this.mid,
    required this.deep,
    required this.haze,
    required this.floorTint,
  });

  /// Brightest, at the top of the frame where the light comes in.
  final Color surface;
  final Color mid;

  /// Darkest, down at the floor.
  final Color deep;

  /// What distance does to a color — the tint the far silhouettes take, and
  /// the color of the light shafts.
  final Color haze;

  /// Multiplied over the sand.
  ///
  /// The pack's floor is cream (236, 226, 181) because it was drawn for a
  /// bright shallow aquarium. Dropped in untouched at the bottom of a dark
  /// page it is the single brightest thing on screen — a glaring slab under
  /// the content, which is exactly backwards: the floor is the part of the
  /// scene furthest from the light. Modulating it toward the deep water
  /// color sinks it without repainting the art.
  final Color floorTint;

  /// The house water.
  ///
  /// Deliberately graded toward **teal-green rather than the pack's own sky
  /// blue**. The pack is drawn for a bright cyan aquarium; dropping that
  /// straight in puts a hard cyan rectangle next to a dark green bottom bar,
  /// a dark green top bar and dark green cards, and the app stops looking
  /// like one app. Keeping the hue inside the family already there — this is
  /// `AppTheme.deepForest` walked toward teal, not away from it — buys the
  /// underwater read without the collision.
  static const ReefWater lagoon = ReefWater(
    surface: Color(0xFF1E7C74),
    mid: Color(0xFF135A55),
    deep: Color(0xFF0C2F2C),
    haze: Color(0xFF8FD8D2),
    floorTint: Color(0xFF86AB9C),
  );

  /// A darker grade for full-page backdrops, where the water sits behind
  /// content and must never compete with it.
  static const ReefWater abyss = ReefWater(
    surface: Color(0xFF13463F),
    mid: Color(0xFF0E332C),
    deep: Color(0xFF091F1B),
    haze: Color(0xFF7FC9C4),
    floorTint: Color(0xFF4E6E64),
  );

  LinearGradient get gradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[surface, mid, deep],
    stops: const <double>[0, 0.55, 1],
  );
}

/// An underwater scene: water, light, a sea floor with things growing on it,
/// fish crossing it and bubbles rising through it.
///
/// Built to be dropped into a [Stack] behind content — it paints and never
/// takes a tap ([IgnorePointer] all the way down), so a card laid over it
/// keeps every gesture it had.
///
/// **Deterministic, not random per frame.** Everything is placed from [seed]
/// through a fresh [math.Random], so the same scene comes back identical on
/// every rebuild. A reef that reshuffled its own seaweed each time the gold
/// counter changed would be worse than no reef at all, and that is exactly
/// what an unseeded `Random()` inside `build` does.
///
/// **Reduced motion is a still frame, not an empty one.** With animations
/// disabled the clock is simply never started; fish and bubbles stay where
/// their phases put them. Somebody who turns motion off should still get the
/// reef, just a photograph of it.
class ReefScene extends StatefulWidget {
  const ReefScene({
    super.key,
    this.water = ReefWater.lagoon,
    this.seed = 7,
    this.floorHeight = 62,
    this.showFloor = true,
    this.fishCount = 3,
    this.bubbleCount = 9,
    this.showLight = true,
    this.showHaze = true,
    this.period = const Duration(seconds: 30),
  });

  final ReefWater water;
  final int seed;

  /// Visible height of the sea floor, from the bottom of the scene up to the
  /// crest of the sand wave.
  final double floorHeight;

  final bool showFloor;
  final int fishCount;
  final int bubbleCount;

  /// The slow shafts of light coming down from the surface.
  final bool showLight;

  /// The far silhouette bank behind the near floor.
  final bool showHaze;

  /// One full cycle of the slowest element. Everything else is a multiple of
  /// it, so the scene repeats seamlessly instead of drifting apart.
  final Duration period;

  @override
  State<ReefScene> createState() => _ReefSceneState();
}

class _ReefSceneState extends State<ReefScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: widget.period,
  );

  late List<_FishPlan> _fish;
  late List<_BubblePlan> _bubbles;
  late List<_PlantPlan> _plants;
  late List<_PlantPlan> _hazePlants;

  @override
  void initState() {
    super.initState();
    _layout();
  }

  @override
  void didUpdateWidget(covariant ReefScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seed != widget.seed ||
        oldWidget.fishCount != widget.fishCount ||
        oldWidget.bubbleCount != widget.bubbleCount ||
        oldWidget.floorHeight != widget.floorHeight) {
      _layout();
    }
  }

  void _layout() {
    final rng = math.Random(widget.seed);

    _fish = <_FishPlan>[
      for (var i = 0; i < widget.fishCount; i++)
        _FishPlan(
          fish: ReefFish.shoal[rng.nextInt(ReefFish.shoal.length)],
          // Spread down the water column but never into the floor and never
          // so high they crop against the top edge.
          depth: 0.10 + rng.nextDouble() * 0.58,
          width: 26 + rng.nextDouble() * 20,
          phase: rng.nextDouble(),
          // At most about two laps of the slowest element: a fish crossing
          // faster than that reads as a bug rather than as a fish.
          laps: 0.8 + rng.nextDouble() * 0.9,
          rightward: rng.nextBool(),
          bob: 3 + rng.nextDouble() * 5,
        ),
    ];

    _bubbles = <_BubblePlan>[
      for (var i = 0; i < widget.bubbleCount; i++)
        _BubblePlan(
          x: rng.nextDouble(),
          size: 3 + rng.nextDouble() * 7,
          phase: rng.nextDouble(),
          laps: 1.4 + rng.nextDouble() * 1.6,
          drift: 6 + rng.nextDouble() * 14,
          opacity: 0.18 + rng.nextDouble() * 0.26,
        ),
    ];

    // Plants go down in clumps rather than at even spacing. An evenly spaced
    // row of seaweed reads as a fence; two or three growing out of the same
    // patch of sand reads as a reef.
    const near = <ReefProp>[
      ReefProp.kelpTall,
      ReefProp.kelpShort,
      ReefProp.coralTall,
      ReefProp.coralShort,
      ReefProp.grass,
      ReefProp.kelpStub,
    ];
    _plants = <_PlantPlan>[];
    var x = 0.04 + rng.nextDouble() * 0.06;
    while (x < 0.97) {
      final clump = 1 + rng.nextInt(3);
      for (var i = 0; i < clump && x < 0.99; i++) {
        _plants.add(
          _PlantPlan(
            prop: near[rng.nextInt(near.length)],
            x: x,
            heightFactor: 0.55 + rng.nextDouble() * 0.85,
            sway: 0.012 + rng.nextDouble() * 0.022,
            phase: rng.nextDouble(),
            flip: rng.nextBool(),
          ),
        );
        x += 0.022 + rng.nextDouble() * 0.03;
      }
      // Rocks and starfish on the open sand between clumps — what stops the
      // gaps reading as somewhere the scenery ran out.
      if (rng.nextDouble() < 0.55) {
        _plants.add(
          _PlantPlan(
            prop: rng.nextBool()
                ? ReefProp.rockWide
                : (rng.nextBool() ? ReefProp.rockTall : ReefProp.starfish),
            x: x,
            heightFactor: 0.30 + rng.nextDouble() * 0.28,
            sway: 0,
            phase: 0,
            flip: rng.nextBool(),
          ),
        );
        x += 0.03 + rng.nextDouble() * 0.04;
      }
      x += 0.06 + rng.nextDouble() * 0.10;
    }

    _hazePlants = <_PlantPlan>[
      for (var i = 0; i < 7; i++)
        _PlantPlan(
          prop: i.isEven
              ? ReefProp.hazeKelp
              : (i % 3 == 0 ? ReefProp.hazeRockTall : ReefProp.hazeRock),
          x: 0.03 + i * 0.145 + rng.nextDouble() * 0.05,
          heightFactor: 0.6 + rng.nextDouble() * 0.7,
          sway: 0.008,
          phase: rng.nextDouble(),
          flip: rng.nextBool(),
        ),
    ];
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      if (_clock.isAnimating) _clock.stop();
    } else if (!_clock.isAnimating) {
      _clock.repeat();
    }

    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: widget.water.gradient),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            // An unbounded parent hands a LayoutBuilder infinity, and every
            // position below is a fraction of the box — so bail rather than
            // lay anything out at NaN.
            if (!size.width.isFinite || !size.height.isFinite) {
              return const SizedBox.shrink();
            }
            return AnimatedBuilder(
              animation: _clock,
              builder: (context, _) {
                final t = _clock.value;
                return Stack(
                  clipBehavior: Clip.hardEdge,
                  children: <Widget>[
                    if (widget.showLight)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _LightShaftPainter(
                            progress: t,
                            tint: widget.water.haze,
                          ),
                        ),
                      ),
                    if (widget.showHaze) _buildHazeBank(size, t),
                    for (final bubble in _bubbles)
                      _buildBubble(bubble, size, t),
                    for (final fish in _fish) _buildFish(fish, size, t),
                    if (widget.showFloor) _buildFloor(size, t),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// The far bank: the pack's own haze-blue silhouettes, sitting behind and
  /// slightly above the near floor and held to a low opacity so they read as
  /// distance rather than as a second, brighter reef pasted on top.
  Widget _buildHazeBank(Size size, double t) {
    final bandHeight = widget.floorHeight * 1.6;
    return Positioned(
      left: 0,
      right: 0,
      bottom: widget.floorHeight * 0.62,
      height: bandHeight,
      child: Opacity(
        opacity: 0.13,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: widget.floorHeight * 0.55,
              child: Image.asset(
                ReefArt.distantTop,
                repeat: ImageRepeat.repeatX,
                alignment: Alignment.bottomLeft,
                fit: BoxFit.none,
                scale: ReefArt.tile / (widget.floorHeight * 1.1),
              ),
            ),
            for (final plant in _hazePlants)
              _plantWidget(plant, size, t, bottom: widget.floorHeight * 0.34),
          ],
        ),
      ),
    );
  }

  Widget _buildFloor(Size size, double t) {
    // The sand's crest sits `floorHeight` above the bottom and the wave dips
    // below it, so the solid body has to start above the crest line or the
    // dips show water where sand should be.
    final topTile = ReefArt.sandTop[widget.seed % ReefArt.sandTop.length];
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: widget.floorHeight * 2.2,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          // Body first, then the wavy lip over it. The lip is transparent
          // above its crest, which is what gives the floor a silhouette
          // rather than a ruled line.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: widget.floorHeight * 0.72,
            child: Image.asset(
              ReefArt.sandBody,
              repeat: ImageRepeat.repeat,
              fit: BoxFit.none,
              alignment: Alignment.bottomLeft,
              scale: ReefArt.tile / (widget.floorHeight * 1.6),
              color: widget.water.floorTint,
              colorBlendMode: BlendMode.modulate,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: widget.floorHeight * 0.52,
            height: widget.floorHeight * 0.62,
            child: Image.asset(
              topTile,
              repeat: ImageRepeat.repeatX,
              fit: BoxFit.none,
              alignment: Alignment.bottomLeft,
              scale: ReefArt.tile / (widget.floorHeight * 1.35),
              color: widget.water.floorTint,
              colorBlendMode: BlendMode.modulate,
            ),
          ),
          // Sinks the floor into shadow toward the very bottom. Without it
          // the sand is a flat slab of one color and the plants look like
          // stickers laid on it rather than things growing out of it.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: widget.floorHeight * 1.3,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    widget.water.deep.withValues(alpha: 0),
                    widget.water.deep.withValues(alpha: 0.68),
                  ],
                ),
              ),
            ),
          ),
          for (final plant in _plants)
            _plantWidget(plant, size, t, bottom: widget.floorHeight * 0.80),
        ],
      ),
    );
  }

  /// One plant, standing on [bottom] and leaning with the current.
  ///
  /// The sway rotates about the plant's *base*, not its center — kelp bends
  /// from where it is rooted. Rotating about the center slides the roots out
  /// of the sand on every swing, which was the first thing tried and is
  /// immediately obvious once you look at the bottom of the frame.
  Widget _plantWidget(
    _PlantPlan plan,
    Size size,
    double t, {
    required double bottom,
  }) {
    final box = plan.prop.boxFor(
      widget.floorHeight * plan.heightFactor * _propScale(size.width),
    );
    final angle = plan.sway == 0
        ? 0.0
        : math.sin((t * 2 + plan.phase) * 2 * math.pi) * plan.sway;
    return Positioned(
      left: plan.x * size.width - box / 2,
      bottom: bottom,
      width: box,
      height: box,
      child: Transform(
        alignment: Alignment.bottomCenter,
        transform: Matrix4.identity()
          ..rotateZ(angle)
          ..scaleByDouble(plan.flip ? -1.0 : 1.0, 1.0, 1.0, 1.0),
        child: Image.asset(plan.prop.asset, fit: BoxFit.contain),
      ),
    );
  }

  /// Props shrink in a narrow frame.
  ///
  /// Plants are placed at *fractions* of the width, so the same reef laid
  /// out at 850px and at 360px has the same number of plants — and sized off
  /// the floor height alone, each one goes from a tenth of the frame to a
  /// fifth of it. On a phone that turned the hero into a hedge with the
  /// title behind it. Scaling with the width keeps the reef reading as a
  /// wide scene at any size instead of as a close-up of two seaweeds.
  static double _propScale(double width) => (width / 640).clamp(0.55, 1.0);

  Widget _buildFish(_FishPlan plan, Size size, double t) {
    final box = plan.fish.boxFor(plan.width);
    // Travel from fully off one edge to fully off the other, so a fish never
    // pops into existence in the middle of open water.
    final lane = (t * plan.laps + plan.phase) % 1.0;
    final span = size.width + box * 2;
    final x = plan.rightward
        ? -box + lane * span
        : size.width + box - lane * span;
    final bob = math.sin((lane * 2 + plan.phase) * 2 * math.pi) * plan.bob;
    return Positioned(
      left: x,
      top: plan.depth * size.height + bob,
      width: box,
      height: box,
      child: Transform.scale(
        scaleX: plan.rightward ? 1 : -1,
        child: Image.asset(plan.fish.asset, fit: BoxFit.contain),
      ),
    );
  }

  Widget _buildBubble(_BubblePlan plan, Size size, double t) {
    final lane = (t * plan.laps + plan.phase) % 1.0;
    // Up from just below the floor to just past the surface.
    final y = size.height - lane * (size.height + plan.size * 2);
    final wobble = math.sin((lane * 3 + plan.phase) * 2 * math.pi) * plan.drift;
    // Fade in off the floor and out at the surface so bubbles neither appear
    // nor vanish with a hard edge.
    final fade = math.sin(lane * math.pi).clamp(0.0, 1.0);
    return Positioned(
      left: plan.x * size.width + wobble,
      top: y,
      width: plan.size,
      height: plan.size,
      child: Opacity(
        opacity: plan.opacity * fade,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.28),
            border: Border.all(color: Colors.white, width: 1),
          ),
        ),
      ),
    );
  }
}

@immutable
class _FishPlan {
  const _FishPlan({
    required this.fish,
    required this.depth,
    required this.width,
    required this.phase,
    required this.laps,
    required this.rightward,
    required this.bob,
  });

  final ReefFish fish;
  final double depth;
  final double width;
  final double phase;
  final double laps;
  final bool rightward;
  final double bob;
}

@immutable
class _BubblePlan {
  const _BubblePlan({
    required this.x,
    required this.size,
    required this.phase,
    required this.laps,
    required this.drift,
    required this.opacity,
  });

  final double x;
  final double size;
  final double phase;
  final double laps;
  final double drift;
  final double opacity;
}

@immutable
class _PlantPlan {
  const _PlantPlan({
    required this.prop,
    required this.x,
    required this.heightFactor,
    required this.sway,
    required this.phase,
    required this.flip,
  });

  final ReefProp prop;
  final double x;

  /// Multiple of the scene's floor height, resolved to pixels at paint time.
  final double heightFactor;

  final double sway;
  final double phase;
  final bool flip;
}

/// Sunlight coming down through moving water.
///
/// Three wide, soft, slightly tapered bands that sway across and breathe in
/// brightness. Painted rather than composed from widgets because a blurred
/// gradient per shaft is one `drawPath` each here against three more layers
/// in the tree, and this sits underneath everything else on the page.
class _LightShaftPainter extends CustomPainter {
  const _LightShaftPainter({required this.progress, required this.tint});

  final double progress;
  final Color tint;

  static const List<({double x, double width, double speed, double phase})>
  _shafts = <({double x, double width, double speed, double phase})>[
    (x: 0.18, width: 0.26, speed: 1.0, phase: 0.0),
    (x: 0.52, width: 0.19, speed: -0.7, phase: 0.33),
    (x: 0.81, width: 0.30, speed: 0.55, phase: 0.66),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (final shaft in _shafts) {
      // A slow sway across a fraction of the width rather than a full
      // traverse: shafts of light waver, they do not commute.
      final sway =
          math.sin((progress * shaft.speed + shaft.phase) * 2 * math.pi) *
          size.width *
          0.06;
      final breathe =
          0.5 + 0.5 * math.sin((progress * 2 + shaft.phase) * 2 * math.pi);
      final center = shaft.x * size.width + sway;
      final half = shaft.width * size.width / 2;

      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            tint.withValues(alpha: 0.15 + breathe * 0.07),
            tint.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.92))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);

      // Tapered: wide at the surface, narrowing as it goes down, and leaning
      // slightly so the three are not parallel.
      final path = Path()
        ..moveTo(center - half, -size.height * 0.1)
        ..lineTo(center + half, -size.height * 0.1)
        ..lineTo(center + half * 0.32 + size.width * 0.05, size.height * 0.95)
        ..lineTo(center - half * 0.32 + size.width * 0.05, size.height * 0.95)
        ..close();
      canvas.drawPath(path, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LightShaftPainter old) =>
      old.progress != progress || old.tint != tint;
}
