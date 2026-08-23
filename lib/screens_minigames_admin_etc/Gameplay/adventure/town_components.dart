import 'dart:math' as math;

import 'package:bonfire/bonfire.dart';
import 'package:flutter/material.dart'
    show Colors, Paint, PaintingStyle, StrokeCap;

import '../../../constants/app_assets.dart';
import '../../../models_Like_Skins_and_lessons_templates/town_spot_models.dart';

/// The player, with collision actually turned on.
///
/// **This is the fix for walking through walls and off the map.** Bonfire's
/// [SimplePlayer] mixes in `Movement`, `Attackable`, `Vision`,
/// `PlayerControllerListener` and `MovementByJoystick` — but *not*
/// `BlockMovementCollision`, and it ships with no hitbox at all. So the
/// map's `"collider": true` layers were being built into real
/// `RectangleHitbox`es the whole time and the player simply had nothing to
/// collide with, and drifted straight through the boundary wall into the
/// void. Only `PlatformPlayer` gets the mixin by default in this version;
/// a top-down player has to opt in like this.
class TownPlayer extends SimplePlayer with BlockMovementCollision {
  TownPlayer({
    required super.position,
    required super.size,
    required SimpleDirectionAnimation super.animation,
  });

  @override
  Future<void> onLoad() {
    // A "feet" hitbox rather than one covering the whole sprite: it's
    // narrower and sits in the bottom third, so the character's head can
    // pass in front of a wall above them the way top-down RPGs expect,
    // instead of bumping a full tile early.
    add(
      RectangleHitbox(
        size: Vector2(size.x * 0.55, size.y * 0.35),
        position: Vector2(size.x * 0.225, size.y * 0.6),
      ),
    );
    return super.onLoad();
  }
}

/// A place you can walk into — store, bank, school, and so on. Uses
/// Bonfire's [Sensor] mixin so it fires on overlap rather than needing a
/// tap target, then hands the spot up to Flutter to render the prompt.
class TownSpotComponent extends GameComponent with Sensor<Player> {
  TownSpotComponent({
    required this.spot,
    required this.onEnter,
    required this.onExit,
    required this.isVisited,
  }) {
    final pixels = townTileToPixels(spot.tileX, spot.tileY);
    // Sized a little over one tile and nudged back by the overhang so the
    // sensor is centred on its tile rather than hanging off the corner.
    position = Vector2(pixels.dx - 8, pixels.dy - 8);
    size = Vector2.all(32);
  }

  final TownSpot spot;
  final void Function(TownSpot spot) onEnter;
  final void Function(TownSpot spot) onExit;
  final bool Function(String id) isVisited;

  double _pulse = 0;

  @override
  void onContact(Player component) => onEnter(spot);

  @override
  void onContactExit(Player component) => onExit(spot);

  @override
  void update(double dt) {
    _pulse = (_pulse + dt) % 2.0;
    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    final visited = isVisited(spot.id);
    final accent = spot.kind.accent;
    final centre = Offset(size.x / 2, size.y / 2);

    // A soft breathing halo so a spot reads as "interactive" from across
    // the map, the way a glowing object does in a point-and-click game.
    final wave = (math.sin(_pulse * math.pi) + 1) / 2;
    final haloRadius = 10 + (wave * 3);

    canvas.drawCircle(
      centre,
      haloRadius + 4,
      Paint()..color = accent.withValues(alpha: visited ? 0.10 : 0.22),
    );
    canvas.drawCircle(
      centre,
      haloRadius,
      Paint()..color = accent.withValues(alpha: visited ? 0.28 : 0.55),
    );
    canvas.drawCircle(
      centre,
      haloRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = visited ? accent.withValues(alpha: 0.6) : Colors.white,
    );

    // A tick once you've been in, so the map doubles as the checklist.
    if (visited) {
      final tick = Path()
        ..moveTo(centre.dx - 4, centre.dy)
        ..lineTo(centre.dx - 1, centre.dy + 3.5)
        ..lineTo(centre.dx + 4.5, centre.dy - 3);
      canvas.drawPath(
        tick,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round
          ..color = Colors.white,
      );
    }
    super.render(canvas);
  }
}

/// A townsperson: a looping idle animation from the real NPC frame sets in
/// `assets/map_assets_coins/`, plus a sensor that surfaces their dialogue
/// when you walk up.
///
/// Uses `SimpleNpc` rather than a bare component so it sits in Bonfire's
/// NPC layer and renders/sorts with the rest of the world.
class TownNpcComponent extends SimpleNpc with Sensor<Player> {
  TownNpcComponent({
    required this.npc,
    required Future<SpriteAnimation> idle,
    required this.onEnter,
    required this.onExit,
  }) : super(
         position: Vector2(
           npc.tileX * 16.0,
           npc.tileY * 16.0,
         ),
         // Height-first so the frames keep their 102:116 shape — sizing an
         // NPC into a square squashes it the same way it squashed the
         // player (see [TownPlayer]).
         size: Vector2(26 * AppAssets.npcAspectRatio, 26),
         // These NPCs stand still, so every facing is the same idle loop —
         // `SimpleDirectionAnimation` only requires the two "right" ones.
         animation: SimpleDirectionAnimation(
           idleRight: idle,
           runRight: idle,
         ),
       );

  final TownNpc npc;
  final void Function(TownNpc npc) onEnter;
  final void Function(TownNpc npc) onExit;

  @override
  void onContact(Player component) => onEnter(npc);

  @override
  void onContactExit(Player component) => onExit(npc);

  @override
  void render(Canvas canvas) {
    // A small "talk to me" pip above the head, so an NPC reads as
    // interactive rather than scenery.
    canvas.drawCircle(
      Offset(size.x / 2, -5),
      3,
      Paint()..color = const Color(0xFFFFD45C),
    );
    super.render(canvas);
  }
}

/// A coin lying on the ground. Collected by walking over it.
class TownCoinComponent extends GameComponent with Sensor<Player> {
  TownCoinComponent({
    required this.value,
    required int tileX,
    required int tileY,
    required this.onCollect,
  }) {
    final pixels = townTileToPixels(tileX, tileY);
    position = Vector2(pixels.dx, pixels.dy);
    size = Vector2.all(16);
  }

  final int value;
  final void Function(int value) onCollect;

  bool _taken = false;
  double _bob = 0;

  @override
  void onContact(Player component) {
    if (_taken) {
      return;
    }
    // Guarded because Sensor fires on an interval while overlapping —
    // without this a coin pays out repeatedly for one walk-over.
    _taken = true;
    onCollect(value);
    removeFromParent();
  }

  @override
  void update(double dt) {
    _bob = (_bob + dt) % 2.0;
    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    final lift = math.sin(_bob * math.pi) * 1.5;
    final centre = Offset(size.x / 2, size.y / 2 + lift);
    canvas.drawCircle(
      centre,
      6,
      Paint()..color = const Color(0xFFFFD45C),
    );
    canvas.drawCircle(
      centre,
      6,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFF8A6400),
    );
    canvas.drawCircle(
      Offset(centre.dx - 1.5, centre.dy - 1.5),
      1.6,
      Paint()..color = Colors.white.withValues(alpha: 0.75),
    );
    super.render(canvas);
  }
}
