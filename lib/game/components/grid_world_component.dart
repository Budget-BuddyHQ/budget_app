import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class GridWorldComponent extends PositionComponent {
  GridWorldComponent({
    required Vector2 mapSize,
    this.tileSize = 64,
  }) {
    size = mapSize;
    anchor = Anchor.topLeft;
  }

  final double tileSize;

  @override
  void render(Canvas canvas) {
    final basePaint = Paint()..color = const Color(0xFF0B251C);
    final gridPaint = Paint()
      ..color = const Color(0xFF85EFAC).withValues(alpha: 0.10)
      ..strokeWidth = 1;
    final accentPaint = Paint()
      ..color = const Color(0xFF163F31).withValues(alpha: 0.85);

    canvas.drawRect(size.toRect(), basePaint);

    for (double x = 0; x <= size.x; x += tileSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), gridPaint);
    }
    for (double y = 0; y <= size.y; y += tileSize) {
      canvas.drawLine(Offset(0, y), Offset(size.x, y), gridPaint);
    }

    final patches = <Rect>[
      Rect.fromLTWH(tileSize * 2, tileSize * 2, tileSize * 3, tileSize * 2),
      Rect.fromLTWH(tileSize * 8, tileSize * 5, tileSize * 2, tileSize * 3),
      Rect.fromLTWH(tileSize * 14, tileSize * 11, tileSize * 3, tileSize * 2),
      Rect.fromLTWH(tileSize * 4, tileSize * 13, tileSize * 2.5, tileSize * 2),
    ];

    for (final patch in patches) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(patch, const Radius.circular(18)),
        accentPaint,
      );
    }
  }
}
