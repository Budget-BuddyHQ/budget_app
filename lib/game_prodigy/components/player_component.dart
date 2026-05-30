import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'enemy_monster_component.dart';

class PlayerComponent extends PositionComponent
    with CollisionCallbacks, HasGameReference<FlameGame> {
  PlayerComponent({
    required super.position,
    required this.joystick,
    required this.worldBounds,
    required this.collisionRects,
    required this.onEncounter,
  }) : super(size: Vector2(78, 92), anchor: Anchor.center);

  final JoystickComponent joystick;
  final Rect worldBounds;
  final List<Rect> collisionRects;
  final ValueChanged<EnemyMonsterComponent> onEncounter;

  final Set<LogicalKeyboardKey> _keysPressed = <LogicalKeyboardKey>{};
  bool movementEnabled = true;
  final Vector2 _velocity = Vector2.zero();
  Vector2? _pointerTarget;
  Vector2? _pointerDirection;
  double _animationClock = 0;
  FacingDirection _facing = FacingDirection.down;

  static const double maxSpeed = 180;
  static const double acceleration = 880;
  static const double friction = 920;
  static const double pointerStopRadius = 18;

  Vector2 get motion => _velocity.clone();

  @override
  Future<void> onLoad() async {
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

  void setPointerTarget(Vector2 worldPosition) {
    _pointerTarget = worldPosition.clone();
  }

  void clearPointerTarget() {
    _pointerTarget = null;
  }

  void setPointerDirection(Vector2 direction) {
    if (direction.length2 == 0) {
      _pointerDirection = null;
      return;
    }

    _pointerTarget = null;
    _pointerDirection = direction.normalized();
  }

  void clearPointerDirection() {
    _pointerDirection = null;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!movementEnabled) {
      _velocity.setZero();
      _pointerTarget = null;
      _pointerDirection = null;
      return;
    }

    final input = _readInputVector();
    if (input.length2 > 0) {
      input.normalize();
      _velocity.x = _approach(
        _velocity.x,
        input.x * maxSpeed,
        acceleration * dt,
      );
      _velocity.y = _approach(
        _velocity.y,
        input.y * maxSpeed,
        acceleration * dt,
      );
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
    final moving = _velocity.length2 > 20;
    final stepWave = moving ? (_animationClock % 1) : 0;
    final bob = moving ? (stepWave < 0.5 ? -2.0 : 2.0) : 0.0;
    final scale = _fieldScale;
    final cardWidth = 60.0 * scale;
    final cardHeight = 74.0 * scale;
    final radius = 18.0 * scale;
    final cardRect = Rect.fromCenter(
      center: Offset.zero,
      width: cardWidth,
      height: cardHeight,
    );
    final cardRRect = RRect.fromRectAndRadius(
      cardRect,
      Radius.circular(radius),
    );
    final directionNudge = switch (_facing) {
      FacingDirection.left => -3.0 * scale,
      FacingDirection.right => 3.0 * scale,
      _ => 0.0,
    };

    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.translate(0, bob);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, 26 * scale),
          width: 58 * scale,
          height: 14 * scale,
        ),
        Radius.circular(12 * scale),
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 * scale),
    );
    canvas.drawRRect(
      cardRRect.inflate(10 * scale),
      Paint()
        ..color = const Color(0xFF85EFAC).withValues(alpha: 0.20)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 18 * scale),
    );
    canvas.drawRRect(
      cardRRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF173E31), Color(0xFF071711)],
        ).createShader(cardRect),
    );
    canvas.drawRRect(
      cardRRect.deflate(2 * scale),
      Paint()..color = Colors.white.withValues(alpha: 0.05),
    );
    canvas.drawRRect(
      cardRRect,
      Paint()
        ..color = const Color(0xFF85EFAC).withValues(alpha: 0.58)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2 * scale,
    );
    canvas.drawCircle(
      Offset(directionNudge, -2 * scale),
      24 * scale,
      Paint()
        ..color = const Color(0xFF85EFAC).withValues(alpha: 0.48)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6 * scale,
    );
    canvas.drawCircle(
      Offset(directionNudge, -2 * scale),
      20 * scale,
      Paint()..color = const Color(0xFF85EFAC).withValues(alpha: 0.10),
    );
    _drawHealthBar(
      canvas,
      centerY: -cardHeight * 0.34,
      width: cardWidth * 0.68,
      scale: scale,
      accent: const Color(0xFF85EFAC),
      value: 1,
    );
    _paintIcon(
      canvas,
      Icons.shield_rounded,
      Offset(directionNudge, -2 * scale),
      34 * scale,
      const Color(0xFF85EFAC),
    );
    _paintIcon(
      canvas,
      Icons.flash_on_rounded,
      Offset(14 * scale + directionNudge, 14 * scale),
      18 * scale,
      const Color(0xFFFFD45C),
    );
    _paintLabel(
      canvas,
      'YOU',
      Offset(0, cardHeight * 0.31),
      10 * scale,
      const Color(0xFFFFFFFF),
    );
    canvas.restore();
  }

  double get _fieldScale {
    return (game.size.x / 900).clamp(0.78, 1.22).toDouble();
  }

  void _drawHealthBar(
    Canvas canvas, {
    required double centerY,
    required double width,
    required double scale,
    required Color accent,
    required double value,
  }) {
    final background = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(0, centerY),
        width: width,
        height: 5 * scale,
      ),
      Radius.circular(8 * scale),
    );
    final fill = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        -width / 2,
        centerY - (2.5 * scale),
        width * value,
        5 * scale,
      ),
      Radius.circular(8 * scale),
    );

    canvas.drawRRect(
      background,
      Paint()..color = Colors.black.withValues(alpha: 0.34),
    );
    canvas.drawRRect(fill, Paint()..color = accent);
  }

  void _paintIcon(
    Canvas canvas,
    IconData icon,
    Offset center,
    double size,
    Color color,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          color: color,
          fontSize: size,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  void _paintLabel(
    Canvas canvas,
    String label,
    Offset center,
    double size,
    Color color,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is EnemyMonsterComponent &&
        !other.isDefeated &&
        movementEnabled) {
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
    final pointer = _pointerDirection?.clone() ?? _readPointerVector();
    final combined = keyboard + stick + pointer;
    if (combined.length2 > 1) {
      combined.normalize();
    }
    return combined;
  }

  Vector2 _readPointerVector() {
    final target = _pointerTarget;
    if (target == null) {
      return Vector2.zero();
    }

    final delta = target - position;
    if (delta.length2 <= pointerStopRadius * pointerStopRadius) {
      _pointerTarget = null;
      return Vector2.zero();
    }

    return delta..normalize();
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
      position.x =
          (position.x.clamp(
                    worldBounds.left + size.x / 2,
                    worldBounds.right - size.x / 2,
                  )
                  as num)
              .toDouble();
    } else {
      position.y += amount;
      position.y =
          (position.y.clamp(
                    worldBounds.top + size.y / 2,
                    worldBounds.bottom - size.y / 2,
                  )
                  as num)
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

enum FacingDirection { up, down, left, right }
