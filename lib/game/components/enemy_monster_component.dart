import 'dart:math' as math;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class EnemyMonsterComponent extends PositionComponent with CollisionCallbacks {
  EnemyMonsterComponent({
    required super.position,
    required this.enemyName,
  }) : super(
          size: Vector2.all(58),
          anchor: Anchor.center,
        );

  final String enemyName;
  bool isDefeated = false;
  double _pulse = 0;

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
  }

  @override
  void render(Canvas canvas) {
    if (isDefeated) {
      return;
    }

    final glowPaint = Paint()
      ..color = const Color(0xFFFFD45C).withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    final bodyPaint = Paint()..color = const Color(0xFFB24F4F);
    final shellPaint = Paint()..color = const Color(0xFFFFD45C);
    final eyePaint = Paint()..color = Colors.black;

    final scale = 1 + (0.04 * (0.5 + 0.5 * (1 + math.sin(_pulse))));
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.scale(scale);

    canvas.drawCircle(Offset.zero, 28, glowPaint);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 42, height: 34),
      bodyPaint,
    );
    canvas.drawCircle(const Offset(0, -4), 14, shellPaint);
    canvas.drawCircle(const Offset(-5, -7), 2.2, eyePaint);
    canvas.drawCircle(const Offset(5, -7), 2.2, eyePaint);
    canvas.drawRect(
      Rect.fromCenter(center: const Offset(-10, 15), width: 8, height: 10),
      bodyPaint,
    );
    canvas.drawRect(
      Rect.fromCenter(center: const Offset(10, 15), width: 8, height: 10),
      bodyPaint,
    );
    canvas.restore();
  }
}
