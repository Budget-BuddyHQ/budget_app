import 'dart:math' as math;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class EnemyMonsterComponent extends PositionComponent with CollisionCallbacks {
  EnemyMonsterComponent({
    required super.position,
    required this.enemyName,
    required this.movementBounds,
    this.roamRadius = 140,
  }) : super(
          size: Vector2.all(58),
          anchor: Anchor.center,
        ) {
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
    add(
      CircleHitbox()
        ..collisionType = CollisionType.passive,
    );
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
    final squash = 1 + (math.sin(_pulse) * 0.03);
    final facingRight = _movement.x >= 0;
    final glowAlpha = 0.16 + (_spawnFlash * 0.18);

    final glowPaint = Paint()
      ..color = const Color(0xFFFFD45C).withValues(alpha: glowAlpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    final bodyPaint = Paint()..color = const Color(0xFFB24F4F);
    final shellPaint = Paint()..color = const Color(0xFFFFD45C);
    final outlinePaint = Paint()
      ..color = const Color(0xFF572727)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    final eyePaint = Paint()..color = Colors.black;

    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.scale(squash, 1 / squash);
    canvas.translate(0, bob);

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 18), width: 40, height: 12),
      Paint()..color = Colors.black.withValues(alpha: 0.20),
    );
    canvas.drawCircle(Offset.zero, 28, glowPaint);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 0), width: 42, height: 34),
      bodyPaint,
    );
    canvas.drawCircle(const Offset(0, -4), 14, shellPaint);
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 0), width: 42, height: 34),
      outlinePaint,
    );
    canvas.drawCircle(const Offset(0, -4), 14, outlinePaint);

    final headOffset = facingRight ? 5.0 : -5.0;
    canvas.drawCircle(Offset(headOffset, -10), 10, bodyPaint);
    canvas.drawCircle(Offset(headOffset - 3, -12), 2.2, eyePaint);
    canvas.drawCircle(Offset(headOffset + 3, -12), 2.2, eyePaint);

    final legWave = math.sin(_stepClock) * 2.4;
    canvas.drawRect(
      Rect.fromCenter(center: Offset(-10, 15 + legWave), width: 8, height: 10),
      bodyPaint,
    );
    canvas.drawRect(
      Rect.fromCenter(center: Offset(10, 15 - legWave), width: 8, height: 10),
      bodyPaint,
    );
    canvas.restore();
  }
}
