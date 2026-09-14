import 'dart:math' as math;
import 'package:bonfire/bonfire.dart';
import 'package:flutter/material.dart'
    show
        Colors,
        EdgeInsets,
        Offset,
        Paint,
        PaintingStyle,
        Radius,
        RRect,
        Rect,
        StrokeCap;

import '../../../constants/app_assets.dart';
import '../../../models_Like_Skins_and_lessons_templates/town_spot_models.dart';

/// Where the town's joystick sits, in one place.
///
/// The joystick and the tap-to-walk check both read this, so the two cannot
/// disagree about where the stick is. The values are Bonfire's own defaults,
/// written out: bottom-left, 80px across, 100px in from the corner.
class TownJoystickLayout {
  const TownJoystickLayout._();

  static const double size = 80;
  static const EdgeInsets margin = EdgeInsets.all(100);

  /// How far outside its circle Bonfire still starts a drag. From
  /// `JoystickDirectional.directionalDown`, which inflates the stick's
  /// bounds by 50 on every side.
  static const double grabSlop = 50;

  /// A little more on top, so a thumb that lands just past the grab area is
  /// ignored rather than sending the player walking to the corner.
  static const double tapSlop = 20;

  /// Whether a touch at [screen] belongs to the joystick, on a viewport of
  /// [viewport] logical pixels. Same coordinate space as
  /// `GestureEvent.screenPosition` and the joystick's own hit test.
  static bool owns(Offset screen, Vector2 viewport) {
    final radius = size / 2;
    final centre = Offset(
      margin.left + radius,
      viewport.y - margin.bottom - radius,
    );
    return Rect.fromCircle(
      center: centre,
      radius: radius + grabSlop + tapSlop,
    ).contains(screen);
  }
}

class TownPlayer extends SimplePlayer
    with BlockMovementCollision, PathFinding, TapGesture {
  TownPlayer({
    required super.position,
    required super.size,
    required SimpleDirectionAnimation super.animation,
    super.speed,
  });

  @override
  Future<void> onLoad() {
    add(
      RectangleHitbox(
        size: Vector2(size.x * 0.55, size.y * 0.35),
        position: Vector2(size.x * 0.225, size.y * 0.6),
      ),
    );
    return super.onLoad();
  }

  @override
  void onTap() {}

  /// Whether the joystick (or a movement key) is currently held.
  bool _stickHeld = false;

  /// The joystick takes over from a tap-to-walk path the moment it moves.
  ///
  /// Without this the two fought: a path set by an earlier tap kept pulling
  /// the player toward its target while the stick pushed another way.
  @override
  void onJoystickChangeDirectional(JoystickDirectionalEvent event) {
    _stickHeld = event.directional != JoystickMoveDirectional.IDLE;
    if (_stickHeld && isMovingAlongThePath) {
      stopMoveAlongThePath();
    }
    super.onJoystickChangeDirectional(event);
  }

  /// Tap anywhere on the map to walk there — but not on the joystick.
  ///
  /// **Why the joystick was broken.** Bonfire hands every touch-down to both
  /// the joystick and this player, and `onTapDownScreen` fires for all of
  /// them. So putting a thumb on the stick *also* set a walk path to the
  /// spot under the thumb — the bottom-left of the screen — and from then on
  /// the stick and the path pulled the character in two directions. It read
  /// as a joystick that steers wrong, sticks, or drags the player to the
  /// corner.
  ///
  /// A touch in the joystick's area, or any tap while the stick is held with
  /// the other thumb, is now left to the joystick.
  ///
  /// (This used to be `onTapDown`, which Bonfire only fires for taps *on the
  /// player sprite*, so tap-to-walk did nothing. `onTapDownScreen` is the one
  /// that fires anywhere.)
  @override
  void onTapDownScreen(GestureEvent event) {
    super.onTapDownScreen(event);
    if (_stickHeld) return;
    if (TownJoystickLayout.owns(
      event.screenPosition.toOffset(),
      gameRef.camera.viewport.virtualSize,
    )) {
      return;
    }
    moveAlongThePath([event.worldPosition]);
  }
}

