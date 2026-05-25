import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import 'player_component.dart';

class CameraLeadTargetComponent extends PositionComponent {
  CameraLeadTargetComponent({
    required this.player,
    required this.mapBounds,
  }) : super(
          position: player.position.clone(),
          size: Vector2.all(1),
          anchor: Anchor.center,
        );

  final PlayerComponent player;
  final Rect mapBounds;

  static const double _leadDistance = 72;
  static const double _followSharpness = 4.4;

  @override
  void update(double dt) {
    super.update(dt);

    final motion = player.motion;
    final desired = player.position.clone();
    if (motion.length2 > 4) {
      motion.normalize();
      desired.add(motion * _leadDistance);
    }

    final factor = math.min(1.0, dt * _followSharpness);
    position += (desired - position) * factor;

    position.x = position.x.clamp(mapBounds.left, mapBounds.right).toDouble();
    position.y = position.y.clamp(mapBounds.top, mapBounds.bottom).toDouble();
  }
}
