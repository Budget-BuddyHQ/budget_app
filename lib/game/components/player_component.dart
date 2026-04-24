import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'enemy_monster_component.dart';

class PlayerComponent extends PositionComponent with CollisionCallbacks {
  PlayerComponent({
    required super.position,
    required this.joystick,
    required this.worldBounds,
    required this.collisionRects,
    required this.onEncounter,
  }) : super(
          size: Vector2(56, 56),
          anchor: Anchor.center,
        );

  final JoystickComponent joystick;
  final Rect worldBounds;
  final List<Rect> collisionRects;
  final ValueChanged<EnemyMonsterComponent> onEncounter;

  final Set<LogicalKeyboardKey> _keysPressed = <LogicalKeyboardKey>{};
  bool movementEnabled = true;
  final Vector2 _velocity = Vector2.zero();
  double _animationClock = 0;
  FacingDirection _facing = FacingDirection.down;
  Sprite? _sprite;

  static const double maxSpeed = 180;
  static const double acceleration = 880;
  static const double friction = 920;

  Vector2 get motion => _velocity.clone();

  @override
  Future<void> onLoad() async {
    try {
      _sprite = await Sprite.load('images/turtles/player_topview.png');
    } catch (_) {
      _sprite = null;
    }
    add(
      RectangleHitbox.relative(
        Vector2(0.48, 0.48),
        parentSize: size,
        anchor: Anchor.center,
      )..collisionType = CollisionType.active,
    );
  }

  void setKeyboardState(Set<LogicalKeyboardKey> keysPressed) {
    _keysPressed
      ..clear()
      ..addAll(keysPressed);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!movementEnabled) {
      _velocity.setZero();
      return;
    }

    final input = _readInputVector();
    if (input.length2 > 0) {
      input.normalize();
      _velocity.x = _approach(_velocity.x, input.x * maxSpeed, acceleration * dt);
      _velocity.y = _approach(_velocity.y, input.y * maxSpeed, acceleration * dt);
      _animationClock += dt * 8;
      _updateFacing(input);
    } else {
      _velocity.x = _approach(_velocity.x, 0, friction * dt);
      _velocity.y = _approach(_velocity.y, 0, friction * dt);
    }

    final delta = _velocity * dt;
    _moveAxis(delta.x, true);
    _moveAxis(delta.y, false);
  }

  @override
  void render(Canvas canvas) {
    if (_sprite != null) {
      _sprite!.render(
        canvas,
        position: Vector2.zero(),
        size: size,
      );
      return;
    }

    final moving = _velocity.length2 > 20;
    final stepWave = moving ? (_animationClock % 1) : 0;
    final legOffset = moving ? (stepWave < 0.5 ? -2.5 : 2.5) : 0.0;
    final headTilt = switch (_facing) {
      FacingDirection.left => -5.0,
      FacingDirection.right => 5.0,
      _ => 0.0,
    };

    final shellPaint = Paint()..color = const Color(0xFFF6E37C);
    final bodyPaint = Paint()..color = const Color(0xFF5C815D);
    final outlinePaint = Paint()
      ..color = const Color(0xFF1B5E4A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final glowPaint = Paint()
      ..color = const Color(0xFF85EFAC).withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 2), width: 44, height: 28),
      glowPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 0), width: 40, height: 28),
      shellPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 2), width: 52, height: 32),
      bodyPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(headTilt, -16), width: 18, height: 16),
      bodyPaint,
    );

    canvas.drawOval(
      Rect.fromCenter(center: Offset(-15, 16 + legOffset), width: 10, height: 8),
      bodyPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(15, 16 - legOffset), width: 10, height: 8),
      bodyPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(-18, 4 - legOffset), width: 10, height: 8),
      bodyPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(18, 4 + legOffset), width: 10, height: 8),
      bodyPaint,
    );

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 2), width: 52, height: 32),
      outlinePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 0), width: 40, height: 28),
      outlinePaint,
    );

    final eyeOffsetX = _facing == FacingDirection.left ? -3.5 : 3.5;
    canvas.drawCircle(Offset(headTilt + eyeOffsetX, -18), 1.8, Paint()..color = Colors.black);
    canvas.restore();
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is EnemyMonsterComponent && !other.isDefeated && movementEnabled) {
      onEncounter(other);
    }
  }

  Vector2 _readInputVector() {
    final keyboard = Vector2.zero();
    if (_keysPressed.contains(LogicalKeyboardKey.keyA) ||
        _keysPressed.contains(LogicalKeyboardKey.arrowLeft)) {
      keyboard.x -= 1;
    }
    if (_keysPressed.contains(LogicalKeyboardKey.keyD) ||
        _keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
      keyboard.x += 1;
    }
    if (_keysPressed.contains(LogicalKeyboardKey.keyW) ||
        _keysPressed.contains(LogicalKeyboardKey.arrowUp)) {
      keyboard.y -= 1;
    }
    if (_keysPressed.contains(LogicalKeyboardKey.keyS) ||
        _keysPressed.contains(LogicalKeyboardKey.arrowDown)) {
      keyboard.y += 1;
    }

    final stick = joystick.relativeDelta.clone();
    final combined = keyboard + stick;
    if (combined.length2 > 1) {
      combined.normalize();
    }
    return combined;
  }

  void _updateFacing(Vector2 input) {
    if (input.x.abs() > input.y.abs()) {
      _facing = input.x >= 0 ? FacingDirection.right : FacingDirection.left;
      return;
    }
    _facing = input.y >= 0 ? FacingDirection.down : FacingDirection.up;
  }

  double _approach(double current, double target, double maxDelta) {
    if (current < target) {
      return ((current + maxDelta).clamp(current, target) as num).toDouble();
    }
    return ((current - maxDelta).clamp(target, current) as num).toDouble();
  }

  void _moveAxis(double amount, bool horizontal) {
    if (amount == 0) {
      return;
    }

    if (horizontal) {
      position.x += amount;
      position.x = (position.x.clamp(
        worldBounds.left + size.x / 2,
        worldBounds.right - size.x / 2,
      ) as num)
          .toDouble();
    } else {
      position.y += amount;
      position.y = (position.y.clamp(
        worldBounds.top + size.y / 2,
        worldBounds.bottom - size.y / 2,
      ) as num)
          .toDouble();
    }

    final bounds = Rect.fromCenter(
      center: Offset(position.x, position.y),
      width: size.x * 0.48,
      height: size.y * 0.48,
    );

    for (final collisionRect in collisionRects) {
      if (!bounds.overlaps(collisionRect)) {
        continue;
      }

      if (horizontal) {
        if (amount > 0) {
          position.x = collisionRect.left - (size.x * 0.24);
        } else {
          position.x = collisionRect.right + (size.x * 0.24);
        }
      } else {
        if (amount > 0) {
          position.y = collisionRect.top - (size.y * 0.24);
        } else {
          position.y = collisionRect.bottom + (size.y * 0.24);
        }
      }
      break;
    }
  }
}

enum FacingDirection {
  up,
  down,
  left,
  right,
}