class TownSpotComponent extends GameComponent with Sensor<Player> {
  TownSpotComponent({
    required this.spot,
    required this.townMap,
    required this.onEnter,
    required this.onExit,
    required this.isVisited,
    this.isLocked = false,
  }) {
    // Which town decides where this marker stands. The two maps put their
    // buildings in entirely different places, so a marker pinned to one set
    // of coordinates ends up inside a wall on the other.
    final pixels = townTileToPixels(spot.xOn(townMap), spot.yOn(townMap));
    position = Vector2(pixels.dx - 8, pixels.dy - 8);
    size = Vector2.all(32);
  }

  final TownSpot spot;

  /// Whether this building wants a lesson finished first.
  ///
  /// Drawn differently rather than hidden. A missing marker reads as a town
  /// with holes in it; a locked one reads as somewhere to come back to, which
  /// is the whole point — the lock exists to send somebody to a lesson, not
  /// to keep them out of a building. See `town_unlocks.dart`.
  final bool isLocked;
  final TownMap townMap;
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

    final wave = (math.sin(_pulse * math.pi) + 1) / 2;
    final haloRadius = 10 + (wave * 3);

    canvas.drawCircle(
      centre,
      haloRadius + 4,
      Paint()
        ..color = accent.withValues(
          alpha: isLocked ? 0.08 : (visited ? 0.10 : 0.22),
        ),
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

    if (isLocked) {
      // A padlock, drawn rather than hidden. A missing marker reads as a town
      // with holes in it; a locked one reads as somewhere to come back to.
      final body = Rect.fromCenter(
        center: Offset(centre.dx, centre.dy + 1.5),
        width: 8,
        height: 6.5,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(body, const Radius.circular(1.5)),
        Paint()..color = Colors.white,
      );
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(centre.dx, centre.dy - 2),
          width: 5.5,
          height: 6,
        ),
        math.pi,
        math.pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..color = Colors.white,
      );
      super.render(canvas);
      return;
    }

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

class TownNpcComponent extends SimpleNpc with Sensor<Player> {
  TownNpcComponent({
    required this.npc,
    // Which town this is. NPCs stand somewhere different on the second map,
    // and used not to be drawn there at all — see `TownNpc.tileX2`.
    required TownMap map,
    required Future<SpriteAnimation> idle,
    required Future<SpriteAnimation> walk,
    required this.onEnter,
    required this.onExit,
  }) : _home = Vector2(npc.xOn(map) * 16.0, npc.yOn(map) * 16.0),
       super(
         position: Vector2(npc.xOn(map) * 16.0, npc.yOn(map) * 16.0),
         size: Vector2(26 * AppAssets.npcAspectRatio, 26),
         animation: SimpleDirectionAnimation(idleRight: idle, runRight: walk),
       );

  final TownNpc npc;
  final void Function(TownNpc npc) onEnter;
  final void Function(TownNpc npc) onExit;

  final Vector2 _home;

  static const double _patrolSpeed = 14;
  static const double _pauseSeconds = 1.6;

  double _progress = 0;
  int _direction = 1;
  double _pause = 0;
  bool _talking = false;

  double get _range => npc.patrolTiles * 16.0;

  @override
  void update(double dt) {
    super.update(dt);
    if (npc.patrolTiles <= 0) return;

    if (_talking) {
      _playIdle();
      return;
    }

    if (_pause > 0) {
      _pause -= dt;
      _playIdle();
      return;
    }

    _progress += _direction * _patrolSpeed * dt;
    if (_progress >= _range || _progress <= 0) {
      _progress = _progress.clamp(0, _range);
      _direction = -_direction;
      _pause = _pauseSeconds;
    }

    position = npc.patrolHorizontal
        ? Vector2(_home.x + _progress, _home.y)
        : Vector2(_home.x, _home.y + _progress);

    if (npc.patrolHorizontal) {
      if (_direction > 0) {
        animation?.play(SimpleAnimationEnum.runRight);
      } else {
        animation?.play(SimpleAnimationEnum.runLeft);
      }
    } else {
      animation?.play(SimpleAnimationEnum.runRight);
    }
  }

  void _playIdle() => animation?.play(SimpleAnimationEnum.idleRight);

  @override
  void onContact(Player component) {
    _talking = true;
    onEnter(npc);
  }

  @override
  void onContactExit(Player component) {
    _talking = false;
    onExit(npc);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(
      Offset(size.x / 2, -5),
      3,
      Paint()..color = const Color(0xFFFFD45C),
    );
    super.render(canvas);
  }
}

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
    canvas.drawCircle(centre, 6, Paint()..color = const Color(0xFFFFD45C));
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
