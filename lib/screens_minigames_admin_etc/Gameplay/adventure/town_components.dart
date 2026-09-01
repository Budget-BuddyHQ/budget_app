import 'dart:math' as math;
import 'package:bonfire/bonfire.dart';
import 'package:flutter/material.dart'
    show Colors, Paint, PaintingStyle, StrokeCap;

import '../../../constants/app_assets.dart';
import '../../../models_Like_Skins_and_lessons_templates/town_spot_models.dart';

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

  @override
  bool onTapDown(GestureEvent event) {
    moveAlongThePath([event.worldPosition]);
    return super.onTapDown(event);
  }
}

class TownSpotComponent extends GameComponent with Sensor<Player> {
  TownSpotComponent({
    required this.spot,
    required this.onEnter,
    required this.onExit,
    required this.isVisited,
  }) {
    final pixels = townTileToPixels(spot.tileX, spot.tileY);
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
    required Future<SpriteAnimation> idle,
    required Future<SpriteAnimation> walk,
    required this.onEnter,
    required this.onExit,
  }) : _home = Vector2(npc.tileX * 16.0, npc.tileY * 16.0),
       super(
         position: Vector2(npc.tileX * 16.0, npc.tileY * 16.0),
         size: Vector2(26 * AppAssets.npcAspectRatio, 26),
         animation: SimpleDirectionAnimation(
           idleRight: idle,
           runRight: walk,
         ),
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