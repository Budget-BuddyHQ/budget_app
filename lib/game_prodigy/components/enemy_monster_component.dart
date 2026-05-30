import 'dart:math' as math;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class EnemyMonsterComponent extends PositionComponent
    with CollisionCallbacks, HasGameReference<FlameGame> {
  EnemyMonsterComponent({
    required super.position,
    required this.enemyName,
    required this.movementBounds,
    this.roamRadius = 140,
  }) : super(size: Vector2(78, 92), anchor: Anchor.center) {
    _spawnOrigin = position.clone();
    _random = math.Random(enemyName.hashCode);
  }

  final String enemyName;
  final Rect movementBounds;
  final double roamRadius;

  late final math.Random _random;
  late Vector2 _spawnOrigin;
  Vector2? _targetPosition;
  final Vector2 _movement = Vector2.zero();

  bool isDefeated = false;
  double _pulse = 0;
  double _stepClock = 0;
  double _waitTimer = 0.35;
  double _respawnTimer = 0;
  double _spawnFlash = 0;

  @override
  Future<void> onLoad() async {
    add(CircleHitbox()..collisionType = CollisionType.passive);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _pulse += dt * 3;
    _spawnFlash = math.max(0, _spawnFlash - (dt * 1.4));

    if (isDefeated) {
      if (_respawnTimer > 0) {
        _respawnTimer -= dt;
      }
      if (_respawnTimer <= 0) {
        isDefeated = false;
        _spawnFlash = 1;
        _targetPosition = null;
        _waitTimer = 0.45;
      }
      return;
    }

    if (_waitTimer > 0) {
      _waitTimer -= dt;
      _movement.setZero();
      return;
    }

    _targetPosition ??= _pickTarget();
    final target = _targetPosition!;
    final delta = target - position;

    if (delta.length2 < 14 * 14) {
      _targetPosition = null;
      _waitTimer = 0.45 + (_random.nextDouble() * 0.75);
      _movement.setZero();
      return;
    }

    delta.normalize();
    _movement.setFrom(delta);
    position += delta * (36 * dt);
    _stepClock += dt * 7;

    position.x = position.x.clamp(
      movementBounds.left + size.x / 2,
      movementBounds.right - size.x / 2,
    );
    position.y = position.y.clamp(
      movementBounds.top + size.y / 2,
      movementBounds.bottom - size.y / 2,
    );
  }

  void scheduleRespawn(
    Vector2 nextPosition, {
    Duration delay = const Duration(milliseconds: 900),
  }) {
    isDefeated = true;
    _respawnTimer = delay.inMilliseconds / 1000;
    _spawnOrigin = nextPosition.clone();
    position.setFrom(nextPosition);
    _targetPosition = null;
    _movement.setZero();
  }

  Vector2 _pickTarget() {
    final origin = _spawnOrigin;
    final rawX = origin.x + ((_random.nextDouble() * 2) - 1) * roamRadius;
    final rawY = origin.y + ((_random.nextDouble() * 2) - 1) * roamRadius;

    final clampedX = rawX.clamp(
      movementBounds.left + size.x / 2,
      movementBounds.right - size.x / 2,
    );
    final clampedY = rawY.clamp(
      movementBounds.top + size.y / 2,
      movementBounds.bottom - size.y / 2,
    );
    return Vector2(clampedX.toDouble(), clampedY.toDouble());
  }

  @override
  void render(Canvas canvas) {
    if (isDefeated) {
      return;
    }

    final bob = math.sin(_stepClock) * 2.4;
    final pulse = 1 + (math.sin(_pulse) * 0.025);
    final facingRight = _movement.x >= 0;
    final glowAlpha = 0.16 + (_spawnFlash * 0.24);
    final scale = _fieldScale;
    final cardWidth = 62.0 * scale;
    final cardHeight = 76.0 * scale;
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
    final directionNudge = facingRight ? 3.0 * scale : -3.0 * scale;

    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.scale(pulse, 1 / pulse);
    canvas.translate(0, bob);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, 27 * scale),
          width: 56 * scale,
          height: 12 * scale,
        ),
        Radius.circular(12 * scale),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.24),
    );
    canvas.drawRRect(
      cardRRect.inflate(9 * scale),
      Paint()
        ..color = const Color(0xFFFFD45C).withValues(alpha: glowAlpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 15 * scale),
    );
    canvas.drawRRect(
      cardRRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4A2026), Color(0xFF180B12)],
        ).createShader(cardRect),
    );
    canvas.drawRRect(
      cardRRect.deflate(2 * scale),
      Paint()..color = const Color(0xFFFFD45C).withValues(alpha: 0.08),
    );
    canvas.drawRRect(
      cardRRect,
      Paint()
        ..color = const Color(0xFFFFD45C).withValues(alpha: 0.62)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2 * scale,
    );
    _drawHealthBar(
      canvas,
      centerY: -cardHeight * 0.34,
      width: cardWidth * 0.70,
      scale: scale,
      accent: const Color(0xFFFFD45C),
      value: 1,
    );
    _paintIcon(
      canvas,
      Icons.crisis_alert_rounded,
      Offset(directionNudge, -2 * scale),
      34 * scale,
      const Color(0xFFFFD45C),
    );
    _paintIcon(
      canvas,
      Icons.bolt_rounded,
      Offset(-14 * scale + directionNudge, 14 * scale),
      18 * scale,
      const Color(0xFFFF6B6B),
    );
    _paintLabel(
      canvas,
      'FOE',
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
}
